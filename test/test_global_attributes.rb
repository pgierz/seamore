require_relative "../lib/global_attributes.rb"

require "minitest/autorun"


class GlobalAttributesTests < Minitest::Test
  def setup
  end
  
  
  def teardown
  end
  
  
  def test_global_attributes_for_variable_so_have_variable_id_so
    builder = GlobalAttributesBuilder.new
    builder.set_experiment_info(id: "highres-future", variant_label: "r1i1p1f002", first_year: 2000)
    builder.set_parent_experiment_info(id: "control", variant_label: "r1i1p1f002", first_year: 1900)
    builder.set_variable_info(id: "so", frequency: "mon", table_id: "Omon", realms: ["ocean"])
    builder.set_grid_info(source_id: "AWI-CM-1-0-LR",
                        nominal_resolution: "50 km",
                        txt: "FESOM 1.4 (unstructured grid in the horizontal with 126859 wet nodes; 46 levels; top grid cell 0-5 m)")
    
    ga = builder.build_global_attributes(data_specs_version: "01.00.27")
    assert "so", ga.attributes['variable_id']
  end
end