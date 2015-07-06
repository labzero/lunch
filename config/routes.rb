Rails.application.routes.draw do
  devise_for :users, controllers: { sessions: 'users/sessions' }, :skip => [:sessions]
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"

  get '/details' => 'welcome#details'
  get '/healthy' => 'welcome#healthy'
  get '/terms-of-use' => 'error#standard_error', as: :terms_of_use
  get '/disclaimer-reuters' => 'error#standard_error', as: :disclaimer_reuters
  get '/online-security' => 'error#standard_error', as: :online_security
  get '/grid_demo' => 'welcome#grid_demo'

  get '/dashboard' => 'dashboard#index'

  get '/dashboard/quick_advance_rates' => 'dashboard#quick_advance_rates'

  post '/dashboard/quick_advance_preview' => 'dashboard#quick_advance_preview'

  post '/dashboard/quick_advance_perform' => 'dashboard#quick_advance_perform'

  get '/dashboard/current_overnight_vrc' => 'dashboard#current_overnight_vrc'

  get '/reports' => 'reports#index'
  get '/reports/capital-stock-activity' => 'reports#capital_stock_activity'
  get '/reports/borrowing-capacity' => 'reports#borrowing_capacity'
  get '/reports/settlement-transaction-account' => 'reports#settlement_transaction_account'
  get '/reports/advances' => 'reports#advances_detail'
  get '/reports/historical-price-indications' => 'reports#historical_price_indications'
  get '/reports/cash-projections' => 'reports#cash_projections'
  get '/reports/current-price-indications' => 'reports#current_price_indications'
  get '/reports/interest-rate-resets' => 'reports#interest_rate_resets'
  get '/reports/dividend-statement' => 'reports#dividend_statement'
  get '/reports/securities-services-statement' => 'reports#securities_services_statement'
  get '/reports/letters-of-credit' => 'reports#letters_of_credit'
  get '/reports/securities-transactions' => 'reports#securities_transactions'
  get '/reports/authorizations' => 'reports#authorizations'
  get '/reports/putable-advance-parallel-shift-sensitivity' => 'reports#parallel_shift', as: 'reports_parallel_shift'
  get '/reports/current-securities-position' => 'reports#current_securities_position'
  get '/reports/monthly-securities-position' => 'reports#monthly_securities_position'
  get '/reports/forward-commitments' => 'reports#forward_commitments'
  get '/reports/capital-stock-and-leverage' => 'reports#capital_stock_and_leverage'

  get '/advances' => 'advances#index'
  get '/advances/manage-advances' => 'advances#manage_advances'

  get '/settings' => 'settings#index'
  post '/settings/save' => 'settings#save'
  get '/settings/two-factor' => 'settings#two_factor'
  post '/settings/two-factor/pin' => 'settings#reset_pin'
  post '/settings/two-factor/resynchronize' => 'settings#resynchronize'
  get '/settings/users' => 'settings#users'
  post '/settings/users/:id/lock' => 'settings#lock', as: 'user_lock'
  post '/settings/users/:id/unlock' => 'settings#unlock', as: 'user_unlock'
  get '/settings/users/:id' => 'settings#edit_user', as: 'user'
  patch '/settings/users/:id' => 'settings#update_user'
  get '/settings/users/:id/confirm_delete' => 'settings#confirm_delete', as: 'user_confirm_delete'
  delete '/settings/users/:id' => 'settings#delete_user'

  get '/jobs/:job_status_id' => 'jobs#status', as: 'job_status'
  get '/jobs/:job_status_id/download' => 'jobs#download', as: 'job_download'
  get '/jobs/:job_status_id/cancel' => 'jobs#cancel', as: 'job_cancel'

  scope 'corporate_communications/:category' do
    resources :corporate_communications, only: :show, as: :corporate_communication
    get '/' => 'corporate_communications#category', as: :corporate_communications
  end

  scope 'resources' do
    get '/forms' => 'resources#forms'
    get '/guides' => 'resources#guides'
    get '/download/:file' => 'resources#download', as: :resources_download
  end

  scope 'products' do
    get '/summary' => 'products#index', as: :product_summary
    get '/letters-of-credit' => 'error#standard_error'
    get '/community_programs' => 'error#standard_error'
    scope 'advances' do
      get 'adjustable-rate-credit' => 'error#standard_error', as: :arc
      get 'advances-for-community-enterprise' => 'error#standard_error', as: :ace
      get 'amortizing' => 'error#standard_error'
      get 'arc-embedded' => 'error#standard_error'
      get 'callable' => 'error#standard_error'
      get 'choice-libor-arc' => 'error#standard_error'
      get 'community-investment-program' => 'error#standard_error', as: :cip
      get 'auction-indexed' => 'error#standard_error'
      get 'fixed-rate-credit' => 'error#standard_error', as: :frc
      get 'frc-embedded' => 'error#standard_error'
      get 'knockout' => 'error#standard_error'
      get 'mortgage-partnership-finance' => 'error#standard_error', as: :mpf
      get 'other-cash-needs' => 'error#standard_error', as: :ocn
      get 'putable' => 'error#standard_error'
      get 'securities-backed-credit' => 'error#standard_error', as: :sbc
      get 'variable-rate-credit' => 'error#standard_error', as: :vrc
    end
  end

  devise_scope :user do
    get '/' => 'users/sessions#new', :as => :new_user_session
    post '/' => 'users/sessions#create', :as => :user_session
    delete 'logout' => 'users/sessions#destroy', :as => :destroy_user_session
    get '/member' => 'members#select_member', :as => :members_select_member
    post '/member' => 'members#set_member', :as => :members_set_member
  end

  root 'users/sessions#new'

  get '/error' => 'error#standard_error' unless Rails.env.production?
  get '/maintenance' => 'error#maintenance' unless Rails.env.production?

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
