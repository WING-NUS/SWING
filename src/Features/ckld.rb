#!/usr/bin/ruby

#KL Divergence of a word across probability distribution in C (current category) across all categories (C^)
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

    l_topic_termfs_map = s_JSON["category_term_freq"][category] 

    l_category_topics = s_JSON["category_topics"][category]

    l_cluster_termfs_map = s_JSON["category_term_freq"] 



    l_total_c_count=0
    l_total_count=0
    #computing total frequency of category
    l_all_terms= l_topic_termfs_map.values
    l_all_terms.each do |value|
        l_total_c_count += value
    end
    #computing total frequency of all terms in all categories
    l_cluster_termfs_map.keys.each do |category|
        l_category_termfs=l_cluster_termfs_map[category]
        l_all_terms= l_category_termfs.values
        l_all_terms.each do |value|
            l_total_count +=value
         end

    end

    l_total_count_n = (l_total_count-l_total_c_count)+1

    l_JSON["splitted_sentences"].each do |l_Article|
        l_Article["sentences"].each do |l_senid, l_sentence|
            score =0
            norm_score=0
            words = word_breaker l_sentence.downcase
            words.each do |word|
                if not stoplist.IsStopWord word
                    word = word.stem
                    
                    term_cf=1
                    term_cf= l_topic_termfs_map[word] if l_topic_termfs_map.has_key? word

                    term_TCF = 1 
                    l_cluster_termfs_map.keys.each do |category|
                        l_category_termfs = l_cluster_termfs_map[category]
                        if l_category_termfs.has_key? word
                            term_TCF += l_category_termfs[word] 
                        end
                     end

                    term_TCF = (term_TCF-term_cf)+0.001

                    p_c  = term_cf.to_f/l_total_c_count.to_f
                    p_rc = term_TCF.to_f/l_total_count_n.to_f
                    kld_w = p_c*(Math.log(1+p_c/p_rc)/Math.log(2))
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

