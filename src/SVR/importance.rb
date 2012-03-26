#!/usr/bin/ruby
### ziheng

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/..')
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../..')
require 'rubygems'
require 'pp'
require 'json'
require 'fileutils'
require 'getopt/std'
require '../lib/ptb_tokenizer'
require '../lib/stemmable'
require 'Input/StopList'
#$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../..') unless $LOAD_PATH.include?(File.dirname(__FILE__) + '/..')

def sentence_breaker(text)
    temp_file = '/tmp/temp.'+rand.to_s
    File.open(temp_file, 'w') do |f|
        f.puts text
    end
    `#{File.dirname(__FILE__)}/../../lib/duc2003.breakSent/breakSent-multi.pl #{temp_file}`
    lines=File.readlines temp_file
    FileUtils.rm(temp_file)
    return lines
end

def calc_sent_importance(models, s)
    bigram_m = Hash.new(0)
    bigram_s = Hash.new(0)

    s_stems = s.downcase.split.map {|w| w.stem} 
    s_len = s_stems.size
    return 0.0 if s_len == 0
    0.step(s_stems.size-2) do |i| 
        bigram_s[s_stems[i]+'_'+s_stems[i+1]] += 1
    end

    models.each do |m|
        m.each do |s1|
            s_stems = s1.downcase.split.map {|w| w.stem} 
            0.step(s_stems.size-2) do |i| 
                bigram_m[s_stems[i]+'_'+s_stems[i+1]] += 1
            end
        end
    end
    sum = 0
    (bigram_m.keys & bigram_s.keys).each do |k|
        sum += [bigram_m[k], bigram_s[k]].max
    end
    importance = sum * 1.0 / s_len
    importance
end

def calc_sent_importance_SU4(models, s)
    bigram_m = Hash.new(0)
    bigram_s = Hash.new(0)

    s_stems = s.downcase.split.map {|w| w.stem} 
    s_stems.unshift('START')
    return 0.0 if s_stems.size == 0
    comb_len = 0
    0.step(s_stems.size>=5 ? s_stems.size-5 : 0) do |j|
        sub_arr = s_stems[j..(j+5)]
        comb = generate_combination(sub_arr)
        comb_len = comb.size
        comb.each do |b|
            bigram_s[b] += 1
        end
    end
    return 0.0 if comb_len == 0

    comb_len2 = 0
    models.each do |m|
        m.each do |s1|
            s_stems = s1.downcase.split.map {|w| w.stem} 
            s_stems.unshift('START')
            0.step(s_stems.size>=5 ? s_stems.size-5 : 0) do |j|
                sub_arr = s_stems[j..(j+5)]
                comb = generate_combination(sub_arr)
                comb_len2 += comb.size
                comb.each do |b|
                    bigram_m[b] += 1
                end
            end
        end
    end
    sum = 0
    (bigram_m.keys & bigram_s.keys).each do |k|
        sum += [bigram_m[k], bigram_s[k]].max
    end
    importance = sum * 1.0 / comb_len
    importance
end

def generate_combination(arr)
    comb = []
    0.step(arr.size-2) do |i|
        (i+1).step(arr.size-1) do |j|
            comb << arr[i]+'_'+arr[j]
        end
    end
    comb
end

if __FILE__ == $0 then
    opt = Getopt::Std.getopts("m:")
    if opt["m"] then
        model_dir = opt["m"]
    else
        puts 'please provide model directory'
        exit
    end

    stoplist = StopList.new

    ARGF.each do |l_JSN|
        l_JSON = JSON.parse l_JSN
        importances = {}
        id = l_JSON['corpus'][0]['docset'].sub(/[A-Z]-/, '-')
        models = []
        Dir.glob("#{model_dir}/#{id}*").each do |fn|
            sents = []
            sentence_breaker(File.readlines(fn).join).each do |s|
                sents << stoplist.filter(PTBTokenizer.tokenize(s).strip)
                #sents << s
            end
            models << sents
        end

        l_SentenceScores=[]
        l_JSON["splitted_sentences"].each do |l_Article|
            l_Article["sentences"].each do |l_senid, l_sentence| 
                importances["#{l_Article["doc_id"]}_#{l_senid}"] = calc_sent_importance(models, stoplist.filter(PTBTokenizer.tokenize(l_sentence).strip)) 
                #importances["#{l_Article["doc_id"]}_#{l_senid}"] = calc_sent_importance(models, l_sentence)
            end
        end
        l_JSON["importances"] = importances
        puts l_JSON.to_json()
    end
end
