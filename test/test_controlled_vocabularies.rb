require_relative "../lib/controlled_vocabularies.rb"

require "minitest/autorun"


class ControlledVocabulariesTests < Minitest::Test
  def setup
  end
  
  
  def teardown
  end
  
  
  def test_can_create_controlled_vocabularies_instance
    cv = ControlledVocabularies.new "#{__dir__}/fixtures/CV"
    assert_kind_of ControlledVocabularies, cv
  end
end
