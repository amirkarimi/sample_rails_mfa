Rails.application.routes.draw do
  get 'dashboard/index'
  get 'home/index'
  get 'dashboard/disable_mfa'
  root to: "home#index"
  
  devise_for :users, controllers: { sessions: "sessions" }
  devise_scope :user do
    match '/auth/mfa/check',    to: 'sessions#mfa_check',   via: :get
    match '/auth/mfa/callback', to: 'sessions#mfa_callback', via: :get
  end
end
