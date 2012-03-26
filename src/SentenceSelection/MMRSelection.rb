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
require File.dirname(__FILE__)+'/../SVR/importance'


module WINGSummarisation
    module SentenceSelection

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

def SentenceSelection.CalculateMMR(a_Sentence, a_SentenceRelevance, a_Title, a_Narrative, a_ZoneIndex, a_arrSelected)
    
    # Compute Sim1
    # TODO
#   l_Sim1 = 0.0
#   l_Bag = {}
#   a_Title.split(' ').each do |l_Term|
#       if not l_Bag.has_key?(l_Term) then
#           l_Bag[l_Term] = 0
#       end
#   end
#   a_Narrative.split(' ').each do |l_Term|
#       if not l_Bag.has_key?(l_Term) then
#           l_Bag[l_Term] = 0
#       end
#   end
#   l_VectorQuery = {}
#   l_VectorQuery = l_VectorQuery.replace(l_Bag)
#   l_VectorQuery = PopulateVector(l_VectorQuery, a_Sentence)
#   l_VectorTopic = {}
#   l_VectorTopic = l_VectorTopic.replace(l_Bag)
#   l_VectorTopic = PopulateVector(l_VectorTopic, a_Title + " " + a_Narrative)
#   l_Sim1 = ComputeCosim(l_VectorQuery, l_VectorTopic)


    if a_Sentence == nil then
        return 0.0
    end

    # Make use of pre-computed sentence relevance score
    l_Sim1 = a_SentenceRelevance


=begin
    # Compute Sim2
    # Collect all terms in a_arrSeleted
    l_Bag = {}
    a_arrSelected.each do |l_Sentence|
        l_Sentence.split(' ').each do |l_Term|
            if not l_Bag.has_key?(l_Term) then
               l_Bag[l_Term] = 0  
            end
        end
    end
    if not a_Sentence == nil then
        a_Sentence.split(' ').each do |l_Term|
            if not l_Bag.has_key?(l_Term) then
                l_Bag[l_Term] = 0
            end
        end
    end

    # Form vectors for query sentence and each already selected sentence
    l_VectorQuery = {}
    l_VectorQuery = l_VectorQuery.replace(l_Bag)
    l_VectorQuery = PopulateVector(l_VectorQuery, a_Sentence)
    # Compute cosine sim between vector of query sentence, and each
    # of the other already selected sentences
    l_MaxSim2 = 0.0
    a_arrSelected.each do |l_Sentence|
        l_VectorSentence = {}
        l_VectorSentence = l_VectorSentence.replace(l_Bag)
        l_VectorSentence = PopulateVector(l_VectorSentence, l_Sentence)
        #$stderr.puts l_VectorSentence
        l_CurSim = ComputeCosim(l_VectorQuery, l_VectorSentence)
        #$stderr.puts "#{l_CurSim}:#{l_MaxSim2}\n"
        if l_CurSim > l_MaxSim2 then
            l_MaxSim2 = l_CurSim
        end
    end
=end

    l_Sim2 = 0.0
    if a_arrSelected.size > 0 then
        l_Sim2 = calc_sent_importance([a_arrSelected], a_Sentence) 
    end
    #a_arrSelected.each do |l_Sentence|
        #r2 = calc_sent_importance([[a_Sentence]], l_Sentence)
        ##if r2 > l_MaxSim2 then
        ##    l_MaxSim2 = r2
        ##end
        #l_MaxSim2 += r2 
    #end

    # We want to find and return the diff between Sim1 and max(all Sim2)
    res = l_Sim1 - l_Sim2

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
   
    #l_RankedSentences = l_JSON["sentences_ranked"]
    l_DocSet = l_JSON["corpus"][0]["docset"]

    # Retrieve topic
    l_Title = WINGSummarisation::SentenceSelection.GetTopicTitle(l_DocSet)
    l_Narrative = WINGSummarisation::SentenceSelection.GetTopicNarrative(l_DocSet)
    #$stderr.puts "#{l_DocSet}: #{l_Title} - #{l_Narrative}"

    l_JSON["summary"] = ""

    l_arrSelected = []
    # Do until length of summary is met
    # while length is ok
    while l_JSON["summary"].split(/\s/).length < 100 do
        l_BestMMR = -9999.0
        l_BestSentence = ""
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
            
            #$stderr.puts "Retrieved #{l_MappedDocID}_#{l_MappedSenID}: [#{l_Score}]  #{l_CandidateSentence}"

            # Calculate MMR 
            l_MMR = WINGSummarisation::SentenceSelection.CalculateMMR(l_CandidateSentence, l_Score, l_Title, l_Narrative, -1, l_arrSelected)
        
            if l_MMR > l_BestMMR then
                l_BestMMR = l_MMR
                l_BestSentence = l_CandidateSentence
            end
            

        end # End of l_JSON["zones"].each do
        l_arrSelected << l_BestSentence
        l_JSON["summary"] << l_BestSentence + "\n"
    end # end while

    l_JSON["summary_title"] = l_Title
    l_JSON["summary_narrative"] = l_Narrative

    $stdout.puts l_JSON.to_json
    #$stdout.puts l_arrSelected

end

