Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    passwords: 'users/passwords'
  }

  resource :profile, only: [:show, :edit, :update]

  resources :calendars, only: [:index] do
    collection do
      post :copy_yesterday
    end
  end
  resources :foods, except: [:show] do
    member do
      post :duplicate
      patch :toggle_favorite
    end
  end
  resource :daily_calorie_requirement, only: [:show]

  resource :setting, only: [:show, :update] do
    patch :update_preferences
  end
  resources :day_food_groups, only: [:create, :destroy]
  resources :food_labels, only: [:create, :destroy]

  resources :days, only: [:update] do
    member do
      patch :update_water
    end
    resources :day_foods, only: [:new, :create, :edit, :update, :destroy]
    resources :day_recipes, only: [:new, :create, :edit, :update, :destroy]
    resources :workout_sessions, only: [:new, :create, :edit, :update, :destroy]
  end

  resources :exercises, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    collection { get :search }
    member     { get :last_performance }
  end

  resources :weight_entries, only: [:index, :create, :destroy]

  resources :recipes do
    member do
      post :duplicate
    end
    resources :recipe_ratings, only: [:create, :destroy]
  end

  post 'days/:date/add_food', to: 'days#add_food', as: :add_food_to_day

  get 'home', to: 'home#index', as: :home

  root "home#index"
end
