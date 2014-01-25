require 'deckhand/configuration/model_dsl'

class Deckhand::Configuration::ModelConfig
  attr_reader :model

  def initialize(options = {}, &block)
    default_options = {
      singular: [:label, :fields_to_show, :search_scope],
      defaults: {show: [], exclude: []}
    }
    @label_defaults = options.delete(:label_defaults)
    @model = options.delete(:model)
    @dsl = Deckhand::Configuration::ModelDSL.new(default_options.merge(options), &block)
  end

  # a model's label can either be a symbol name of a method on that model,
  # or a block that will be eval'ed in instance context.
  # it can be defined in the model's configuration block with the "label" keyword,
  # or fall back to the "model_label" keyword at the top level of configuration.
  # the top-level configuration only supports methods, not blocks.
  def label
    @dsl.label ||= @label_defaults.detect {|attr| @model.method_defined? attr } || @label_defaults.last
  end

  def has_action?(action)
    actions.map(&:first).include? action
  end

  def has_action_form?(action)
    has_action?(action) and actions.any? {|name, options| name == action && options.include?(:form) }
  end

  def action_form_class(action)
    model.const_get(action.to_s.camelize)
  end

  def fields_to_show(options = {})
    if options[:flat_only]
      @dsl.show.reject {|name, options| options[:table] }
    elsif options[:table_only]
      @dsl.show.select {|name, options| options[:table] }
    else
      @dsl.show
    end
  end

  def fields_to_edit
    @fields_to_edit ||= begin
      show_and_edit = @dsl.show.select {|name, options| options[:editable] }
      edit_only = @dsl.edit || []
      (show_and_edit + edit_only).map do |name, options|
        options[:type] = :file if Deckhand.config.attachment?(@model, name)
        [name, options]
      end
    end
  end

  def actions
    @dsl.action || []
  end

  def fields_to_include(options = {})
    action_conditions = actions.map {|a| a.last[:if] }.compact.map {|f| [f, {}] }
    fields_to_show(options) + action_conditions # TODO de-duplicate
  end

  def searchable?
    !!search_options[:fields]
  end

  def search_options
    {scope: @dsl.search_scope, fields: @dsl.search_on}
  end

  def table_field?(name)
    fields_to_show(table_only: true).map(&:first).include? name
  end

end