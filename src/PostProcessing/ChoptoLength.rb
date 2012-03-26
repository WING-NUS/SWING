#!/usr/bin/env ruby


# Sentence Reduction Module - Rule based
# NG, Jun Ping - Jun 2011
#


require "rubygems"
require "json"
require "getopt/std"


opt = Getopt::Std.getopts("l:")
$g_Length = opt['l'].to_i


ARGF.each do |l_szJSON|

    l_JSON = JSON.parse(l_szJSON)

    if l_JSON["summary"].nil? then
        break
    end

    l_NewSummary = ""

    #$stderr.puts "Summary before [#{l_JSON['summary'].split(' ').length}]:\n#{l_JSON['summary']}"

    # Try to shorten each sentence in the summary
    #l_Count = 0
    #l_JSON["summary"].split(" ").each do |l_szToken|
    #    if (l_Count < 100) then
    #        l_NewSummary += "#{l_szToken} "
    #        l_Count += 1
    #    else
    #        break
    #    end
    #end
    l_Count = 0
    l_JSON["summary"].split("\n").each do |sent|
        if l_Count + sent.split.size <= $g_Length then
            l_NewSummary += sent + "\n"
            l_Count += sent.split.size
        else
            l_NewSummary += sent.split[0...($g_Length-l_Count)].join(" ")
            break
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

