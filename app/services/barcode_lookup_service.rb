# Résultat partagé par FoodsController#barcode_import (page /foods/new) et
# ScansController#lookup (modale de scan) — les deux doivent afficher la même
# fiche produit même si l'utilisateur possède déjà ce produit (off_id), donc on
# récupère toujours les données OFF, et on signale existing_food en plus.
class BarcodeLookupService
  VALID_LENGTHS = [8, 12, 13].freeze

  def self.call(code:, user:)
    sanitized = code.to_s.gsub(/\D/, "")
    return { error: true } unless VALID_LENGTHS.include?(sanitized.length)

    product = Rails.cache.fetch("off_barcode:#{sanitized}", expires_in: 24.hours) do
      OpenFoodFactsService.by_barcode(sanitized)
    end
    return { error: true } unless product

    result = { product: product.merge(source: "off") }
    if (existing = user.foods.find_by(off_id: sanitized))
      result[:existing_food] = { id: existing.id }
    end
    result
  end
end
