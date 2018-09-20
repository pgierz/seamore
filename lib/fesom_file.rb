require_relative 'frequency.rb'


class FesomYearlyOutputFile # i.e. a netcdf file with one year of fesom output
  attr_reader :variable_id, :year, :path, :approx_interval, :frequency, :unit, :time_method

  def initialize(variable_id:, year:, month:, day:, path:)
    @variable_id = variable_id
    @year = year.to_i
    @path = path
    begin
      cdl = %x(ncdump -h #{path})
      @frequency = frequency_from_netcdf path
      @unit = FesomYearlyOutputFile.unit_from_cdl variable_id, cdl
    rescue RuntimeError => e
      raise "file #{path}: #{e.message}"
    end
    @approx_interval = Frequency.for_name(@frequency).approx_interval
    
    @time_method = Frequency.for_name(@frequency).time_method
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
  def frequency_from_netcdf(path)
    cdl = %x(ncdump -h #{path})
    
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
      raise "can not determine frequency for netcdf #{path}" unless @variable_id == "tso"
      # for tso the frequency should be '3hrPt' (i.e. instantaneous) tso is the only 3-hourly ocean variable we have in CMIP
      # this frequency is based on fesom time steps, i.e. might be used to express 3-hourly
      # read the time axis and see what delta t we really have
      dt = FesomYearlyOutputFile.timestep_delta_from_cdl(%x(ncdump -v time #{path}))
      raise "tso frequency is not 10800 sec (3h) but #{dt} sec for netcdf #{path}" if( dt != 3*3600)
      "3hrPt"
    else
      raise "unknown unit+rate <#{unit}#{rate}> for netcdf #{path}"
    end    
  end


  # fetch time axis from native fesom file CDL (i.e. ncdump -v time)
  def self.timestep_delta_from_cdl(cdl)
    txt = cdl.split("// global attributes:").last
    match = /^.*?time.*/.match txt
    txt = match.to_s
    /(?<t0>\d+), (?<t1>\d+)/ =~ txt
    t1.to_f - t0.to_f
  end

end