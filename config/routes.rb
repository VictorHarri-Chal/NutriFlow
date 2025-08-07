Rails.application.routes.draw do

  resources :calendars, only: [:index]
  resources :foods, except: [:show]

  resources :days, only: [] do
    resources :day_foods, only: [:new, :create, :edit, :update, :destroy]
  end

  post 'days/:date/add_food', to: 'days#add_food', as: :add_food_to_day

  root "calendars#index"
end
