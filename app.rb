#!/usr/bin/env ruby

require 'sinatra'
require 'sinatra/json'
require 'oauth2'
require 'manifoldco_signature'

# Manifold's public key (or your local test version), used for by the
# manifoldco_signature gem to verifiy that requests came from Manifold.
set :master_key, ENV['MASTER_KEY'] || ManifoldcoSignature::MASTER_KEY

# OAuth 2.0 client id and secret pair. Used to exchange a code for a user's
# token during SSO.
set :client_id, ENV['CLIENT_ID']
set :client_secret, ENV['CLIENT_SECRET']

# The URL of manifold's connector url, for completing SSO or making requests
set :connector_url, ENV['CONNECTOR_URL']

oac = OAuth2::Client.new(settings.client_id, settings.client_secret,
                         :site => settings.connector_url,
                         :token_url => '/v1/oauth/tokens'
                        )

# validator ensures that requests coming from Manifold are properly signed.
validator = ManifoldcoSignature::Verifier.new settings.master_key

# We'll use sessions to track users that have logged in via Manifold
set :session_secret, "not secret at all"
enable :sessions

# The cool dashboard. A user has to be authenticated with Manifold to use this.

get '/dashboard' do
  halt 401, 'you must be logged in with Manifold'  unless session[:token]

  token = OAuth2::AccessToken.from_hash oac, session[:token]

  profile = token.get '/v1/self'
  resource = token.get "/v1/resources/#{session[:resource]}"

  <<-HTML
  <body>
  <p> hi #{profile.parsed['target']['name']}, you are logged in</p>

  <p>your resource: #{resource.parsed['name']}</p>
  HTML
end

# Endpoints to implement the provider api for Manifold

put '/v1/resources/:id' do
  halt 401 unless validator.valid? request

  status 201
  json :message => 'your digital cat bonnet is ready'
end

patch '/v1/resources/:id' do
  halt 401 unless validator.valid? request

  status 200
  json :message => 'your digital cat bonnet has been changed'
end

delete '/v1/resources/:id' do
  halt 401 unless validator.valid? request

  status 204
end

put '/v1/credentials/:id' do
  halt 401 unless validator.valid? request

  status 201
  json :message => 'your cat bonnet password is ready', :credentials => {
    :password => 'meow'
  }
end

delete '/v1/credentials/:id' do
  halt 401 unless validator.valid? request

  status 204
end

# SSO requets come from the user's browser, so we don't want to run the
# validator against them.
get '/v1/sso' do
  token = oac.auth_code.get_token(params[:code])
  session[:token] = token.to_hash
  session[:resource] = params[:resource_id]

  redirect to '/dashboard'
end

# End provider api endpoints.
