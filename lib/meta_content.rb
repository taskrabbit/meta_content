require "meta_content/version"

module MetaContent
  extend ActiveSupport::Concern

  autoload :Dsl,        'meta_content/dsl'
  autoload :Query,      'meta_content/query'
  autoload :Sanitizer,  'meta_content/sanitizer'

  included do
    class_attribute :meta_content_fields
    self.meta_content_fields = HashWithIndifferentAccess.new

    after_save :store_meta
  end

  module ClassMethods

    def meta(namespace = nil, &block)
      dsl = MetaContent::Dsl.new(self, namespace)
      dsl.instance_eval(&block)
    end

  end

  def reload(*args)
    @meta = nil
    super
  end

  def meta
    @meta ||= retrieve_meta
  end


  protected

  def retrieve_meta
    return @meta unless @meta.nil?
    return {} if new_record?

    meta_sanitizer.from_database(meta_query.select_all)
  end

  def store_meta
    updates, deletes = meta_changes
    updates = meta_sanitizer.to_database(updates)
    meta_query.update_all(updates)
    meta_query.delete_all(deletes)
  end

  def meta_query
    @meta_query ||= ::MetaContent::Query.new(self)
  end

  def meta_sanitizer
    @meta_sanitizer ||= ::MetaContent::Sanitizer.new(self)
  end

  def meta_changes
    return [{}, {}] if @meta.nil?

    was     = self.send(:attribute_was, :meta) || {}
    is      = self.meta

    updates = {}
    deletes = {}

    is.each do |namespace,namespaced_is|
      namespaced_was = was[namespace] || {}
      deletes[namespace] = namespaced_was.keys - namespaced_is.keys
      updates[namespace] ||= {}
      
      namespaced_is.each do |k,v|
        if v == nil
          deletes[namespace] << k
        elsif was[k] != v
          updates[namespace][k] = v
        end
      end
    end

    [updates, deletes]
  end

  def default_meta(namespace, field)
    options = field_meta(namespace, field)
    options.fetch(:default, nil)
  end
  
  def field_meta(namespace, field)
    options = self.class.meta_content_fields.fetch(namespace, {})
    options.fetch(field, {})
  end

  def read_meta(namespace, field)
    namespaced_meta = self.meta.fetch(namespace, {})
    namespaced_meta.fetch(field, default_meta(namespace, field))
  end

  def write_meta(namespace, field, value)
    self.meta[namespace] ||= {}
    unless self.meta[namespace][field] == value
      attribute_name = namespace.to_s == 'class' ? field : [namespace, field].join('_')
      attribute_will_change!(attribute_name)
      attribute_will_change!(:meta)

      type = field_meta(namespace, field)[:type]
      self.meta[namespace][field] = meta_sanitizer.sanitize(value, type || :string)
    end
  end


end
