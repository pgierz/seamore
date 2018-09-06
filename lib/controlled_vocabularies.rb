require "json"


# https://github.com/WCRP-CMIP/CMIP6_CVs
# https://docs.google.com/document/d/1h0r8RZr_f3-8egBMMh7aqLwy3snpD6_MrDz1q8n5XUk/edit
class ControlledVocabularies < Hash
  def self.print_experiment_ids(cv_file)
    cv = ControlledVocabularies.new [cv_file]
    cv['experiment_id'].each do |k,v|
      puts "#{k} #{v['start_year']}-#{v['end_year']} parent:#{v['parent_experiment_id'].join(', ')}"
    end
  end
  

  def self.new_from_dir(cmip6_cvs_dir)
    ControlledVocabularies.new Dir["#{cmip6_cvs_dir}/*.json"]
  end

  
  def initialize(json_files)  
    json_files.each do |f|
      h = ControlledVocabularies.hash_from_json_file f
      merge! h
    end    
  end


  def self.hash_from_json_file(path)
    begin
      JSON.parse(File.read(path), object_class: Hash)
    rescue JSON::ParserError => e
      raise "file #{path}: #{e.message}"
    end
  end  
end
