require 'deckhand/model_storage/base'

class Deckhand::ModelStorage::Mongoid < Deckhand::ModelStorage::Base

  def field_type(model, name)
    if f = field(model, name)
      f.options[:type].to_s.underscore
    elsif Deckhand.config.for_model(model).table_field?(name)
      :table
    elsif relation?(model, name)
      :relation
    end
  end

  def field(model, name)
    model.constantize.fields.detect {|f| f.first == name.to_s }.last rescue nil
  end

  def relation?(model, name)
    model.constantize.relations.include?(name.to_s) ||
      Deckhand.config.for_model(model).type_override(name) == :relation
  end

  protected

  def query(scope, term, fields)
    scope.or(*search_criteria(term, fields)).limit(5)
  end

  private

  def search_criteria(term, fields)
    fields.map do |field, options|
      case options[:match]
      when :exact
        if field == :id
          {field => term}
        else
          {field => /^#{Regexp.escape term}$/i}
        end
      when :contains, nil
        {field => /#{Regexp.escape term}/i}
      end
    end
  end

end