require 'shellwords'

class Specinfra::Command::Base
  attr_accessor :types

  class NotImplementedError < Exception; end

  def escape(target)
    str = case target
          when Regexp
            target.source
          else
            target.to_s
          end

    Shellwords.shellescape(str)
  end

  def method_missing(meth, *args)
    action, target, subaction = breakdown(meth)

    family  = os[:family]
    version = "V#{os[:release].to_i}"

    common_class = self.class.const_get('Specinfra').const_get('Command')
    base_class   = common_class.const_get('Base')
    os_class     = family.nil? ? base_class : common_class.const_get(family.capitalize)

    begin
      version_class = os_class.const_get(version)
    rescue
      version_class = family.nil? ? os_class : os_class.const_get('Base')
    end

    begin
      command_class = version_class.const_get(target.capitalize)
    rescue
      command_class = base_class.const_get(target.capitalize)
    end

    method =  action
    method += "_#{subaction}" if subaction
    command_class.new.send(method, *args)
  end

  private
  def breakdown(meth)
    types = resource_types.map {|t| t.downcase }.join('|')
    md = meth.to_s.match(/^([^_]+)_(#{types})_(.+)$/)
    return md[1], md[2], md[3]
  end

  def resource_types
    if @types.nil?
      @types = []
      Specinfra::Command::Base.subclasses.each do |s|
        @types << s.to_s.split(':')[-1]
      end
      @types.uniq!
    end
    @types
  end
end

require 'specinfra/command/base/file'
require 'specinfra/command/base/package'
