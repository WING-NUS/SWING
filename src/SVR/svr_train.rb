#!/usr/bin/ruby

### Ziheng
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/..')
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../..')
require 'rubygems'
require 'pp'
require 'json'
require 'fileutils'
require 'getopt/std'
require 'lib/ptb_tokenizer'
require 'Input/WordSplitter'
require 'Input/StopList'
require 'lib/stemmable'
require 'SVR/category_statistics' #unigram stats over collection
#require '../lib/ptb_tokenizer'
#require '../lib/stemmable'

Use_svm_light = true

def print_instances(dir, model_dir, to_file, which_set,xml_file)

    l_use_clean_data = true
    
    ## Computing Category statistics for guided summarization
    cat_stat = CategoryStatistics.new 
    stat_file=cat_stat.json_build_category_statistics dir, xml_file, which_set, l_use_clean_data ##

    #cat_stat = CategoryBigramStatistics.new 
    #stat_file=cat_stat.json_build_category_bigram_statistics dir, xml_file ##

    fh = File.open(to_file, 'w') 
    sets = Dir.glob(dir+'/*/*-'+which_set).sort
    set_cnt = 1
    sets.each do |set_id|
        puts set_cnt.to_s + ' ' + set_id
        set_cnt += 1

        #| ruby Features/gfs.rb -s #{stat_file} \
        #| ruby Features/ckld_d.rb -s #{stat_file} \
        #| ruby Features/rf.rb -s #{stat_file} \
        #| ruby Features/header_topic_relevance.rb \
        #| ruby Features/number_identifier.rb \
        #| ruby Features/contains_location.rb \
        #| ruby Features/contains_person.rb \
        #| ruby Features/kl_divergence.rb \
        #| ruby Input/GetStanfordNERParse.rb \

        #Make sure the order of Features are same in svr_test_all

        cmd_process_data = l_use_clean_data ? "ruby Input/ProcessCleanDocs.rb -s #{set_id} -x #{xml_file}" :
            "ruby Input/ProcessTACTestDocs.rb -s #{set_id} -x #{xml_file} | ruby Input/SentenceSplitter.rb"

        str = `cd #{File.dirname(__FILE__)}/..; \
        #{cmd_process_data} \
        | ruby Features/dfs_bigram.rb \
        | ruby Features/sentenceposition.rb \
        | ruby Features/sentencelength.rb \
        | ruby Features/gfs.rb -s #{stat_file} \
        | ruby Features/ckld_d.rb -s #{stat_file} \
        | ruby SVR/importance.rb -m #{model_dir}`

        #$stderr.puts "#{str}\n"

        l_JSON = JSON.parse(str)
        l_JSON['importances'].keys.sort_by {|a| a.split('_').map {|e| e.to_i}} .each do |id|
            instance = l_JSON['importances'][id].to_s
            cnt = 1
            l_JSON['features'].each do |feat|
                feat.each do |feat_name, feat_values|
                    #instance << " #{cnt}:#{feat_values[id]}" if feat_values[id] != 0
                    instance << " #{cnt}:#{feat_values[id]}"
                end
                cnt += 1
            end
            fh.puts instance
        end

        
       if which_set == "A" then
           set_A_fh = File.open("../eval/set_A_text/"+File.basename(set_id), 'w')
           l_JSON["splitted_sentences"].each do |l_Article|
               l_Article["sentences"].sort {|a,b| a[0].to_i<=>b[0].to_i} .each do |l_senid, l_sentence| 
                   set_A_fh.puts "#{l_Article["doc_id"]}_#{l_senid}\t" + l_JSON['importances']["#{l_Article["doc_id"]}_#{l_senid}"].to_s + "\t" + l_sentence 
               end
           end
           set_A_fh.close
       end

    end
    fh.close
end

def svr_train(train_dir, model_dir, model_file, which_set,xml_file)
    train_file = model_file.match(/\.model$/) ? model_file.sub(/\.model$/, '.train') : model_file+'.train'
    print_instances(train_dir, model_dir, train_file, which_set,xml_file)
    if Use_svm_light then
        svm_dir = File.dirname(__FILE__)+'/../../lib/svm_light'
        `#{svm_dir}/svm_learn -z r -t 2 #{train_file} #{model_file} 1>&2`
    else
        svm_dir = File.dirname(__FILE__)+'/../../lib/libsvm-3.1'
        `#{svm_dir}/svm-train -s 4 #{train_file} #{model_file} 1>&2`
    end
end



if __FILE__ == $0 then
    opt = Getopt::Std.getopts("t:m:f:w:x:")
    train_dir = opt["t"]
    model_dir = opt["m"]
    model_file = opt["f"]
    which_set = opt["w"]
    xml_file = opt["x"]
    if train_dir == nil or model_dir == nil or model_file == nil or which_set == nil or xml_file == nil then
        puts "usage: #{__FILE__} -t training-directory -m model-summary-directory -f model-file -w A|B"
        exit
    end
    if which_set != 'A' and which_set != 'B' then
        #puts "usage: #{__FILE__} -t training-directory -m model-summary-directory -f model-file -w A|B"
        #exit
        which_set = '*'
    end

    svr_train(train_dir, model_dir, model_file, which_set,xml_file)
end
