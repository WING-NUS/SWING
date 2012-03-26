#/usr/bin/ruby


## Praveen Bysani

#$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../..') unless $LOAD_PATH.include?(File.dirname(__FILE__) + '/..')
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

$g_DFS={}
$g_DFS_U={}
def build_dfs sentence_list
    l_unigrams=[]
    sentence_list.each do |l_sentence|
        words= word_breaker l_sentence.downcase
        words.each do |word|
            l_unigrams.push word
        end
    end
    l_unigrams = l_unigrams.uniq
    l_unigrams.each do |unigram|
        unigram= unigram.stem
        if $g_DFS_U.has_key? unigram
            $g_DFS_U[unigram] += 1
        else
            $g_DFS_U[unigram]=1
         end

   end
end

def build_dfs_bigram sentence_list
    l_bigrams=[]
    stoplist = StopList.new #Stop Words
    sentence_list.each do |l_sentence|
        words = word_breaker l_sentence.downcase  #wordbreaker for tokenizing
        words_stem = words.map {|w| w.stem}   #stemmed words for bigrams

        words_stem_stop = Array.new #removing stopwords
        words_stem.each do |word|
            words_stem_stop.push(word) if not stoplist.IsStopWord word
        end
        
        for i in 0..words_stem.length-2 
            bigram = words_stem[i]+"_"+words_stem[i+1]
            l_bigrams.push bigram
        end
    end
    #for i in 0..l_unigrams.length-1
    #    l_unigrams[i]=l_unigrams[i].stem
    #end

   l_bigrams= l_bigrams.uniq #reason for incorrect computation
   
   l_bigrams.each do |stem_bigram|
       if $g_DFS.has_key? stem_bigram 
           df = $g_DFS[stem_bigram]
           df+=1
           $g_DFS[stem_bigram]=df
        else
            $g_DFS[stem_bigram]=1
        end
   end
end
ARGF.each do |l_JSN|
    l_JSON = JSON.parse l_JSN
    $f_dfs={}
    stoplist = StopList.new #Stop Words
    #Build DFS score for each word
    l_topic_sentences=[]
    l_JSON["splitted_sentences"].each do |l_Article|
 
       l_Sentences=l_Article["sentences"].values
       build_dfs_bigram l_Sentences
       build_dfs l_Sentences
    end

    #Calculate DFS feature score for each sentence

    l_SentenceScores=[]
    l_JSON["splitted_sentences"].each do |l_Article|
      l_Article["sentences"].each do |l_senid,l_sentence| 
        score_bi=0
        score_uni=0
        score=0
        #######
        #l_sentence=stoplist.filter(PTBTokenizer.tokenize(l_sentence).strip)
        #words = l_sentence.downcase.split  #wordbreaker for tokenizing
        words = word_breaker l_sentence.downcase #using word_breaker in Input/WordSplitter for tokenization #use ptb_tokenizer instead

        words_stem = words.map {|w| w.stem}   

        words_stem_stop = Array.new
        words_stem.each do |word|
            words_stem_stop.push(word) if not stoplist.IsStopWord word
        end
        
        for i in 0..words_stem.length-2
            bigram = words_stem[i]+"_"+words_stem[i+1]
            score_bi += $g_DFS[bigram]
        end
##Unigram Smoothing
        for i in 0..words_stem_stop.length-1
            score_uni += $g_DFS_U[words_stem_stop[i]]
        end
#############
        score = 0.7*score_bi+0.3*score_uni
        score = score.to_f
        words_len = words.length > 0 ? words.length : 1
        score = score/(l_JSON["corpus"].length*words_len)
        $f_dfs["#{l_Article["doc_id"]}_#{l_senid}"]=score
        end
    end
    feature = { "dfs_bigram" => $f_dfs}
    l_JSON["features"].push feature
   puts l_JSON.to_json()

end

$g_DFS.keys.each do |key|
   # puts "#{key} #{$g_DFS.fetch(key)}"
end
