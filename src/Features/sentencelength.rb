#/usr/bin/ruby
require 'rubygems'
require 'json'
require 'pp'
require '../lib/ptb_tokenizer'

ARGF.each do |l_JSN|
    l_JSON = JSON.parse l_JSN
    $f_sp = {}
    l_JSON["splitted_sentences"].each do |l_Article|
        tot_sen = l_Article["sentences"].length
        l_Article["sentences"].each do |l_senid,l_sentence|
            len = l_sentence.strip.split.size
            $f_sp ["#{l_Article["doc_id"]}_#{l_senid}"] = len >= 10 ? 1 : 0
        end

    end
    feature={"length"=>$f_sp}
    l_JSON["features"].push feature
    puts l_JSON.to_json()
end
