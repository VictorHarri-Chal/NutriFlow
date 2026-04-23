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
      patch :update_steps
    end
    resources :day_foods, only: [:new, :create, :edit, :update, :destroy]
    resources :day_recipes, only: [:new, :create, :edit, :update, :destroy]
    resources :workout_sessions, only: [:new, :create, :edit, :update, :destroy]
    resources :cardio_sessions,  only: [:new, :create, :edit, :update, :destroy]
  end

  resources :workout_programs do
    member do
      patch :activate
      post  :duplicate
    end
    resources :program_days, only: [:update] do
      member { post :copy_to }
      resources :program_exercises, only: [:create, :update, :destroy] do
        collection { patch :reorder }
      end
    end
  end

  resources :exercises, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    collection do
      get  :search
      get  :favorites
      get  :recents
    end
    member do
      get   :last_performance
      patch :toggle_favorite
    end
  end

  resources :weight_entries, only: [:index, :create, :destroy]

  resources :recipes do
    member do
      post  :duplicate
      patch :toggle_favorite
    end
    resources :recipe_ratings, only: [:create, :destroy]
  end

  post 'days/:date/add_food', to: 'days#add_food', as: :add_food_to_day

  get 'statistics', to: 'statistics#index', as: :statistics

  get 'home', to: 'home#index', as: :home

  root "home#index"
end
