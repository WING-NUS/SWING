#/usr/bin/ruby
require 'rubygems'
require 'json'
require 'pp'
## Praveen Bysani
ARGF.each do |l_JSN|
    l_JSON = JSON.parse l_JSN
    $f_sp = {}
    l_JSON["splitted_sentences"].each do |l_Article|
        tot_sen = l_Article["sentences"].length
        l_Article["sentences"].each do |l_senid,l_sentence|
            score =0.0    
            sen_pos = l_senid.to_i+1
            #case l_senid.to_i
            #when 0
            #    score=0.9
            #when 1
            #    score=0.8
            #when 2 
            #    score=0.7
            #else
            #    score=0.5
            #end
            score = (tot_sen - sen_pos +1).to_f/tot_sen.to_f
          $f_sp ["#{l_Article["doc_id"]}_#{l_senid}"]=score
        end

    end
    feature={"sp"=>$f_sp}
    l_JSON["features"].push feature
    puts l_JSON.to_json()
end
