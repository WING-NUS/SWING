#!/usr/bin/env ruby
#
# Takes in as input a series of JSON strings which represents ranked
# sentences in each arg zone.
# Output another JSON string with a set of selected sentences forming 
# a summary
#
# Author:: Ng, Jun Ping (mailto:junping@comp.nus.edu.sg)
# Copyright:: Copyright (c) 2011, Ng Jun Ping

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/..') unless $LOAD_PATH.include?(File.dirname(__FILE__) + '/..')

require 'rubygems'
require 'json'
require 'optparse'
require 'nokogiri'
require 'pp'
require 'base64'
require 'parseconfig'
require File.dirname(__FILE__)+'/../SVR/importance'


MIN_SENTENCE_LENGTH = 4




module WINGSummarisation
    module SentenceSelection


# Performs sentence reduction by invoking the 
#   PostProcessing/SentenceReduction module
def SentenceSelection.PerformSentenceReduction(a_Sentence)

    l_Cmd = "ruby #{File.dirname(__FILE__)}/../PostProcessing/SentenceReduction.rb --oneoff \"#{Base64.encode64(a_Sentence)}\""
    #$stderr.puts "PerformingSentenceReduction:\n#{l_Cmd}"
    l_Reply = `#{l_Cmd}`.lstrip.rstrip
    # $?.exitstatus gives the exit status if we want it

end


def SentenceSelection.ComputeCosim(a_V1, a_V2)
   
    l_Values1 = a_V1.values
    l_Values2 = a_V2.values

    # Numerator part
    l_Count = 0
    l_Sum = 0.0
    while l_Count < l_Values1.length
        l_Sum += l_Values1[l_Count] * l_Values2[l_Count]
        l_Count += 1
    end

    # Calculate normalising factor
    l_Count = 0
    l_Normalise1 = 0.0
    while l_Count < l_Values1.length
        l_Normalise1 += l_Values1[l_Count] ** 2
        l_Count += 1
    end
    l_Normalise1 = Math.sqrt(l_Normalise1)

    l_Count = 0
    l_Normalise2 = 0.0
    while l_Count < l_Values2.length
        l_Normalise2 += l_Values2[l_Count] ** 2
        l_Count += 1
    end
    l_Normalise2 = Math.sqrt(l_Normalise1)
    

    return l_Sum / (l_Normalise1 * l_Normalise2)

end
   

def SentenceSelection.PopulateVector(a_Vector, a_Sentence)

    l_ResultVector = {}
    l_ResultVector = l_ResultVector.replace(a_Vector)
    a_Sentence.split(' ').each do |l_Word|
        if (l_ResultVector.has_key?(l_Word)) then
            l_ResultVector[l_Word] += 1
        end
    end

    return l_ResultVector

end

def SentenceSelection.CalculateMMR(a_Sentence, a_SentenceRelevance, a_Title, a_Narrative, a_ZoneIndex, a_arrSelected, which_set, set_A_sents)
    
#   l_Sim1 = ComputeCosim(l_VectorQuery, l_VectorTopic)


    if a_Sentence == nil then
        return 0.0
    end

    # Make use of pre-computed sentence relevance score
    l_Sim1 = a_SentenceRelevance


    l_Sim2 = 0.0
    if a_arrSelected.size > 0 then
        l_Sim2 = calc_sent_importance([a_arrSelected], a_Sentence) 
    end
    
    res = nil

    if which_set == 'A' then
        res = l_Sim1 - l_Sim2  
    else
        l_Sim3 = 0
        set_A_sents.each do |s|
            sim3 = calc_sent_importance([[s]], a_Sentence)
            if sim3 > l_Sim3 then
                l_Sim3 = sim3
            end
        end
        res = l_Sim1 - 0.2*l_Sim2 - 0.2*l_Sim3 
    end


    # We want to find and return the diff between Sim1 and max(all Sim2)

    # if this is set B, also consider the similarity between this sentence and set A summary
    # and subtract the diff
    #if $g_CmdLineOptions[:prev] != nil then
        #prev_sents = File.readlines($g_CmdLineOptions[:prev]).map {|l| l.strip}
        #l_Sim3 = calc_sent_importance([prev_sents[0...1]], a_Sentence)
        #res = res - l_Sim3
    #end

    return res
end


def SentenceSelection.GetTopicTitle(a_DocSet)
    l_Title = ""
    
    # The Doc Set we get is of the form D0901A-A for example
    # We want to strip away the '-X' prefix
    l_DocSet = a_DocSet.slice(0..a_DocSet.index('-')-1)
    l_XML = Nokogiri::XML(File.new($g_CmdLineOptions[:src]))    
    l_XML.document.xpath("//topic[@id='" + l_DocSet + "']/title").each { |l_Node|
        l_Title = l_Node.text
    }
    l_Title
end

def SentenceSelection.GetTopicNarrative(a_DocSet)
    l_Narrative = ""
    
    # The Doc Set we get is of the form D0901A-A for example
    # We want to strip away the '-X' prefix
    l_DocSet = a_DocSet.slice(0..a_DocSet.index('-')-1)
    l_XML = Nokogiri::XML(File.new($g_CmdLineOptions[:src]))    
    l_XML.document.xpath("//topic[@id='" + l_DocSet + "']/narrative").each { |l_Node|
        l_Narrative = l_Node.text
    }
    l_Narrative = l_Narrative.chomp.reverse.chomp.reverse
end

    end
end


# Defines the allowed options
# # # # # # # # # # # # # # # # # # # # # # # # #
$g_CmdLineOptions = {}
$g_ParsedOptions =  OptionParser.new do |opts|
    opts.banner = "Usage: MMRSelection .rb [options]"
    $g_CmdLineOptions[:maxlength] = 100
    opts.on( '-l', '--maxlength LENGTH', 'Max length of summary to generate [Default: 100]' ) do |l_szMaxLength|
        $g_CmdLineOptions[:maxlength] = l_szMaxLength.to_i
    end
    $g_CmdLineOptions[:reduction] = false
    opts.on( '-r' , '--reduction', 'Turn on within module sentence reduction [Default: false]' ) do
        $g_CmdLineOptions[:reduction] = true
    end
    #$g_CmdLineOptions[:src] = ""
    opts.on( '-s' , '--src Topic_File', 'Path to topic file' ) do |l_szName|
        $g_CmdLineOptions[:src] = l_szName
    end
    opts.on( '-h', '--help', 'Display this screen' ) do
        puts opts
        exit
    end
    opts.on( '-p' , '--previous Previous (Set A) Summary', 'Previous (Set A) Summary' ) do |l_szName|
        $g_CmdLineOptions[:prev] = l_szName
    end
end

# Parse the incoming command line arguments
# # # # # # # # # # # # # # # # # # # # # # # # #
$g_ParsedOptions.parse!

# Check for compulsory switches
# # # # # # # # # # # # # # # # # # # # # # # # # #
if $g_CmdLineOptions[:src].nil? then
    raise OptionParser::MissingArgument
end


# Makes use of the ZonedSentences class to hold the processed elements
ARGF.each do |l_szJSON|

    l_JSON = JSON.parse(l_szJSON)
    which_set = l_JSON["corpus"][0]["docset"].match(/-B/) ? 'B' : 'A'

    set_A_sents = nil
    
    test_conf = ParseConfig.new(File.dirname(__FILE__)+'/../../configuration.conf')
    mmr_similarity = test_conf.params['test']['similarity criteria']
    if mmr_similarity == "summary"

        use_summary = true
    else
        use_summary = false
    end

    if which_set == 'B' then
        if use_summary then
            set_A_sents = File.readlines("../data/set_A_summaries/" + l_JSON["corpus"][0]["docset"].sub(/-B$/, '-A')).map {|l| l.strip}
        else
            lines = File.readlines("../data/set_A_text/" + l_JSON["corpus"][0]["docset"].sub(/-B$/, '-A')).map {|l| l.split(/\t/)}
            set_A_sents = []
            cnt = 0
            lines.sort {|a,b| b[1].to_f<=>a[1].to_f} .each do |a|
                #if a[2].split.size >= 10 then
                set_A_sents << a[2]
                cnt += 1
                #    break if cnt == 10
                #end
            end
        end
    end
   
    #l_RankedSentences = l_JSON["sentences_ranked"]
    l_DocSet = l_JSON["corpus"][0]["docset"]

    # Retrieve topic
    l_Title = WINGSummarisation::SentenceSelection.GetTopicTitle(l_DocSet)
    l_Narrative = WINGSummarisation::SentenceSelection.GetTopicNarrative(l_DocSet)
    #$stderr.puts "#{l_DocSet}: #{l_Title} - #{l_Narrative}"

    l_arrSelected = []
    #selected_sid = []
    if l_JSON["summary"].nil? or l_JSON["summary"].length == 0 then
        l_JSON["summary"] = ""
        #l_JSON["summary_sid"] = ""
    else
        l_JSON["summary"].split("\n").each do |l_Line|
            l_arrSelected << l_Line 
        end
        #selected_sid = l_JSON["summary_sid"].strip.split
    end


    while l_JSON["summary"].split(/\s/).length < $g_CmdLineOptions[:maxlength] do
        l_BestMMR = -9999.0
        l_BestSentence = ""
        best_ID = nil
        l_JSON["SVR"].each do |l_RawScoreHash|

            # 1. Make use of MMR, calculate the scores for every sentence
            #    we come across
            l_ID = l_RawScoreHash[0]
            l_Score = l_RawScoreHash[1]

            #$stderr.puts "#{l_RawScoreHash}|#{l_ID}|#{l_Score}"
            # Retrieved the mapped doc and sentence IDs
            #l_MappedDocID, l_MappedSenID = l_RawScoreHash[l_ID.to_i()].split('_')
            l_MappedDocID = l_ID.split('_')[0].to_i()
            l_MappedSenID= l_ID.split('_')[1].to_i()
            l_CandidateSentence = l_JSON["splitted_sentences"][l_MappedDocID]["sentences"]["#{l_MappedSenID}"]

           
            # ###################################
            # Heuristics to quicken the process
            # i.e. skip sentences which we feel should not make it to the summary
            # Skip sentences that are too short to be informative
            if l_CandidateSentence.split.length < MIN_SENTENCE_LENGTH then
                next
            end
            # Skip sentences which are already in the selected sentence array or summary
            if (not l_arrSelected.index(l_CandidateSentence).nil?) or
               (not l_JSON["summary"].split("\n").index(l_CandidateSentence).nil?) then
                next
            end
            ######################################

            #$stderr.puts "Retrieved #{l_MappedDocID}_#{l_MappedSenID}: [#{l_Score}]  #{l_CandidateSentence}"

            # Calculate MMR 
            l_MMR = WINGSummarisation::SentenceSelection.CalculateMMR(l_CandidateSentence, l_Score, l_Title, l_Narrative, -1, l_arrSelected, which_set, set_A_sents)
        
            if l_MMR > l_BestMMR then
                l_BestMMR = l_MMR
                l_BestSentence = l_CandidateSentence
                best_ID = l_ID
            end
            

        end # End of l_JSON["zones"].each do
        
        #svr_scores.delete(best_ID)
        l_arrSelected << l_BestSentence
        if $g_CmdLineOptions[:reduction] then
            l_JSON["summary"] << WINGSummarisation::SentenceSelection.PerformSentenceReduction(l_BestSentence) + "\n"
        else
            l_JSON["summary"] << l_BestSentence + "\n"
        end
        #l_JSON["summary_sid"] << " " + best_ID
    end # end while


    $stdout.puts l_JSON.to_json

end

