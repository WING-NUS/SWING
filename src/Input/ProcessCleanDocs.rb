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

    $g_arrDocs = Array.new
    $g_docArray = []
    doc_num=0

    Dir.glob(src_dir+'/*').each do |fn|
        document = REXML::Document.new(File.new(fn))
        doc = document.get_elements('/DOC')[0]
        text = nil

        doc_sentences = {}
        text = ""
        
        # there are two types of TAC document XML structures
        if doc.attributes.size > 0 then
            doc_id = doc.attributes['id']
            doc_type = doc.attributes['type']
            #e = document.get_elements('/DOC/HEADLINE')[0]
            #headline = e != nil ? e.text.strip : ''
            headline = document.get_elements('/DOC/HEADLINE/s').map {|a| a.text.strip} .join(" ")
            e = document.get_elements('/DOC/DATELINE')[0]
            dateline = e != nil ? e.text.strip : ''
            #dateline = e != nil ? e.text.strip : ''
            sen_num = 0
            document.get_elements('/DOC/TEXT/s').each do |e|
                sent_txt = e.text.strip
                text << sent_txt + " "
                doc_sentences[sen_num] = sent_txt
                sen_num += 1
            end
        else
            e = document.get_elements('/DOC/DOCNO')[0] != nil ? document.get_elements('/DOC/DOCNO')[0] : document.get_elements('/DOC/DOCID')[0]
            doc_id = e != nil ? e.text.strip : ''
            e = document.get_elements('/DOC/DOCTYPE')[0]
            doc_type = e != nil ? e.text.strip : ''
            #e = document.get_elements('/DOC/BODY/HEADLINE')[0]
            #headline = e != nil ? e.text.strip : ''
            headline = document.get_elements('/DOC/BODY/HEADLINE/s').map {|a| a.text.strip} .join(" ")
            e = document.get_elements('/DOC/DATE_TIME')[0] != nil ? document.get_elements('/DOC/DATE_TIME')[0] : document.get_elements('/DOC/DATETIME')[0]
            dateline = e != nil ? e.text.strip : ''
            sen_num = 0
            document.get_elements('/DOC/BODY/TEXT/s').each do |e|
                sent_txt = e.text.strip
                text << sent_txt + " "
                doc_sentences[sen_num] = sent_txt
                sen_num += 1
            end
        end

        text.strip!

        if text == '' then
            STDERR.puts 'error: text empty!'
            STDERR.puts fn
            exit
        end

        # Save parsed information
        l_objDoc = { 
            "docset"=>File.basename(src_dir), 
            "id"=>doc_id , 
            "type"=>doc_type, 
            "headline"=>headline, 
            "dateline"=>dateline, 
            "text"=>text,
            "category"=>category 
        }
        $g_arrDocs.push(l_objDoc)

        l_docSent = {"doc_id" => doc_num}
        l_docSent["actual_doc_id"] = l_objDoc["id"]
        l_docSent["docset"] = l_objDoc["docset"]
        l_docSent["sentences"] = doc_sentences
        l_docSent["category"]=category 
        doc_num += 1
        $g_docArray.push l_docSent
    end
    
    $g_JSON = {"corpus"=>$g_arrDocs}
    $g_JSON["splitted_sentences"] = $g_docArray
    $g_JSON["features"] = []
    puts JSON.generate($g_JSON)
end



