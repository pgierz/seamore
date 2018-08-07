require_relative "../lib/data_request.rb"

require "minitest/autorun"


class FindVariables < Minitest::Test
  def setup
    @datarequest_path = "#{__dir__}/fixtures/CMIP6_Oday.json"
  end
  
  
  def teardown
  end

  
  def test_can_read_variable_ids_from_datarequest
    assert variable_ids_from_datarequest(@datarequest_path).sort == ["chlos", "omldamax", "phycos", "sos", "sossq", "tos", "tossq"].sort
  end
end
