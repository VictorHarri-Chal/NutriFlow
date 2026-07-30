require "rails_helper"

# Regression coverage for the program_exercise_sets schema split: set/reps/weight
# moved off program_exercises onto their own table (see
# db/migrate/20260714104845_create_program_exercise_sets.rb and
# db/migrate/*_remove_sets_columns_from_program_exercises.rb). The API layer was
# built before that migration and referenced the removed columns directly —
# these specs pin the corrected nested-sets contract so that regresses loudly
# instead of silently 500ing again.
RSpec.describe "Api::V1::ProgramExercises", type: :request do
  let(:user) { create(:user) }
  let(:exercise) { Exercise.create!(exercise_id: "ex-1", name: "Bench Press") }
  let(:workout_program) { user.workout_programs.create!(name: "Push Pull Legs", split_type: "ppl") }
  let(:program_day) { workout_program.program_days.create!(day_of_week: 0, name: "Push") }

  describe "POST /api/v1/workout_programs/:workout_program_id/program_days/:program_day_id/program_exercises" do
    it "creates a program exercise with nested sets and returns them" do
      post "/api/v1/workout_programs/#{workout_program.id}/program_days/#{program_day.id}/program_exercises",
           params: {
             exercise_id: exercise.id,
             rest_seconds: 90,
             program_exercise_sets_attributes: [
               { position: 0, reps_target: 8, weight_target: 60, rpe: 8, set_types: ["working"] },
               { position: 1, reps_target: 8, weight_target: 60, rpe: 9, set_types: ["working"] }
             ]
           },
           headers: auth_headers_for(user),
           as: :json

      expect(response).to have_http_status(:created)
      expect(json["sets"].size).to eq(2)
      expect(json["sets"].first).to include("reps_target" => 8, "weight_target" => 60.0, "rpe" => 8)
      expect(json).not_to have_key("reps_target") # old flat shape must be gone
    end
  end

  describe "PATCH .../program_exercises/:id" do
    it "updates an existing set via nested attributes" do
      program_exercise = program_day.program_exercises.create!(
        exercise: exercise,
        program_exercise_sets_attributes: [{ position: 0, reps_target: 5, weight_target: 100 }]
      )
      set_id = program_exercise.program_exercise_sets.first.id

      patch "/api/v1/workout_programs/#{workout_program.id}/program_days/#{program_day.id}/program_exercises/#{program_exercise.id}",
            params: { program_exercise_sets_attributes: [{ id: set_id, reps_target: 6 }] },
            headers: auth_headers_for(user),
            as: :json

      expect(response).to have_http_status(:ok)
      expect(json["sets"].first["reps_target"]).to eq(6)
    end
  end

  describe "GET /api/v1/workout_programs/:id (show)" do
    it "nests sets under each program_exercise instead of flat fields" do
      program_day.program_exercises.create!(
        exercise: exercise,
        program_exercise_sets_attributes: [{ position: 0, reps_target: 10, weight_target: 40 }]
      )

      get "/api/v1/workout_programs/#{workout_program.id}", headers: auth_headers_for(user)

      expect(response).to have_http_status(:ok)
      pe = json["program_days"].first["program_exercises"].first
      expect(pe["sets"].first["reps_target"]).to eq(10)
      expect(pe).not_to have_key("reps_target")
    end
  end

  describe "POST .../program_days/:program_day_id/copy_to" do
    it "deep-copies exercises and their sets to the target day" do
      program_day.program_exercises.create!(
        exercise: exercise,
        program_exercise_sets_attributes: [{ position: 0, reps_target: 12, weight_target: 20 }]
      )
      target_day = workout_program.program_days.create!(day_of_week: 2, name: "Pull")

      post "/api/v1/workout_programs/#{workout_program.id}/program_days/#{program_day.id}/copy_to",
           params: { target_day_id: target_day.id },
           headers: auth_headers_for(user),
           as: :json

      expect(response).to have_http_status(:ok)
      copied = target_day.reload.program_exercises.first
      expect(copied.program_exercise_sets.first.reps_target).to eq(12)
    end
  end

  describe "POST /api/v1/workout_programs/:id/duplicate" do
    it "deep-copies exercises and their sets into the duplicated program" do
      program_day.program_exercises.create!(
        exercise: exercise,
        program_exercise_sets_attributes: [{ position: 0, reps_target: 15, weight_target: 0 }]
      )

      post "/api/v1/workout_programs/#{workout_program.id}/duplicate", headers: auth_headers_for(user)

      expect(response).to have_http_status(:created)
      duplicated_program = WorkoutProgram.find(json["id"])
      copied_set = duplicated_program.program_days.first.program_exercises.first.program_exercise_sets.first
      expect(copied_set.reps_target).to eq(15)
    end
  end
end
