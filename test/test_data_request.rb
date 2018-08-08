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
    assert_equal ["chlos", "omldamax", "phycos", "sos", "sossq", "tos", "tossq"].sort, @t.variable_ids.sort
  end
  
  
  def test_can_read_version
    assert_equal "01.00.27", @t.version 
  end


  def test_can_read_table_id
    assert_equal "Oday", @t.table_id 
  end

end
