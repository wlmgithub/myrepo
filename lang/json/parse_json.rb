#
# lwang: parse json with ruby
#
require 'rubygems'
require 'json'


data = `glu -f stg-beta status`

puts data


result = JSON.parse(data)

puts result.class

if result.has_key? 'Error'
  raise "result has key Error"
end

# ok
all_entries = result['entries']

all_entries.each { |entry|

  if entry.has_key? 'agent'
    print  entry['metadata']['container']['name'], "\t"
    print  entry['agent']

    wars_str = entry['initParameters']['wars']

    wars_ary = wars_str.split('|')

    wars_ary.each { |w| 
      if w =~ /ivy:.*\/(.*(?:-STG-BETA)?)\/(.*)/
        print "\n\t#{$1}\t#{$2}"
      end

    }

  end

  puts
  puts

}


