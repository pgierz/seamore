
class FesomOutputDir
  def initialize(d)
    eliglible_files = Dir[File.join(d,"*")].grep(/\/(?<variable_id>\w+)_fesom_\d{8}\.nc\Z/)
    
    @variable_files = []
    eliglible_files.each do |f|
      /(?<variable_id>\w+)_fesom_(?<year>\d{4})(?<month>\d{2})(?<day>\d{2})\.nc\Z/ =~ File.basename(f)
      @variable_files << FesomOutputFile.new(variable_id: variable_id, year: year, month: month, day: day, path: f)
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


class FesomOutputFile
  attr_reader :variable_id, :approx_interval, :frequency, :unit

  def initialize(variable_id:, year:, month:, day:, path:, cdl_data: nil)
    raise "can not have both set: a path and CDL data" if (path && cdl_data)
    @variable_id = variable_id
    if path
      begin
        @frequency = FesomOutputFile.frequency_from_cdl %x(ncdump -h #{path})
        @unit = FesomOutputFile.unit_from_cdl variable_id, %x(ncdump -h #{path})
      rescue RuntimeError => e
        raise "file #{path}: #{e.message}"
      end
    elsif cdl_data
      @frequency = FesomOutputFile.frequency_from_cdl cdl_data
      @unit = FesomOutputFile.unit_from_cdl variable_id, cdl_data
    end
    @approx_interval = Frequency.for_name(@frequency).approx_interval
  end
  
  
  def <=>(other)
    "#{@variable_id} #{@approx_interval} #{@frequency}" <=> "#{other.variable_id} #{other.approx_interval} #{other.frequency}"
  end
  
  
  def to_s
    "#{@variable_id} '#{unit}' [#{@frequency}]"
  end
  

  # variable unit from native fesom file CDL (i.e. ncdump)
  def self.unit_from_cdl(variable_id, cdl)
     match = /#{variable_id}:units = "(?<unit>.+)"/.match cdl # there seems to be an error with rubys "".=~ as we do not get access to the unis variable then interpolating variable_id, using //.match seems to solve this
     match[:unit]
  end


  # fetch frequency from native fesom file CDL (i.e. ncdump)
  # https://github.com/WCRP-CMIP/CMIP6_CVs/blob/master/CMIP6_frequency.json
  def self.frequency_from_cdl(cdl)
    match = /^.*?output_schedule.*/.match cdl
    sout = match.to_s

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
      puts "NOTE: assuming frequency rate of #{unit}#{rate} equals 3hr for netcdf CDL"
      # solution: read the time axis and see what delta t we really have

      # for tso the frequency should be 3hrPt now (i.e. instantaneous)      
      "3hrPt" # this is hackish but does apply for the PRIMAVERA runs (tso is the only 3-hourly variable)      
    else
      raise "unknown unit+rate <#{unit}#{rate}> for netcdf CDL"
    end    
  end

end