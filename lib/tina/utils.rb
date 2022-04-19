#!/usr/bin/env ruby
# Id$ nonnax 2022-03-29 19:36:11 +0800
require 'uri'
require 'rack'
require 'json'
require 'erb'

REGEXES = Hash.new { |h, pattern| h[pattern] = U(pattern).compile_path_params  }

# decorator utils
class H < Hash
  def to_query_string(repeat_keys: false)
    repeat_keys ? send(:_repeat_keys) : send(:_single_keys)
  end

  def _single_keys
    inject([]) do |a, (k, v)|
      case v
        when Hash then  v = v._single_keys
        when Array then v = v.join(',')
      end
      a << [k, v].join('=')
    end.join('&')
  end
  private :_single_keys

  def _repeat_keys() URI.encode_www_form(self) end
  private :_repeat_keys
  
  # auto-symbolized hash
  def self.[](h) H.new(h) end  
  def initialize(h) merge!(h).keys_to_sym! end
  def keys_to_str()  transform_keys{|k| k.to_s.split('_').map(&:capitalize).join('-')} end
  def keys_to_sym!() transform_keys!{|k| k.to_s.tr('-', '_').downcase.to_sym} end
end

# Any decorator util
# validity of methods depend on the `base` object passed to the `()` constructor
#
class U
  attr_accessor :base
  
  def initialize(base) @base=base end  
  # string decorators
  def clean_path_info() Rack::Utils.clean_path_info(base) end 
  
  def compile_path
    slugs = []
    compiled_path = base.gsub(/:\w+/) do |match|
      slugs << match.gsub(':', '').to_sym
      '([^/?#]+)'
    end
    [/^(#{compiled_path})\/?$/, slugs]
  end

  def compile_pattern
    base.gsub(/:\w+/){ |match| '([^/?#]+)'}
    .then{|p| /^(#{p})\/?$/}
  end
  
  # matchdata decorators
  def capture_slugs(h)
    raise ArgumentError, 'missing keys :compiled_path, :slugs', caller unless [:compiled_path, :slugs].all?{|e| h.keys.include?(e)}
    md=base.match(h[:compiled_path])
    h[:slugs].zip(md.captures).to_h
  rescue Exception => e
    puts e
    Hash[]
  end

  # hash decorators  
  def keys_to_str() base.transform_keys{|k| k.to_s.split('_').map(&:capitalize).join('-')} end
  def keys_to_sym!() base.transform_keys!{|k| k.to_s.tr('-', '_').downcase.to_sym} end
  alias symbolize_keys keys_to_sym!  
  def to_query_string(...) H[base].to_query_string(...) end
  
  # Rack::Utils
  def self.method_missing(m, *a, **params, &b) Rack::Utils.send(m, *a, **params, &b) end
end

module Kernel
  def H(h) H[h] end
  def U(any) U.new(any) end
  def Q(s)   Q.new(s)   end
  def render(s, **locals)
    new_b=binding.dup
    new_b.instance_eval{ locals.each{|k, v|local_variable_set(k, v)}}
    ERB.new(s).result(new_b)
  end
end
