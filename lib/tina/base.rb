#!/usr/bin/env ruby
# frozen_string_literal: true

# Id$ nonnax 2022-03-24 21:33:46 +0800
require_relative 'response'

class Tina
  attr :env, :req, :res, :handler 
  
  def initialize() 
    @handler = Handler.map 
  end
  def default() 
    unless yield
      status=res.status
      handler[status].tap{ |h| h ? instance_eval(&h['DEFAULT']) : res.write('Not Found') }
      res.status=404 # restore as res.write sets res.status==200
    end
  end
  def call(env)
    @req, @res, @env, md= Rack::Request.new(env), Tina::Response.new(nil, 404), env 
    path, body = handler.detect{|p, _| md=req.path_info.match( PATTERN[p] )}
    default do
      if path
        path, *slugs = Array(md&.captures)
        instance_exec(*slugs, req.params, &body[req.request_method])
      end
    end
    res.finish
  rescue Exception => e
    [500, {}, [e.message].flatten]
  end

  @settings=Hash.new{|h, k| h[k]={}}
  @settings[:render][:layout]='views/layout.erb'
  def self.settings; @settings end
  
  PATTERN=Hash.new{|h, path| 
    h[path]=path
    .gsub(/:\w+/){ |match| '([^/?#]+)' }
    .then{|p| /^(#{p})\/?$/ } 
  }
  
  def session
    env["rack.session"] || raise(RuntimeError,
      "You're missing a session handler. use Rack::Session::Cookie")
  end
end

class Tina
  module Handler
    tina_handler = Hash.new { |h, k| h[k.to_s] = {} }
    define_method(:map) { tina_handler }
    define_method(:handle){|status=404, &block| tina_handler[status]['DEFAULT']=block }
    define_method(:get)    do |u, &block| tina_handler[u]['GET']=block  end
    define_method(:post)   do |u, &block| tina_handler[u]['POST']=block end
    define_method(:delete) do |u, &block| tina_handler[u]['DELETE']=block end
    def _erb(s, **locals)
      binding.dup
      .tap{ |b| b.instance_eval{ locals.each{|k, v|local_variable_set(k, v)}}}
      .then{|b| ERB.new(s).result(b)}
    end
  end
end

Kernel.include Tina::Handler
