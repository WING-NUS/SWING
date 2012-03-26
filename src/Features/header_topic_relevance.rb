#/usr/bin/rubyp
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/..')
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../..')

require 'rubygems'
require 'json'
require 'pp'
require '../lib/ptb_tokenizer'
require 'Input/WordSplitter'
require 'lib/stemmable'

#Computing similarity of each sentnce with the headline of that document
#Compute similarity of sentence with all the headlines in the cluster


def rouge2_similarity headline, sentence
    bigram_h = Hash.new(0)
    bigram_s = Hash.new(0)
    importance      = 0

    for i in 0..headline.length-2
        bigram_h[headline[i]+'_'+headline[i+1]] +=1
    end

    for i in 0..sentence.length-2
        bigram_s[sentence[i]+'_'+sentence[i+1]] +=1
    end
    (bigram_h.keys & bigram_s.keys).each do |k|
           importance += [bigram_h[k], bigram_s[k]].max
         end
    return importance
end

def rouge1_similarity headline,sentence
    unigram_h  = Hash.new(0)
    unigram_s  = Hash.new(0)
    importance = 0 
    for i in 0..headline.length-1
        unigram_h[headline[i]] +=1
    end
    for i in 0..sentence.length-1
        unigram_s[sentence[i]] +=1
    end
    (unigram_h.keys&unigram_s.keys).each do |k|
        importance += [unigram_s[k],unigram_h[k]].max
    end
    return importance
end

def jaccard_similarity headline, sentence
    headline_words = headline.uniq
    sent_words = sentence.uniq
    
    importance = (headline_words & sent_words).length.to_f/((headline_words | sent_words).length+1)
    return importance
end

ARGF.each do |l_JSN|
    l_JSON = JSON.parse l_JSN
    $f_headers = {}
    topic_text = l_JSON["corpus"][0]["topic_text"]
    topic_words = word_breaker topic_text.downcase
    
#=begin    
    header_words=[]
    l_JSON["splitted_sentences"].each do |l_Article|
            
            headline = l_Article["headline"]
            headline=headline.gsub(/\s+/, ' ').strip
            header_words.push word_breaker headline.downcase

    end
    header_words=header_words.flatten #headlines of all documents in cluster
    header_words = header_words.map{|w| w.stem}

#=end
    l_JSON["splitted_sentences"].each do |l_Article|

            headline = l_Article["headline"]
            headline=headline.gsub(/\s+/, ' ').strip
            l_header_words = word_breaker headline.downcase  #use only current document headline
            #l_header_words = l_header_words.map{|w| w.stem}

            headline = l_header_words.join(" ")
            #$stderr.puts "headline: #{headline}"
            l_Article["sentences"].each do |l_senid,l_sentence|
                sent_words = word_breaker l_sentence.downcase
                #sent_words = sent_words.map{|w| w.stem}
                
                score = rouge1_similarity header_words, sent_words
                sent_words.length > 0? word_len =sent_words.length : word_len=1
                score = score.to_f/word_len

                $f_headers["#{l_Article["doc_id"]}_#{l_senid}"]=score
            end
        end
    feature={"length"=>$f_headers}
    l_JSON["features"].push feature
    puts l_JSON.to_json()
end
