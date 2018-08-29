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
  
end
