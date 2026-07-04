json.data @programs do |p|
  json.id         p.id
  json.name       p.name
  json.split_type p.split_type
  json.is_active  p.is_active
end
