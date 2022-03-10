require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord
    # dynamic initialize with #send
    def initialize(options={})
        options.each do |property, value|
            self.send("#{property}=", value)
        end
    end

    # dynamic #table_names with #pluralize
    def self.table_name
        self.to_s.downcase.pluralize
    end
    
    # dynamic #column_names with PRAGMA and #results_as_hash
    def self.column_names
        DB[:conn].results_as_hash = true
        sql = "PRAGMA table_info('#{table_name}')"
        table_info = DB[:conn].execute(sql)
        column_names = []
        table_info.each do |column|
            column_names << column["name"]
        end
        column_names.compact
    end
    #=> ["id", "name", "album"]
    
    # programmatically omit id-columns for INSERTs
    def col_names_for_insert
        self.class.column_names.delete_if {|col| col == "id"}.join(", ")
    end
    #=> "name, album"
    
    def table_name_for_insert
        self.class.table_name
    end

    # insert dynamic values
    def values_for_insert
        values = []
        self.class.column_names.each do |col_name|
            values << "'#{send(col_name)}'" unless send(col_name).nil?
        end
        values.join(", ")
    end

    def save
        statement = DB[:conn].execute("INSERT INTO #{self.table_name_for_insert} (#{self.col_names_for_insert}) VALUES (#{self.values_for_insert})")
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{self.table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        DB[:conn].execute("SELECT * FROM #{self.table_name} WHERE name = ?", [name])
    end

    def self.find_by(attr)
        v = attr.values.first
        reformat_v = ((v.class == Fixnum) ? v : "'#{v}'")
        sql = "SELECT * FROM #{self.table_name} WHERE #{attr.keys.first} = #{reformat_v} LIMIT 1"
        DB[:conn].execute(sql)
    end
end