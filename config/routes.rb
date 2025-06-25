Rails.application.routes.draw do

  resources :calendars, only: [:index]
  resources :foods, only: [:index]

  root "calendars#index"
end
