require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'interactive_record.rb'

class Student < InteractiveRecord
    #dynamic readers + writers: iterate over the return value of #column_names with #attr_accessor
    self.column_names.each { |col_name| attr_accessor col_name.to_sym}
end
