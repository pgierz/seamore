require_relative "data_request.rb"


class FesomOutputDir
  def initialize(d)
    eliglible_files = Dir[File.join(d,"*")].grep(/\/(?<variable_id>\w+)_fesom_\d{8}\.nc\Z/)
    eliglible_files.sort!
    
    @variables = []
    eliglible_files.each do |f|
      /(?<variable_id>\w+)_fesom_(?<year>\d{4})(?<month>\d{2})(?<day>\d{2})\.nc\Z/ =~ File.basename(f)
      @variables << variable_id
    end    
  end
  
end
