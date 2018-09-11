require "ostruct"


class GlobalAttributesBuilder
  def set_experiment_info(id:, variant_label:, first_year:)
    @experiment_info = OpenStruct.new(:id => id,
                                      :variant_label => variant_label,
                                      :first_year => first_year)
  end


  def set_parent_experiment_info(id:, variant_label:, first_year:)
    @parent_experiment_info = OpenStruct.new(:id => id,
                                             :variant_label => variant_label,
                                             :first_year => first_year)
  end
  
  
  def set_variable_info(id:, frequency:, table_id:, table_realm:)
    @variable_info = OpenStruct.new(:id => id,
                                    :frequency => frequency,
                                    :table_id => table_id,
                                    :table_realm => table_realm)
  end
  
  
  def set_grid_info(source_id:, nominal_resolution:, txt:)
    @grid_info = OpenStruct.new(:source_id => source_id,
                                :nominal_resolution => nominal_resolution,
                                :txt => txt)
  end
end


# required global netcdf attributes as described here: https://docs.google.com/document/d/1h0r8RZr_f3-8egBMMh7aqLwy3snpD6_MrDz1q8n5XUk/edit
class GlobalAttributes
end
