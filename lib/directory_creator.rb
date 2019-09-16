require "date"

# create directory structure according to section "Directory structure template" in https://docs.google.com/document/d/1h0r8RZr_f3-8egBMMh7aqLwy3snpD6_MrDz1q8n5XUk/edit


class DirectoryCreator


# <mip_era>/
#  <activity_id>/
#   <institution_id>/
# 	 <source_id>/
#     <experiment_id>/
#      <member_id>/
#       <table_id>/
#        <variable_id>/
#         <grid_label>/
#          <version>


  def self.subdirs_for_cmor_file(f)
    names = %w(mip_era activity_id institution_id source_id experiment_id sub_experiment_id variant_label table_id variable_id grid_label creation_date)

    ncdump_h_txt = %x(ncdump -h #{f})
    global_attr_txt = ncdump_h_txt.split('// global attributes:').last
    values = {}
  
    names.each do |n|
      match = /:#{n} = "(?<val>.*?)" ;/.match(global_attr_txt)
      raise "can not find global attribute \"#{n}\"" unless match
      values[n] = match[:val]
    end
  
    dir_templates = %w(mip_era activity_id institution_id source_id experiment_id member_id table_id variable_id grid_label version)
    dir_names = dir_templates.map do |t|
      if t == "member_id"
        if(values['sub_experiment_id'] == "none")
          values['variant_label']
        else
          "#{values['sub_experiment_id']}-#{values['variant_label']}"
        end
      elsif t == "version"
        (Date.parse values['creation_date']).to_time.strftime "v%Y%m%d"
      else
        values[t]
      end
    end
  
    dir_names
  end


  def self.create_directories(files)
  
    files.each do |file|
      subdirs = DirectoryCreator.subdirs_for_cmor_file file
      system "mkdir -p #{File.join subdirs}"
      cmd = "ln #{file} #{File.join(subdirs, File.basename(file))}"
      puts cmd
      system cmd
    end
  end

end
