##############################################
## PTB tokenizer in sed converted to ruby 
## by Ziheng Lin (linziheng@gmail.com)

require 'iconv'

class PTBTokenizer
    def PTBTokenizer.tokenize(untrusted_text)
        ic = Iconv.new('UTF-8//IGNORE', 'UTF-8')
        text=ic.iconv(untrusted_text)
        #the following code copied from Robert MacIntyre's Penn Treebank tokenizer
        #$$textRef =~ s/^"/`` /g;
        text.gsub!(/^"/, '`` ')
        text.gsub!(/``/, ' `` ')     # added 2009/4/1
        #$$textRef =~ s/([ \([{<])"/$1 `` /g;
        text.gsub!(/([ \(\[{<])"/, "\\1 `` ")
        # close quotes handled at end

        #$$textRef =~ s/\.\.\./ ... /g;
        text.gsub!(/\.\.\./, " ... ")
        #$$textRef =~ s/[,;:@#\$%&]/ $& /g;
        text.gsub!(/[,;:@#\$%&]/, " \\& ")

        # Assume sentence tokenization has been done first, so split FINAL periods
        # only. 
        #$$textRef =~ s/([^.])([.])([\])}>"']*)[ \t]*$/$1 $2$3 /g;
        text.gsub!(/([^.])([.])([\])}>"']*)[ \t]*$/, "\\1 \\2\\3 ")
        # however, we may as well split ALL question marks and exclamation points,
        # since they shouldn't have the abbrev.-marker ambiguity problem
        #$$textRef =~ s/[?!]/ $& /g;
        text.gsub!(/[?!]/, " \\& ")

        # parentheses, brackets, etc.
        #$$textRef =~ s/[\]\[\(\){}\<\>]/ $& /g;
        text.gsub!(/[\]\[\(\){}\<\>]/, " \\& ")
        # Some taggers, such as Adwait Ratnaparkhi's MXPOST, use the parsed-file
        # version of these symbols.
        # UNCOMMENT THE FOLLOWING 6 LINES if you're using MXPOST.
        #$$textRef =~ s/\(/-LRB-/g;
        #$$textRef =~ s/\)/-RRB-/g;
        #$$textRef =~ s/\[/-LSB-/g;
        #$$textRef =~ s/\]/-RSB-/g;
        #$$textRef =~ s/{/-LCB-/g;
        #$$textRef =~ s/}/-RCB-/g;

        #$$textRef =~ s/--/ -- /g;
        text.gsub!(/--/, " -- ")

        # NOTE THAT SPLIT WORDS ARE NOT MARKED.  Obviously this isn't great, since
        # you might someday want to know how the words originally fit together --
        # but it's too late to make a better system now, given the millions of
        # words we've already done "wrong".

        # First off, add a space to the beginning and end of each line, to reduce
        # necessary number of regexps.
        #$$textRef =~ s/$/ /;
        text.gsub!(/$/, " ")
        #$$textRef =~ s/^/ /;
        text.gsub!(/^/, " ")

        #$$textRef =~ s/"/ '' /g;
        text.gsub!(/"/, " '' ")
        text.gsub!(/''/, " '' ") # added 2009/4/1 
        # possessive or close-single-quote
        #$$textRef =~ s/([^'])' /$1 ' /g;
        text.gsub!(/([^'])' /, "\\1 ' ")
        # as in it's, I'm, we'd
        #$$textRef =~ s/'([sSmMdD]) / '$1 /g;
        text.gsub!(/'([sSmMdD]) /, " '\\1 ")
        #$$textRef =~ s/'ll / 'll /g;
        text.gsub!(/'ll /, " 'll ")
        #$$textRef =~ s/'re / 're /g;
        text.gsub!(/'re /, " 're ")
        #$$textRef =~ s/'ve / 've /g;
        text.gsub!(/'ve /, " 've ")
        #$$textRef =~ s/n't / n't /g;
        text.gsub!(/n't /, " n't ")
        #$$textRef =~ s/'LL / 'LL /g;
        text.gsub!(/'LL /, " 'LL ")
        #$$textRef =~ s/'RE / 'RE /g;
        text.gsub!(/'RE /, " 'RE ")
        #$$textRef =~ s/'VE / 'VE /g;
        text.gsub!(/'VE /, " 'VE ")
        #$$textRef =~ s/N'T / N'T /g;
        text.gsub!(/N'T /, " N'T ")

        #$$textRef =~ s/ ([Cc])annot / $1an not /g;
        text.gsub!(/ ([Cc])annot /, " \\1an not ")
        #$$textRef =~ s/ ([Dd])'ye / $1' ye /g;
        text.gsub!(/ ([Dd])'ye /, " \\1' ye ")
        #$$textRef =~ s/ ([Gg])imme / $1im me /g;
        text.gsub!(/ ([Gg])imme /, " \\1im me ")
        #$$textRef =~ s/ ([Gg])onna / $1on na /g;
        text.gsub!(/ ([Gg])onna /, " \\1on na ")
        #$$textRef =~ s/ ([Gg])otta / $1ot ta /g;
        text.gsub!(/ ([Gg])otta /, " \\1ot ta ")
        #$$textRef =~ s/ ([Ll])emme / $1em me /g;
        text.gsub!(/ ([Ll])emme /, " \\1em me ")
        #$$textRef =~ s/ ([Mm])ore'n / $1ore 'n /g;
        text.gsub!(/ ([Mm])ore'n /, " \\1ore 'n ")
        #$$textRef =~ s/ '([Tt])is / '$1 is /g;
        text.gsub!(/ '([Tt])is /, " '\\1 is ")
        #$$textRef =~ s/ '([Tt])was / '$1 was /g;
        text.gsub!(/ '([Tt])was /, " '\\1 was ")
        #$$textRef =~ s/ ([Ww])anna / $1an na /g;
        text.gsub!(/ ([Ww])anna /, " \\1an na ")
        # s/ ([Ww])haddya / $1ha dd ya /g;
        # s/ ([Ww])hatcha / $1ha t cha /g;

        # clean out extra spaces
        #$$textRef =~ s/  */ /g;
        text.gsub!(/  */, " ")
        #$$textRef =~ s/^ *//g;	
        text.gsub!(/^ */, "")
        text
    end
end

