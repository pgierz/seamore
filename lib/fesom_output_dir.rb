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


class FesomOutputFile
  # fetch frequency from native fesom file
  # https://github.com/WCRP-CMIP/CMIP6_CVs/blob/master/CMIP6_frequency.json
  def self.frequency(f)
    sout = %x(ncdump -h #{f} | grep output_schedule)
    /unit: (?<unit>\w) / =~ sout
    /rate: (?<rate>\d+)/ =~ sout
  
    case "#{unit}#{rate}"
    when "y1"
      "yr"
    when "m1"
      "mon"
    when "d1"
      "day"
    when /s\d+/
      # this frequency is based on fesom time steps, i.e. might be used to express 3-hourly
      puts "NOTE: assuming frequency rate of #{unit}#{rate} equals 3hr for #{f}"
      # solution: read the time axis and see what delta t we really have

      # for tso the frequency should be 3hrPt now (i.e. instantaneous)      
      "3hrPt" # this is hackish but does apply for the PRIMAVERA runs (tso is the only 3-hourly variable)      
    else
      raise "unknown unit+rate <#{unit}#{rate}> for file <#{f}>"
    end    
  end

end