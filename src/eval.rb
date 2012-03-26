#/usr/bin/ruby
### Ziheng
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/..')
$LOAD_PATH.unshift(File.dirname(__FILE__) + '/../..')

require 'rubygems'
require 'pp'
require 'json'
require 'fileutils'
require 'getopt/std'
require 'parseconfig'

# run rouge for a summary
def run_ROUGE(peer_root, model_root)
    peer_root = File.expand_path(peer_root)
    model_root = File.expand_path(model_root)
    rouge_in_file = '../data/rouge.in'
    which_set = nil
    File.open(rouge_in_file, 'w') do |f|
        f.puts '<ROUGE_EVAL version="1.5.5">'
        Dir.glob(peer_root+'/*').sort.each do |peer|
            if which_set == nil then
                if File.basename(peer).match(/-A$/) then
                    which_set = 'A'
                else
                    which_set = 'B'
                end
            end
            id = File.basename(peer).sub(/[A-Z]-/, '-').sub(/\..*/, '')
            model_files = Dir.glob(model_root+'/'+id+'*').map {|l| File.basename(l)}
            f.puts "<EVAL ID=\"#{id}\">"
            f.puts '<PEER-ROOT>'
            f.puts peer_root
            f.puts '</PEER-ROOT>'
            f.puts '<MODEL-ROOT>'
            f.puts model_root
            f.puts '</MODEL-ROOT>'
            f.puts '<INPUT-FORMAT TYPE="SPL">'
            f.puts '</INPUT-FORMAT>'
            f.puts '<PEERS>'
            f.puts "<P ID=\"Z\">#{File.basename(peer)}</P>"
            f.puts '</PEERS>'
            f.puts '<MODELS>'
            model_files.each do |fn|
                f.puts "<M ID=\"#{fn[-1..-1]}\">#{fn}</M>"
            end
            f.puts '</MODELS>'
            f.puts '</EVAL>'
        end
        f.puts '</ROUGE_EVAL>'
    end

    rouge_out_file = rouge_in_file.sub(/in$/, 'out')
    rouge_dir = '../lib/ROUGE-1.5.5'
    `#{rouge_dir}/ROUGE-1.5.5.pl -l 130 -n 4 -w 1.2 -m -2 4 -u -c 95 -r 1000 -f A -p 0.5 -t 0 -a -d #{rouge_in_file} > #{rouge_out_file}` #change to -l 100

    rouge_out_str = File.readlines(rouge_out_file).join()
    puts "Set #{which_set} " + rouge_out_str.match(/(ROUGE-1 Average_R: \S+) /)[1] + '; ' +
        rouge_out_str.match(/(ROUGE-2 Average_R: \S+) /)[1] + '; ' +
        rouge_out_str.match(/(ROUGE-SU4 Average_R: \S+) /)[1]
    #r2_values=rouge_out_str.scan(/ROUGE-2 Eval D11[\-A-Z0-9\.]+ R:(\S+)/)
    #r2_values.each do |value|
    #    puts value
    #end

end



if __FILE__ == $0 then
        
    
    test_conf = ParseConfig.new(File.dirname(__FILE__)+'/../configuration.conf')
    model_root = test_conf.params['test']['model summaries dir']
    peer_root = "../data/Summaries/"+test_conf.params['test']['summaries dir']
    run_ROUGE(peer_root, model_root)
end
