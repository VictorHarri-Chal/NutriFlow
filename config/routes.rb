Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  devise_for :users, controllers: {
    registrations:      'users/registrations',
    passwords:          'users/passwords',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  namespace :api do
    namespace :v1 do
      devise_scope :user do
        # Auth
        post   "sessions",      to: "sessions#create"
        delete "sessions",      to: "sessions#destroy"

        # Registration
        post   "registrations", to: "registrations#create"
      end

      # Password reset (public — no auth)
      post   "passwords",     to: "passwords#create"

      # SSO iOS (public — no auth)
      post "sessions/apple",  to: "auth#apple"
      post "sessions/google", to: "auth#google"
      post "identities/apple/link", to: "auth#link_apple"

      # User (authentifié)
      resource  :profile,  only: [:show, :update]
      resource  :password, only: [:update]
      resource  :account,  only: [:destroy]
      resource  :settings, only: [:show, :update]

      # Statistics
      get "statistics", to: "statistics#index"

      # Nutrition
      resources :foods do
        collection do
          get :search
          get :lookup
        end
        member do
          post :favorite
          patch :toggle_pantry
        end
      end
      resources :food_labels
      resources :day_food_groups
      resources :recipes do
        member do
          patch :toggle_favorite
          post  :add_to_shopping_list
        end
        resources :recipe_items,   only: [:create, :update, :destroy]
        resources :recipe_ratings, only: [:create, :update, :destroy]
      end

      # Calendar
      resources :days, param: :date, only: [:index, :show, :update] do
        member do
          patch :update_water
          patch :update_steps
          post  :copy_yesterday
        end
        resources :day_foods,   only: [:create, :update, :destroy]
        resources :day_recipes, only: [:create, :update, :destroy]
        resources :workout_sessions, only: [:create, :update, :destroy] do
          resources :workout_sets, only: [:create, :update, :destroy]
        end
        resources :cardio_sessions, only: [:create, :update, :destroy] do
          resources :cardio_blocks, only: [:create, :update, :destroy]
        end
      end

      # Fitness — Exercices
      resources :exercises do
        collection do
          get :favorites
          get :search
          get :recents
        end
        member do
          post   :favorite
          delete :unfavorite
          get    :last_performance
        end
      end

      # Fitness — Programmes
      resources :workout_programs do
        member do
          post :activate
          post :duplicate
        end
        resources :program_days, only: [:create, :update, :destroy] do
          member do
            post :copy_to
          end
          resources :program_exercises, only: [:create, :update, :destroy] do
            collection { patch :reorder }
            member     { patch :move }
          end
        end
      end

      # Other
      resources :weight_entries
      resources :shopping_lists do
        member do
          delete :clear_checked
          delete :clear_all
        end
        resources :shopping_list_items, only: [:create, :update, :destroy]
      end
    end
  end

  resource :profile, only: [:show, :edit, :update]

  resources :calendars, only: [:index] do
    collection do
      post :copy_yesterday
    end
  end
  resources :foods do
    collection do
      get   :search_import
      get   :barcode_import
      patch :bulk_pantry
      post  :add_missing_to_shopping_list
    end
    member do
      post  :duplicate
      patch :toggle_favorite
      patch :toggle_pantry
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

  resources :recipes do
    member do
      post  :duplicate
      patch :toggle_favorite
      post  :add_to_shopping_list
    end
    resources :recipe_ratings, only: [:create, :destroy]
  end

  resources :shopping_lists, only: [:index, :show, :destroy] do
    member do
      delete :clear_checked
      delete :clear_all
    end
    resources :shopping_list_items, only: [:create, :update, :destroy]
  end

  post 'days/:date/add_food', to: 'days#add_food', as: :add_food_to_day

  get 'statistics', to: 'statistics#index', as: :statistics

  get 'home', to: 'home#index', as: :home

  root "home#index"
end
