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
  
  #PRIMAVERA_DELIVERED_VARS = %w(evs fsitherm hfds mlotst omldamax opottemptend pbo prlq prsn rsdo siarean siareas sic sidmassevapsubl sidmasssi sidmassth sidmasstranx sidmasstrany siextentn siextents sifllatstop sisnconc sisnmass sisnthick sispeed sistrxdtop sistrxubot sistrydtop sistryubot sithick sitimefrac siu siv sivol sivoln sivols so soga sos tauuo tauvo thetao thetaoga tos tso u2o uo uso uto v2o vo volo vso vto w2o wfo wo wso wto zos zossq)
  
  def report_on_data_request(data_request_tables_dir)
    request = DataRequest.new_from_tables_dir(data_request_tables_dir)
    request_vars = request.variable_ids
    
    # see if we have each existing fesom variable in the data request
    @variables.each do |fevar|
#    PRIMAVERA_DELIVERED_VARS.each do |fevar|
      cmorvar = FesomVariable.variable_id_for_data_request("550", "01.00.27", fevar)
      if(request_vars.include? cmorvar)
        if(cmorvar == fevar)
          puts "FESOM #{fevar}"
        else
          puts "FESOM #{fevar} => CMOR #{cmorvar}"
       end
      else
        puts "FESOM #{fevar} !! can not assign to any CMOR variable"
      end
    end
  end
    
end


class FesomVariable
    def self.variable_id_for_data_request(fesom_svn_revision, request_version, fesom_variable)
      mappings = {}
      mappings["550"] = {}
      mappings["550"]["01.00.27"] = {}
      mappings["550"]["01.00.27"]["tso"] = "tos"
      
      v = mappings[fesom_svn_revision][request_version][fesom_variable]
      v ||= fesom_variable
      #puts "FESOM revision #{fesom_svn_revision}::#{fesom_variable} => data request #{request_version}::#{v}"
      v
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