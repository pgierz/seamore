require 'fileutils'


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
    raise cmd unless system cmd
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
