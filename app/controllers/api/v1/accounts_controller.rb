class Api::V1::AccountsController < Api::V1::BaseController
  def destroy
    current_user.destroy
    render json: {}, status: :no_content
  end
end
