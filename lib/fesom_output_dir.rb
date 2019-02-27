require_relative "fesom_file.rb"

class FesomOutputDir
  attr_reader :variable_files

  def initialize(d, first_year=nil, last_year=nil)
    eliglible_files = Dir[File.join(d,"*")].grep(/\/(?<variable_id>\w+)_fesom_\d{8}\.nc\Z/)

    @variable_files = []
    eliglible_files.each do |f|
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
  
  
  #PRIMAVERA_DELIVERED_VARS = %w(evs fsitherm hfds mlotst omldamax opottemptend pbo prlq prsn rsdo siarean siareas sic sidmassevapsubl sidmasssi sidmassth sidmasstranx sidmasstrany siextentn siextents sifllatstop sisnconc sisnmass sisnthick sispeed sistrxdtop sistrxubot sistrydtop sistryubot sithick sitimefrac siu siv sivol sivoln sivols so soga sos tauuo tauvo thetao thetaoga tos tso u2o uo uso uto v2o vo volo vso vto w2o wfo wo wso wto zos zossq)
  
  def report_on_data_request(data_request_tables_dir)
    request = DataRequest.new_from_tables_dir(data_request_tables_dir)
    request_vars = request.variable_ids
    
    # see if we have each existing fesom variable in the data request
    @variable_files.each do |fevar|
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
