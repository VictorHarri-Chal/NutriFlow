is_fav = defined?(@favorited_ids) ? @favorited_ids.include?(exercise.id) : current_user.exercise_favorites.exists?(exercise: exercise)

json.id                exercise.id
json.name              exercise.name
json.body_part         exercise.body_part
json.equipment         exercise.equipment
json.target_muscle     exercise.target_muscle
json.secondary_muscles exercise.secondary_muscles
json.category          exercise.category
json.difficulty        exercise.difficulty
json.description       exercise.description
json.instructions      exercise.instructions
json.gif_url           exercise.gif_url
json.image_thumbnail_url exercise_image_url(exercise, variant: :thumbnail)
json.image_medium_url    exercise_image_url(exercise, variant: :medium)
json.is_favorited      is_fav
