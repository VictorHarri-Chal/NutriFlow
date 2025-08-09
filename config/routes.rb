Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    passwords: 'users/passwords'
  }

  resource :profile, only: [:show, :edit, :update]

  resources :calendars, only: [:index]
  resources :foods, except: [:show]
  resource :daily_calorie_requirement, only: [:show]

  resource :setting, only: [:show]

  resources :days, only: [] do
    resources :day_foods, only: [:new, :create, :edit, :update, :destroy]
  end

  post 'days/:date/add_food', to: 'days#add_food', as: :add_food_to_day

  root "calendars#index"
end
