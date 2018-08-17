require_relative "../lib/frequency.rb"

require "minitest/autorun"


class FrequencyTests < Minitest::Test
  def setup
  end
  
  
  def teardown
  end
  
  
  def test_frequency_for_mon_has_name_mon
    assert_equal "mon", Frequency.for_name("mon").name
  end


  def test_frequency_for_monPt_has_name_mon
    assert_equal "mon", Frequency.for_name("monPt").name
  end


  def test_interval_for_mon_is_30
    assert_equal 30.0, Frequency.for_name("mon").approx_interval
  end


  def test_mon_ist_sorted_before_dec
    assert_equal 1, (Frequency::F_dec <=> Frequency::F_mon)
  end


  def test_3hr_and_3hrPt_have_same_sort_order
    assert_equal 0, (Frequency::F_3hr <=> Frequency::F_3hrPt)
  end


  def test_3hr_doe_not_equal_3hrPt
     refute_equal Frequency::F_3hr, Frequency::F_3hrPt
  end
end
