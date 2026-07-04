json.data @exercises do |exercise|
  json.partial! "api/v1/exercises/exercise", exercise: exercise
end

json.meta do
  json.current_page @pagy.page
  json.total_pages  @pagy.pages
  json.total_count  @pagy.count
end
