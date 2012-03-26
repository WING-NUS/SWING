#!/usr/bin/env ruby


# Minimum Length > Drops all sentencess less than some prescribed length
# NG, Jun Ping - Jun 2011
#


require "rubygems"
require "json"
require "getopt/std"

opt = Getopt::Std.getopts("l:")
$g_MinLength = opt['l'].to_i


ARGF.each do |l_szJSON|

    l_JSON = JSON.parse(l_szJSON)

    if l_JSON["summary"].nil? then
        break
    end

    l_NewSummary = ""

    #$stderr.puts "Summary before [#{l_JSON['summary'].split(' ').length}]:\n#{l_JSON['summary']}"

    # Try to shorten each sentence in the summary
    l_JSON["summary"].split("\n").each do |l_szLine|

        if l_szLine.split.length > $g_MinLength then
            #$stderr.puts "SR: #{l_szLine}"
            l_NewSummary += "#{l_szLine}\n"
        end

    end

    #$stderr.puts "Summary after [#{l_NewSummary.split(' ').length}]:\n#{l_NewSummary}"

#    if not l_JSON['summary'] == l_NewSummary
#        $stderr.puts l_NewSummary
#    end
    
    # Overwrite with new summaryy
    l_JSON["summary"] = l_NewSummary

    # Return the JSON string
    $stdout.puts l_JSON.to_json

end

