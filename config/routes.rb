Rails.application.routes.draw do

  resources :calendars, only: [:index]
  resources :foods, except: [:show]

  root "calendars#index"
end
