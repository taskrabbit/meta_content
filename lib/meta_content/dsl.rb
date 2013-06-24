module MetaContent
  class Dsl

    def initialize(klass, namespace)
      @klass = klass
      @namespace = namespace
    end

    %w(integer int float number date datetime time boolean bool symbol sym string).each do |type|
      class_eval <<-CODE
        def #{type}(*fields)
          options = fields.extract_options!
          options[:type] = :#{type}
          fields.each do |f|
            field(f, options)
          end
        end
      CODE
    end

    def field(*fields)
      options = fields.extract_options!
      options[:namespace] = @namespace
      fields.each do |field|
        create_accessors_for_meta_field(field, options)
      end
    end

    protected

    def create_accessors_for_meta_field(field, options = {})
      given_namespace = options[:namespace]
      implied_namespace = given_namespace || :class

      @klass.meta_content_fields[implied_namespace] ||= {}
      @klass.meta_content_fields[implied_namespace][field] = options.except(:namespace)

      method_name = [given_namespace, field].compact.join('_')
      @klass.class_eval <<-EV, __FILE__, __LINE__+1
        def #{method_name}
          read_meta(:#{implied_namespace}, :#{field})
        end

        def #{method_name}=(val)
          write_meta(:#{implied_namespace}, :#{field}, val)
        end

        def #{method_name}?
          ![nil, 0, false, ""].include?(#{method_name})
        end

        def #{method_name}_changed?
          changes = meta_changes
          !!(
            changes[0]["#{implied_namespace}"].try(:keys).try(:include?, "#{field}") ||
            changes[1]["#{implied_namespace}"].try(:include?, "#{field}")
          )
        end
      EV
    end

  end
end
