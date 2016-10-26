Igneous::Smart::Engine.routes.draw do

  scope ':ehr_source_id', constraints: {ehr_source_id: /\S{1,36}/ } do
    resources :apps, only: [:index, :show]
  end

  resources :apps, only: [:show, :create]
  resources :fhir_servers, only: [:create, :index]

  match 'apps/details/:id' => 'apps_details#show', via: [:get]
  get 'user/preauth' => 'user#preauth'
  get 'user/preauth/url' => 'user#preauth_url'
  post 'launch/resolve' => 'launch_context#resolve', :constraints => { format: :json }
  post 'validator/results' => 'app_validator#results', :constraints => { format: :json }
end
