namespace :exercises do
  desc "Seed exercises from ExerciseDB API (RapidAPI free tier — ~500 requests)"
  task seed: :environment do
    require "net/http"
    require "json"

    api_key = ENV.fetch("RAPIDAPI_KEY") do
      abort "ERROR: RAPIDAPI_KEY env variable is not set. Add it to your .env file."
    end

    host    = "exercisedb.p.rapidapi.com"
    headers = {
      "X-RapidAPI-Key"  => api_key,
      "X-RapidAPI-Host" => host
    }

    # Délai entre requêtes — évite les 429 sur gros batches
    RATE_LIMIT_SLEEP = 0.3

    def fetch_with_retry(uri, headers, retries: 3)
      attempts = 0
      loop do
        attempts += 1
        request = Net::HTTP::Get.new(uri)
        headers.each { |k, v| request[k] = v }

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.read_timeout = 10
          http.request(request)
        end

        if response.code == "429" && attempts <= retries
          wait = 5 * attempts
          puts "\n  ⏳ Rate limited (429) — attente #{wait}s avant retry #{attempts}/#{retries}..."
          sleep wait
          next
        end

        return response
      end
    end

    # Load excluded exercise IDs (no GIF available from API)
    excluded_ids_path = Rails.root.join("config", "excluded_exercise_ids.json")
    excluded_ids = excluded_ids_path.exist? ? JSON.parse(File.read(excluded_ids_path)).to_set : Set.new
    puts "→ #{excluded_ids.size} exercices exclus (sans GIF)" if excluded_ids.any?

    # Body parts ordered by training relevance
    body_parts = ["back", "chest", "upper legs", "shoulders", "upper arms",
                  "waist", "lower legs", "lower arms", "neck", "cardio"]

    total_created  = 0
    total_skipped  = 0
    total_requests = 0

    body_parts.each do |body_part|
      puts "\n→ Fetching: #{body_part}"
      offset = 0
      limit  = 10

      loop do
        encoded_part = body_part.gsub(" ", "%20")
        uri = URI("https://#{host}/exercises/bodyPart/#{encoded_part}")
        uri.query = URI.encode_www_form({ limit: limit, offset: offset })

        response = fetch_with_retry(uri, headers)
        total_requests += 1

        unless response.is_a?(Net::HTTPSuccess)
          puts "  ✗ HTTP #{response.code} pour #{body_part} (offset #{offset}) — body part ignoré"
          break
        end

        exercises = JSON.parse(response.body)
        break if exercises.empty?

        exercises.each do |data|
          next if excluded_ids.include?(data["id"])

          record = Exercise.find_or_initialize_by(exercise_id: data["id"])
          was_new = record.new_record?

          record.assign_attributes(
            name:               data["name"],
            body_part:          data["bodyPart"],
            equipment:          data["equipment"],
            target_muscle:      data["target"],
            secondary_muscles:  Array(data["secondaryMuscles"]),
            instructions:       Array(data["instructions"]).join("\n"),
            description:        data["description"],
            difficulty:         data["difficulty"],
            category:           data["category"]
          )

          if record.save
            was_new ? total_created += 1 : total_skipped += 1
          else
            puts "  ✗ Save failed pour #{data['name']}: #{record.errors.full_messages.join(', ')}"
          end
        end

        print "  offset=#{offset} (+#{exercises.size}) req=#{total_requests}\r"
        $stdout.flush
        offset += limit

        # Sécurité : stop à 480 requêtes (garde 20 de marge)
        if total_requests >= 480
          puts "\n⚠ Limite 500 requêtes proche — arrêt préventif."
          break
        end

        sleep RATE_LIMIT_SLEEP
      end
    end

    puts "\n\n✓ Terminé. Créés: #{total_created}, Mis à jour: #{total_skipped}, Requêtes API: #{total_requests}"
    puts "  Total exercices en DB: #{Exercise.global.count}"
  end

  desc "Download GIFs for all exercises. Reprend où elle s'est arrêtée. S'arrête automatiquement si le quota mensuel est atteint."
  task :fetch_gifs, [:limit] => :environment do |_, args|
    require "net/http"
    require "fileutils"

    api_key = ENV.fetch("RAPIDAPI_KEY") do
      abort "ERROR: RAPIDAPI_KEY non définie dans .env"
    end

    gif_dir = Rails.root.join("public", "exercise_gifs")
    FileUtils.mkdir_p(gif_dir)

    scope = Exercise.global.where(gif_status: nil).order(:exercise_id)
    scope = scope.limit(args[:limit].to_i) if args[:limit].present?

    total     = scope.count
    ok_count  = 0
    none_count = 0
    requests  = 0
    quota_hit = false

    puts "→ #{total} exercices à traiter"
    puts "  GIFs enregistrés dans : #{gif_dir}\n\n"

    scope.each_with_index do |exercise, i|
      gif_path = gif_dir.join("#{exercise.exercise_id}.gif")

      if gif_path.exist?
        exercise.update_columns(gif_status: "ok", gif_url: "/exercise_gifs/#{exercise.exercise_id}.gif")
        ok_count += 1
        print "  [#{i + 1}/#{total}] #{exercise.exercise_id} → déjà en cache ✓\r"
        $stdout.flush
        next
      end

      uri = URI("https://exercisedb.p.rapidapi.com/image?exerciseId=#{exercise.exercise_id}&resolution=360")
      req = Net::HTTP::Get.new(uri)
      req["X-RapidAPI-Key"]  = api_key
      req["X-RapidAPI-Host"] = "exercisedb.p.rapidapi.com"

      begin
        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 15) { |h| h.request(req) }
        requests += 1

        case response.code
        when "200"
          if response["Content-Type"].to_s.start_with?("image/")
            File.binwrite(gif_path, response.body)
            exercise.update_columns(gif_status: "ok", gif_url: "/exercise_gifs/#{exercise.exercise_id}.gif")
            ok_count += 1
            print "  [#{i + 1}/#{total}] #{exercise.exercise_id} → ✓ #{response.body.bytesize / 1024}KB\r"
          else
            exercise.update_column(:gif_status, "none")
            none_count += 1
            print "  [#{i + 1}/#{total}] #{exercise.exercise_id} → pas d'image\r"
          end
        when "429"
          puts "\n\n⚠ Quota mensuel atteint après #{requests} requêtes. Relancez le mois prochain."
          quota_hit = true
          break
        when "404"
          exercise.update_column(:gif_status, "none")
          none_count += 1
          print "  [#{i + 1}/#{total}] #{exercise.exercise_id} → 404 (pas de GIF)\r"
        else
          exercise.update_column(:gif_status, "none")
          none_count += 1
          print "  [#{i + 1}/#{total}] #{exercise.exercise_id} → HTTP #{response.code}\r"
        end
      rescue => e
        print "  [#{i + 1}/#{total}] #{exercise.exercise_id} → erreur réseau\r"
      end

      $stdout.flush
      sleep 0.4
    end

    remaining = Exercise.global.where(gif_status: nil).count
    puts "\n\n✓ #{quota_hit ? 'Quota atteint' : 'Terminé'}."
    puts "  GIFs téléchargés    : #{ok_count}"
    puts "  Sans GIF (masqués)  : #{none_count}"
    puts "  Requêtes API        : #{requests}"
    puts "  Restants à traiter  : #{remaining}"
    puts "  Exercices visibles  : #{Exercise.visible.count} / #{Exercise.global.count}"
  end

  # ---------------------------------------------------------------------------
  # exercises:translate
  # Uses the DeepL free API (500 000 chars/month) to translate exercise name,
  # description and instructions into French.
  #
  # Prerequisites:
  #   1. Sign up at https://www.deepl.com/fr/pro-api (free, no credit card)
  #   2. Add to .env:  DEEPL_API_KEY=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx:fx
  #
  # Usage:
  #   bin/rails exercises:translate            # translate all untranslated
  #   bin/rails "exercises:translate[50]"      # translate up to 50 exercises
  #   bin/rails "exercises:translate[0,true]"  # re-translate everything (force)
  # ---------------------------------------------------------------------------
  desc "Translate exercises to French using DeepL free API"
  task :translate, [:limit, :force] => :environment do |_, args|
    require "net/http"
    require "json"

    api_key = ENV.fetch("DEEPL_API_KEY") do
      abort <<~MSG
        ERROR: DEEPL_API_KEY is not set.
          1. Sign up (free) at https://www.deepl.com/fr/pro-api
          2. Copy your Authentication Key (ends with :fx for free plan)
          3. Add to .env:  DEEPL_API_KEY=your-key-here:fx
      MSG
    end

    force = args[:force].to_s == "true"
    scope = force ? Exercise.global : Exercise.global.where(description_fr: nil)
    scope = scope.limit(args[:limit].to_i) if args[:limit].to_i > 0

    total = scope.count
    if total.zero?
      puts "✓ Tous les exercices ont déjà une traduction française. Utilisez force=true pour re-traduire."
      next
    end

    # Estimate character usage
    sample = scope.limit(20)
    avg_chars = sample.sum { |e| e.name.to_s.length + e.description.to_s.length + e.instructions.to_s.length } / [sample.size, 1].max
    puts "→ #{total} exercices à traduire (~#{(avg_chars * total / 1000.0).round(1)}k chars estimés)\n\n"

    # Translate a batch of texts via DeepL. Returns translated array in same order.
    translate_batch = lambda do |texts|
      valid_indices = texts.each_index.select { |i| texts[i].present? }
      return texts if valid_indices.empty?

      uri = URI("https://api-free.deepl.com/v2/translate")
      http = Net::HTTP.new(uri.hostname, uri.port)
      http.use_ssl = true
      http.read_timeout = 30

      req = Net::HTTP::Post.new(uri.path)
      req["Authorization"] = "DeepL-Auth-Key #{api_key}"
      req["Content-Type"]  = "application/x-www-form-urlencoded"

      params  = valid_indices.map { |i| "text=#{URI.encode_www_form_component(texts[i])}" }
      params += %w[target_lang=FR source_lang=EN formality=prefer_less]
      req.body = params.join("&")

      response = http.request(req)

      if response.code == "456"
        puts "\n⚠ Quota mensuel DeepL atteint. Réessayez le mois prochain."
        exit 1
      end

      unless response.code == "200"
        puts "\n✗ DeepL error #{response.code}: #{response.body}"
        return texts
      end

      translations = JSON.parse(response.body)["translations"].map { |t| t["text"] }
      result = texts.dup
      valid_indices.each_with_index { |orig_i, t_i| result[orig_i] = translations[t_i] }
      result
    end

    translated = 0
    errors     = 0
    BATCH      = 50

    scope.find_in_batches(batch_size: BATCH) do |batch|
      # Exercise names stay in English (universal gym terminology) — only
      # descriptions and instructions are translated.
      descriptions = batch.map(&:description)
      instructions = batch.map(&:instructions)

      descriptions_fr = translate_batch.call(descriptions)
      instructions_fr = translate_batch.call(instructions)

      batch.each_with_index do |exercise, i|
        if exercise.update(
          description_fr: descriptions_fr[i],
          instructions_fr: instructions_fr[i]
        )
          translated += 1
        else
          errors += 1
          puts "  ✗ #{exercise.exercise_id} #{exercise.name}: #{exercise.errors.full_messages.join(', ')}"
        end
      end

      print "  #{translated}/#{total} traduits...\r"
      $stdout.flush
      sleep 0.2 # be polite to the API
    end

    puts "\n\n✓ Terminé. Traduits: #{translated}, Erreurs: #{errors}"
    puts "  Exercices avec traduction FR: #{Exercise.global.where.not(name_fr: nil).count} / #{Exercise.global.count}"
  end

  desc "Reset gif_status to nil (pour re-vérifier tous les exercices)"
  task reset_gif_status: :environment do
    count = Exercise.global.update_all(gif_status: nil, gif_url: nil)
    puts "Reset gif_status pour #{count} exercices."
  end

  desc "Show current exercise counts by body part"
  task stats: :environment do
    puts "Exercise counts by body part:"
    Exercise.global.group(:body_part).count.sort_by { |_, c| -c }.each do |part, count|
      puts "  #{part.ljust(20)} #{count}"
    end
    puts "  #{"TOTAL".ljust(20)} #{Exercise.global.count}"
  end

  desc "Clear all global exercises (use with caution)"
  task clear: :environment do
    count = Exercise.global.count
    Exercise.global.delete_all
    puts "Deleted #{count} global exercises."
  end
end
