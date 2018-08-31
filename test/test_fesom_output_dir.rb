require_relative "../lib/fesom_output_dir.rb"

require "minitest/autorun"


class FesomOutputDirTests < Minitest::Test
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
end
