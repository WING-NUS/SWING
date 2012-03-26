#!/usr/bin/env ruby
# encoding: UTF-8

### Ziheng

require 'rubygems'
require 'optparse'
require 'json'
require 'getopt/std'
require 'rexml/document'
require 'pp'
require 'rexml/xpath'


if __FILE__ == $0 then
    opt = Getopt::Std.getopts("s:x:")
    src_dir = opt["s"]
    topic_xml = opt["x"]
    if src_dir == nil then
        puts "usage: #{__FILE__} -s tac-doc-directory -x topic_xml"
        exit
    end
    if topic_xml == nil then
        puts "usage: #{__FILE__} -s tac_doc directory -x topic_xml"
        exit
    end
    
    ## Extract Category Information 
    topic_id= File.basename(src_dir).slice 0..-3
    topic_doc = REXML::Document.new(File.new(topic_xml))
    category=topic_doc.elements["TACtaskdata/topic[@id='#{topic_id}']"].attributes['category']
    topic_text = ''
    topic_text = topic_doc.elements["TACtaskdata/topic[@id='#{topic_id}']/title"].text
    topic_text = topic_text.rstrip.lstrip

    $g_arrDocs = Array.new

    Dir.glob(src_dir+'/*').each do |fn|
        document = REXML::Document.new(File.new(fn))
        doc = document.get_elements('/DOC')[0]
        text = nil

        # there are two types of TAC document XML structures
        if doc.attributes.size > 0 then
            doc_id = doc.attributes['id']
            doc_type = doc.attributes['type']
            e = document.get_elements('/DOC/HEADLINE')[0]
            headline = e != nil ? e.text.strip : ''
            e = document.get_elements('/DOC/DATELINE')[0]
            dateline = e != nil ? e.text.strip : ''
            text = ""
            document.get_elements('/DOC/TEXT/P').each do |e|
                text << e.text.gsub(/\s+/, ' ').strip + "\n"
            end
            if text == '' then
                text = document.get_elements('/DOC/TEXT')[0].text.strip
            end
        else
            e = document.get_elements('/DOC/DOCNO')[0] != nil ? document.get_elements('/DOC/DOCNO')[0] : document.get_elements('/DOC/DOCID')[0]
            doc_id = e != nil ? e.text.strip : ''
            e = document.get_elements('/DOC/DOCTYPE')[0]
            doc_type = e != nil ? e.text.strip : ''
            e = document.get_elements('/DOC/BODY/HEADLINE')[0]
            headline = e != nil ? e.text.strip : ''
            e = document.get_elements('/DOC/DATE_TIME')[0] != nil ? document.get_elements('/DOC/DATE_TIME')[0] : document.get_elements('/DOC/DATETIME')[0]
            dateline = e != nil ? e.text.strip : ''
            text = ""
            document.get_elements('/DOC/BODY/TEXT/P').each do |e|
                text << e.text.gsub(/\s+/, ' ').strip + "\n"
            end
            if text == '' then
                text = document.get_elements('/DOC/BODY/TEXT')[0].text.strip
            end
        end

        text.gsub!(/\s+/, " ")
        text.strip!

        if text == '' then
            STDERR.puts 'error: text empty!'
            STDERR.puts fn
            exit
        end

        # Save parsed information
        l_objDoc = { "docset"=>File.basename(src_dir), "id"=>doc_id , "type"=>doc_type, "headline"=>headline, "dateline"=>dateline, "text"=>text,"category"=>category,"topic_text"=>topic_text }
        $g_arrDocs.push(l_objDoc)
    end
    
    $g_FinalStruct = {"corpus"=>$g_arrDocs}
    puts JSON.generate($g_FinalStruct)

end



