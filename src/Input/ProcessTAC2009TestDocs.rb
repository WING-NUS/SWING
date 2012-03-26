#!/usr/bin/env ruby
#
#
# Reads in TAC2009 test documents
# and converts them into JSON format for further
# processing.
#
# Author:: Ng, Jun Ping (mailto: junping@comp.nus.edu.sg)
# Copyright::  Copyright (c) 2011, Ng Jun Ping


require 'rubygems'
require 'optparse'
require 'json'
require 'nokogiri'


VERSION_NO = 'v1.0 2011-Feb-05 13:20 +0800'
AUTHOR_INFO = 'NG, Jun Ping --- ngjp@nus.edu.sg'


# Defines the allowed options
# # # # # # # # # # # # # # # # # # # # # # # # #
$g_CmdLineOptions = {}
$g_ParsedOptions =  OptionParser.new do |opts|
    opts.banner = "Converts TAC 2009 XML test docs into JSON format.\nUsage:ProcessTAC2009TestDocs.rb  [options]"
    opts.on( '-v', '--version', 'Prints version information' ) do
        puts VERSION_NO
        puts AUTHOR_INFO
        puts ""
        exit
    end
    $g_CmdLineOptions[:srcdir] = "./"
    opts.on( '-s', '--srcdir DIR', String, 'Directory where TAC test documents are found [Default: ./]') do |l_szSrc|
        $g_CmdLineOptions[:srcdir] = l_szSrc
    end
    opts.on( '-h', '--help', 'Display this screen' ) do
        puts opts
        exit
    end
end

# Parse the incoming command line arguments
# # # # # # # # # # # # # # # # # # # # # # # # #
$g_ParsedOptions.parse!


# Used to hold parsed XML documents
$g_arrDocs = Array.new

# Read in from each file of the directory
$g_SrcDir = Dir.new($g_CmdLineOptions[:srcdir].to_s())
$g_arrDocSet = $g_CmdLineOptions[:srcdir].to_s().split('/')
$g_DocSet = $g_arrDocSet[$g_arrDocSet.length-1]
$g_SrcDir.each do |l_szFileName|
    if (l_szFileName == "." or l_szFileName == "..") then
        # Skip
    else

        # Make use of the nokogiri parser to process the XML test doc
        l_szFullFileName = $g_CmdLineOptions[:srcdir].to_s() + l_szFileName
        #puts "FileName: #{l_szFullFileName}"
        l_szFile = File.open(l_szFullFileName)
        l_Doc = Nokogiri::XML(l_szFile)
        l_Doc.document.xpath('/DOC').each do |l_NodeDoc|
            l_DocID = l_NodeDoc.xpath('/DOC/@id')
            l_DocType = l_NodeDoc.xpath('/DOC/@type')
            l_Headline = l_NodeDoc.xpath('/DOC/HEADLINE').text.chomp.reverse.chomp.reverse
            l_Dateline = l_NodeDoc.xpath('/DOC/DATELINE').text.chomp.reverse.chomp.reverse
            l_NewsText = ""
            l_NodeText = l_NodeDoc.xpath('/DOC/TEXT')
            l_NodeText.xpath('//P').each do |l_szText|
                l_NewsText += l_szText.text.gsub(/\n/," ").chomp.reverse.chomp.reverse
                l_NewsText += "\n"
            end

            # Save parsed information
            l_objDoc = { "docset"=>$g_DocSet, "id"=>l_DocID , "type"=>l_DocType, "headline"=>l_Headline, "dateline"=>l_Dateline, "text"=>l_NewsText }
            $g_arrDocs.push(l_objDoc)

        end
        l_szFile.close

    end
end

$g_FinalStruct = {"corpus"=>$g_arrDocs}
puts JSON.generate($g_FinalStruct)
