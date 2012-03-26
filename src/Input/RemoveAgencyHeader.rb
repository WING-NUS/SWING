#/usr/bin/ruby

### DEPRECATED
### Now done in SentenceReduction.rb

# Removes the news agency tag from the first line of articles
# Agency headers include things like
#  (REUTERS) --
#  ...
#
# This is now depracated. Agency headers are now removed as part of
#  PostProcessing/SentenceReduction.rb
#
# NG, Jun Ping
#  junping@comp.nus.edu.sg
#

require 'rubygems'
require 'pp'
require 'json'
require 'fileutils'

# Old sentence breaker. This code is not updated.
#  Rest of the pipeline is 
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




ARGF.each do |l_szJSON|


    $g_JSON = JSON.parse l_szJSON
    $g_docArray = []

    doc_num=0
    $g_JSON["corpus"].each do |l_Article|
        l_docSent={"doc_id" => doc_num}
        l_docSent["actual_doc_id"] = l_Article["id"]
        l_docSent["docset"] = l_Article["docset"]
        
        sen_num=0
        l_ProcessedText = ""
        l_ArticleText = l_Article["text"]
        #l_Sentences = sentence_breaker(l_ArticleText)
        l_Sentences = l_ArticleText.split('\n')
        l_Sentences.each do |l_Sentence|
            if sen_num <= 1 then

                # Strip away agency header
                l_TextAfter = l_Sentence.gsub(/^[A-Za-z0-9,\. \(\)]*[-_]+/,"")
                #$stderr.puts "Before: #{l_Sentence}\nAfter: #{l_TextAfter}\n\n"
                l_ProcessedText += l_TextAfter
            else
                l_ProcessedText += l_Sentence
            end if
            sen_num +=1
        end
        l_Article["text"] = l_ProcessedText
    end
end

puts JSON.generate $g_JSON
