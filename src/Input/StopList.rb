#Create a list of stop words and provides a method to check if or not a word is stopWord
## Praveen Bysani
class StopList
    attr_accessor :stopwords, :punctuations

    def initialize
        #file = "../lib/stopwordLists/searchEngineWorld.txt"
        file = "../lib/stopwordLists/dvlVerity.txt"
        @stopwords = File.readlines(file).map {|l| l.strip}
        @punctuations = %w/! " # $ % & \ ' '' ( ) * + , - -- . ... \/ : ; < = > ? @ [ \ ] ^ _ ` `` { | } ~/
    end

    def IsStopWord word
        if @stopwords.include? word
            return true
        else
            return false
        end
    end

    def printList
        print @stopwords
    end

    def filter(str)
        (str.split - @stopwords - @punctuations).join(' ')
    end

    def filter_stopwords(str)
        (str.split - @stopwords).join(' ')
    end

    def filter_punctuations(str)
        (str.split - @punctuations).join(' ')
    end
end
    
