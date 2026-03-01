Rails.application.routes.draw do
  devise_for :users

  authenticated :user do
    root "home#index", as: :authenticated_root
  end
  root "dashboard#index"

  get "up" => "rails/health#show", as: :rails_health_check
  get "home", to: "home#index", as: :home
  get "awaiting-approval", to: "approvals#show", as: :awaiting_approval
  get "leaderboard", to: "leaderboards#index", as: :leaderboard
  get "history", to: "history#index", as: :history

  resources :matches, only: [:index]
  resources :picks, only: [:create, :update]
  resources :users, only: [:index, :show]
  get "dashboard", to: "dashboard#index", as: :dashboard

  namespace :admin do
    root "dashboard#index"
    post "daily_match_entries", to: "dashboard#daily_match_entries", as: :daily_match_entries

    resources :users, only: [:index, :edit, :update] do
      member do
        patch :approve
        patch :deny
      end
    end

    resources :seasons
    resources :teams
    resources :matches do
      member do
        patch :set_result
        post :recalculate
      end
    end

    resources :picks, only: [:index, :edit, :update]
    resources :points_events, only: [:index, :new, :create]
    resources :points_rules, only: [:edit, :update]
    resources :data_imports, only: [:index, :create]
    post "recalculations/season/:season_id", to: "recalculations#season", as: :recalculate_season
  end
end
