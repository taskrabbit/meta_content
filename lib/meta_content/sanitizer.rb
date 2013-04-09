module MetaContent
  class Sanitizer

    def initialize(record)
      @record = record
    end

    def from_database(raw_results)
      sanitized_results = HashWithIndifferentAccess.new
      raw_results.each do |namespace, results|
        results.each do |k,v|
          options = schema[namespace] || {}
          options = options[k]
          next unless options
          sanitized_results[namespace] ||= {}
          sanitized_results[namespace][k] = sanitize_from_database(v, options[:type] || :string)
        end
      end
      sanitized_results
    end
    
    def to_database(changes)
      sanitized_results = HashWithIndifferentAccess.new
      changes.each do |namespace, namespaced_changes|
        namespaced_changes.map do |k,v|
          options = schema[namespace] || {}
          options = options[k]
          next unless options
          
          sanitized_results[namespace] ||= {}
          sanitized_results[namespace][k] = sanitize_to_database(v, options[:type] || :string)
        end
      end
      sanitized_results
    end
    
    def sanitize(value, type)
      return nil if value.nil?
      # simulate writing and reading from database
      change = sanitize_to_database(value, type)
      sanitize_from_database(change.value, type)
    end

    protected
    
    def sanitize_from_database(value, type)
      return nil if value.nil?
      
      case type
      when :integer, :fixnum, :int
        value.to_i
      when :float, :number
        value.to_f
      when :date
        Date.parse(value)
      when :datetime, :time
        Time.parse(value)
      when :boolean, :bool
        value == "true"
      when :symbol, :sym
        value.to_sym
      else
        value.to_s
      end
    end

    def sanitize_to_database(value, type)
      int_value = nil
      float_value = nil
      case type
      when :integer, :fixnum, :int
        begin
          if value.respond_to? :strftime
            int_value = value.strftime("%s").to_i
          else
            int_value = value.to_i
          end
        rescue StandardError => e
          int_value = 0
        end
        str_value = int_value.to_s
      when :float, :number
        begin
          float_value = value.to_f
        rescue StandardError => e
          float_value = 0.0
        end
        str_value = float_value.to_s
      when :datetime, :time
        value = parse_time(value)
        
        if value.respond_to? :strftime
          str_value = value.strftime("%Y-%m-%dT%H:%M:%S%:z")
          int_value = value.strftime("%s").to_i # epoch time
        else
          str_value = nil
        end
      when :date
        value = parse_time(value)
        
        if value.respond_to? :strftime
          str_value = value.strftime("%Y-%m-%d")
          int_value = value.strftime("%s").to_i # epoch time
        else
          str_value = nil
        end
      when :boolean, :bool
        if value != true && value != false
          value = ["1", "true", "yes"].include?(value.to_s)
        end
        
        if value == true
          str_value = "true"
          int_value = 1
        else
          str_value = "false"
          int_value = 0
        end
      when :symbol, :sym
        str_value = value.to_s
      else
        str_value = value.to_s
      end
      
      int_value   ||= float_value.to_i if float_value
      int_value   ||= str_value.length if str_value
      float_value ||= int_value.to_f
      
      Change.new(str_value, int_value, float_value)
    end

    def parse_time(value)
      result = nil
      if value.is_a? String
        result = Time.parse(value) rescue nil  # don't care if it blows up, nbd
        value = value.to_i if value.to_i > 0 && result.nil?
      end
      result ||= Time.at(value) if value.is_a? Integer
      result || value
    end

    def klass
      @record.class
    end

    def schema
      klass.meta_content_fields
    end


    class Change < Struct.new(:value, :int_value, :float_value)
      
    end
  end
end
