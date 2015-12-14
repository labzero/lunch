Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"

  get '/details' => 'welcome#details'
  get '/healthy' => 'welcome#healthy'
  get '/session_status' => 'welcome#session_status'
  get '/disclaimer-reuters' => 'error#not_found', as: :disclaimer_reuters
  get '/online-security' => 'error#not_found', as: :online_security
  get '/grid_demo' => 'welcome#grid_demo'

  get '/dashboard' => 'dashboard#index'

  get '/dashboard/quick_advance_rates' => 'dashboard#quick_advance_rates'

  post '/dashboard/quick_advance_preview' => 'dashboard#quick_advance_preview'

  post '/dashboard/quick_advance_perform' => 'dashboard#quick_advance_perform'

  get '/dashboard/current_overnight_vrc' => 'dashboard#current_overnight_vrc'

  get '/dashboard/recent_activity' => 'dashboard#recent_activity'

  get '/dashboard/account_overview' => 'dashboard#account_overview'

  get '/attachments/download/:id/:filename' => 'attachments#download', as: :attachment_download, filename: /[^\/]+/

  scope 'reports', as: :reports do
    get '/' => 'reports#index'
    get '/account-summary' => 'reports#account_summary'
    get '/advances' => 'reports#advances_detail'
    get '/authorizations' => 'reports#authorizations'
    get '/borrowing-capacity' => 'reports#borrowing_capacity'
    get '/capital-stock-activity' => 'reports#capital_stock_activity'
    get '/capital-stock-and-leverage' => 'reports#capital_stock_and_leverage'
    get '/capital-stock-trial-balance' => 'reports#capital_stock_trial_balance'
    get '/cash-projections' => 'reports#cash_projections'
    get '/current-price-indications' => 'reports#current_price_indications'
    get '/current-securities-position' => 'reports#current_securities_position'
    get '/dividend-statement' => 'reports#dividend_statement'
    get '/forward-commitments' => 'reports#forward_commitments'
    get '/historical-price-indications' => 'reports#historical_price_indications'
    get '/interest-rate-resets' => 'reports#interest_rate_resets'
    get '/letters-of-credit' => 'reports#letters_of_credit'
    get '/monthly-securities-position' => 'reports#monthly_securities_position'
    get '/mortgage-collateral-update' => 'reports#mortgage_collateral_update'
    get '/putable-advance-parallel-shift-sensitivity' => 'reports#parallel_shift', as: :parallel_shift
    get '/securities-services-statement' => 'reports#securities_services_statement', as: :securities_services_statement
    get '/securities-transactions' => 'reports#securities_transactions'
    get '/settlement-transaction-account' => 'reports#settlement_transaction_account'
    get '/todays-credit' => 'reports#todays_credit'
  end

  get '/advances' => 'advances#index'
  get '/advances/manage-advances' => 'advances#manage_advances'

  scope 'settings', as: :settings do
    get    '/'                         => 'error#not_found'
    get    '/password'                 => 'settings#change_password'
    put    '/password'                 => 'settings#update_password'
    post   '/save'                     => 'settings#save'
    get    '/two-factor'               => 'settings#two_factor'
    put    '/two-factor/pin'           => 'settings#reset_pin'
    post   '/two-factor/pin'           => 'settings#new_pin'
    post   '/two-factor/resynchronize' => 'settings#resynchronize'
    get    '/users'                    => 'settings#users'
    patch  '/users/:id'                => 'settings#update_user'
    delete '/users/:id'                => 'settings#delete_user'
  end

  scope 'settings' do
    get    '/users/new'                => 'settings#new_user', as: 'new_user'
    post   '/users'                    => 'settings#create_user', as: 'users'
    get    '/users/:id'                => 'settings#edit_user', as: 'user'
    get    '/users/:id/confirm_delete' => 'settings#confirm_delete', as: 'user_confirm_delete'
    post   '/users/:id/lock'           => 'settings#lock', as: 'user_lock'
    post   '/users/:id/unlock'         => 'settings#unlock', as: 'user_unlock'
    get    '/expired-password'         => 'settings#expired_password', as: :user_expired_password
    put    '/expired-password'         => 'settings#update_expired_password'
  end

  get '/jobs/:job_status_id' => 'jobs#status', as: 'job_status'
  get '/jobs/:job_status_id/download' => 'jobs#download', as: 'job_download'
  get '/jobs/:job_status_id/cancel' => 'jobs#cancel', as: 'job_cancel'

  scope 'corporate_communications/:category' do
    resources :corporate_communications, only: :show, as: :corporate_communication
    get '/' => 'corporate_communications#category', as: :corporate_communications
  end

  scope 'resources' do
    get '/business-continuity' => 'resources#business_continuity'
    get '/forms' => 'resources#forms'
    get '/guides' => 'resources#guides'
    get '/capital-plan' => 'resources#capital_plan'
    get '/download/:file' => 'resources#download', as: :resources_download
    get 'fee_schedules' => 'resources#fee_schedules'
    scope 'membership' do
      get 'overview' => 'resources#membership_overview', as: :membership_overview
      get 'application' => 'resources#membership_application', as: :membership_application
      scope 'application' do
        get 'commercial-savings-and-industrial' => 'resources#commercial_application', as: :commercial_application
        get 'community-development' => 'error#not_found', as: :community_development_application
        get 'credit-union' => 'error#not_found', as: :credit_union_application
        get 'insurance-company' => 'error#not_found', as: :insurance_company_application
      end
    end
  end

  scope 'products' do
    get '/authorizations' => 'products#authorizations', as: :products_authorizations
    get '/summary' => 'products#index', as: :product_summary
    get '/letters-of-credit' => 'error#not_found'
    get '/community_programs' => 'error#not_found'
    get '/interest-rate-swaps-caps-floors' => 'products#swaps', as: :product_swaps
    scope 'advances' do
      get 'adjustable-rate-credit' => 'products#arc', as: :arc
      get 'advances-for-community-enterprise' => 'error#not_found', as: :ace
      get 'amortizing' => 'products#amortizing', as: :amortizing
      get 'arc-embedded' => 'products#arc_embedded', as: :arc_embedded
      get 'callable' => 'products#callable', as: :callable
      get 'choice-libor' => 'products#choice_libor', as: :choice_libor
      get 'community-investment-program' => 'error#not_found', as: :cip
      get 'auction-indexed' => 'products#auction_indexed', as: :auction_indexed
      get 'fixed-rate-credit' => 'products#frc', as: :frc
      get 'frc-embedded' => 'products#frc_embedded', as: :frc_embedded
      get 'knockout' => 'products#knockout', as: :knockout
      get 'mortgage-partnership-finance' => 'products#mpf', as: :mpf
      get 'pfi' => 'products#pfi', as: :pfi
      get 'other-cash-needs' => 'products#ocn', as: :ocn
      get 'putable' => 'products#putable', as: :putable
      get 'securities-backed-credit' => 'products#sbc', as: :sbc
      get 'variable-rate-credit' => 'products#vrc', as: :vrc
    end
  end

  constraints Constraints::FeatureEnabled.new('securities') do
    scope 'securities' do
      get 'manage' => 'securities#manage', as: :manage_securities
    end
  end

  devise_scope :user do
    get '/' => 'users/sessions#new', :as => :new_user_session
    post '/' => 'users/sessions#create', :as => :user_session
    delete 'logout' => 'users/sessions#destroy', :as => :destroy_user_session
    get 'logged-out' => 'members#logged_out'
    post '/switch' => 'members#switch_member', :as => :members_switch_member
    get '/member' => 'members#select_member', :as => :members_select_member
    post '/member' => 'members#set_member', :as => :members_set_member
    get 'member/terms' => 'members#terms', :as => :terms
    post 'member/terms' => 'members#accept_terms', :as => :accept_terms
    get 'member/password' => 'users/passwords#new', as: :new_user_password
    post 'member/password' => 'users/passwords#create', as: :user_password
    get 'member/password/reset' => 'users/passwords#edit', as: :edit_user_password
    put 'member/password' => 'users/passwords#update'
    get '/terms-of-use' => 'members#terms_of_use', as: :terms_of_use
    get '/contact' => 'members#contact', as: :contact
    get '/privacy-policy' => 'members#privacy_policy', as: :privacy_policy
  end
  devise_for :users, controllers: { sessions: 'users/sessions', passwords: 'users/passwords' }, :skip => [:sessions, :passwords]

  root 'users/sessions#new'

  constraints Constraints::WebAdmin.new do
    mount Flipper::UI.app(Rails.application.flipper) => '/admin'
  end

  get '/error' => 'error#standard_error' unless Rails.env.production?
  get '/maintenance' => 'error#maintenance' unless Rails.env.production?
  get '/not-found' => 'error#not_found' unless Rails.env.production?

  # This catchall route MUST be listed here last to avoid catching previously-named routes
  get '*unmatched_route' => 'error#not_found'

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
