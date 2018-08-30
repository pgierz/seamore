require_relative "../lib/cmorizer.rb"

require "minitest/autorun"


class CMORizerTests < Minitest::Test
  def setup
  end
  
  
  def teardown
  end
  
  
  def test_project_can_eval_experiment_id
    src_txt = <<~'EOFHEREDOC'
      experiment_id "highres-future" do
        indir ""
        outdir ""
      end
    EOFHEREDOC
  
    project = CMORizer::Project.new src_txt
    assert_kind_of CMORizer::Project, project
  end
  
  
  def test_cmorizations_can_have_multiple_cmip_tables
    src_txt = <<~'EOFHEREDOC'
      cmorize tos_day => [tos_Oday, tos_Omon, tos_Odec]
      cmorize prsn_day => [prsn_3hr, prsn_day, prsn_ImonAnt, prsn_ImonGre, prsn_Amon, prsn_Omon]
    EOFHEREDOC
  
    project = CMORizer::Project.new src_txt
    assert_kind_of CMORizer::Project, project
  end
  
  
  def test_cmorization_can_have_empty_block
    src_txt = <<~'EOFHEREDOC'
      cmorize omldamax_day => [omldamax_Oday] do
      end
    EOFHEREDOC
  
    project = CMORizer::Project.new src_txt
    assert_kind_of CMORizer::Project, project
  end
  
  
  def test_cmorization_can_have_KtodegC_unit_step_in_block
    src_txt = <<~'EOFHEREDOC'
      cmorize tso_3hrPt => [tos_3hr] do
        unit 'K' => 'degC'
      end
    EOFHEREDOC
  
    project = CMORizer::Project.new src_txt
    assert_kind_of CMORizer::Project, project
  end
  
    
  def test_year_ranges_split_evenly
    ranges = CMORizer::Project.year_ranges(first: 2000, last: 2029, step: 10)
    assert_equal [[2000,2009], [2010,2019], [2020,2029]], ranges
  end


  def test_year_ranges_last_range_may_be_shorter
    ranges = CMORizer::Project.year_ranges(first: 2000, last: 2024, step: 10)
    assert_equal [[2000,2009], [2010,2019], [2020,2024]], ranges
  end


  def test_year_ranges_solitary_range_might_be_shorter
    ranges = CMORizer::Project.year_ranges(first: 2000, last: 2004, step: 10)
    assert_equal [[2000,2004]], ranges
  end


  def test_year_ranges_solitary_range_might_have_same_first_and_last_when_shorter
    ranges = CMORizer::Project.year_ranges(first: 2000, last: 2000, step: 10)
    assert_equal [[2000,2000]], ranges
  end


  def test_year_ranges_solitary_range_might_have_same_first_and_last
    ranges = CMORizer::Project.year_ranges(first: 2000, last: 2000, step: 1)
    assert_equal [[2000,2000]], ranges
  end


  def test_year_ranges_might_have_same_first_and_last
    ranges = CMORizer::Project.year_ranges(first: 2000, last: 2002, step: 1)
    assert_equal [[2000,2000], [2001,2001], [2002,2002]], ranges
  end
end
