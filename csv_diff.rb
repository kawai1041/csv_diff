#!/usr/local/bin/ruby
#
# encoding: CP932
#
# 2015.05.23:KAWAI Toshikazu
#

require 'csv'
require 'set'

INI_FILE = 'csv_diff.ini'

class INI
  attr_reader :keys, :org, :ref, :out, :header
  def initialize(ini_file = INI_FILE)
    File.open(ini_file, 'r') {|f|
      f.each {|line|
        line.strip!
        next if line.size == 0 or line[0] == '#'
        case line
        when /^file_prefix:(.+)/
          @file_prefix = $1
        when /^keys:(.+)/
          @keys = $1.split(',').map {|e| (e.to_i - 1)}
        when /^org_file:(.+)/
          @org = $1
        when /^ref_file:(.+)/
          @ref = $1
        when /^output_file:(.+)/
          @out = $1
        when /^header:(.+)/
          if $1 =~ /yes/i
            @header = true
          else
            @header = false
          end
        end
      }
    }
    raise "INI file ERROR keys not defined" if @keys == nil
    raise "INI file ERROR file not defined" if @file_prefix == nil and (@org == nil or @ref == nil)
    raise "INI FILE ERROR prefix and (org_file, ref_file) both degined" if @file_prefix and (@org or @ref)
    if @org == nil and @ref == nil
      set_org_ref
    end
    if @out == nil
      @out = 'diff_' + File.basename(@org, ".*") + '_' + File.basename(@ref, ".*") + '.csv'
    end
  end
  
  private
  def set_org_ref
    org_mtime = ref_mtime = Time.new(0)     
    Dir.glob(@file_prefix + '*').each {|file|
      mtime = File.stat(file).mtime
      if mtime > org_mtime
        org_mtime = mtime
        @org = file
        if mtime > ref_mtime
          org_mtime = ref_mtime
          ref_mtime = mtime
          @org = @ref
          @ref = file
        end
      end
    }
  end
    
end


def key(line, keys)
  csv_a = line.parse_csv
  keys.map {|e| csv_a[e]}.join(':::')
end

ini = INI.new

org = {}
org_keys = Set.new
ref = {}
ref_keys = Set.new

File.open(ini.out, 'w') {|of|
  header_line = nil
  File.open(ini.org, 'r') {|f|
    f.each {|line|
      if header_line == nil and ini.header
        header_line = line
      end
      k = key(line, ini.keys)
      of.puts "same key #{k} found in org file. new record is used" if org_keys.include? k
      org_keys << k
      org[key(line, ini.keys)] = line
    }
  }

  File.open(ini.ref, 'r') {|f|
    f.each {|line|
      k = key(line, ini.keys)
      of.puts "same key #{k} found in ref file. new record is used" if ref_keys.include? k
      ref_keys << k
      ref[key(line, ini.keys)] = line
    }
  }
  
  of.puts "from #{ini.org} to #{ini.ref}"
  of.puts '増減,' + header_line if ini.header
    
  (org_keys - ref_keys).each {|k|
    of.print "-," + org[k]
  }

  (ref_keys - org_keys).each {|k|
    of.print "+," + ref[k]
  }
}