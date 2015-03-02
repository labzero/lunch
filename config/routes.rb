Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: 'users/sessions' }, :skip => [:sessions]
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"

  get '/details' => 'welcome#details'

  get '/grid_demo' => 'welcome#grid_demo'

  get '/dashboard' => 'dashboard#index'

  get '/dashboard/quick_advance_rates' => 'dashboard#quick_advance_rates'

  post '/dashboard/quick_advance_preview' => 'dashboard#quick_advance_preview'

  post '/dashboard/quick_advance_confirmation' => 'dashboard#quick_advance_confirmation'

  get '/dashboard/current_overnight_vrc' => 'dashboard#current_overnight_vrc'

  get '/reports' => 'reports#index'
  get '/reports/capital-stock-activity' => 'reports#capital_stock_activity'
  get '/reports/borrowing-capacity' => 'reports#borrowing_capacity'
  get '/reports/settlement-transaction-account' => 'reports#settlement_transaction_account'
  get '/reports/advances' => 'reports#advances_detail'
  get '/reports/historical-price-indications' => 'reports#historical_price_indications'

  get '/settings' => 'settings#index'

  scope 'corporate_communications/:category' do
    resources :corporate_communications, only: :show, as: :corporate_communication
    get '/' => 'corporate_communications#category', as: :corporate_communications
  end

  post '/settings/save' => 'settings#save'

  devise_scope :user do
    get '/' => 'users/sessions#new', :as => :new_user_session
    post '/' => 'users/sessions#create', :as => :user_session
    delete 'logout' => 'users/sessions#destroy', :as => :destroy_user_session
  end

  root 'users/sessions#new'

  get '/error' => 'error#standard_error' unless Rails.env.production?

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
