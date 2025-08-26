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
  resources :day_food_groups, only: [:create, :destroy]
  resources :food_labels, only: [:create, :destroy]

  resources :days, only: [] do
    resources :day_foods, only: [:new, :create, :edit, :update, :destroy]
  end

  resources :recipes

  post 'days/:date/add_food', to: 'days#add_food', as: :add_food_to_day

  get 'home', to: 'home#index', as: :home

  root "home#index"
end
