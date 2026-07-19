class ScansController < ApplicationController
  def new
    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to root_path }
    end
  end

  def lookup
    result = BarcodeLookupService.call(code: params[:code], user: current_user)
    if result[:error]
      render json: { error: t("controllers.foods.barcode_not_found") }, status: :not_found
    else
      render json: result
    end
  end

  def create
    result = BarcodeLookupService.call(code: params[:code], user: current_user)
    return render json: { error: t("controllers.foods.barcode_not_found") }, status: :not_found if result[:error]

    product = result[:product]
    food = current_user.foods.build(
      off_id:           product[:off_id],
      name:             product[:name],
      brand:            product[:brand],
      calories:         product[:calories],
      proteins:         product[:proteins],
      carbs:            product[:carbs],
      fats:             product[:fats],
      sugars:           product[:sugars],
      fiber:            product[:fiber],
      saturated_fat:    product[:saturated_fat],
      salt:             product[:salt],
      nutriscore_grade: product[:nutriscore],
      nova_group:       product[:nova_group],
      ecoscore_grade:   product[:ecoscore_grade],
      allergens:        product[:allergens],
      traces:           product[:traces],
      additives:        product[:additives],
      labels:           product[:labels],
      ingredients_text: product[:ingredients_text],
      micronutrients:   product[:micronutrients],
      source:           product[:source]
    )

    if food.save
      render json: { food: { id: food.id, name: food.name } }
    else
      render json: { errors: food.errors.full_messages.uniq }, status: :unprocessable_entity
    end
  end
end
