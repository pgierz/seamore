require_relative "../lib/find_variables.rb"

require "minitest/autorun"


class FindVariables < Minitest::Test
  def setup
    @datarequest_path = "#{__dir__}/fixtures/CMIP6_Oday.json"
  end
  
  
  def teardown
  end

  
  def test_can_read_variables_from_datarequest
    assert variables_from_datarequest(@datarequest_path).sort == ["chlos", "omldamax", "phycos", "sos", "sossq", "tos", "tossq"].sort
  end
end
