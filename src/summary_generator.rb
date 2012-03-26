#!/usr/bin/ruby
### Ziheng
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/..')
$LOAD_PATH.unshift(File.dirname(__FILE__) )

require 'rubygems'
require 'pp'
require 'json'
require 'fileutils'
require 'Input/WordSplitter'
require 'Input/StopList'
require 'SVR/svr_test_one'
require 'SVR/category_statistics'
require 'parseconfig'


if __FILE__ == $0 then

    test_conf = ParseConfig.new(File.dirname(__FILE__)+'/../configuration.conf')
    test_dir = test_conf.params['test']['documents dir']
    model_file = "../data/"+test_conf.params['test']['model file']
    summ_dir = "../data/Summaries/"+test_conf.params['test']['summaries dir']
    which_set = test_conf.params['test']['document set']
    xml_file = test_conf.params['test']['xml file']


    max_len = test_conf.params['general']['summary length']
    
    features = test_conf.params['general']['features']
    granularity = test_conf.params['general']['scoring granularity']
    clean_data = test_conf.params['general']['clean data']
    
    if clean_data == "no"
        use_clean_data = false
    elsif clean_data == "yes"
        use_clean_data = true
    end
    #Computing category statistics for guided summarization   
    if granularity == "sentence"
        cat_stat = CategoryStatistics.new
        stat_file=cat_stat.json_build_category_statistics test_dir, xml_file, which_set, use_clean_data
    elsif granularity == "NP"
        stat_file=  File.dirname(__FILE__)+'/../data/Phrases/NP_2011.txt'
    elsif granularity == "VP"
        stat_file=  File.dirname(__FILE__)+'/../data/Phrases/VP_2011.txt'
    elsif granularity == "PP"
        stat_file=  File.dirname(__FILE__)+'/../data/Phrases/PP_2011.txt'
    end

    sets = Dir.glob(test_dir+'/*/*-'+which_set).sort
    set_cnt = 1
    sets.each do |set_id|
        summary_id = File.basename(set_id)
        puts set_cnt.to_s + ' ' + set_id + ' ' + summary_id
        set_cnt += 1


        feature_list = features.split(",")
        feature_list =feature_list.map{ |feature| feature.strip}
        user_features =''
        feature_list.each do |feature|
            case feature
            when 'dfs'
                user_features += "| ruby Features/dfs_bigram.rb "
            when 'sp'
                user_features += "| ruby Features/sentenceposition.rb "
            when 'crs'
                user_features += "| ruby Features/gfs.rb -s #{stat_file} "
            when 'ckld'
                user_features += "| ruby Features/ckld.rb -s #{stat_file} "
            when 'sl'
                user_features += "| ruby Features/sentencelength.rb "
            else
                puts "Invalid features"
            end
        end

        
        cmd_process_data = use_clean_data ? "ruby Input/ProcessCleanDocs.rb -s #{set_id} -x #{xml_file}" :
            "ruby Input/ProcessTACTestDocs.rb -s #{set_id} -x #{xml_file} | ruby Input/SentenceSplitter.rb"

            #str = `cd #{File.dirname(__FILE__)}/..; \
        str = `#{cmd_process_data} \
            #{user_features} \
        | ruby SVR/svr_test_one.rb -f #{model_file} \
        | ruby SentenceSelection/MMRSelectionWithSR.rb -s #{xml_file} --reduction --maxlength #{max_len} \
        | ruby PostProcessing/ChoptoLength.rb -l #{max_len}` 


        l_JSON = JSON.parse(str)

       if which_set == "A" then
           set_A_fh = File.open("../data/set_A_text/"+File.basename(set_id), 'w')
           l_JSON["splitted_sentences"].each do |l_Article|
               l_Article["sentences"].sort {|a,b| a[0].to_i<=>b[0].to_i} .each do |l_senid, l_sentence| 
                   set_A_fh.puts "#{l_Article["doc_id"]}_#{l_senid}\t" + l_JSON['SVR']["#{l_Article["doc_id"]}_#{l_senid}"].to_s + "\t" + l_sentence 
               end
           end
           set_A_fh.close
       end

        Dir.mkdir(summ_dir) if not File::exists?( summ_dir )

        File.open(summ_dir + '/' + summary_id, 'w') do |fh|
            fh.puts l_JSON["summary"]
        end

        if which_set == 'A' then
            `cp -f #{summ_dir + '/' + summary_id} ../data/set_A_summaries/`
        end
    end
end
