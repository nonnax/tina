#!/usr/bin/env ruby
# Id$ nonnax 2022-03-24 21:34:18 +0800
require_relative 'lib/tina'
require 'json'
require 'rack/protection'
require 'securerandom'

use Rack::Session::Cookie, secret: SecureRandom.hex(64)
# use Rack::Protection

pretty=JSON.method(:pretty_generate)
# use Rack::CommonLogger
# use Rack::ShowExceptions
# use Rack::Lint
use Rack::Static, :urls => ["/css"], :root=>'public'
 
get '/' do |params|
  session.clear
  res.json env.to_json
end

get '/login' do |params|
  session[:name] = 'tina'
  res.write 'please log in'
end

get '/:any' do |any|
  if session[:name]
    res.write _erb( "{<%=any%>} <%=user%>", any:, user: session[:name])
  else
    res.redirect '/login'
  end
end

post '/:any' do |any|
  partial={POST: any}
  res.json partial.to_json
end

handle 404 do
  res.erb '#Not here', md:true
end
# pp Kernel.map['GET'].map{|e| e.first}
puts pretty[Kernel.map]

run Tina.new
