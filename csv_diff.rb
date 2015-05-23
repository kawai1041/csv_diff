#!/usr/local/bin/ruby -KS
# encoding: CP932
#
# 2015.05.23:KAWAI Toshikazu
#

require 'csv'
require 'set'

DIFF_ORG = 'org.csv'
DIFF_REF = 'ref.csv'
KEYS = '1,2,4'

def key(line, keys)
  csv_a = line.parse_csv
  keys.parse_csv.map {|e| e.to_i - 1}.map {|ee| csv_a[ee]}.join(':::')
end

org = {}
org_keys = Set.new
ref = {}
ref_keys = Set.new

File.open(DIFF_ORG, 'r') {|f|
  f.each {|line|
    k = key(line,KEYS)
    raise "same key #{k} found in org file" if org_keys.include? k
    org_keys << k
    org[key(line,KEYS)] = line
  }
}

File.open(DIFF_REF, 'r') {|f|
  f.each {|line|
    k = key(line,KEYS)
    raise "same key #{k} found in ref file" if ref_keys.include? k
    ref_keys << k
    ref[key(line,KEYS)] = line
  }
}

puts "from #{DIFF_ORG} to #{DIFF_REF}"
(org_keys - ref_keys).each {|k|
  print "DELETED, " + org[k]
}

(ref_keys - org_keys).each {|k|
    print "INSERTED, " + ref[k]
}
