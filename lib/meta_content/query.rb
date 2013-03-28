module MetaContent
  class Query
    
    def initialize(record)
      @record = record
    end

    def h(val)
      ActiveRecord::Base.sanitize(val)
    end
    
    def select_all
      sql = "SELECT #{qtn}.namespace, #{qtn}.lookup, #{qtn}.value, #{qtn}.int_value FROM #{qtn} WHERE #{qtn}.object_id = #{h(pk)}"
      results = {}
      execute(sql).each do |row|
        results[row[0]] ||= {}
        results[row[0]][row[1]] = row[2]
      end
      results
    end

    def update_all(changes)
      sql = "INSERT INTO #{qtn}(namespace,object_id,lookup,value,int_value) VALUES "
      values = changes.map do |namespace, namespaced_changes|
        namespaced_changes.map do |k, change|
          "(#{h(namespace)},#{h(pk)},#{h(k)},#{h(change.value)},#{h(change.int_value)})"
        end
      end.flatten
      sql << values.join(',')
      sql << " ON DUPLICATE KEY UPDATE value = VALUES(value), int_value = VALUES(int_value)"
      execute(sql) if values.any?
    end

    def delete_all(deletes)
      deletes.each do |namespace, keys|
        next unless keys.any?
        key_clause = keys.map{|k| h(k) }.join(',')
        sql = "DELETE FROM #{qtn} WHERE #{qtn}.object_id = #{h(pk)} AND #{qtn}.namespace = #{h(namespace)} AND #{qtn}.lookup IN (#{key_clause})"
        execute(sql)
      end
    end

    protected

    def qtn
      "`#{klass.table_name}_meta`"
    end

    def pk
      @record.id
    end

    def klass
      @record.class
    end

    def execute(sql)
      klass.connection.execute(sql)
    end

  end
end