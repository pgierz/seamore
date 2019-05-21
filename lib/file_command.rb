require 'fileutils'
require 'open3'


class FileCommand
  def run(infiles, outfile)
    execute_atomically(infiles, outfile)
  end
  
  
  private
  def execute_atomically(infiles, outfile)
    outfile_inprogress = "#{outfile}.inprogress"

    # this might be an incomplete step from a previous aborted run,
    # the .inprogress file might be removed to resume cmorization
    # should they be removed automatically?
    raise "file exists: #{outfile_inprogress}" if File.exist?(outfile_inprogress)
    system_call cmd_txt(infiles, outfile_inprogress)
    
    raise "file exists: #{outfile}" if File.exist? outfile
    FileUtils.mv outfile_inprogress, outfile
  end


  # determine if a command has been executed successfully
  def command_success?(out, err, status)
    return false unless status.success?
    return false unless err.empty?
    
    true
  end


  private
  def system_call(cmd)
    t0 = Time.now
    prefix = "#{Thread.current.name}: " if Thread.current.name
    puts "#{prefix}=> #{t0.strftime "%H:%M:%S"}  #{cmd}"
    out, err, status = Open3.capture3(cmd)
    raise "#{prefix}#{cmd} : #{err} #{out}" unless command_success?(out, err, status)
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


# nco utilities issue a warning to stderr if the path of an input file has more than 254 characters
# we want to ignore this 20th century warning and do not abort if it appears on stderr
# https://github.com/nco/nco/blob/405aea3e6777dc9dd3ccb931471bdc9d8440ca7e/src/nco/nco_fl_utl.c#L386
module NCO_warning_filter
  def command_success?(out, err, status)
    return false unless status.success?
    unless err.empty?
      return false unless err =~ /and may not be portable to older operating systems/
    end
    
    true
  end
end


class NCCOPY_COMPRESS_cmd < OutofplaceCommand
  include NCO_warning_filter

  def cmd_txt_outofplace(infiles, outfile)
    raise "can handle only 1 file in #{self.class} but got #{infiles.size} #{infiles.inspect}" if infiles.size != 1
    %Q(nccopy -k enhanced-nc3 -d 1 -s #{infiles[0]} #{outfile})
  end
end


class CDO_cmd < OutofplaceCommand
  def command_success?(out, err, status) # cdo almost always prints something to the error stream
    return false unless status.success?
        
    true
  end
end


class CDO_MERGE_cmd < CDO_cmd
  def cmd_txt_outofplace(infiles, outfile)
    %Q(cdo mergetime #{infiles.join(' ')} #{outfile})
  end
end


class CDO_SET_T_UNITS_DAYS_cmd < CDO_cmd
  def cmd_txt_outofplace(infiles, outfile)
    %Q(cdo settunits,days #{infiles.join(' ')} #{outfile})
  end
end


class CDO_MONMEAN_cmd < CDO_cmd
  def cmd_txt_outofplace(infiles, outfile)
    %Q(cdo monmean #{infiles.join(' ')} #{outfile}) # this will rename our "number_of_time_bounds" dimension to "bnds"
  end
end


class CDO_TIMMEAN_cmd < CDO_cmd
  def cmd_txt_outofplace(infiles, outfile)
    %Q(cdo timmean #{infiles.join(' ')} #{outfile}) # this will rename our "number_of_time_bounds" dimension to "bnds"
  end
end


class CDO_YEARMEAN_cmd < CDO_cmd
  def cmd_txt_outofplace(infiles, outfile)
    %Q(cdo yearmean #{infiles.join(' ')} #{outfile}) # this will rename our "number_of_time_bounds" dimension to "bnds"
  end
end


class CDO_MULC_cmd < CDO_cmd
  def initialize(factor)
    @factor = factor
  end
  
  def cmd_txt_outofplace(infiles, outfile)
    raise "can handle only 1 file in #{self.class} but got #{infiles.size} #{infiles.inspect}" if infiles.size != 1
    %Q(cdo mulc,#{@factor} #{infiles.join(' ')} #{outfile})
  end
end


class CDO_SUBC_cmd < CDO_cmd
  def initialize(subtrahend)
    @subtrahend = subtrahend
  end
  
  def cmd_txt_outofplace(infiles, outfile)
    raise "can handle only 1 file in #{self.class} but got #{infiles.size} #{infiles.inspect}" if infiles.size != 1
    %Q(cdo subc,#{@subtrahend} #{infiles.join(' ')} #{outfile})
  end
end


class MEAN_TIMESTAMP_ADJUST_cmd < InplaceCommand
  def cmd_txt_inplace(file)
    bin = "ncn mean_timestamp_adjust" unless bin # assume binary is known via PATH
    %Q(#{bin} #{file})
  end
end


class INSERT_TIME_BOUNDS_cmd < InplaceCommand
  def cmd_txt_inplace(file)
    bin = "ncn insert_time_bounds" unless bin # assume binary is known via PATH
    %Q(#{bin} #{file})
  end
end


class NCATTED_ADD_GLOBAL_ATTRIBUTES_cmd < InplaceCommand
  include NCO_warning_filter

  def initialize(attributes_hash)
    @attributes = attributes_hash
  end

  def cmd_txt_inplace(file)
    att_args = ""
    @attributes.each do |att_name, att_txt|
      if att_txt.is_a? Integer
        att_args += %Q( -a #{att_name},global,o,l,#{att_txt})
      elsif att_txt.is_a? Float
        att_args += %Q( -a #{att_name},global,o,d,#{att_txt})
      else
        att_args += %Q( -a #{att_name},global,o,c,"#{att_txt}")
      end
    end
    %Q(ncatted --create_ram -h#{att_args} #{file})
  end
end


class NCATTED_DELETE_GLOBAL_ATTRIBUTES_cmd < InplaceCommand
  include NCO_warning_filter

  def initialize(attribute_names)
    @attribute_names = attribute_names
  end

  def cmd_txt_inplace(file)
    att_args = ""
    @attribute_names.each {|n| att_args += %Q( -a #{n},global,d,,)}
    %Q(ncatted --create_ram -h#{att_args} #{file})
  end
end


class NCATTED_DELETE_VARIABLE_ATTRIBUTES_cmd < InplaceCommand
  include NCO_warning_filter

  def initialize(var_name, attribute_names)
    @var_name = var_name
    @attribute_names = attribute_names
  end

  def cmd_txt_inplace(file)
    att_args = ""
    @attribute_names.each {|n| att_args += %Q( -a #{n},#{@var_name},d,,)}
    %Q(ncatted --create_ram -h#{att_args} #{file})
  end
end


class NCATTED_SET_VARIABLE_DESCRIPTION_cmd < InplaceCommand
  include NCO_warning_filter

  def initialize(var_name, description)
    @var_name, @description = var_name, description
  end

  def cmd_txt_inplace(file)
    # there seems to be an error when setting chars with ncatted:
    # a single quote ' always results in a \' in the netcdf. the same effect as putting a \' in the first place
    # so we currently can not put all variable descriptions correctly, as some contain single quotes
    %Q(ncatted --create_ram -h -a description,#{@var_name},o,c,"#{@description}" #{file})
  end
end


class NCATTED_SET_VARIABLE_CELL_METHODS_cmd < InplaceCommand
  include NCO_warning_filter

  def initialize(var_name, cell_methods)
    @var_name, @cell_methods = var_name, cell_methods
  end

  def cmd_txt_inplace(file)
    %Q(ncatted --create_ram -h -a cell_methods,#{@var_name},o,c,"#{@cell_methods}" #{file})
  end
end


class NCATTED_SET_VARIABLE_UNITS_cmd < InplaceCommand
  include NCO_warning_filter

  def initialize(var_name, unit)
    @var_name, @unit = var_name, unit
  end

  def cmd_txt_inplace(file)
    # beware: the attribute is called 'units' (with 's')
    %Q(ncatted --create_ram -h -a units,#{@var_name},o,c,"#{@unit}" #{file})
  end
end


class NCATTED_SET_VARIABLE_STANDARD_NAME_cmd < InplaceCommand
  include NCO_warning_filter

  def initialize(var_name, standard_name)
    @var_name, @standard_name = var_name, standard_name
  end

  def cmd_txt_inplace(file)
    %Q(ncatted --create_ram -h -a standard_name,#{@var_name},o,c,"#{@standard_name}" #{file})
  end
end


class NCATTED_SET_LAT_LON_BNDS_STANDARD_NAME_cmd < InplaceCommand
  include NCO_warning_filter

  def cmd_txt_inplace(file)
    # set standard_name according to the CF conventions
    %Q(ncatted --create_ram -h -a standard_name,lat_bnds,o,c,"lat_bnds" -a standard_name,lon_bnds,o,c,"lon_bnds" #{file})
  end
end


class NCRENAME_RENAME_VARIABLE_cmd < InplaceCommand
  include NCO_warning_filter

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
  include NCO_warning_filter

  def cmd_txt_inplace(file)
    # from the docs: "ncrename will change the names of the input-file in place"
    %Q(ncrename -h -d .nodes_2d,ncells -d .nodes_3d,ncells #{file}) # the dot '.' prefix tells ncrename that it is an optional rename
  end
end


class NCKS_APPEND_GRID_cmd < InplaceCommand
  include NCO_warning_filter

  def initialize(grid_description_file)
    @grid_description_file = grid_description_file
  end

  def cmd_txt_inplace(file)
    # ncks will create a temporary copy of the file
    # see section "2.3 Temporary Output Files" in the docs
    %Q(ncks -h --create_ram --no_tmp_fl -A -v lat,lon,lat_bnds,lon_bnds #{@grid_description_file} #{file}) # the nodes dimension must be identical in geid description and variable file, e.g. 'ncells'
  end
end


class NCATTED_APPEND_COORDINATES_VALUE_cmd < InplaceCommand
  include NCO_warning_filter

  def initialize(variable_id)
    @variable_id = variable_id
  end

  def cmd_txt_inplace(file)
    # this does not seem to create a temporary file, but no mention of in-place operation in the ncatted docs
    %Q(ncatted -h --create_ram -a coordinates,#{@variable_id},a,c,'lat lon' #{file})
  end
end


