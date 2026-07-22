Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users, controllers: {
    registrations: 'users/registrations',
    passwords: 'users/passwords',
    confirmations: 'users/confirmations'
  }

  resource :profile, only: [:show, :edit, :update]
  resource :onboarding, only: [:edit, :update], controller: 'onboarding'

  resources :calendars, only: [:index] do
    collection do
      post :copy_yesterday
    end
  end
  resources :fasting_sessions, only: [:create, :destroy] do
    member { patch :finish }
  end
  resources :foods do
    collection do
      get   :search_import
      get   :barcode_import
      patch :bulk_pantry
      post  :add_missing_to_shopping_list
    end
    member do
      post   :duplicate
      patch  :toggle_favorite
      patch  :toggle_pantry
      delete :force_destroy
    end
  end
  resources :scans, only: [:new, :create] do
    collection { get :lookup }
  end
  resource :setting, only: [:show, :update] do
    patch :update_preferences
    delete :sign_out_other_sessions
    delete :reset_data
  end
  resources :day_food_groups, only: [:create, :edit, :update, :destroy]
  resources :food_labels, only: [:create, :edit, :update, :destroy]

  resources :days, only: [:update] do
    member do
      patch :update_water
      patch :update_steps
    end
    resources :day_foods,        only: [:new, :create, :edit, :update, :destroy], shallow: true
    resources :day_recipes,      only: [:new, :create, :edit, :update, :destroy], shallow: true
    resources :workout_sessions, only: [:new, :create, :edit, :update, :destroy], shallow: true
    resources :cardio_sessions,  only: [:new, :create, :edit, :update, :destroy], shallow: true
  end

  resources :workout_programs do
    member do
      patch :activate
      post  :duplicate
    end
    resources :program_days, only: [:update], shallow: true do
      member { post :copy_to }
      resources :program_exercises, only: [:new, :create, :edit, :update, :destroy], shallow: true do
        collection { patch :reorder }
        member     { patch :move }
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
  resources :body_measurements, only: [:create, :destroy]

  resources :recipes do
    member do
      post  :duplicate
      patch :toggle_favorite
      post  :add_to_shopping_list
    end
    resources :recipe_ratings, only: [:create, :destroy], shallow: true
  end

  resources :shopping_lists, only: [:index, :show, :destroy] do
    member do
      delete :clear_checked
      delete :clear_all
      patch  :archive
      post   :merge_into_current
      post   :replace_current
    end
    collection do
      get  :history
      get  :week_preview
      post :generate_from_week
      get  :suggestions_preview
    end
    resources :shopping_list_items, only: [:create, :update, :destroy], shallow: true do
      collection { patch :reorder }
    end
  end

  post 'days/:date/add_food', to: 'days#add_food', as: :add_food_to_day

  get 'statistics', to: 'statistics#index', as: :statistics

  get 'home', to: 'home#index', as: :home

  root "home#index"
end
