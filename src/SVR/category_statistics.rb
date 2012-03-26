#!/usr/bin/ruby
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/..')
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../..')

### Praveen Bysani
require 'rubygems'
require 'pp'
require 'json'
require 'fileutils'
require 'lib/ptb_tokenizer'
require 'Input/WordSplitter'
require 'Input/StopList'
require 'lib/stemmable'
require 'getopt/std'
#require '../lib/ptb_tokenizer'
#require '../lib/stemmable'

class CategoryStatistics

#attr_accessor :$g_CM, :$g_CDM, :$g_TDMap, :$g_TWMap, $g_CTMap

def initialize
#########################################################
$g_CTMap ={}   #Key:category_id , value:topics in that category

$g_TWFMap = {} #key: topic_id, value: all unigrams in topic
$g_CTM ={}

$g_TDMap = {} #Key:topic_id, value: HashMap of DFS of topic (key:word value:dfs)
$g_CDM = {} #key:category_id, value:HashMap of doc frequencies in topic (key:word , value:number of docs in category in which word occurred)

$g_TWMap = {}  #Key:topic_id , value: unique unigrams in topic
$g_CM={} # Key:category_id , value: hashmap of topic frequencies (key:word, value:number of topics in which word occurred)
##########################################################

end

#################################################################################################
#Build TFS for each category
def build_category_tfs category_id
    l_ToFS={} #TFS map for category
    $g_CTMap.fetch(category_id).each do |topic_id|
        $g_TWMap.fetch(topic_id).each do |word|
            if l_ToFS.has_key? word
                tf = l_ToFS[word]
                tf = tf+1
                l_ToFS[word]=tf
            else
                l_ToFS[word]=1
            end
        end
    end
    $g_CM[category_id]= l_ToFS
end
### Build category term frequency for each category
def build_category_term_frequency category_id
    l_terFS={}
    $g_CTMap.fetch(category_id).each do |topic_id|
        $g_TWFMap.fetch(topic_id).keys.each do |word|
            if l_terFS.has_key? word
                l_terFS[word] += $g_TWFMap[topic_id].fetch(word)
            else
                
                l_terFS[word] = $g_TWFMap[topic_id].fetch(word)
            end
        end
    end
    $g_CTM[category_id] = l_terFS
end
def build_category_dfs category_id
    l_Cdfs={}
    $g_CTMap.fetch(category_id).each do |topic_id|
        $g_TDMap.fetch(topic_id).keys.each do |word|
           if l_Cdfs.has_key? word
                add_dfs=l_Cdfs[word]
                add_dfs = add_dfs+$g_TDMap.fetch(topic_id).fetch(word)
                l_Cdfs[word]=add_dfs
           else
               l_Cdfs[word]=$g_TDMap.fetch(topic_id).fetch(word)
           end 
        end
    end
    $g_CDM[category_id]=l_Cdfs
end

def build_topic_dfs_map ld_sentences, topic_id
    l_dfs ={}
    stoplist = StopList.new
    ld_sentences.each do |l_article|
        l_unigrams=[]
        l_article.each do |l_sentence|
            words = word_breaker l_sentence.downcase #downcase
            l_unigrams.push words
            end
        l_unigrams=l_unigrams.flatten.uniq

        l_unigrams.each do |word|
            if not stoplist.IsStopWord word
                word=word.stem #stemming
                if l_dfs.has_key? word
                    df = l_dfs[word]
                    df=df+1
                    l_dfs[word]=df
                else
                    l_dfs[word]=1
                end

            end
        end
    end
    $g_TDMap[topic_id] = l_dfs
end

#Mapping all the terms in a topic to the topic_id
def build_topic_word_map l_Sentences, topic_id
    l_unigrams=[]
    stoplist=StopList.new
    l_Sentences.each do |l_sentence|    
        words = word_breaker l_sentence.downcase  #wordbreaker for tokenizing
        l_unigrams.push words
     end
    l_unigrams=l_unigrams.flatten.uniq
    l_unigrams.each do |word|
      if not stoplist.IsStopWord word 
        word=word.stem #stemming
        
        #Building topic-> words map
        
        topic_words=[]
        topic_words=$g_TWMap[topic_id].to_a
        topic_words << word if not topic_words.include? word
        #topic_words << word 
        $g_TWMap[topic_id]=topic_words

        #$g_TWMap[topic_id] << word
        #############################
        end
    end
end

#Computing frequency of all the terms in a topic
def build_topic_word_frequency_map l_Sentences, topic_id
    l_tokens=[]
    l_wfs = {} 
    stoplist= StopList.new
    l_Sentences.each do |l_sentence|
        words = word_breaker l_sentence.downcase
        l_tokens.push words
    end
    l_tokens = l_tokens.flatten
    l_tokens.each do |token|
        if not stoplist.IsStopWord token
            token=token.stem
            if l_wfs.has_key? token
                l_wfs[token] += 1
            else
                l_wfs[token]=1
            end
        end
    end
    $g_TWFMap[topic_id]=l_wfs
end
#Mapping all the topics belonging to a category
def build_category_topic_map category, topic_id
        topics=[]
        topics = $g_CTMap[category].to_a
        topics << topic_id
        topics=topics.uniq
        $g_CTMap[category]=topics
end


def json_build_category_statistics train_dir, xml_file, which_set, use_clean_data

    $g_docs_dir = train_dir
    #$g_cluster = opt['w']
    $g_xml = xml_file
    $g_topics = Dir.glob($g_docs_dir+'/*/*-'+which_set).sort #change cluster to B
    

    $g_topics.each do |l_topic|
        str = use_clean_data ? `ruby Input/ProcessCleanDocs.rb -s #{l_topic} -x #{$g_xml}` :
            `ruby Input/ProcessTACTestDocs.rb -s #{l_topic} -x #{$g_xml} | ruby Input/SentenceSplitter.rb`
        l_JSON = JSON.parse str
        category = l_JSON['corpus'][0]["category"]
        topic_id = l_JSON['corpus'][0]["docset"].slice 0..-3
        build_category_topic_map category,topic_id

        lt_Sentences = []
        ld_Sentences = []
        l_JSON["splitted_sentences"].each do |l_Article|
            ld_Sentences=l_Article["sentences"].values
            lt_Sentences.push ld_Sentences
       end
       build_topic_dfs_map lt_Sentences, topic_id

       lt_flatten = lt_Sentences.flatten
       build_topic_word_map lt_flatten, topic_id
       build_topic_word_frequency_map lt_flatten, topic_id
    end


    $g_CTMap.keys.each do |category|
        build_category_tfs category
        build_category_dfs category
        build_category_term_frequency category
    end 



    $g_JSON = { "category_topic_freq"=>$g_CM , "category_doc_freq"=>$g_CDM,"category_term_freq"=>$g_CTM,"category_topics"=>$g_CTMap}

    stat_file = '../data/category_stats'
    fw = File.open stat_file,'w'
    fw.puts JSON.generate $g_JSON
    fw.close
    return stat_file
    #puts JSON.generate($g_JSON)
end
###############################################################################################
end
