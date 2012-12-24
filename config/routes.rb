Volant::Application.routes.draw do
  root :to => 'outgoing/apply_forms#index'


  match '/email_templates/howto' => 'email_templates#howto', :as => :email_templates_howto
  match '/incoming/workcamps/export_alliance.xml' => 'incoming/workcamps#export_alliance_xml', :as => :alliance_in
  match '/outgoing/workcamps/export_alliance.xml' => 'outgoing/workcamps#export_alliance_xml', :as => :alliance_out
  match '/incoming/workcamps/friday_list_csv' => 'incoming/workcamps#friday_list_csv', :format => 'csv', :as => :friday_list
  match '/outgoing/apply_forms/export' => 'outgoing/apply_forms#export', :format => 'csv', :as => :outgoing_apply_forms_export

  # AdHoc fix - do it better?
  match ':controller/:action',
                  :requirements => { :action => /auto_complete_(belongs_to_)?for_\S+/ },
                  :conditions => { :method => :get },
                  :as => :auto_complete

  match '/login' => 'sessions#new', :as => :login
  match '/logout' => 'sessions#destroy', :as => :logout

  # TODO - should be post
  # Active Scaffold link to change the apply form state
  match '/apply_forms/accept/:id?_method=get' => 'apply_forms#accept',
                        :_method => 'get',
                        :parent_controller => 'apply_forms',
                        :conditions => { :method => :get },
                        :as => :accept

  resources :payments, :active_scaffold => true
  resources :organizations, :active_scaffold => true
  resources :networks, :active_scaffold => true
  resources :email_templates, :active_scaffold => true
  resources :tags, :active_scaffold => true
  resources :users, :active_scaffold => true
  resources :workcamp_intentions, :active_scaffold => true
  resources :workcamp_assignments, :active_scaffold => true
  resources :countries, :active_scaffold => true
  resources :languages, :active_scaffold => true
  resources :infosheets, :active_scaffold => true
  resources :import_changes, :active_scaffold => true, :member => {  :apply => :post }
  #TODO - remove this REST API
  resources :countries,
            :controller => 'RestfulCountries',
            :path_prefix => '/rest',
            :only => [ :index, :show ]

  resources :apply_forms,
            :controller => 'RestfulApplyForms',
            :path_prefix => '/rest',
            :only => [ :create, :show ]

  resources :workcamp_intentions,
            :controller => 'RestfulWorkcampIntentions',
            :path_prefix => '/rest',
            :only => [ :index, :show ]

  resources :workcamps,
            :controller => 'RestfulWorkcamps',
            :only => [ :index, :show ],
            :has_one => :country,
            :path_prefix => '/rest',
            :has_one => :workcamp_intention,
            :collection => {  :total => :get }

  resource :session

  namespace :public do
    resources :workcamps, :only => [ :index, :show ]
  end

  namespace :outgoing do
    resources :volunteers, :active_scaffold => true
    resources :apply_forms, :controller => :apply_forms, :active_scaffold => true
    resources :apply_forms_special, :active_scaffold => true
    resources :workcamps, :active_scaffold => true

    resources :imported_workcamps, :active_scaffold => true,
              :collection => { :confirm_all => :post, :cancel_all => :post, :confirm => :post }

    resources :updated_workcamps, :active_scaffold => true,
              :collection => { :confirm_all => :post, :cancel_all => :post, :confirm => :post }

    resources :imports, :only => [ :new, :create, :show ], :active_scaffold => false
  end

  namespace :incoming do
    resources :preparation_workcamps, :active_scaffold => true
    resources :season_workcamps, :active_scaffold => true

    # resources :workcamps, :as => 'wc_with_partners', :controller => 'incoming/workcamps_with_partners', :active_scaffold => true
    resources :leaders, :active_scaffold => true
    resources :participations, :active_scaffold => true
    resources :participants, :active_scaffold => true
    resources :partners, :active_scaffold => true
    resources :hosting, :active_scaffold => true
    resources :bookings, :active_scaffold => true
  end


  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  match ':controller/:action/:id'
  match ':controller/:action.:format'
  match ':controller/:action/:id.:format'

  # TODO - possible to remove somehow? - ActiveScaffold cannot find it without these routes
  match '/incoming/:controller/:action/:id'
  match '/incoming/:controller/:action.:format'
  match '/incoming/:controller/:action/:id.:format'
  match '/outgoing/:controller/:action/:id'
  match '/outgoing/:controller/:action.:format'
  match '/outgoing/:controller/:action/:id.:format'
end
