require 'fileutils'
require 'open3'


class FileCommand
  def run(infiles, outfile)
    execute_atomically(infiles, outfile)
  end
  
  
  private
  def execute_atomically(infiles, outfile)
    outfile_inprogress = "#{outfile}.inprogress"

    raise "file exists: #{outfile_inprogress}" if File.exist?(outfile_inprogress)
    system_call cmd_txt(infiles, outfile_inprogress)
    
    raise "file exists: #{outfile}" if File.exist? outfile
    FileUtils.mv outfile_inprogress, outfile
  end


  private
  def system_call(cmd)
    t0 = Time.now
    prefix = "#{Thread.current.name}" if Thread.current.name
    puts "#{prefix}=> #{t0.strftime "%H:%M:%S"}  #{cmd}"
    out, err, status = Open3.capture3(cmd)
    raise "#{cmd} : #{err}" unless status.success?
    puts "#{prefix}<= #{sprintf('%5.1f',Time.now-t0)} sec"
  end
end


class OutofplaceCommand < FileCommand
  def inplace?
    false
  end  


  def cmd_txt(infiles, outfile)
    cmd_txt_outofplace(infiles, outfile)
  end
end


class InplaceCommand < FileCommand
  def inplace?
    true
  end  


  def cmd_txt(infiles, outfile)
    raise "can handle only 1 file in #{self.class} but got #{infiles.size} #{infiles.inspect}" if infiles.size != 1
    FileUtils.mv infiles[0], outfile
    cmd_txt_inplace(outfile)
  end
end


class CDO_MERGE_cmd < OutofplaceCommand
  def cmd_txt_outofplace(infiles, outfile)
    %Q(cdo mergetime #{infiles.join(' ')} #{outfile})
  end
end


class CDO_SET_T_UNITS_DAYS_cmd < OutofplaceCommand
  def cmd_txt_outofplace(infiles, outfile)
    %Q(cdo settunits,days #{infiles.join(' ')} #{outfile})
  end
end


class FESOM_MEAN_TIMESTAMP_ADJUST_cmd < InplaceCommand
  def cmd_txt_inplace(file)
    bin = ENV["FESOM_MEAN_TIMESTAMP_ADJUST_BIN"]
    bin = "fesom_mean_timestamp_adjust" unless bin # env not set, assume binary is available via PATH
    %Q(#{bin} #{file})
  end
end


class NCATTED_ADD_GLOBAL_ATTRIBUTES_cmd < InplaceCommand
  def initialize(attributes_hash)
    @attributes = attributes_hash
  end

  def cmd_txt_inplace(file)
    att_args = ""
    @attributes.each {|att_name, att_txt| att_args += %Q( -a #{att_name},global,o,c,"#{att_txt}") }
    %Q(ncatted --create_ram --no_tmp_fl -h#{att_args} #{file})
  end
end


class NCATTED_DELETE_GLOBAL_ATTRIBUTES_cmd < InplaceCommand
  def initialize(attribute_names)
    @attribute_names = attribute_names
  end

  def cmd_txt_inplace(file)
    att_args = ""
    @attribute_names.each {|n| att_args += %Q( -a #{n},global,d,,)}
    %Q(ncatted --create_ram --no_tmp_fl -h#{att_args} #{file})
  end
end


class NCATTED_SET_VARIABLE_DESCRIPTION_cmd < InplaceCommand
  def initialize(var_name, description)
    @var_name, @description = var_name, description
  end

  def cmd_txt_inplace(file)
    %Q(ncatted --create_ram --no_tmp_fl -h -a description,#{@var_name},o,c,"#{@description}" #{file})
  end
end


class NCRENAME_RENAME_VARIABLE_cmd < InplaceCommand
  def initialize(old_name, new_name)
    @old_name, @new_name = old_name, new_name
  end

  def cmd_txt_inplace(file)
    if @old_name == @new_name
      %Q(:) # shell noop as ncrename fails with an error if the new name is the same as the old name
    else
      %Q(ncrename -h -v #{@old_name},#{@new_name} #{file})
    end
  end
end


class NCRENAME_DIMENSION_NODES_XD_TO_NCELLS_cmd < InplaceCommand
  def cmd_txt_inplace(file)
    # from the docs: "ncrename will change the names of the input-file in place"
    %Q(ncrename -h -d .nodes_2d,ncells -d .nodes_3d,ncells #{file}) # the dot '.' prefix tells ncrename that it is an optional rename
  end
end


class NCKS_APPEND_GRID_cmd < InplaceCommand
  def initialize(grid_description_file)
    @grid_description_file = grid_description_file
  end

  def cmd_txt_inplace(file)
    # ncks will create a temporary copy of the file
    # see section "2.3 Temporary Output Files" in the docs
    %Q(ncks --create_ram --no_tmp_fl -A -v lat,lon,lat_bnds,lon_bnds #{@grid_description_file} #{file}) # the nodes dimension must be identical in geid description and variable file, e.g. 'ncells'
  end
end


class NCATTED_APPEND_COORDINATES_VALUE_cmd < InplaceCommand
  def initialize(variable_id)
    @variable_id = variable_id
  end

  def cmd_txt_inplace(file)
    # this does not seem to create a temporary file, but no mention of in-place operation in the ncatted docs
    %Q(ncatted --create_ram --no_tmp_fl -a coordinates,#{@variable_id},a,c,'lat lon' #{file})
  end
end


