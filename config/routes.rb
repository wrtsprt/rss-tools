Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  #
  #
  resources :enhancers

  root :to => 'hs_fix#index'
  get '/heise_newsfeed(.format)' => 'hs_fix#index'
  get '/de_morgen(.format)' => 'de_morgen_#index'
end
