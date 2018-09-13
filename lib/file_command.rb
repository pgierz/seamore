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
    %Q(ncatted -h#{att_args} #{file})
  end
end


class NCATTED_DELETE_GLOBAL_ATTRIBUTES_cmd < InplaceCommand
  def initialize(attribute_names)
    @attribute_names = attribute_names
  end

  def cmd_txt_inplace(file)
    att_args = ""
    @attribute_names.each {|n| att_args += %Q( -a #{n},global,d,,)}
    %Q(ncatted -h#{att_args} #{file})
  end
end


class NCATTED_SET_VARIABLE_DESCRIPTION_cmd < InplaceCommand
  def initialize(var_name, description)
    @var_name, @description = var_name, description
  end

  def cmd_txt_inplace(file)
    %Q(ncatted -h -a description,#{@var_name},o,c,"#{@description}" #{file})
  end
end
