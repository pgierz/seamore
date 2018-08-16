require_relative "../lib/data_request.rb"

require "minitest/autorun"


class DataRequestTests < Minitest::Test
  def setup
    @datarequest_paths = []
    @datarequest_paths << "#{__dir__}/fixtures/CMIP6_3hr.json"
    @datarequest_paths << "#{__dir__}/fixtures/CMIP6_SIday.json"
    @datarequest_paths << "#{__dir__}/fixtures/CMIP6_Oday.json"
  end
  
  
  def teardown
  end
  
  
  def test_approx_interval_for_table_Omon_is_30
    assert_equal 30.0, DataRequest.approx_interval_for_table("Omon")
  end


  def test_approx_interval_for_frequency_mon_is_30
    assert_equal 30.0, DataRequest.approx_interval_for_frequency("mon")
  end


  def test_difmxybo_and_difmxybo2d_exist
    dr = DataRequest.new(["#{__dir__}/fixtures/difmxybo2d/CMIP6_Oclim.json"])
    assert_equal %w(difmxybo difmxybo2d), dr.variable_ids
  end


  def test_returns_version
    assert_equal "01.00.27", DataRequest.new(@datarequest_paths).version 
  end
  
  
  def test_returns_merged_table_ids
    assert_equal %w(3hr Oday SIday), DataRequest.new(@datarequest_paths).table_ids
  end


  def test_returns_merged_variable_ids
    assert_equal %w(chlos clt hfls hfss huss mrro mrsos omldamax phycos pr prc prsn ps rlds rldscs rlus rsds rsdscs rsdsdiff rsus rsuscs siconc siconca sisnthick sispeed sitemptop sithick sitimefrac siu siv sos sossq tas tos tos tossq tslsi uas vas), DataRequest.new(@datarequest_paths).variable_ids
  end
 
 
  def test_can_be_created_with_multiple_table_paths
    DataRequest.new(@datarequest_paths)
  end
  
end


class DataRequestTableTests < Minitest::Test
  def setup
    @datarequest_path = "#{__dir__}/fixtures/CMIP6_Oday.json"
    @t = DataRequestTable.new(@datarequest_path)
  end
  
  
  def teardown
  end
  
  
  def test_can_create_variable_objects
    assert_equal "chlos", @t.variable_entries.first.variable_id
  end


  def test_can_read_frequencies
    assert_equal ["day"], @t.frequencies
  end


  def test_can_read_multiple_frequencies
    assert_equal %w(3hr 3hrPt), DataRequestTable.new("#{__dir__}/fixtures/CMIP6_3hr.json").frequencies
  end

  
  def test_can_read_variable_ids
    assert_equal ["chlos", "omldamax", "phycos", "sos", "sossq", "tos", "tossq"], @t.variable_ids
  end
  
  
  def test_can_read_version
    assert_equal "01.00.27", @t.version 
  end


  def test_can_read_table_id
    assert_equal "Oday", @t.table_id 
  end

end
