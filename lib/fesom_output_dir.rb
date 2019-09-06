require_relative "fesom_file.rb"

class FesomOutputDir
  attr_reader :variable_files

  def initialize(d, first_year=nil, last_year=nil)
    eligible_files = Dir[File.join(d,"*")].grep(/\/(?<variable_id>\w+)_fesom_\d{8}\.nc\Z/)
    
    @variable_files = []
    eligible_files.each do |f|
      /(?<variable_id>\w+)_fesom_(?<year>\d{4})(?<month>\d{2})(?<day>\d{2})\.nc\Z/ =~ File.basename(f)
      if(first_year && last_year) # might be nil, i.e. read every year
        if(first_year <= year.to_i && year.to_i <= last_year)
          @variable_files << FesomYearlyOutputFile.new(variable_id: variable_id, year: year, month: month, day: day, path: f)
        end
      else
        @variable_files << FesomYearlyOutputFile.new(variable_id: variable_id, year: year, month: month, day: day, path: f)
      end
    end    
    
    @variable_files.sort!
  end
  
  
  def to_s
    @variable_files.inject('') {|sum,f| sum + "#{f}\n"}
  end
  
end
