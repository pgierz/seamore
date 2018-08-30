require "json"


# https://github.com/WCRP-CMIP/CMIP6_CVs
# https://docs.google.com/document/d/1h0r8RZr_f3-8egBMMh7aqLwy3snpD6_MrDz1q8n5XUk/edit
class ControlledVocabularies
  def initialize(cmip6_cvs_dir)
    eliglible_files = Dir["#{cmip6_cvs_dir}/CMIP6_*.json"]
    p eliglible_files
  end
end
