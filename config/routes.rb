Rails.application.routes.draw do
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

  scope 'reports', as: :reports do
    get '/' => 'reports#index'
    get '/capital-stock-activity' => 'reports#capital_stock_activity'
    get '/borrowing-capacity' => 'reports#borrowing_capacity'
    get '/settlement-transaction-account' => 'reports#settlement_transaction_account'
    get '/advances' => 'reports#advances_detail'
    get '/historical-price-indications' => 'reports#historical_price_indications'
    get '/cash-projections' => 'reports#cash_projections'
    get '/current-price-indications' => 'reports#current_price_indications'
    get '/interest-rate-resets' => 'reports#interest_rate_resets'
    get '/dividend-statement' => 'reports#dividend_statement'
    get '/securities-services-statement' => 'reports#securities_services_statement'
    get '/letters-of-credit' => 'reports#letters_of_credit'
    get '/securities-transactions' => 'reports#securities_transactions'
    get '/authorizations' => 'reports#authorizations'
    get '/putable-advance-parallel-shift-sensitivity' => 'reports#parallel_shift', as: :parallel_shift
    get '/current-securities-position' => 'reports#current_securities_position'
    get '/monthly-securities-position' => 'reports#monthly_securities_position'
    get '/forward-commitments' => 'reports#forward_commitments'
    get '/capital-stock-and-leverage' => 'reports#capital_stock_and_leverage'
    get '/account-summary' => 'reports#account_summary'
  end

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
      get 'adjustable-rate-credit' => 'products#arc', as: :arc
      get 'advances-for-community-enterprise' => 'error#standard_error', as: :ace
      get 'amortizing' => 'products#amortizing', as: :amortizing
      get 'arc-embedded' => 'error#standard_error'
      get 'callable' => 'error#standard_error'
      get 'choice-libor' => 'products#choice_libor', as: :choice_libor
      get 'community-investment-program' => 'error#standard_error', as: :cip
      get 'auction-indexed' => 'error#standard_error'
      get 'fixed-rate-credit' => 'products#frc', as: :frc
      get 'frc-embedded' => 'products#frc_embedded'
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
    get 'member/terms' => 'members#terms', :as => :terms
    post 'member/terms' => 'members#accept_terms', :as => :accept_terms
    get 'member/password' => 'users/passwords#new', as: :new_user_password
    post 'member/password' => 'users/passwords#create', as: :user_password
    get 'member/password/reset' => 'users/passwords#edit', as: :edit_user_password
  end
  devise_for :users, controllers: { sessions: 'users/sessions', passwords: 'users/passwords' }, :skip => [:sessions, :passwords]

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
