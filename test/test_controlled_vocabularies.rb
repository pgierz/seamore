require_relative "../lib/controlled_vocabularies.rb"

require "minitest/autorun"


class ControlledVocabulariesTests < Minitest::Test
  def setup
  end
  
  
  def teardown
  end
  
  
  def test_can_create_controlled_vocabularies_instance
    cv = ControlledVocabularies.new ["#{__dir__}/fixtures/CV/CMIP6_experiment_id.json"]
    assert_kind_of ControlledVocabularies, cv
  end


  def test_can_read_experiment_id_json
    cv = ControlledVocabularies.new ["#{__dir__}/fixtures/CV/CMIP6_experiment_id.json"]
    assert cv['experiment_id']
  end


  def test_can_read_start_year_from_experiment_id
    cv = ControlledVocabularies.new ["#{__dir__}/fixtures/CV/CMIP6_experiment_id.json"]    
    assert_equal "2015", cv['experiment_id']['highres-future']['start_year']
  end


  def test_can_read_experiment_id_and_source_id_from_directory
    puts
    cv = ControlledVocabularies.new_from_dir "#{__dir__}/fixtures/CV"
    assert_equal "2015", cv['experiment_id']['highres-future']['start_year']
    assert cv['experiment_id']
    assert cv['source_id']
  end
end
