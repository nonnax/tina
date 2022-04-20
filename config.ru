#!/usr/bin/env ruby
# Id$ nonnax 2022-03-24 21:34:18 +0800
require_relative 'lib/tina'
require 'json'

# use Rack::CommonLogger
# use Rack::ShowExceptions
# use Rack::Lint
use Rack::Static, :urls => ["/css"], :root=>'public'
 
get '/' do |params|
    res.json env.to_json
end

get '/:any' do |any|
    res.write _erb( "{<%=any%>}", any:)
end

post '/:any' do |any|
    partial=_erb( "POST {<%=any%>}", any:)
    res.write partial
end

handle 404 do
  res.erb %{#Not here}, md:true
end
# pp Kernel.map['GET'].map{|e| e.first}
pp Kernel.map

run Tina.new
