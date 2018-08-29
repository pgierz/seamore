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
  
end
