Rails.application.routes.draw do
  get 'password_resets/create'
  get 'password_resets/edit'
  get 'password_resets/update'
  get 'login' => 'user_sessions#new', as: :login
  post 'logout' => 'user_sessions#destroy', as: :logout
  get 'about' => 'pages#about', as: :about
  root to: 'pages#home'
  
  resources :password_resets
  resources :user_sessions

  resources :users do
    member do
      get :activate
      patch :default_group
    end
    collection do
      get :auto_complete
    end
  end

  shallow do # Only the collection routes of the children get member routes of the parent
    resources :user_groups do
      resources :groceries do
        resources :items do
          collection do
            get :auto_complete
            patch :add
          end
          member do
            patch :remove
          end
        end
        member do
          patch :finish
          patch :reopen
          get :email_group
        end
      end
      member do
        get :metrics
      end
    end
  end
end
