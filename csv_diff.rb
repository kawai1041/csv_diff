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
  attr_reader :keys, :org, :ref
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
        end
      }
    }
    raise "INI file ERROR" if @file_prefix == nil or @keys == nil
    set_org_ref
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

File.open(ini.org, 'r') {|f|
  f.each {|line|
    k = key(line, ini.keys)
    raise "same key #{k} found in org file" if org_keys.include? k
    org_keys << k
    org[key(line, ini.keys)] = line
  }
}

File.open(ini.ref, 'r') {|f|
  f.each {|line|
    k = key(line, ini.keys)
    raise "same key #{k} found in ref file" if ref_keys.include? k
    ref_keys << k
    ref[key(line, ini.keys)] = line
  }
}

puts "from #{ini.org} to #{ini.ref}"
(org_keys - ref_keys).each {|k|
  print "-," + org[k]
}

(ref_keys - org_keys).each {|k|
  print "+," + ref[k]
}
