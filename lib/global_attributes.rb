require "ostruct"
require 'securerandom'
require 'date'


class GlobalAttributesBuilder
  def set_experiment_info(id:, source_id:, variant_label:, first_year:, last_year:)
    @experiment_info = OpenStruct.new(:id => id,
                                      :source_id => source_id,
                                      :variant_label => variant_label,
                                      :first_year => first_year,
                                      :last_year => last_year)
  end


  def set_parent_experiment_info(id:, source_id:, variant_label:, first_year:, last_year:)
    @parent_experiment_info = OpenStruct.new(:id => id,
                                             :source_id => source_id,
                                             :variant_label => variant_label,
                                             :first_year => first_year,
                                             :last_year => last_year)
  end
  
  
  def set_variable_info(id:, frequency:, table_id:, realms:)
    @variable_info = OpenStruct.new(:id => id,
                                    :frequency => frequency,
                                    :table_id => table_id,
                                    :realms => realms)
  end
  
  
  def set_grid_info(nominal_resolution:, txt:)
    @grid_info = OpenStruct.new(:nominal_resolution => nominal_resolution,
                                :txt => txt)
  end
  
  
  def build_global_attributes(data_specs_version:)
    GlobalAttributes.new(data_specs_version: data_specs_version,
                         variable_info: @variable_info,
                         grid_info: @grid_info,
                         experiment_info: @experiment_info,
                         parent_experiment_info: @parent_experiment_info)
  end
end


# required global netcdf attributes as described here: https://docs.google.com/document/d/1h0r8RZr_f3-8egBMMh7aqLwy3snpD6_MrDz1q8n5XUk/edit
class GlobalAttributes
  attr_reader :filename

  def initialize(data_specs_version:, variable_info:, grid_info:, experiment_info:, parent_experiment_info:nil)
    institution_id = "AWI"
    mip_era = "CMIP6"
    sub_experiment_id = "none"
    
    @attributes = {}
    @attributes['activity_id'] = "HighResMIP"
    @attributes['Conventions'] = "CF-1.7 CMIP-6.0" # this depends on the version of the file https://docs.google.com/document/d/1h0r8RZr_f3-8egBMMh7aqLwy3snpD6_MrDz1q8n5XUk/edit
    @attributes['creation_date'] = creation_date_txt(Time.now)
    @attributes['data_specs_version'] = data_specs_version
    @attributes['experiment'] = experiment_info.id
    @attributes['experiment_id'] = @attributes['experiment']
    @attributes['forcing_index'] = "002"
    @attributes['frequency'] = variable_info.frequency
    @attributes['further_info_url'] = "http://furtherinfo.es-doc.org/#{mip_era}.#{institution_id}.#{experiment_info.source_id}.#{experiment_info.id}.#{sub_experiment_id}.#{experiment_info.variant_label}"
    @attributes['grid'] = grid_info.txt #cv['source_id'][experiment_info.source_id].model_component.ocean.description
    @attributes['grid_label'] = "gn"
    @attributes['initialization_index'] = "1"
    @attributes['institution'] = "Alfred Wegener Institute, Helmholtz Centre for Polar and Marine Research, Am Handelshafen 12, 27570 Bremerhaven, Germany"
    @attributes['institution_id'] = institution_id
    @attributes['license'] = "CMIP6 model data produced by Alfred Wegener Institute, Helmholtz Centre for Polar and Marine Research, Am Handelshafen 12, 27570 Bremerhaven, Germany is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License (https://creativecommons.org/licenses/). Consult https://pcmdi.llnl.gov/CMIP6/TermsOfUse for terms of use governing CMIP6 output, including citation requirements and proper acknowledgment. Further information about this data, including some limitations, can be found via the further_info_url (recorded as a global attribute in this file). The data producers and data providers make no warranty, either express or implied, including, but not limited to, warranties of merchantability and fitness for a particular purpose. All liabilities arising from the supply of the information (including any liability arising in negligence) are excluded to the fullest extent permitted by law."
    @attributes['mip_era'] = mip_era
    @attributes['nominal_resolution'] = grid_info.nominal_resolution
    @attributes['physics_index'] = "1"
    @attributes['product'] = "model-output"
    @attributes['realization_index'] = "1"
    @attributes['realm'] = variable_info.realms.join(' ')
    @attributes['source'] = experiment_info.source_id
    @attributes['source_id'] = @attributes['source']
    @attributes['source_type'] = "AOGCM"
    @attributes['sub_experiment'] = "none"
    @attributes['sub_experiment_id'] = sub_experiment_id
    @attributes['table_id'] = variable_info.table_id
    @attributes['tracking_id'] = "hdl:21.14100/#{SecureRandom.uuid}"
    @attributes['variable_id'] = variable_info.id
    @attributes['variant_label'] = experiment_info.variant_label
#    @attributes['external_variables'] = #FESOM: areacello ECHAM: areacella # we do not reference any of these, so it is "not appropriate" to include this attribute
    if(parent_experiment_info)
      @attributes['branch_method'] = "standard"
      @attributes['branch_time_in_child'] = "0.0D0"
      d = 0; parent_experiment_info.first_year.upto(experiment_info.first_year) {|y| d += days_in_year y}
      @attributes['branch_time_in_parent'] = "#{d}.0D0"
      @attributes['parent_activity_id'] = "HighResMIP"
      @attributes['parent_experiment_id'] = parent_experiment_info.id
      @attributes['parent_mip_era'] = "CMIP6"
      @attributes['parent_source_id'] = parent_experiment_info.source_id
      @attributes['parent_time_units'] = "days since #{parent_experiment_info.first_year}-1-1"
      @attributes['parent_variant_label'] = parent_experiment_info.variant_label
    end

    @filename = create_filename(@attributes, experiment_info.first_year, experiment_info.last_year, variable_info.frequency)
  end

  
  def frequency
    @attributes['frequency']
  end
  

  def as_hash
    @attributes
  end
  
  
  private def creation_date_txt(time)
    # YYY-MM-DDTHH:MM:SSZ (Z is special timezone designator for UTC)
    time.gmtime.strftime "%Y-%m-%dT%H:%M:%SZ"
  end
  
  
  def days_in_year(year)
    Date.new(year+1, 1, 1).next_day(-1).yday
  end
  
  
  private def create_filename(att_hash, first_year, last_year, frequency_txt)
    # see https://docs.google.com/document/d/1h0r8RZr_f3-8egBMMh7aqLwy3snpD6_MrDz1q8n5XUk/edit page 13
    # <variable_id>_<table_id>_<source_id>_<experiment_id>_<member_id>_<grid_label>[_<time_range>].nc
    if(att_hash['sub_experiment_id'] == "none")
      member_id = att_hash['variant_label']
    else
      member_id = "#{att_hash['sub_experiment_id']}-#{att_hash['variant_label']}"
    end
    time_range = filename_time_range(first_year, last_year, frequency_txt)
    
    "#{att_hash['variable_id']}_#{att_hash['table_id']}_#{att_hash['source_id']}_#{att_hash['experiment_id']}_#{member_id}_#{att_hash['grid_label']}_#{time_range}.nc"
  end


  private def filename_time_range(first_year, last_year, frequency_txt)
  # see https://docs.google.com/document/d/1h0r8RZr_f3-8egBMMh7aqLwy3snpD6_MrDz1q8n5XUk/edit table 2
    case frequency_txt
    when "mon"
      "#{first_year}01-#{last_year}12"
    when "day"
      "#{first_year}0101-#{last_year}1231"
    when "3hr"
      "#{first_year}01010000-#{last_year}12312359"
    when "3hrPt"
      "#{first_year}01010130-#{last_year}12312230"
    else
      raise "unknown frequency <#{frequency_txt}>"
    end
  end  
end
