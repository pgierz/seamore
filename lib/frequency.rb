class TimeMethods
  ALL = [MEAN=:MEAN, POINT=:INSTANTANEOUS, CLIMATOLOGY=:CLIMATOLOGY, NONE=:NONE]
end


# https://github.com/WCRP-CMIP/CMIP6_CVs/blob/master/CMIP6_frequency.json
class Frequency
  include Comparable
  attr_reader :name, :approx_interval, :time_method
  

  def self.for_name(n)
    freq = ALL.find {|f| f.name == n}
    raise "can not determine Frequency object for #{n}" unless freq
    freq
  end


  def initialize(name, approx_interval, time_method=TimeMethods::MEAN)
    @name = name
    @approx_interval = approx_interval
    @time_method = time_method
  end


  ALL = [
    F_1hr = Frequency.new("1hr", 1.0/24),    
    F_3hr = Frequency.new("3hr", 3.0/24),
    F_6hr = Frequency.new("6hr", 6.0/24),
    F_day = Frequency.new("day", 1.0), # there is no dayPt frequency
    F_mon = Frequency.new("mon", 30.0),
    F_yr = Frequency.new("yr", 365.0),
    F_dec = Frequency.new("dec", 3650.0),
    F_hrPt = Frequency.new("1hrPt", 1.0/24, TimeMethods::POINT),
    F_3hrPt = Frequency.new("3hrPt", 3.0/24, TimeMethods::POINT),
    F_6hrPt = Frequency.new("6hrPt", 6.0/24, TimeMethods::POINT),
    F_monPt = Frequency.new("monPt", 30.0, TimeMethods::POINT),
    F_yrPt = Frequency.new("yrPt", 365.0, TimeMethods::POINT),
    F_1hrCM = Frequency.new("1hrCM", 1.0/24, TimeMethods::CLIMATOLOGY),
    F_fx = Frequency.new("fx", 0, TimeMethods::NONE),
    F_monC = Frequency.new("monC", 30.0, TimeMethods::CLIMATOLOGY),
    F_subhrPt = Frequency.new("subhrPt", 0.017361, TimeMethods::POINT), # there is no subhr time:mean
    ]
    
  
  def <=>(other)
    @approx_interval <=> other.approx_interval
  end


  def ==(other)
    @name == other.name
  end
end
