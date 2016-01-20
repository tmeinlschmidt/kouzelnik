# phantom module for headless js browser form fill
require 'yaml'
require 'tempfile'

module Phantom

  # define paths with files
  CONFIG_PHANTOM = Rails.root.to_s+'/app/phantom'
  CONFIG_SITES_PATH = CONFIG_PHANTOM+'/sites/'
  CONFIG_TEMPLATES_PATH = CONFIG_PHANTOM+'/templates/'
  
  # phantom options
  CONFIG_PHANTOM_PATH = `which phantomjs`.chop                   # or define directly - FULL path
  CONFIG_PHANTOM_OPTS = '--ignore-ssl-errors=yes'

  class FieldError < Exception; end
  class PhantomError < Exception; end

  # {{{ class Field
  class Field

    # validation definitions
    FIELD_VALIDATIONS = {
      :string => /\w\+/i,
      :number => /\d\+/,
      :phone_number => /^[0-9 ()+-]*$/,
      :email => /^([0-9a-z._-]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
    }

    attr_reader :name
    attr_reader :_field
    attr_reader :field_value
    attr_reader :field_validation
    attr_reader :valid

    def initialize(field)
      @name = field.keys[0]
      @_field = field[@name]
    end

    def method_missing(name)
      name = name.to_s
      return @_field[name] if @_field[name]
    end

    def set_value(value)
      @field_value = value
      #@field_validation = validate(@field_value)     # FIXME
      @valid = true
    end

    private

    # perform validations
    def validate(value)
      return true if !validation || validation.blank?
      # against regexp
      if (validation =~ /^\/.*\/$/) == 0
        return value =~ validation.to_regexp
      end
      unless FIELD_VALIDATIONS.keys.include?(validation.to_sym)
        raise FieldError, "Unknown field validation '#{validation}'."
      end
      return (value =~ FIELD_VALIDATIONS[validation.to_sym]) != nil
    end


  end
  # }}}

  # {{{ helper
  # contains helper methods to draw
  module FieldHelper

    def render_phantom_field(field, current_value = nil)
      return unless field
      case field.type
        when 'text' then _render_phantom_text(field, current_value)
        when 'select' then _render_phantom_select(field, current_value)
        when 'checkbox' then _render_phantom_checkbox(field, current_value)
        when 'radio' then _render_phantom_radio(field, current_value)
      end
    end
    
    private

    def _render_phantom_text(field, current_value = nil) 
      current_value ||= field.default
      tag('input', {:value => current_value, :type => 'text', :name => field.name})
    end

    def _render_phantom_checkbox(field, current_value = nil)
      checked = field.default
      checked = true if current_value
      tag('input', {:type => 'checkbox', :value => field.value, :checked => checked, :name => field.name})
    end

    def _render_phantom_radio(field, current_value = nil)
      content = ''
      field.values.each do |k,v|
        checked = ((current_value && k == current_value) || (!current_value && field.default == k))
        content << tag('input',  {:type => 'radio', :name => field.name, :value => k, :checked => checked})
        content << "&nbsp;#{v}&nbsp;"
      end
      content_tag('span',content, {}, false)
    end

    def _render_phantom_select(field, current_value = nil)
      options = ''
      field.values.each do |k,v|
        sel = (k == current_value)
        k = '' if k=='_default_'
        options << content_tag('option', v, {:value => k, :selected => sel})
      end
      content_tag('select', options, {:name => field.name}, false)
    end

  end
  # }}}

  # load and process sites
  class Site
    
    attr_reader :config
    attr_reader :site_name
    attr_reader :site_path
    attr_reader :fields

    def initialize(site_name)
      @site_name = site_name
      load_site
      @fields = get_fields
    end

    # load site config
    def load_site
      begin
        _config = YAML::load(IO.read(site_file_path))
      rescue Exception => e
        raise PhantomError, "Unable to open and load site '#{@site_name}'"
      end
      @config = _config[@site_name]
    end
    
    # return name of template file
    def get_template_file
      @config['template']
    end
    
    # match fields agains given params and set value into object (and do validations)
    def match_fields(params)
      @fields.each do |field|
        field.set_value(params[field.name])
      end
    end

    def phantom!
      file = render
      return false unless file
      # call phantom here
      command = "#{CONFIG_PHANTOM_PATH} #{CONFIG_PHANTOM_OPTS} #{file}"
      begin
        result = `#{command}`
      rescue Exception => e
        File.delete(file)
        raise PhantomError, e.message
      end
      File.delete(file)
      result
    end

    private
    
    # takes template and render all the fields into it
    # returns name of temporary file or false
    def render
      begin
        template = IO.read(get_template_path)
      rescue Exception => e
        raise PhantomError, e.message
      end
      # with all the fields
      @fields.each do |field|
        template = template.gsub(Regexp.new("\\[\\[#{field.field}\\]\\]"), field.field_value.to_s)
      end
      template = template.gsub(Regexp.new("\\[\\[ENTRY_POINT\\]\\]"), @config['entry_point'])
      # write
      path = ''
      begin
        Tempfile.open(['phantom','.coffee'], "#{Rails.root}/tmp") do |f|
          f.print template
          path = f.path
        end
      rescue
        return false
      end
      path
    end

    # return array of fields
    def get_fields
      _fields = @config['form']['fields']
      _fields.map{|k,v| Field.new(k=>v)}
    end

    # get template path
    def get_template_path
      CONFIG_TEMPLATES_PATH+@config['template']
    end
    
    # return site path
    def site_file_path
      @site_path = CONFIG_SITES_PATH+@site_name+'.yml'
    end

  end

  # load and process templates
  class Template
  end

end
