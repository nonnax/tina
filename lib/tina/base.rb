#!/usr/bin/env ruby
# frozen_string_literal: true

# Id$ nonnax 2022-03-24 21:33:46 +0800
require_relative 'utils'
require_relative 'response'

class Tina
  attr :env, :req, :res, :handler 
  
  def initialize() 
    @handler = Kernel.map 
  end
  def default() 
    unless yield
      status=res.status
      handler[status.to_s].tap{ |h| h ? instance_eval(&h['404'][:block]) : res.write('Not Found') }
      res.status=status # restore as res.write sets res.status==200
    end
  end
  def call(env)
    @req, @res, @env, md= Rack::Request.new(env), Tina::Response.new(nil, 404), env 
    path, data = handler.detect{|k, v| req.path_info.match?( REGEXP(k) )}
    r=data[req.request_method] if path
    default do
      if r
        md=req.path_info.match(REGEXP(path))
        path, *slugs = Array(md&.captures)
        slugs << req.params
        instance_exec(*slugs, req.params, &r[:block])
      end
    end
    res.finish
  rescue Exception => e
    [500, {}, [e.message, e.backtrace].flatten]
  end

  @settings=Hash.new{|h, k| h[k]={}}
  @settings[:render]=Hash[:layout,'views/layout.erb']
  def self.settings; @settings end
  def REGEXP(path)
    path.gsub(/:\w+/){ |match| '([^/?#]+)'}
    .then{|p|  /^(#{p})\/?$/ }
  end
  
end

module Kernel
  tina_handler = Hash.new { |h, k| h[k] = {} }
  define_method(:map) { tina_handler }
  define_method(:not_found){|status=404,&block|  tina_handler[status.to_s]['404']={block: } }
  define_method(:get) do |u, &block|  tina_handler[u]['GET']={ block: }  end
  define_method(:post) do |u, &block| tina_handler[u]['POST']={ block: } end
end
