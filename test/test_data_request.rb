require_relative "../lib/data_request.rb"

require "minitest/autorun"


class DataRequestTests < Minitest::Test
  def setup
    @datarequest_paths = []
    @datarequest_paths << "#{__dir__}/fixtures/CMIP6_3hr.json"
    @datarequest_paths << "#{__dir__}/fixtures/CMIP6_Oday.json"
    @datarequest_paths << "#{__dir__}/fixtures/CMIP6_SIday.json"
  end
  
  
  def teardown
  end
  
  
  def test_returns_version
    assert_equal "01.00.27", DataRequest.new(@datarequest_paths).version 
  end
  
  
  def test_returns_merged_table_ids
    assert_equal %w(3hr Oday SIday), DataRequest.new(@datarequest_paths).table_ids
  end


  def test_returns_merged_variable_ids
    assert_equal %w(clt hfls hfss huss mrro mrsos pr prc prsn ps rlds rldscs rlus rsds rsdscs rsdsdiff rsus rsuscs tas tos tslsi uas vas chlos omldamax phycos sos sossq tos tossq siconc siconca sisnthick sispeed sitemptop sithick sitimefrac siu siv), DataRequest.new(@datarequest_paths).variable_ids
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
