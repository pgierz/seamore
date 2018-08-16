require_relative "../lib/fesom_possible_var.rb"

require "minitest/autorun"


class FesomPossibleVarTests < Minitest::Test
  def setup
    code = <<~'EOFHEREDOC'
    call volo_const%init(1, 'volo', 'total volume of liquid seawater', 'm3') ! this could be optimized, as the value does not change. we use the standard output writer procedure for simplicity
    call soga_mean%init(1, 'soga', 'global average sea water salinity', 'psu')
    call tso_mean%init(n2, 'tso', 'sea surface temperature of liquid ocean, sampled synoptically', 'K')
    EOFHEREDOC

    @vars = FesomPossibleVar.create_from_fortran_code(code, sort: false)
  end
  
  
  def teardown
  end
  

  def test_parses_volo_from_fortran_code
    refute_nil @vars
    v = @vars[0]
    assert_equal "volo", v.variable_id
    assert_equal "total volume of liquid seawater",  v.description
    assert_equal "m3",  v.unit
    assert_equal TimeMethods::MEAN,  v.time_method
  end


  def test_parses_soga_from_fortran_code
    refute_nil @vars
    v = @vars[1]
    assert_equal "soga",  v.variable_id
    assert_equal "global average sea water salinity",  v.description
    assert_equal "psu",  v.unit
    assert_equal TimeMethods::MEAN,  v.time_method
  end


  def test_parses_tso_from_fortran_code
    refute_nil @vars
    v = @vars[2]
    assert_equal "tso",  v.variable_id
    assert_equal "sea surface temperature of liquid ocean, sampled synoptically",  v.description
    assert_equal "K",  v.unit
    assert_equal TimeMethods::POINT,  v.time_method
  end
  
  
  def test_85_possible_vars_exist
    vars = FesomPossibleVar.create_from_fortran_code(FESOM_VARIABLE_INITIALIZATION_CODE, sort: false)
    assert_equal 85, vars.size
  end
end
