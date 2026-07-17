namespace :exercises do
  desc "Import tension_profile classification from tmp/exercises_export.csv (column 'tension', hand-classified)"
  task import_tension_profile: :environment do
    require "csv"

    path = Rails.root.join("tmp", "exercises_export.csv")
    abort "ERROR: #{path} not found — copy the classified CSV into tmp/ first." unless path.exist?

    LABEL_TO_PROFILE = {
      "etirement"   => "stretch",
      "contraction" => "contraction",
      "mixte"       => "mixed",
    }.freeze

    lines = File.readlines(path)
    header_index = lines.index { |line| line.start_with?("exercise_id,") }
    abort "ERROR: no 'exercise_id,...' header row found in #{path}" unless header_index

    rows = CSV.parse(lines[header_index..].join, headers: true)
             .reject { |row| row["exercise_id"].to_s.strip.empty? }

    updated  = Hash.new(0)
    skipped_blank  = 0
    skipped_unknown_id = []

    rows.each do |row|
      label = row["tension"].to_s.strip
      if label.empty?
        skipped_blank += 1
        next # leave tension_profile nil, matches "never guess"
      end

      profile = LABEL_TO_PROFILE.fetch(label) { raise "Unknown tension label #{label.inspect} for #{row['exercise_id']}" }

      exercise = Exercise.global.find_by(exercise_id: row["exercise_id"])
      unless exercise
        skipped_unknown_id << row["exercise_id"]
        next
      end

      exercise.update_column(:tension_profile, profile)
      updated[profile] += 1
    end

    puts "→ #{rows.size} lignes lues dans le CSV"
    updated.each { |profile, count| puts "  #{profile}: #{count}" }
    puts "→ #{skipped_blank} laissés non classés (case vide dans le CSV)"
    puts "→ #{skipped_unknown_id.size} exercise_id du CSV introuvables en base: #{skipped_unknown_id.join(', ')}" if skipped_unknown_id.any?
  end
end
