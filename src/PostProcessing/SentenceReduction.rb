#!/usr/bin/env ruby


# Sentence Reduction Module - Rule based
# NG, Jun Ping - Jun 2011
#


require "rubygems"
require "json"
require "optparse"
require "base64"


# Invoke rules to process input sentnece
# @param a_szLine [in] line to process
# @return processed line
def ProcessSentence(a_szLine)

    # Rules
    a_szLine = Rule0_agency_headers(a_szLine)
    a_szLine = Rule1_whose_whom(a_szLine)
    a_szLine = Rule2_reported_said(a_szLine)
    a_szLine = Rule3_according_to(a_szLine)
    a_szLine = Rule4_bad_sentence_start(a_szLine)
    a_szLine = Rule5_redundant_intros(a_szLine)
    a_szLine = Rule6_age(a_szLine)
    a_szLine = Rule7_days_of_week(a_szLine)
    a_szLine = Rule8_remove_gmt(a_szLine)
    a_szLine = Rule9_caps_opening(a_szLine)
    a_szLine.strip

end


def Rule0_agency_headers(a_szLine)

    #l_TextAfter = a_szLine.gsub(/^[A-Za-z0-9,\. :\-\(\)]*([-_]+ |UTC)/,"")
    l_TextAfter = a_szLine.gsub(/^[A-Za-z0-9\., ]+ \(Xinhua\)/,"")
    l_TextAfter = l_TextAfter.gsub(/^[A-Z][A-Za-z, ]+ [0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2} UTC/,"")
    l_TextAfter = l_TextAfter.gsub(/^[0-9]{2}:[0-9]{2}:[0-9]{2} UTC/,"")
    l_TextAfter = l_TextAfter.gsub(/\-\-(January|February|March|April|May|June|July|August|September|October|November|December) [0-9]{2}[, ]*[0-9]{4}:?/,"")
    l_TextAfter = l_TextAfter.gsub(/Cox News Service SAN FRANCISCO -/,"")
end

# Eg. .., who is the director of XXX,
def Rule1_whose_whom(a_szLine)

    a_szLine.gsub(/, who[(se)|(m)] .+ ?,/,"")

end


# Eg. .., the newspapers reported yesterday noon....
# Eg. XXX said that YYYY ...
def Rule2_reported_said(a_szLine)

    l_TextAfter = a_szLine.gsub(/[,|('')|"] [^,]+ (announced|reported|told|said|say|revealed)+( ?[^\.]+)*/,"")
    l_TextAfter = l_TextAfter.gsub(/^[a-z]+ (said) (that )?/,"")

end

# Eg. .., according to police reports.
def Rule3_according_to(a_szLine)

    a_szLine.gsub(/, ?according to .+\./,".")

end

# Eg. Moreover, the sun is not setting...
def Rule4_bad_sentence_start(a_szLine)

    a_szLine.gsub(/^([Nn]onetheless|[Mm]oreover),? ?/,"")

end


# Eg. The study shows that ....
# Eg. According to (...), ...
def Rule5_redundant_intros(a_szLine)

    a_szLine = a_szLine.gsub(/^The study (shows|reveals) that the /,"")
    a_szLine.gsub(/^According to [^,]+, ?/,"")

end

# Eg. Steve Jobs, 35, ...
def Rule6_age(a_szLine)

    a_szLine.gsub(/, ?[0-9]+, ?/," ")

end


def Rule7_days_of_week(a_szLine)

    a_szLine = a_szLine.gsub(/(([Oo]n|[Aa]s of) )?(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)[ \.,]/,"")
    a_szLine = a_szLine.gsub(/(([Oo]n|[Aa]s of) )?(Mon|Tue|Wed|Thu|Fri|Sat|Sun) /,"")

end


def Rule8_remove_gmt(a_szLine)
    a_szLine = a_szLine.gsub(/\([0-9]+ GMT\)/,"")
end


def Rule9_caps_opening(a_szLine)
    a_szLine = a_szLine.gsub(/^[A-Z]{2,},? /,"")
end


$g_CmdLineOptions = {}
$g_ParsedOptions = OptionParser.new do |opts|
    opts.banner = "Performs sentence reduction through a series of regular expression rules.\n Usage: PostProcessing\SentenceReduction.rb [options]"
    opts.on( '-v', '--version', 'Prints version information') do
        puts VERSION_NO
        puts AUTHOR_INFO
        puts ""
        exit
    end
    $g_CmdLineOptions[:oneoff] = false
    opts.on( '-o', '--oneoff SENTENCE', String, 'Performs a one-time reduction on an sentence passed in as an argument') do |l_szSentence|
        $g_CmdLineOptions[:oneoff] = true

        # Process sentence
        $stdout.puts ProcessSentence(Base64.decode64(l_szSentence).lstrip.rstrip)

    end
    opts.on('-h','--help','Display this screen') do
        puts opts
        exit
    end
end


$g_ParsedOptions.parse!


# Check mode of operation
# This module supports direct invokation and can run independently
#  from the rest of the Summarisation pipeline
if $g_CmdLineOptions[:oneoff] then
    exit
end

ARGF.each do |l_szJSON|

    l_JSON = JSON.parse(l_szJSON)

    if l_JSON["summary"].nil? then
        break
    end

    l_NewSummary = ""

    #$stderr.puts "Summary before [#{l_JSON['summary'].split(' ').length}]:\n#{l_JSON['summary']}"

    # Try to shorten each sentence in the summary
    l_JSON["summary"].split("\n").each do |l_szLine|

        l_szLine = ProcessSentence(l_szLine)
        l_szLine.strip!

        #$stderr.puts "SR: #{l_szLine}"
        l_NewSummary += "#{l_szLine}\n"
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

