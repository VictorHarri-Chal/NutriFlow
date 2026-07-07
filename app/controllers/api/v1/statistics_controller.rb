class Api::V1::StatisticsController < Api::V1::BaseController
  VALID_PERIODS = [7, 30, 90, 365].freeze

  def index
    period = VALID_PERIODS.include?(params[:period]&.to_i) ? params[:period].to_i : 30
    from   = period.days.ago.to_date

    render json: {
      nutrition: nutrition_stats(from),
      training:  training_stats(from, period),
      cardio:    cardio_stats(from, period),
      wellbeing: wellbeing_stats(from, period)
    }
  end

  private

  # ── Nutrition ─────────────────────────────────────────────────────────────

  def nutrition_stats(from)
    days = current_user.days
                       .where(date: from..Date.today)
                       .includes(
                         day_foods:   [:food, :day_food_group],
                         day_recipes: [:day_food_group, { recipe: { recipe_items: :food } }]
                       )
                       .order(:date)

    logged_days = days.select { |d| d.day_foods.any? || d.day_recipes.any? }

    avg_calories = avg_proteins = avg_carbs = avg_fats = 0
    macros_distribution = {}
    daily_calories = []
    daily_proteins = []
    top_meal_groups = []

    if logged_days.any?
      totals = logged_days.map { |d| day_macros(d) }
      n = logged_days.size.to_f
      avg_calories = (totals.sum { |t| t[:calories] } / n).round
      avg_proteins = (totals.sum { |t| t[:proteins] } / n).round(1)
      avg_carbs    = (totals.sum { |t| t[:carbs] }    / n).round(1)
      avg_fats     = (totals.sum { |t| t[:fats] }     / n).round(1)

      protein_kcal = avg_proteins * 4
      carbs_kcal   = avg_carbs * 4
      fats_kcal    = avg_fats * 9
      total_kcal   = [protein_kcal + carbs_kcal + fats_kcal, 1].max.to_f
      macros_distribution = {
        proteins_pct: (protein_kcal / total_kcal * 100).round,
        carbs_pct:    (carbs_kcal / total_kcal * 100).round,
        fats_pct:     (fats_kcal / total_kcal * 100).round
      }

      days_by_date = days.index_by(&:date)
      range        = (from..Date.today).to_a

      daily_calories = range.map { |d|
        { date: d, calories: days_by_date[d] ? day_macros(days_by_date[d])[:calories] : 0 }
      }
      daily_proteins = range.map { |d|
        { date: d, proteins: days_by_date[d] ? day_macros(days_by_date[d])[:proteins] : 0 }
      }

      meal_totals = Hash.new(0.0)
      logged_days.each do |d|
        (d.day_foods + d.day_recipes).each do |entry|
          group_name = entry.day_food_group&.name || "other"
          meal_totals[group_name] += entry.total_calories.to_f
        end
      end
      top_meal_groups = meal_totals.sort_by { |_, v| -v }.first(5)
                                   .map { |name, cal| { name: name, calories: cal.round } }
    end

    logged_dates    = logged_days.map(&:date).sort
    current_streak  = calc_current_streak(logged_dates)
    best_streak     = calc_best_streak(logged_dates)

    {
      logged_days_count:           logged_days.size,
      avg_calories:                avg_calories,
      avg_proteins:                avg_proteins,
      avg_carbs:                   avg_carbs,
      avg_fats:                    avg_fats,
      current_nutrition_streak:    current_streak,
      best_nutrition_streak:       best_streak,
      daily_calories:              daily_calories,
      daily_proteins:              daily_proteins,
      macros_distribution:         macros_distribution,
      top_meal_groups:             top_meal_groups
    }
  end

  # ── Training ─────────────────────────────────────────────────────────────

  def training_stats(from, period)
    workout_sessions = WorkoutSession.joins(:day)
                                     .where(days: { user_id: current_user.id, date: from..Date.today })
                                     .includes(:day, workout_sets: :exercise)
                                     .order("days.date")

    all_sets    = workout_sessions.flat_map(&:workout_sets)
    total_sets  = all_sets.size
    total_vol   = all_sets.sum { |ws| ws.weight_kg.to_f * ws.reps.to_i }.round

    # Frequency
    range            = (from..Date.today).to_a
    sessions_by_date = workout_sessions.index_by { |s| s.day.date }
    frequency = range.map { |d|
      { date: d, sessions: sessions_by_date[d] ? 1 : 0 }
    }

    # Muscle group distribution
    body_vols  = all_sets.each_with_object({}) { |ws, h|
      bp = ws.exercise&.body_part; next if bp.blank?
      h[bp] = (h[bp] || 0) + ws.weight_kg.to_f * ws.reps.to_i
    }
    total_vol_f = body_vols.values.sum.to_f
    muscle_group_distribution = body_vols.sort_by { |_, v| -v }.first(6).map { |bp, vol|
      { body_part: bp, volume_pct: total_vol_f > 0 ? (vol / total_vol_f * 100).round : 0 }
    }

    # Recent PRs
    recent_prs = WorkoutSet.joins(workout_session: :day)
                           .includes(:exercise, workout_session: :day)
                           .where(is_pr: true)
                           .where(days: { user_id: current_user.id, date: from..Date.today })
                           .order("days.date DESC")
                           .limit(5)
                           .map { |ws|
      {
        exercise_name: ws.exercise&.name,
        weight_kg:     ws.weight_kg,
        reps:          ws.reps,
        date:          ws.workout_session.day.date
      }
    }

    # Top estimated 1RMs (Brzycki)
    one_rm_by = {}
    exercise_names = {}
    all_sets.each do |ws|
      next unless ws.weight_kg.present? && ws.reps.present?
      next unless ws.reps.between?(1, 10) && ws.weight_kg.to_f > 0
      orm = (ws.weight_kg.to_f * 36.0 / (37.0 - ws.reps.to_f)).round(1)
      eid = ws.exercise_id
      one_rm_by[eid] = [one_rm_by[eid] || 0.0, orm].max
      exercise_names[eid] ||= ws.exercise&.name
    end
    top_1rms = one_rm_by.sort_by { |_, v| -v }.first(3).map { |eid, orm|
      { exercise_name: exercise_names[eid], estimated_1rm_kg: orm }
    }

    # Training streak (weeks with at least one session, consecutive from most recent)
    session_dates      = workout_sessions.map { |s| s.day.date }.to_set
    active_weeks       = range.group_by(&:beginning_of_week)
                              .select { |_, wds| wds.any? { |d| session_dates.include?(d) } }
                              .keys
                              .sort

    current_training_streak_weeks = calc_current_streak_weeks(active_weeks)
    best_training_streak_weeks    = calc_best_streak_weeks(active_weeks)

    {
      session_count:                   workout_sessions.size,
      total_sets:                      total_sets,
      total_volume_kg:                 total_vol,
      current_training_streak_weeks:   current_training_streak_weeks,
      best_training_streak_weeks:      best_training_streak_weeks,
      frequency:                       frequency,
      muscle_group_distribution:       muscle_group_distribution,
      recent_prs:                      recent_prs,
      top_1rms:                        top_1rms
    }
  end

  # ── Cardio ───────────────────────────────────────────────────────────────

  def cardio_stats(from, period)
    cardio_blocks = CardioBlock.joins(cardio_session: :day)
                               .where(days: { user_id: current_user.id, date: from..Date.today })
                               .includes(cardio_session: :day)
                               .order("days.date")

    total_minutes  = cardio_blocks.sum(&:duration_minutes)
    total_calories = cardio_blocks.sum { |b| b.calories_burned.to_i }
    session_count  = cardio_blocks.map(&:cardio_session_id).uniq.size

    running_machines = %w[treadmill outdoor_run]
    total_distance = cardio_blocks.sum { |b|
      b.distance_km.present? ? b.distance_km.to_f
      : (running_machines.include?(b.machine) && b.speed_kmh.present? ? b.speed_kmh.to_f * b.duration_minutes.to_f / 60.0 : 0)
    }.round(1)

    running_blocks = cardio_blocks.select { |b| running_machines.include?(b.machine) && b.speed_kmh.present? }
    total_run_min  = running_blocks.sum(&:duration_minutes).to_f
    avg_speed_kmh  = (running_blocks.any? && total_run_min > 0) ?
      (running_blocks.sum { |b| b.speed_kmh.to_f * b.duration_minutes.to_f } / total_run_min).round(1) : nil

    # Machine distribution
    machine_counts = cardio_blocks.group_by(&:machine).transform_values(&:count).sort_by { |_, v| -v }
    total_blocks   = machine_counts.values.sum.to_f
    machine_distribution = machine_counts.map { |m, c|
      { machine: m, pct: total_blocks > 0 ? (c / total_blocks * 100).round : 0 }
    }

    # Intensity distribution
    intensity = { light: 0, moderate: 0, intense: 0 }
    cardio_blocks.each do |b|
      met = CardioBlock::MET_BY_MACHINE[b.machine] ||
            (b.machine.in?(running_machines) ? (b.speed_kmh.to_f >= 10 ? 10.5 : 7.5) : 7.0)
      bucket = met < 6.0 ? :light : (met < 9.0 ? :moderate : :intense)
      intensity[bucket] += 1
    end
    total_int = intensity.values.sum.to_f
    intensity_distribution = {
      light_pct:    total_int > 0 ? (intensity[:light]    / total_int * 100).round : 0,
      moderate_pct: total_int > 0 ? (intensity[:moderate] / total_int * 100).round : 0,
      intense_pct:  total_int > 0 ? (intensity[:intense]  / total_int * 100).round : 0
    }

    # Activity chart
    blocks_by_date = cardio_blocks.group_by { |b| b.cardio_session.day.date }
    activity = (from..Date.today).map { |d|
      { date: d, duration_minutes: blocks_by_date[d]&.sum(&:duration_minutes) || 0 }
    }

    {
      session_count:          session_count,
      total_duration_minutes: total_minutes,
      total_calories:         total_calories,
      total_distance_km:      total_distance,
      avg_speed_kmh:          avg_speed_kmh,
      machine_distribution:   machine_distribution,
      intensity_distribution: intensity_distribution,
      activity:               activity
    }
  end

  # ── Wellbeing ────────────────────────────────────────────────────────────

  def wellbeing_stats(from, period)
    days_range = current_user.days.where(date: from..Date.today).order(:date).to_a
    profile    = current_user.profile

    wb_days    = days_range.select { |d| d.energy_level.present? || d.mood.present? || d.sleep_quality.present? }
    avg_energy = avg_val(wb_days.map(&:energy_level).compact)
    avg_mood   = avg_val(wb_days.map(&:mood).compact)
    avg_sleep  = avg_val(wb_days.map(&:sleep_quality).compact)

    # Water
    water_goal_ml  = profile&.water_goal_ml.to_i
    hydration_days = days_range.select { |d| d.water_ml.to_i > 0 }
    avg_water_ml   = avg_val(hydration_days.map { |d| d.water_ml.to_i })&.round
    water_goal_pct = (avg_water_ml && water_goal_ml > 0) ?
      [(avg_water_ml.to_f / water_goal_ml * 100).round, 100].min : nil

    # Preload 365-day range for streak calculations (shared by water + steps)
    all_by_date = current_user.days.where(date: (Date.today - 365)..Date.today).index_by(&:date)

    water_streak = water_success_rate = nil
    if water_goal_ml > 0
      today_ok    = all_by_date[Date.today]&.water_ml.to_i >= water_goal_ml
      start       = today_ok ? Date.today : Date.yesterday
      streak = 0
      start.downto(Date.today - 365) { |d|
        entry = all_by_date[d]
        break unless entry && entry.water_ml.to_i >= water_goal_ml
        streak += 1
      }
      water_streak = streak

      reached = hydration_days.count { |d| d.water_ml.to_i >= water_goal_ml }
      water_success_rate = period > 0 ? (reached.to_f / period * 100).round : nil
    end

    # Steps
    steps_goal  = profile&.default_daily_steps.to_i
    steps_days  = days_range.select { |d| d.steps.present? }
    avg_steps   = avg_val(steps_days.map { |d| d.steps.to_i })&.round
    steps_goal_pct = (avg_steps && steps_goal > 0) ?
      [(avg_steps.to_f / steps_goal * 100).round, 100].min : nil

    steps_streak = steps_success_rate = nil
    if avg_steps && steps_goal > 0
      today_ok    = all_by_date[Date.today]&.steps.to_i >= steps_goal
      start       = today_ok ? Date.today : Date.yesterday
      streak = 0
      start.downto(Date.today - 365) { |d|
        entry = all_by_date[d]
        break unless entry && entry.steps.to_i >= steps_goal
        streak += 1
      }
      steps_streak = streak
      reached = steps_days.count { |d| d.steps.to_i >= steps_goal }
      steps_success_rate = period > 0 ? (reached.to_f / period * 100).round : nil
    end

    # Evolution chart — preload weight entries and days to avoid N+1
    days_by_date          = days_range.index_by(&:date)
    weight_entries_by_date = current_user.weight_entries
                                         .where(date: from..Date.today)
                                         .index_by(&:date)

    evolution = (from..Date.today).filter_map { |d|
      wb = days_by_date[d]
      we = weight_entries_by_date[d]
      next unless wb || we
      {
        date:          d,
        energy_level:  wb&.energy_level,
        mood:          wb&.mood,
        sleep_quality: wb&.sleep_quality,
        weight_kg:     we&.weight_kg
      }
    }

    {
      avg_energy:          avg_energy,
      avg_mood:            avg_mood,
      avg_sleep:           avg_sleep,
      avg_water_ml:        avg_water_ml,
      water_goal_pct:      water_goal_pct,
      water_streak:        water_streak,
      water_success_rate:  water_success_rate,
      avg_steps:           avg_steps,
      steps_goal_pct:      steps_goal_pct,
      steps_streak:        steps_streak,
      steps_success_rate:  steps_success_rate,
      evolution:           evolution
    }
  end

  # ── Helpers ──────────────────────────────────────────────────────────────

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
    check  = Date.today
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

  def avg_val(arr)
    return nil if arr.empty?
    (arr.sum.to_f / arr.size).round(1)
  end

  def calc_current_streak_weeks(sorted_week_starts)
    return 0 if sorted_week_starts.empty?
    current_week = Date.today.beginning_of_week
    streak = 0
    # Walk backwards from current week
    check = current_week
    loop do
      if sorted_week_starts.include?(check)
        streak += 1
        check -= 1.week
      elsif check == current_week
        # Allow grace: if this week has no session yet, start from last week
        check -= 1.week
      else
        break
      end
    end
    streak
  end

  def calc_best_streak_weeks(sorted_week_starts)
    return 0 if sorted_week_starts.empty?
    best = current = 1
    sorted_week_starts.each_cons(2) do |a, b|
      if (b - a).to_i == 7
        current += 1
        best = current if current > best
      else
        current = 1
      end
    end
    best
  end
end
