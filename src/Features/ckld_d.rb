#!/usr/bin/ruby

#KL Divergence of a word across probability distribution in C (current category) across all categories (C^) 
#in terms of document frequencies rather than term frequencies for each word

#Praveen Bysani

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/..')
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../..')

require 'rubygems'
require 'pp'
require 'json'
require 'fileutils'
require 'Input/WordSplitter'
require 'Input/StopList'
require 'lib/stemmable'
require 'getopt/std'

opt = Getopt::Std.getopts("s:")
stat_file = opt['s']

ARGF.each do |l_JSN|
    
    l_JSON = JSON.parse l_JSN
    s_JSON = JSON.parse(File.read stat_file)
    
    $f_ckld = {}
    stoplist = StopList.new

    category = l_JSON['corpus'][0]['category']

    l_topic_dfs_map = s_JSON["category_doc_freq"][category] #change to terms

    l_category_topics = s_JSON["category_topics"][category]
    
    l_cluster_topics = s_JSON["category_topics"]
    l_cluster_dfs_map = s_JSON["category_doc_freq"] #change to terms



    topic_c_docs=0
    topic_docs=0

    topic_c_docs = l_category_topics.length*10
    l_cluster_topics.keys.each do |category|
        l_category_topics = l_cluster_topics[category]
        topic_docs += l_category_topics.length
    end
    topic_docs = topic_docs*10


    l_JSON["splitted_sentences"].each do |l_Article|
        l_Article["sentences"].each do |l_senid, l_sentence|
            score =0
            norm_score=0
            words = word_breaker l_sentence.downcase
            words.each do |word|
                if not stoplist.IsStopWord word
                    word = word.stem
                    
                    term_df= l_topic_dfs_map[word]

                    term_DCF = 0 
                    l_cluster_dfs_map.keys.each do |category|
                        l_category_dfs = l_cluster_dfs_map[category]
                        if l_category_dfs.has_key? word
                            term_DCF += l_category_dfs[word]
                        end
                     end

                    #term_DCF = (term_DCF-term_df)+0.001

                    p_c  = term_df.to_f/topic_c_docs.to_f
                    p_rc = term_DCF.to_f/topic_docs.to_f
                    kld_w = p_c*(Math.log10(p_c/p_rc))
                    score += kld_w
                    #norm_score += kld_w*kld_w
                end
             end
            score = score.to_f
            words_len = words.length > 0 ? words.length : 1
            #norm_score = norm_score > 0 ? norm_score : 1
            score = score/words_len
            $f_ckld["#{l_Article["doc_id"]}_#{l_senid}"]=score
            
      end
    end
    feature = {"ckld" => $f_ckld}
    l_JSON["features"].push feature
    puts l_JSON.to_json()
end

