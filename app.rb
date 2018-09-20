#!/usr/bin/env ruby

require 'set'
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

# Products, plans, and regions we know about
products = Set.new ['bonnets']
plans = Set.new ['small', 'large']
regions = Set.new ['aws::us-east-1']

# Our in-memory db
db = {:resources=> {}, :credentials => {} }

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
  halt 401, json(:message => 'bad signature') unless validator.valid? request

  body = JSON.parse(request.body.read)
  halt 400, json(:message => 'bad product') unless products.include? body['product']
  halt 400, json(:message => 'bad plan') unless plans.include? body['plan']
  halt 400, json(:message => 'bad region') unless regions.include? body['region']

  existing = db[:resources][params['id']]
  unless existing.nil?
    halt 409, json(:message => 'resource already exists') unless existing == body
  end

  db[:resources][params['id']] = body

  status 201
  json :message => 'your digital cat bonnet is ready'
end

patch '/v1/resources/:id' do
  halt 401, json(:message => 'bad signature') unless validator.valid? request

  body = JSON.parse(request.body.read)
  halt 400, json(:message => 'bad plan') unless plans.include? body['plan']

  resource = db[:resources][params['id']]
  halt 404, json(:message => 'no such resource') if resource.nil?

  status 200
  json :message => 'your digital cat bonnet has been changed'
end

delete '/v1/resources/:id' do
  halt 401, json(:message => 'bad signature') unless validator.valid? request

  not_found = db[:resources].delete(params['id']).nil?
  halt 404, json(:message => 'no such resource') if not_found

  status 204
end

get '/v1/resources/:id/measures' do
  halt 401, json(:message => 'bad signature') unless validator.valid? request

  resource = db[:resources][params['id']]
  halt 404, json(:message => 'no such resource') if resource.nil?

  status 200
  json(
    :resource_id => params['id'],
    :period_start => params['period_start'],
    :period_end => params['period_end'],
    :measures => { 'feature-a' => 0, 'feature-b' => 1000 }
  )
end


put '/v1/credentials/:id' do
  halt 401, json(:message => 'bad signature') unless validator.valid? request

  body = JSON.parse(request.body.read)

  resource = db[:resources][body['resource_id']]
  halt 404, json(:message => 'no such resource') if resource.nil?

  db[:credentials][params['id']] = body

  status 201
  json :message => 'your cat bonnet password is ready', :credentials => {
    :PASSWORD => 'meow'
  }
end

delete '/v1/credentials/:id' do
  halt 401, json(:message => 'bad signature') unless validator.valid? request

  not_found = db[:credentials].delete(params['id']).nil?
  halt 404, json(:message => 'no such credential') if not_found

  status 204
end

# SSO requets come from the user's browser, so we don't want to run the
# validator against them.
get '/v1/sso' do
  begin
    token = oac.auth_code.get_token(params[:code])
  rescue OAuth2::Error => err
    return 401, "This is a page that the user would see"
  end

  session[:token] = token.to_hash
  session[:resource] = params[:resource_id]

  redirect to '/dashboard'
end

# End provider api endpoints.
