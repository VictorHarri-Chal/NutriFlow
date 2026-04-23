# frozen_string_literal: true

class StatisticsController < ApplicationController
  VALID_PERIODS = [7, 30, 90, 365].freeze

  def index
    @period = VALID_PERIODS.include?(params[:period]&.to_i) ? params[:period].to_i : 30

    @available_tabs = ["nutrition"]
    @available_tabs << "training"  if current_user.show_workout_section?
    @available_tabs << "cardio"    if current_user.show_cardio_section?
    @available_tabs << "bien_etre" if current_user.show_day_note?

    requested = params[:tab]
    if @available_tabs.include?(requested)
      @tab = requested
      session[:statistics_tab] = @tab
    elsif @available_tabs.include?(session[:statistics_tab])
      @tab = session[:statistics_tab]
    else
      @tab = "nutrition"
      session[:statistics_tab] = @tab
    end

    @from = @period.days.ago.to_date

    case @tab
    when "nutrition"  then load_nutrition_stats
    when "training"   then load_training_stats
    when "cardio"     then load_cardio_stats
    when "bien_etre"  then load_wellbeing_stats
    end
  end

  private

  # ── Nutrition ───────────────────────────────────────────────────────────────

  def load_nutrition_stats
    days = current_user.days
                       .where(date: @from..Date.today)
                       .includes(
                         day_foods:   [:food, :day_food_group],
                         day_recipes: [:day_food_group, { recipe: { recipe_items: :food } }]
                       )
                       .order(:date)

    @logged_days = days.select { |d| d.day_foods.any? || d.day_recipes.any? }

    if @logged_days.any?
      totals = @logged_days.map { |d| day_macros(d) }
      n = @logged_days.size.to_f
      @avg_calories = (totals.sum { |t| t[:calories] } / n).round
      @avg_proteins = (totals.sum { |t| t[:proteins] } / n).round(1)
      @avg_carbs    = (totals.sum { |t| t[:carbs] }    / n).round(1)
      @avg_fats     = (totals.sum { |t| t[:fats] }     / n).round(1)

      # Macros donut (kcal from each macro)
      @macros_donut_data   = [(@avg_proteins * 4).round, (@avg_carbs * 4).round, (@avg_fats * 9).round]
      @macros_donut_labels = [
        t("views.statistics.nutrition.macro_proteins"),
        t("views.statistics.nutrition.macro_carbs"),
        t("views.statistics.nutrition.macro_fats")
      ]

      # Meal breakdown donut (top 5 groups by calorie share)
      meal_totals = Hash.new(0.0)
      @logged_days.each do |d|
        (d.day_foods + d.day_recipes).each do |entry|
          group_name = entry.day_food_group&.name || t("views.statistics.nutrition.no_group")
          meal_totals[group_name] += entry.total_calories.to_f
        end
      end
      sorted_meals = meal_totals.sort_by { |_, v| -v }.first(5)
      @meal_breakdown_labels = sorted_meals.map(&:first)
      @meal_breakdown_data   = sorted_meals.map { |_, v| v.round }
    end

    @calorie_goal      = current_user.profile&.calories_needed_for_goal.to_i
    @days_logged_count = @logged_days.size
    @total_period_days = (Date.today - @from).to_i + 1

    # Streak
    logged_dates    = @logged_days.map(&:date).sort
    @current_streak = calc_current_streak(logged_dates)
    @best_streak    = calc_best_streak(logged_dates)

    # Charts — daily for ≤ 30 days, weekly otherwise
    days_by_date = days.index_by(&:date)
    range        = (@from..Date.today).to_a

    if @period <= 30
      @cal_labels     = range.map { |d| l(d, format: :short) }
      @cal_data       = range.map { |d| days_by_date[d] ? day_macros(days_by_date[d])[:calories] : 0 }
      @protein_labels = @cal_labels
      @protein_data   = range.map { |d| days_by_date[d] ? day_macros(days_by_date[d])[:proteins] : 0 }
    else
      weeks           = range.group_by(&:beginning_of_week).sort
      @cal_labels     = weeks.map { |w, _| l(w, format: :short) }
      @cal_data       = weeks.map { |_, wds| wds.sum { |d| days_by_date[d] ? day_macros(days_by_date[d])[:calories] : 0 } }
      @protein_labels = @cal_labels
      @protein_data   = weeks.map do |_, wds|
        vals = wds.filter_map { |d| days_by_date[d] ? day_macros(days_by_date[d])[:proteins] : nil }
        vals.any? ? (vals.sum / vals.size.to_f).round(1) : 0
      end
    end
  end

  # ── Training ─────────────────────────────────────────────────────────────────

  def load_training_stats
    @workout_sessions = WorkoutSession.joins(:day)
                                      .where(days: { user_id: current_user.id, date: @from..Date.today })
                                      .includes(:day, workout_sets: :exercise)
                                      .order("days.date")

    @session_count = @workout_sessions.size

    all_sets      = @workout_sessions.flat_map(&:workout_sets)
    @total_sets   = all_sets.size
    @total_volume = all_sets.sum { |ws| ws.weight_kg.to_f * ws.reps.to_i }.round

    # Frequency chart
    range            = (@from..Date.today).to_a
    sessions_by_date = @workout_sessions.index_by { |s| s.day.date }

    if @period == 7
      @freq_labels = range.map { |d| l(d, format: :short) }
      @freq_data   = range.map { |d| sessions_by_date[d] ? 1 : 0 }
    elsif @period == 30
      groups = range.each_slice(3).to_a
      @freq_labels = groups.map { |g| l(g.first, format: :short) }
      @freq_data   = groups.map { |g| g.count { |d| sessions_by_date[d] } }
    elsif @period == 365
      months = range.group_by { |d| d.beginning_of_month }.sort
      @freq_labels = months.map { |m, _| l(m, format: :month_year) }
      @freq_data   = months.map { |_, days| days.count { |d| sessions_by_date[d] } }
    else
      weeks = range.group_by(&:beginning_of_week).sort
      @freq_labels = weeks.map { |w, _| l(w, format: :short) }
      @freq_data   = weeks.map { |_, days| days.count { |d| sessions_by_date[d] } }
    end

    # Muscle group CSS bars (% of total volume, top 6)
    body_vols = all_sets.each_with_object({}) do |ws, h|
      bp = ws.exercise&.body_part
      next if bp.blank?
      h[bp] = (h[bp] || 0) + ws.weight_kg.to_f * ws.reps.to_i
    end
    sorted     = body_vols.sort_by { |_, v| -v }
    total_vol  = body_vols.values.sum.to_f
    @muscle_groups = sorted.map { |bp, vol| [bp, total_vol > 0 ? (vol / total_vol * 100).round : 0] }

    # PRs (last 10 in period)
    @recent_prs = WorkoutSet.joins(workout_session: :day)
                            .includes(:exercise, workout_session: :day)
                            .where(is_pr: true)
                            .where(days: { user_id: current_user.id, date: @from..Date.today })
                            .order("days.date DESC")
                            .limit(5)

    # Exercise progression chart
    exercise_ids = WorkoutSet.joins(workout_session: :day)
                             .where(days: { user_id: current_user.id, date: @from..Date.today })
                             .distinct
                             .pluck(:exercise_id)
    favorite_ids = current_user.favorited_exercises.pluck(:id).to_set
    @user_exercises = Exercise.where(id: exercise_ids)
                              .order(:name)
                              .sort_by { |e| [favorite_ids.include?(e.id) ? 0 : 1, e.name] }

    @selected_exercise = @user_exercises.find { |e| e.id == params[:exercise_id]&.to_i } if params[:exercise_id].present?
    @selected_exercise ||= @user_exercises.first

    load_exercise_progress(@selected_exercise) if @selected_exercise

    # Training streak (weeks in range with ≥1 session)
    session_dates = @workout_sessions.map { |s| s.day.date }
    all_weeks = range.group_by(&:beginning_of_week)
    @training_streak_weeks       = all_weeks.count { |_, wds| wds.any? { |d| session_dates.include?(d) } }
    @training_total_weeks        = all_weeks.size

    # Estimated 1RM (Brzycki: weight × 36 / (37 − reps), valid for reps 1–10)
    one_rm_by_exercise = {}
    all_sets.each do |ws|
      next unless ws.weight_kg.present? && ws.reps.present?
      next unless ws.reps.between?(1, 10) && ws.weight_kg.to_f > 0
      orm = (ws.weight_kg.to_f * 36.0 / (37.0 - ws.reps.to_f)).round(1)
      eid = ws.exercise_id
      one_rm_by_exercise[eid] = [one_rm_by_exercise[eid] || 0.0, orm].max
    end
    top_orm_ids = one_rm_by_exercise.sort_by { |_, v| -v }.first(3).map(&:first)
    exercise_names = @user_exercises.index_by(&:id)
    @top_1rms = top_orm_ids.filter_map do |eid|
      name = exercise_names[eid]&.name_fr.presence || exercise_names[eid]&.name
      next if name.nil?
      [name, one_rm_by_exercise[eid]]
    end

    # Most progressive exercises (% weight gain first half vs second half)
    mid_date    = @from + (@period / 2).days
    sets_early  = all_sets.select { |ws| ws.workout_session.day.date < mid_date }
    sets_late   = all_sets.select { |ws| ws.workout_session.day.date >= mid_date }
    early_max   = sets_early.group_by(&:exercise_id).transform_values { |ss| ss.map(&:weight_kg).compact.map(&:to_f).max || 0 }
    late_max    = sets_late.group_by(&:exercise_id).transform_values  { |ss| ss.map(&:weight_kg).compact.map(&:to_f).max || 0 }

    @most_progressive = (early_max.keys & late_max.keys).filter_map { |eid|
      early = early_max[eid]; late = late_max[eid]
      next if early.zero?
      gain = ((late - early) / early * 100).round(1)
      next if gain <= 0
      name = exercise_names[eid]&.name_fr.presence || exercise_names[eid]&.name
      [name, gain, late]
    }.sort_by { |_, g, _| -g }.first(5)
  end

  def load_exercise_progress(exercise)
    sets = WorkoutSet.joins(workout_session: :day)
                     .includes(workout_session: :day)
                     .where(exercise: exercise)
                     .where(days: { user_id: current_user.id, date: @from..Date.today })
                     .order("days.date")

    by_date = sets.group_by { |s| s.workout_session.day.date }
    @progress_labels = by_date.keys.map { |d| l(d, format: :short) }
    @progress_data   = by_date.values.map { |s| s.map(&:weight_kg).compact.max&.to_f || 0 }
  end

  # ── Cardio ───────────────────────────────────────────────────────────────────

  def load_cardio_stats
    @cardio_blocks = CardioBlock.joins(cardio_session: :day)
                                .where(days: { user_id: current_user.id, date: @from..Date.today })
                                .includes(cardio_session: :day)
                                .order("days.date")

    @cardio_total_minutes  = @cardio_blocks.sum(&:duration_minutes)
    @cardio_total_calories = @cardio_blocks.sum { |b| b.calories_burned.to_i }
    @cardio_session_count  = @cardio_blocks.map(&:cardio_session_id).uniq.size

    # Total distance: use distance_km if present, else estimate from speed × time
    running_machines = %w[treadmill outdoor_run]
    @cardio_total_distance = @cardio_blocks.sum do |b|
      if b.distance_km.present?
        b.distance_km.to_f
      elsif running_machines.include?(b.machine) && b.speed_kmh.present?
        (b.speed_kmh.to_f * b.duration_minutes.to_f / 60.0)
      else
        0
      end
    end.round(1)

    # Avg speed (weighted by duration, running blocks only)
    running_blocks = @cardio_blocks.select { |b| running_machines.include?(b.machine) && b.speed_kmh.present? }
    if running_blocks.any?
      total_run_min = running_blocks.sum(&:duration_minutes).to_f
      @avg_speed = total_run_min > 0 ? (running_blocks.sum { |b| b.speed_kmh.to_f * b.duration_minutes.to_f } / total_run_min).round(1) : nil
    end

    # Intensity distribution (based on MET thresholds)
    intensity_counts = { light: 0, moderate: 0, intense: 0 }
    @cardio_blocks.each do |b|
      met = CardioBlock::MET_BY_MACHINE[b.machine] ||
            (b.machine.in?(%w[treadmill outdoor_run]) ? (b.speed_kmh.to_f >= 10 ? 10.5 : 7.5) : 7.0)
      bucket = if met < 6.0 then :light
               elsif met < 9.0 then :moderate
               else :intense
               end
      intensity_counts[bucket] += 1
    end
    @intensity_donut_labels = intensity_counts.keys.map { |k| t("views.statistics.cardio.intensity.#{k}") }
    @intensity_donut_data   = intensity_counts.values

    # Activity chart — granularity adapts to period
    range          = (@from..Date.today).to_a
    blocks_by_date = @cardio_blocks.group_by { |b| b.cardio_session.day.date }

    if @period == 7
      @cardio_week_labels = range.map { |d| l(d, format: :short) }
      @cardio_week_data   = range.map { |d| blocks_by_date[d]&.sum(&:duration_minutes) || 0 }
    elsif @period == 30
      groups = range.each_slice(3).to_a
      @cardio_week_labels = groups.map { |g| l(g.first, format: :short) }
      @cardio_week_data   = groups.map { |g| g.sum { |d| blocks_by_date[d]&.sum(&:duration_minutes) || 0 } }
    elsif @period == 365
      months = range.group_by { |d| d.beginning_of_month }.sort
      @cardio_week_labels = months.map { |m, _| l(m, format: :month_year) }
      @cardio_week_data   = months.map { |_, days| days.sum { |d| blocks_by_date[d]&.sum(&:duration_minutes) || 0 } }
    else
      weeks = range.group_by(&:beginning_of_week).sort
      @cardio_week_labels = weeks.map { |w, _| l(w, format: :short) }
      @cardio_week_data   = weeks.map { |_, days| days.sum { |d| blocks_by_date[d]&.sum(&:duration_minutes) || 0 } }
    end

    # Machine distribution donut
    machine_counts = @cardio_blocks.group_by(&:machine)
                                   .transform_values(&:count)
                                   .sort_by { |_, v| -v }
    @machine_donut_labels = machine_counts.map { |m, _| t("views.cardio_sessions.machines.#{m}") }
    @machine_donut_data   = machine_counts.map { |_, c| c }
  end

  # ── Bien-être ────────────────────────────────────────────────────────────────

  def load_wellbeing_stats
    days_range = current_user.days.where(date: @from..Date.today).order(:date)

    @wb_days = days_range.select { |d|
      d.energy_level.present? || d.mood.present? || d.sleep_quality.present?
    }

    energy_vals = @wb_days.map(&:energy_level).compact
    mood_vals   = @wb_days.map(&:mood).compact
    sleep_vals  = @wb_days.map(&:sleep_quality).compact

    @avg_energy = energy_vals.any? ? (energy_vals.sum.to_f / energy_vals.size).round(1) : nil
    @avg_mood   = mood_vals.any?   ? (mood_vals.sum.to_f   / mood_vals.size).round(1)   : nil
    @avg_sleep  = sleep_vals.any?  ? (sleep_vals.sum.to_f  / sleep_vals.size).round(1)  : nil

    # Hydration
    profile          = current_user.profile
    @water_goal_ml   = profile&.water_goal_ml.to_i
    hydration_days   = days_range.select { |d| d.water_ml.to_i > 0 }
    if hydration_days.any?
      @avg_water_ml   = (hydration_days.sum { |d| d.water_ml.to_i }.to_f / hydration_days.size).round
      @hydration_pct  = @water_goal_ml > 0 ? [(@avg_water_ml.to_f / @water_goal_ml * 100).round, 100].min : nil
    end

    # Steps
    @steps_goal = profile&.default_daily_steps.to_i
    steps_days  = days_range.select { |d| d.steps.present? }
    @avg_steps  = steps_days.any? ? (steps_days.sum { |d| d.steps.to_i }.to_f / steps_days.size).round : nil

    # Evolution chart
    wb_by_date = days_range.index_by(&:date)
    range      = (@from..Date.today).to_a

    if @period <= 30
      wb_dates = range.select { |d|
        wb_by_date[d]&.energy_level.present? ||
        wb_by_date[d]&.mood.present? ||
        wb_by_date[d]&.sleep_quality.present?
      }
      @wb_labels      = wb_dates.map { |d| l(d, format: :short) }
      @wb_energy_data = wb_dates.map { |d| wb_by_date[d]&.energy_level }
      @wb_mood_data   = wb_dates.map { |d| wb_by_date[d]&.mood }
      @wb_sleep_data  = wb_dates.map { |d| wb_by_date[d]&.sleep_quality }
    else
      groups = @period == 365 ? range.group_by { |d| d.beginning_of_month } : range.group_by(&:beginning_of_week)
      groups = groups.sort
      @wb_labels = groups.map { |k, _| l(k, format: @period == 365 ? :month_year : :short) }
      @wb_energy_data = groups.map { |_, gd| avg_vals(gd.filter_map { |d| wb_by_date[d]&.energy_level }) }
      @wb_mood_data   = groups.map { |_, gd| avg_vals(gd.filter_map { |d| wb_by_date[d]&.mood }) }
      @wb_sleep_data  = groups.map { |_, gd| avg_vals(gd.filter_map { |d| wb_by_date[d]&.sleep_quality }) }
    end

    # Weight trend
    @weight_entries = current_user.weight_entries.where(date: @from..Date.today).order(:date)
    if @weight_entries.any?
      @weight_labels = @weight_entries.map { |we| l(we.date, format: :short) }
      @weight_data   = @weight_entries.map { |we| we.weight_kg.to_f }
    end
  end

  # ── Helpers ──────────────────────────────────────────────────────────────────

  def day_macros(day)
    foods   = day.day_foods
    recipes = day.day_recipes
    {
      calories: (foods.sum { |f| f.total_calories.to_f } + recipes.sum { |r| r.total_calories.to_f }).round,
      proteins: (foods.sum { |f| f.total_proteins.to_f } + recipes.sum { |r| r.total_proteins.to_f }).round(1),
      carbs:    (foods.sum { |f| f.total_carbs.to_f }    + recipes.sum { |r| r.total_carbs.to_f }).round(1),
      fats:     (foods.sum { |f| f.total_fats.to_f }     + recipes.sum { |r| r.total_fats.to_f }).round(1)
    }
  end

  def calc_current_streak(sorted_dates)
    return 0 if sorted_dates.empty?
    date_set = sorted_dates.to_set
    streak = 0
    check = Date.today
    while date_set.include?(check)
      streak += 1
      check -= 1.day
    end
    streak
  end

  def calc_best_streak(sorted_dates)
    return 0 if sorted_dates.empty?
    best = current = 1
    sorted_dates.each_cons(2) do |a, b|
      if (b - a).to_i == 1
        current += 1
        best = current if current > best
      else
        current = 1
      end
    end
    best
  end

  def avg_vals(arr)
    return nil if arr.empty?
    (arr.sum.to_f / arr.size).round(1)
  end
end
