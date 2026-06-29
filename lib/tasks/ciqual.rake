require "csv"

namespace :ciqual do
  desc "Import ANSES Ciqual foods from CSV — rake ciqual:import or rake 'ciqual:import[/path/to/file.csv]'"
  task :import, [:csv_path] => :environment do |_, args|
    path = args[:csv_path].presence || Rails.root.join("db", "seeds", "ciqual.csv").to_s

    unless File.exist?(path)
      abort <<~MSG
        ERROR: Fichier CSV introuvable : #{path}
        Téléchargez la table Ciqual 2020 depuis https://ciqual.anses.fr/
        Exportez-la en CSV (UTF-8, séparateur ;) et placez-la dans db/seeds/ciqual.csv
      MSG
    end

    rows     = CSV.read(path, headers: true, col_sep: ";", encoding: "UTF-8", row_sep: "\r\n")
    headers  = rows.headers
    # Les en-têtes Ciqual contiennent des \n dans les cellules quotées — normaliser avant toute comparaison
    norm = ->(h) { h.to_s.gsub("\n", " ").strip }

    # Trouver les indices de colonnes par correspondance partielle (les noms Ciqual sont longs)
    col_code     = headers.find { |h| norm.(h) == "alim_code" }
    col_name_fr  = headers.find { |h| norm.(h) == "alim_nom_fr" }
    col_group    = headers.find { |h| norm.(h) == "alim_grp_nom_fr" }
    # Calories UE N°1169 en kcal (index 10) — "kcal" apparaît aussi à l'index 12, find() prend le premier
    col_calories = headers.find { |h| norm.(h).include?("kcal") }
    # Protéines N×6.25 (index 15) — "6.25" est unique à cette colonne
    col_proteins = headers.find { |h| norm.(h).include?("6.25") }
    col_carbs    = headers.find { |h| norm.(h).include?("Glucides") }
    col_fats     = headers.find { |h| norm.(h).include?("Lipides") }
    col_sugars   = headers.find { |h| norm.(h).include?("Sucres") }

    # Extended nutrition label columns
    col_fiber         = headers.find { |h| norm.(h).include?("Fibres") }
    col_saturated_fat = headers.find { |h| norm.(h).include?("saturés") }
    col_salt          = headers.find { |h| norm.(h).include?("Sel") && norm.(h).include?("sodium") }

    # Micronutrient columns
    col_calcium    = headers.find { |h| norm.(h).include?("Calcium") }
    col_iron       = headers.find { |h| norm.(h).include?("Fer (") }
    col_magnesium  = headers.find { |h| norm.(h).include?("Magnésium") }
    col_potassium  = headers.find { |h| norm.(h).include?("Potassium") }
    col_sodium     = headers.find { |h| norm.(h).include?("Sodium") }
    col_zinc       = headers.find { |h| norm.(h).include?("Zinc") }
    col_vitamin_c  = headers.find { |h| norm.(h).include?("Vitamine C") }
    col_vitamin_d  = headers.find { |h| norm.(h).include?("Vitamine D (") }
    col_vitamin_b12 = headers.find { |h| norm.(h).include?("Vitamine B12") }
    col_vitamin_a  = headers.find { |h| norm.(h).include?("équivalents rétinol") }
    col_vitamin_b9 = headers.find { |h| norm.(h).include?("Folates totaux (µg") }
    col_cholesterol = headers.find { |h| norm.(h).include?("Cholestérol") }
    col_epa        = headers.find { |h| norm.(h).include?("EPA") }
    col_dha        = headers.find { |h| norm.(h).include?("DHA") }

    missing = [col_code, col_name_fr, col_calories].select(&:nil?)
    if missing.any?
      abort "ERROR: Colonnes introuvables dans le CSV. Vérifiez le format du fichier Ciqual.\nEn-têtes détectés : #{headers.first(10).join(', ')}"
    end

    puts "Import Ciqual depuis #{path}"
    puts "Colonnes détectées : calories=#{col_calories}, protéines=#{col_proteins}, glucides=#{col_carbs}, lipides=#{col_fats}, sucres=#{col_sugars}"
    puts "Colonnes étendues  : fibres=#{col_fiber ? 'oui' : 'non'}, AG_sat=#{col_saturated_fat ? 'oui' : 'non'}, sel=#{col_salt ? 'oui' : 'non'}"
    puts "Micronutriments    : calcium=#{col_calcium ? 'oui' : 'non'}, fer=#{col_iron ? 'oui' : 'non'}, magnésium=#{col_magnesium ? 'oui' : 'non'}, EPA=#{col_epa ? 'oui' : 'non'}, DHA=#{col_dha ? 'oui' : 'non'}"

    created = 0
    updated = 0
    skipped = 0
    total   = rows.count

    rows.each_with_index do |row, i|
      alim_code = row[col_code].to_s.strip
      name      = row[col_name_fr].to_s.strip

      if alim_code.blank? || name.blank?
        skipped += 1
        next
      end

      micronutrients = {
        calcium:    col_calcium    ? parse_ciqual_value(row[col_calcium])    : nil,
        iron:       col_iron       ? parse_ciqual_value(row[col_iron])       : nil,
        magnesium:  col_magnesium  ? parse_ciqual_value(row[col_magnesium])  : nil,
        potassium:  col_potassium  ? parse_ciqual_value(row[col_potassium])  : nil,
        sodium:     col_sodium     ? parse_ciqual_value(row[col_sodium])     : nil,
        zinc:       col_zinc       ? parse_ciqual_value(row[col_zinc])       : nil,
        vitamin_c:  col_vitamin_c  ? parse_ciqual_value(row[col_vitamin_c])  : nil,
        vitamin_d:  col_vitamin_d  ? parse_ciqual_value(row[col_vitamin_d])  : nil,
        vitamin_b12: col_vitamin_b12 ? parse_ciqual_value(row[col_vitamin_b12]) : nil,
        vitamin_a:  col_vitamin_a  ? parse_ciqual_value(row[col_vitamin_a])  : nil,
        vitamin_b9: col_vitamin_b9 ? parse_ciqual_value(row[col_vitamin_b9]) : nil,
        cholesterol: col_cholesterol ? parse_ciqual_value(row[col_cholesterol]) : nil,
        epa:        col_epa        ? parse_ciqual_value(row[col_epa])        : nil,
        dha:        col_dha        ? parse_ciqual_value(row[col_dha])        : nil
      }.compact.reject { |_, v| v == 0.0 }

      attrs = {
        name:          name,
        food_group:    col_group ? row[col_group].to_s.strip : nil,
        calories:      parse_ciqual_value(row[col_calories]),
        proteins:      col_proteins ? parse_ciqual_value(row[col_proteins]) : 0,
        carbs:         col_carbs    ? parse_ciqual_value(row[col_carbs])    : 0,
        fats:          col_fats     ? parse_ciqual_value(row[col_fats])     : 0,
        sugars:        col_sugars   ? parse_ciqual_value(row[col_sugars])   : 0,
        fiber:         col_fiber         ? parse_ciqual_value(row[col_fiber])         : nil,
        saturated_fat: col_saturated_fat ? parse_ciqual_value(row[col_saturated_fat]) : nil,
        salt:          col_salt          ? parse_ciqual_value(row[col_salt])          : nil,
        micronutrients: micronutrients
      }

      record = CiqualFood.find_by(alim_code: alim_code)
      if record
        record.update!(attrs)
        updated += 1
      else
        CiqualFood.create!(attrs.merge(alim_code: alim_code))
        created += 1
      end

      print "  #{i + 1}/#{total} (#{created} créés, #{updated} mis à jour)\r" if (i + 1) % 100 == 0
      $stdout.flush
    rescue => e
      puts "\n  Erreur ligne #{i + 1} (#{alim_code}): #{e.message}"
      skipped += 1
    end

    puts "\nTerminé : #{created} créés, #{updated} mis à jour, #{skipped} ignorés (total #{total})"
    puts "CiqualFood.count = #{CiqualFood.count}"
  end

  def parse_ciqual_value(val)
    return nil if val.nil?
    # Gère "< 0,1", "traces", "–", "-", valeurs vides → 0
    # Gère "3,2" → 3.2
    cleaned = val.to_s.strip.gsub(",", ".").gsub(/[^0-9.]/, "")
    cleaned.blank? ? 0.0 : cleaned.to_f.round(2)
  end
end
