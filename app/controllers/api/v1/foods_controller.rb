class Api::V1::FoodsController < Api::V1::BaseController
  before_action :set_food, only: [:show, :update, :destroy, :favorite, :toggle_pantry]

  def index
    @q = current_user.foods.includes(:food_labels).ransack(params[:q])
    scope = @q.result

    scope = scope.search_by_name(params[:query]) if params[:query].present?
    scope = scope.where(barcode: params[:barcode]) if params[:barcode].present?
    scope = scope.where(favorite: true) if params[:favorites] == "true"
    scope = scope.where(in_pantry: true) if params[:in_pantry] == "true"

    if params[:label_id].present?
      scope = scope.joins(:food_labels).where(food_labels: { id: params[:label_id] })
    end

    scope = scope.where(category: params[:category]) if params[:category].present?
    scope = scope.order(created_at: :desc)

    @pagy, @foods = pagy(scope, items: 25)
    render :index
  end

  def show
    render :show
  end

  def create
    @food = current_user.foods.build(food_params)
    if @food.save
      render :show, status: :created
    else
      render json: { errors: @food.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @food.update(food_params)
      render :show
    else
      render json: { errors: @food.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @food.destroy
    render json: {}, status: :no_content
  end

  def search
    query = params[:query].to_s.strip
    if query.length < 2
      render json: { data: [], meta: { current_page: 1, total_pages: 0, total_count: 0 } }
      return
    end

    results = CiqualFood.search_by_name(query).limit(20)
    data = results.map do |cf|
      {
        id: nil, name: cf.name, brand: nil,
        calories: cf.calories, proteins: cf.proteins,
        carbs: cf.carbs, fats: cf.fats, sugars: cf.sugars,
        fiber: cf.fiber, saturated_fat: cf.saturated_fat, salt: cf.salt,
        source: "ciqual"
      }
    end
    render json: { data: data }
  end

  def lookup
    barcode = params[:barcode].to_s.strip
    render json: { error: "Barcode requis" }, status: :bad_request and return if barcode.blank?

    result = OpenFoodFactsService.by_barcode(barcode)
    if result
      render json: {
        name:             result[:name],
        brand:            result[:brand],
        calories:         result[:calories],
        proteins:         result[:proteins],
        carbs:            result[:carbs],
        fats:             result[:fats],
        sugars:           result[:sugars],
        fiber:            result[:fiber],
        saturated_fat:    result[:saturated_fat],
        salt:             result[:salt],
        source:           "off",
        off_id:           result[:off_id],
        nutriscore_grade: result[:nutriscore],
        nova_group:       result[:nova_group],
        ecoscore_grade:   result[:ecoscore_grade],
        allergens_tags:   result[:allergens],
        traces_tags:      result[:traces],
        additives_tags:   result[:additives],
        labels_tags:      result[:labels],
        ingredients_text: result[:ingredients_text]
      }
    else
      render json: { error: "Produit non trouvé" }, status: :not_found
    end
  end

  def favorite
    @food.update!(favorite: !@food.favorite)
    render :show
  end

  def toggle_pantry
    @food.update!(in_pantry: !@food.in_pantry)
    render :show
  end

  private

  def set_food
    @food = current_user.foods.find(params[:id])
  end

  def food_params
    permitted = params.permit(
      :name, :brand, :fats, :carbs, :sugars, :proteins, :calories,
      :category, :off_id, :nutriscore_grade, :nova_group, :source,
      :fiber, :saturated_fat, :salt, :ecoscore_grade, :ingredients_text,
      :barcode, :image_url,
      food_label_ids: [],
      allergens: [], traces: [], additives: [], labels: [],
      allergens_tags: [], traces_tags: [], additives_tags: [], labels_tags: [],
      micronutrients: {}
    )

    # Map iOS's *_tags arrays into the storage columns when the plain key wasn't sent
    { "allergens_tags" => "allergens", "traces_tags" => "traces",
      "additives_tags" => "additives", "labels_tags" => "labels" }.each do |tags_key, column|
      tags_value = permitted.delete(tags_key)
      permitted[column] = tags_value if tags_value.present? && permitted[column].blank?
    end

    permitted
  end
end
