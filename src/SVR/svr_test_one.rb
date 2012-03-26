#!/usr/bin/ruby
### Ziheng

$LOAD_PATH.unshift(File.dirname(__FILE__) + '/..')
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../..')
$:.unshift File.dirname(__FILE__)

require 'rubygems'
require 'pp'
require 'json'
require 'fileutils'
require 'getopt/std'
require 'SVR/svr_train'
#require File.dirname(__FILE__)+'/svr_train'

def svr_test(l_JSON, model_file)
    test_file = '/tmp/svm.test.features'
    predict_file = '/tmp/svm.predict.'+rand.to_s

    test_fh = File.open(test_file, 'w')

    l_JSON["splitted_sentences"].each do |l_Article|
        l_Article["sentences"].each do |l_senid,l_sentence|
            id = "#{l_Article["doc_id"]}_#{l_senid}"
            #l_JSON['importances'].keys.sort_by {|a| a.split('_').map {|e| e.to_i}} .each do |id|
            instance = '0'
            cnt = 1
            l_JSON['features'].each do |feat|
                feat.each do |feat_name, feat_values|
                    #instance << " #{cnt}:#{feat_values[id]}" if feat_values[id] != 0
                    instance << " #{cnt}:#{feat_values[id]}"
                end
                cnt += 1
            end
            test_fh.puts instance
        end
    end
    test_fh.close

    svm_dir = File.dirname(__FILE__)+'/../../lib/svm_light'
   `#{svm_dir}/svm_classify #{test_file} #{model_file} #{predict_file}`

    scores = File.readlines(predict_file).map {|l| l.chomp.to_f}
    l_JSON['SVR'] = {}
    l_JSON["splitted_sentences"].each do |l_Article|
        l_Article["sentences"].each do |l_senid,l_sentence|
            id = "#{l_Article["doc_id"]}_#{l_senid}"
            l_JSON['SVR'][id] = scores.shift
        end
    end
    if scores.size != 0 then
        puts 'error: scores.size != 0'
        exit
    end

    `rm -f #{predict_file}`
end

if __FILE__ == $0 then
    opt = Getopt::Std.getopts("f:s:")
    model_file = opt["f"]
    if model_file == nil then
        puts "usage: #{__FILE__} -f model-file"
        exit
    end

    ARGF.each do |l_JSN|
        l_JSON = JSON.parse l_JSN
        svr_test(l_JSON, model_file)
        puts l_JSON.to_json()
    end
end
