require_relative "../lib/data_request.rb"

require "minitest/autorun"


class DataRequestTests < Minitest::Test
  def setup
    @datarequest_path = "#{__dir__}/fixtures/CMIP6_Oday.json"
    @dr = DataRequest.new(@datarequest_path)
  end
  
  
  def teardown
  end

  
  def test_can_read_variable_ids
    assert_equal ["chlos", "omldamax", "phycos", "sos", "sossq", "tos", "tossq"].sort, @dr.variable_ids.sort
  end

end
