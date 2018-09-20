require_relative "../lib/fesom_file.rb"

require "minitest/autorun"


class FesomFileTests < Minitest::Test
  def setup
    volo_cdl = <<~'EOFHEREDOC'
    netcdf volo_fesom_19510101 {
    dimensions:
      time = UNLIMITED ; // (12 currently)
      nodes = 1 ;
    variables:
      double time(time) ;
        time:long_name = "time" ;
        time:units = "seconds since 1951-01-01 0:0:0" ;
        time:calendar = "standard" ;
      float volo(time, nodes) ;
        volo:description = "total volume of liquid seawater" ;
        volo:units = "m3" ;
        volo:grid_type = "unstructured" ;
        volo:_FillValue = 1.e+30f ;

    // global attributes:
        :output_schedule = "unit: d first: 1 rate: 1" ;
    data:

     time = 86400, 172800, 259200, 345600, 432000, 518400, 604800, 691200, 
        777600, 864000, 950400, 1036800 ;

     volo =
      1.081448e+18,
      1.081448e+18,
      1.081448e+18,
      1.081448e+18,
      1.081448e+18,
      1.081448e+18,
      1.081448e+18,
      1.081448e+18,
      1.081448e+18,
      1.081448e+18,
      1.081448e+18,
      1.081448e+18 ;
    }
    EOFHEREDOC
    
    @volo = FesomYearlyOutputFile.new variable_id:"volo", year:"1951", month:"01", day:"01", path:nil, cdl_data:volo_cdl
  end
  
  
  def teardown
  end
  
  
  def test_volo_unit_is_m3
    assert_equal "m3", @volo.unit
  end
  
  
  def test_volo_frequency_is_day
    assert_equal "day", @volo.frequency
  end


  def test_timestep_delta_from_cdl_is_10800
    cdl = <<~'EOFHEREDOC'
    netcdf tso_fesom_27000101 {
    dimensions:
      time = UNLIMITED ; // (30 currently)
      nodes_2d = 830305 ;
    variables:
      double time(time) ;
        time:long_name = "time" ;
        time:units = "seconds since 2700-01-01 0:0:0" ;
        time:calendar = "standard" ;
      float tso(time, nodes_2d) ;
        tso:description = "sea surface temperature of liquid ocean, sampled synoptically" ;
        tso:units = "K" ;
        tso:grid_type = "unstructured" ;
        tso:_FillValue = 1.e+30f ;

    // global attributes:
        :output_schedule = "unit: s first: 24 rate: 24" ;
    data:

     time = 10800, 21600, 32400, 43200, 54000, 64800, 75600, 86400, 97200, 
        108000, 118800, 129600, 140400, 151200, 162000, 172800, 183600, 194400, 
        205200, 216000, 226800, 237600, 248400, 259200, 270000, 280800, 291600, 
        302400, 313200, 324000 ;
    }
    EOFHEREDOC
  
    assert_equal 10800, FesomYearlyOutputFile.timestep_delta_from_cdl(cdl)
  end
end
