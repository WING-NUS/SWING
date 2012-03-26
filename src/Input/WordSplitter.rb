#Tokenizes sentence into words
# Praveen Bysani
def word_breaker text
    words=[]
    text=text.gsub(/\!|\?|\.|\,|\"|`|'/,"")
    words=text.split
    return words
end

