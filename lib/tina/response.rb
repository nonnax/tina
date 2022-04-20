#!/usr/bin/env ruby
# Id$ nonnax 2022-04-15 17:26:56 +0800
# require_relative 'utils'
require 'kramdown'
K=Kramdown::Document
class Tina
  class Response < Rack::Response
    def write(*a)
      self.status=200
      super
    end
    def json(j)
      instance_eval do
        status=200
        headers[Rack::CONTENT_TYPE]='application/json'
        write j
      end
    end
    def html(s)
      instance_eval do
        status=200
        headers[Rack::CONTENT_TYPE]='text/html; charset=utf-8'
        write s
      end
    end

    def erb(s, **locals)
      l=Tina.settings[:render][:layout]
      layout_f = File.read(l) if File.exist?(l)
      layout_f ||= '<%=yield%>'
      s=_erb(layout_f, **locals) do
          _erb(s, **locals).then{|s| 
            (locals.keys & [:md, :markdown]).any? ? K.new(s).to_html : s 
          }
      end
      self.html s 
    end
  end
end
