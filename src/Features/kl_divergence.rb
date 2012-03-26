#/usr/bin/ruby

#
# Authored by: Ng, Jun Ping junping@comp.nus.edu.sg
# Date: 28 Apr 2011
#

# This feature is based on that used by IIIT Hyderabad
# First there is a reference corpus (web base is used)
# We cluster terms with similar distributions (measured by KL-Divergence)
# together
# Then we process the target doc set and do a similar clustering
# of the terms inside the docset
# Then we make use of the Naive Bayes formula given by IIIT
# to compute the score of a sentence.
# In computing the formula, a simplifying assumption I made is 
# to make use of a unigram language model to compute the prior
# probability P(D) of the doc set, and P(D_CAP) of the reference 
# corpus
# And because of this assumption, the prior probabilities are cancelled
# out of the equation and what remains are the conditional
# probabilities, i.e.
# Score of sentence S = \forall s \in S P(s|D) / ( P(s|D) + P(d|D_CAP))
#
# The computed, clustered distribution is produced by 
#  HelperNonPipeline/compute_reference_distribution_for_kld.rb
# and is stored in the file web_base_computed 
#


require 'rubygems'
require 'json'
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../..') unless $LOAD_PATH.include?(File.dirname(__FILE__) + '/..')
#$LOAD_PATH.unshift(File.dirname(__FILE__) + '/..')
#$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../..')

$g_REFCORPUS = File.dirname(__FILE__) + "/" + "web_base_computed"

# Based on the work of McCallum and Baker 1998
# Cluster words with similar frequencies together
# and returns the resulting distribution
# @param a_Text [in] the input text
def ReturnClusteredFrequency(a_Text)


    l_Time1 = Time.new

    # 1. Split up text into unigrams
    l_FrequencyCount = {}
    a_Text.split(' ').each do |l_Word|
        if not l_FrequencyCount.has_key?(l_Word) then
            l_FrequencyCount[l_Word] = 0
        end
        l_FrequencyCount[l_Word] += 1
    end

    #$stderr.puts "Loaded #{l_FrequencyCount.length} words..."
    
    # Total word counts
    l_TotalFreq = 0.0
    l_FrequencyCount.each_value do |l_Freq|
        l_TotalFreq += l_Freq
    end

    # Need to split up into 1,000 clusters perhaps, word by word
    # And compute the KLD between each cluter until all words are
    # assigned to some cluster
    l_TotalClusters = 8000
    l_WordClusters = []
    l_WordsToCluster = {}
    l_FrequencyCount.each_key do |l_Word|
        if l_WordClusters.length < l_TotalClusters then
            l_WordClusters << l_FrequencyCount[l_Word]
            l_WordsToCluster[l_Word] = l_WordClusters.length-1
            #$stderr.puts "Assigning #{l_Word} to cluster #{l_WordClusters.length-1}"
        else
            # Clusters are full, we'd try to merge an existing one
            # before adding the new word in
            # 1. Find "similar" words - which can be approximated by
            #    the smallest differences between their frequency
            # 2. Merge the similar words - and average out their frequencies
            l_SmallestDiff = 10000000
            l_Smallest1 = -1
            l_Smallest2 = -1
            (0..l_WordClusters.length-1).each do |l_Index1|
                (1..l_WordClusters.length-1).each do |l_Index2|
                    #l_CurrDiff = (l_WordClusters[l_Index1] - l_WordClusters[l_Index2]).abs
                    # Calculate the KL-Divergence between both word distributions
                    l_P_Word1 = l_WordClusters[l_Index1] / (l_TotalFreq * 1.0)
                    l_P_Not_Word1 = (l_TotalFreq - l_WordClusters[l_Index1]) / (l_TotalFreq * 1.0)
                    l_P_Word2 = l_WordClusters[l_Index2] / (l_TotalFreq * 1.0)
                    l_P_Not_Word2 = (l_TotalFreq - l_WordClusters[l_Index2]) / (l_TotalFreq * 1.0)
                    l_KLD_12 = l_P_Word1 * Math.log(l_P_Word1/l_P_Word2) + l_P_Not_Word1 * Math.log(l_P_Not_Word1/l_P_Not_Word2)
                    l_KLD_21 = l_P_Word2 * Math.log(l_P_Word2/l_P_Word1) + l_P_Not_Word2 * Math.log(l_P_Not_Word2/l_P_Not_Word1)
                    l_CurrDiff = (l_KLD_12 + l_KLD_21) / 2
                    if l_CurrDiff.abs < l_SmallestDiff and l_Index1 != l_Index2 then
                        l_SmallestDiff = l_CurrDiff.abs
                        l_Smallest1 = l_Index1
                        l_Smallest2 = l_Index2
                    end
                end
            end
            #$stderr.puts "Merging #{l_Smallest1}|#{l_WordClusters[l_Smallest1]} with #{l_Smallest2}|#{l_WordClusters[l_Smallest2]} - #{l_SmallestDiff}"
            l_WordClusters[l_Smallest1] = (l_WordClusters[l_Smallest1] + l_WordClusters[l_Smallest2]) / 2
            l_WordsToCluster.each_key do |l_Key|
                l_WordsToCluster[l_Key] = l_Smallest1 if l_WordsToCluster[l_Key] == l_Smallest2
            end
            l_WordClusters[l_Smallest2] = l_FrequencyCount[l_Word]
            l_WordsToCluster[l_Word] = l_Smallest2
            #$stderr.puts "Inserting #{l_Word} to cluster #{l_Smallest2}"
        end
    end

    l_Time2 = Time.new

    # Generate results

    (0..l_WordClusters.length-1).each do |l_Index|
        l_WordClusters[l_Index] = l_WordClusters[l_Index] / l_TotalFreq
    end

    l_Time3 = Time.new

    #$stderr.puts "Times: #{l_Time1} - #{l_Time2} - #{l_Time3}"

    l_Result = {}
    l_Result["words_hash"] = l_WordsToCluster
    l_Result["distribution"] = l_WordClusters

    l_Result

end



def ConvertToWordHashTable(l_RawDistribution) 

    l_Result = {}
    l_RawDistribution.each do |l_WordRec|
        l_WordRec["words"].each do |l_Word|
            l_Result["#{l_Word}"] = l_WordRec["frequency"] if not l_Result.has_key?(l_Word)
        end
    end

    l_Result

end


def SumUpTotalFrequencies(a_FreqDist)

    l_Sum = 0
    #$stderr.puts "Summing up..."
    a_FreqDist.each_value do |l_Value|
        l_Sum += l_Value
    end
    l_Sum

end


#$stderr.puts "Processing reference corpus..."

# Read in the reference corpus distribution first
$g_REF_DISTRO = {}
File.open($g_REFCORPUS) do |l_File|
    l_Line = l_File.readline()
    l_Ref_JSON = JSON.parse(l_Line)
    $g_REF_DISTRO = ConvertToWordHashTable(l_Ref_JSON)
end

#$stderr.puts "Processing stdin..."

# Start processing input sentences
ARGF.each do |l_JSON|


    l_JSON = JSON.parse(l_JSON)
    
    # 0. We need to collect the distribution of words in a random document set
    #    For this we will make use of the web base collection
    # 1. Then we need to collect the distribution of words in each document set
    l_TextCollection = {}
    l_JSON["corpus"].each do |l_Article|
        l_DocSetID = l_Article["docset"]
        if not l_TextCollection.has_key?(l_DocSetID) then
            l_TextCollection[l_DocSetID] = ""
            #$stderr.puts "Initializing #{l_DocSetID}"
        end
        #$stderr.puts "Adding to #{l_DocSetID}"
        l_TextCollection[l_DocSetID] += l_Article["text"]
    end

    #$stderr.puts "Collected doc text...#{l_TextCollection.length} doc sets."

    # 2. Then for each document set, compute a score for sentences within
    #     based on the KL_Divergence of the 2 diff distributions for 
    #     component words

    l_SampleDistributions = {}
    l_TextCollection.each_key do |l_DocSet|

        #$stderr.puts "Processing DocSet #{l_DocSet}...\n#{l_TextCollection[l_DocSet]}"
        l_Result = ReturnClusteredFrequency(l_TextCollection[l_DocSet])
        
        l_Result_P = []
        (0..l_Result['distribution'].length-1).each do |l_Index|
            l_Item = {}
            l_Item["frequency"] = l_Result['distribution'][l_Index]

            l_Item["words"] = []
            l_Result['words_hash'].each_key do |l_Word|
                if l_Result['words_hash'][l_Word] == l_Index then
                    l_Item["words"] << l_Word
                end
            end

            l_Result_P << l_Item
        end

        l_SampleDistributions[l_DocSet] = ConvertToWordHashTable(l_Result_P)

        # Compute score for each sentence in the docset
        #l_JSON["corpus"].each do |l_Article|
        #    if l_Article["docset"] == l_DocSet then
        #        
        #        l_Text = l_Article["text"]
        #        # Break up text into sentences
        #        
        #
        #        # Score each sentence and place in output JSON
        #
        #    end
        #end    

    end

    #$stderr.puts "Converted doc set distribution..."

    # Go through each sentence and score them
    l_ScoredSentences = {}
    l_JSON["splitted_sentences"].each do |l_SentenceRecords|

        l_DocID = l_SentenceRecords["actual_doc_id"]
        l_DocSet = l_SentenceRecords["docset"]
        #$stderr.puts "Processing DocSet #{l_DocSet}..."
        l_SentenceRecords["sentences"].each do |l_SentenceNum, l_Sentence|
        
            l_Score = 0 # Count score
            l_WordsArray = l_Sentence.split
            l_P_D = 1.0
            l_P_D_CAP = 1.0
            l_P_W_D = 1.0
            l_P_W_D_CAP = 1.0
            l_P_TOTAL_D = SumUpTotalFrequencies(l_SampleDistributions[l_DocSet])
            l_P_TOTAL_D_CAP = SumUpTotalFrequencies($g_REF_DISTRO)
            l_WordsArray.each do |l_Word|
                #P_D *= $g_REF_DISTRO[l_Word] / P_TOTAL_D_CAP
                #P_D_CAP *= $g_REF_DISTRO[l_Word] / P_TOTAL_D_CAP
                if l_SampleDistributions[l_DocSet].has_key?(l_Word) then
                    l_P_W_D = l_P_W_D * ( l_SampleDistributions[l_DocSet][l_Word] / l_P_TOTAL_D )
                end
                if $g_REF_DISTRO.has_key?(l_Word) then
                    l_P_W_D_CAP = l_P_W_D_CAP * ( $g_REF_DISTRO[l_Word] / l_P_TOTAL_D_CAP )
                end
            end
            # In some rare cases the score may turn up as 1 
            # if the sentence has only OOV words
            l_Score = l_P_W_D / (l_P_W_D + l_P_W_D_CAP)
            if l_Score.nan? then 
                l_Score = 0.0
            end
            l_ScoredSentences["#{l_SentenceRecords["doc_id"]}_#{l_SentenceNum}"] = l_Score
        end
    end

    #$stderr.puts "Scored sentences."

    l_JSON["features"].push( {"kld" => l_ScoredSentences} )
   $stdout.puts l_JSON.to_json()

end

