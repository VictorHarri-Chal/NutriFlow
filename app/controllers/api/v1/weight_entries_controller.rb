class Api::V1::WeightEntriesController < Api::V1::BaseController
  before_action :set_weight_entry, only: [:show, :update, :destroy]

  def index
    scope = current_user.weight_entries
    scope = scope.where("date >= ?", params[:from]) if params[:from].present?
    scope = scope.where("date <= ?", params[:to])   if params[:to].present?
    @weight_entries = scope.order(date: :asc)
    render :index
  end

  def show
    render :show
  end

  def create
    date = params[:date].presence || Date.today
    @weight_entry = current_user.weight_entries.find_or_initialize_by(date: date)
    if @weight_entry.update(weight_entry_params.merge(date: date))
      render :show, status: @weight_entry.previously_new_record? ? :created : :ok
    else
      render json: { errors: @weight_entry.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @weight_entry.update(weight_entry_params)
      render :show
    else
      render json: { errors: @weight_entry.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @weight_entry.destroy
    render json: {}, status: :no_content
  end

  private

  def set_weight_entry
    @weight_entry = current_user.weight_entries.find(params[:id])
  end

  def weight_entry_params
    params.permit(:weight_kg, :date)
  end
end
