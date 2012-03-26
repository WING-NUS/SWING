$LOAD_PATH.unshift(File.dirname(__FILE__) + '/..')
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../..')
require 'rubygems'
require 'pp'
require 'json'
require 'fileutils'
require 'lib/ptb_tokenizer'
require 'Input/WordSplitter'
require 'Input/StopList'
require 'lib/stemmable'
require 'getopt/std'

# Using the category_stats and category_bigram_stasts, score sentences based on various topic frequency and document frequency measures

#1) Topic Frequency score (tf): t/T (number of topics in which 'token' occurred/total topics (in category 'c')
#2) Category Document Frequency Score (cdfs): d/D (number of docs in which 'token' occurred/total docs (in category 'c')
#3) Category Relevance score(crs) : tf+cdfs 

#Praveen Bysani

opt = Getopt::Std.getopts("s:")
stat_file = opt['s']


ARGF.each do |l_JSN|
    l_JSON = JSON.parse l_JSN
    category = l_JSON['corpus'][0]["category"]
    
    s_file = File.read stat_file
    s_JSON = JSON.parse s_file

    l_topic_dfs_map = s_JSON["category_doc_freq"][category]
    l_topic_freq_map = s_JSON["category_topic_freq"][category]
    l_category_topics = s_JSON["category_topics"][category]

    $f_gfs={}
    stoplist= StopList.new
    l_SentenceScores=[]
    l_JSON["splitted_sentences"].each do |l_Article|
      l_Article["sentences"].each do |l_senid,l_sentence|
        tf_score = 0
        df_score = 0
        score =0
        words = word_breaker l_sentence.downcase
        
#To use unigram statistics in computing score

#=begin
        words.each do |word|
            if not stoplist.IsStopWord word
                word=word.stem
                tf_score += l_topic_freq_map[word] if l_topic_freq_map.has_key? word
                df_score += l_topic_dfs_map[word]  if l_topic_dfs_map.has_key? word
            end
        end
#=end

        score = 0.3*df_score + 0.7*tf_score
        score = score.to_f

        words_len = words.length > 0 ? words.length : 1
        #score = score/(l_category_topics.length*words_len)
        score = score/(l_category_topics.length*l_JSON["corpus"].length*words_len)
        $f_gfs["#{l_Article["doc_id"]}_#{l_senid}"]=score
      end
    end
    feature = { "gfs" => $f_gfs}
    l_JSON["features"].push feature
    puts l_JSON.to_json()
end
