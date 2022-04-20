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
      self.status=200
      self.headers[Rack::CONTENT_TYPE]='application/json'
      self.write j
    end
    def html(s)
      self.status=200
      self.headers[Rack::CONTENT_TYPE]='text/html; charset=utf-8'
      self.write s
    end
    def erb(s, **locals)
      l=Tina.settings[:render][:layout]
      layout_f = File.read(l) if File.exist?(l)
      layout_f ||= '<%=yield%>'
      s=render(layout_f, **locals) do
          render(s, **locals).then{|s| 
            (locals.keys & [:md, :markdown]).any? ? K.new(s).to_html : s 
          }
      end
      self.html s 
    end
  end
end
