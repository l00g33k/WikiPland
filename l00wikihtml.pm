package l00wikihtml;

use l00httpd;
my (@toclist, $java);


# collapsible Javascript tree: http://webpageworkshop.co.uk/main/article11

$java = "\n".
"<script type=\"text/javascript\">\n".
"var dge=document.getElementById;\n".
"function cl_expcol(a){\n".
"    if(!dge)return;\n".
"    document.getElementById(a).style.display = \n".
"        (document.getElementById(a).style.display=='none') ? 'block':'none';\n".
"}\n".
"</script>\n\n";

my (%colorlu);
$colorlu{'r'} = 'red';
$colorlu{'y'} = 'yellow';
$colorlu{'l'} = 'lime';
$colorlu{'s'} = 'silver';
$colorlu{'a'} = 'aqua';
$colorlu{'f'} = 'fuchsia';
$colorlu{'g'} = 'gray';
$colorlu{'o'} = 'olive';


sub makejavatoc {
    my ($lvl,$ttl, $lvltop, $order, %treetop, $thislvl, $needclose);
    my ($ulid, $output);
    my ($jump, $url, $anchor, $tag);

    $lvltop = 5;
    $order = 0;
    $thislvl = 0;
    $needclose = 0;
    $ulid = 1;

    $output = $java;

    $output .= "<ul>\n";
    foreach $_ (@toclist) {
        ($lvl,$ttl) = split ('\.\.');
        $lvl--;
        if ($lvl < $lvltop) {
            $lvltop = $lvl;
        }
        for ($thislvl; $thislvl > $lvl; $thislvl--) {
            $output .= '  ' x $thislvl . "</li>\n";
            $output .= '  ' x $thislvl . "</ul>\n";
        }
        for ($thislvl; $thislvl < $lvl; $thislvl++) {
            $output .= '  ' x ($thislvl + 1) . "<a href=\"javascript:cl_expcol('ulid$ulid');\">--</a>\n";
            $output .= '  ' x ($thislvl + 1) . "<ul id=\"ulid$ulid\">\n";
            $ulid++;
            $needclose = 0;
        }
        if ($needclose) {
            $needclose = 0;
            $output .= '  ' x $thislvl . "</li>\n";
        }
        ($jump, $anchor, $tag) = &makeanchor ($thislvl, $ttl);
        $jump =~ s/&nbsp;//g;
        $jump =~ s/<br>//g;
        $jump =~ s/\n//g;
        $output .= '  ' x $thislvl . "<li>$jump\n";
        $needclose = 1;
        $order++;
    }
    for ($thislvl; $thislvl >= 0; $thislvl--) {
        $output .= '  ' x $thislvl . "</li>\n";
        $output .= '  ' x $thislvl . "</ul>\n";
    }
#    $output .= "</li>\n";
#    $output .= "</ul>\n";

    $output;
}


sub makeanchor {
    my ($lvl, $ttl) = @_;
    my ($jump, $url, $anchor, $tag);

    $tag = $ttl;
    # $ttl, title, may include font control. remove all HTML tags
    #  <font style="color:black;background-color:silver">Buy</font>
    $tag =~ s/<.+?>//g;
    $tag =~ s/[^0-9A-Za-z]/_/g;

    if ($lvl > 0) {
        $jump = "&nbsp;&nbsp;" x ($lvl - 1);
    } else {
        $jump = '';
    }
    $url = "<a href=\"#$tag\">$ttl</a>";
    $jump .= "$url<br>\n";
    $anchor = "<a name=\"$tag\"></a>";

    ($jump, $anchor, $tag);
}

sub wikihtml {
    # flags: 1='bookmark' is on
    #        2=prefix chapter number
    #        4=bare, no header/footer
    #        8=open link in 'newwin'
    # $ctrl: system variables
    # $pname: current path for relateive wikiword links
    my ($ctrl, $pname, $inbuf, $flags, $fname) = @_;
    my ($oubuf, $bulvl, $tx, $lvn, $desc, $http, $toc, $toccol);
    my ($intbl, @cols, $ii, $lv, $el, $url, @el, @els, $__lineno__);
    my ($jump, $anchor, $last, $tmp, $ahead, $tbuf, $color, $tag, $bareclip);
    my ($desc, $url, $bullet, $bkmking, $clip, $bookmarkkeyfound);
    my ($lnno, $flaged, $postsit, @chlvls, $thischlvl, $lastchlvl);
    my ($lnnoinfo, @lnnoall, $leadcolor, @inputcache, $cacheidx);
    my ($mode0unknown1twiki2markdown, $mdChanged2Tw, $markdownparanobr, $loop);

    undef @chlvls;
    undef $lastchlvl;

    if (!defined($fname)) {
        $fname = '(undef)';
    }
    $bookmarkkeyfound = 0;
    if (($flags & 1) == 0) {
        # not specified for BOOKMARK
        # search %BOOKMARK% in first 4000 lines
        $tmp = 0;
        foreach $_  (split ("\n", $inbuf)) {
            # Erase tags for normal processing
            s/%l00httpd:lnno:(\d+)%//;
            if (/^%BOOKMARK%/) {
                $bookmarkkeyfound = 1;
                last;
            }
            if ($tmp++ > 4000) {
                last;
            }
        }
    }
    if ((($flags & 1) == 1) || ($bookmarkkeyfound != 0)) {
        # flags: 1='bookmark' is on or contains '%BOOKMARK%' at the beginning 
        $oubuf = $inbuf;
        $inbuf = '';
        $bullet = 0;
        $bkmking = 0;
        $lnnoinfo = '';
        @inputcache = split ("\n", $oubuf); # allows look forward
        for ($cacheidx = 0; $cacheidx <= $#inputcache; $cacheidx++) {
            $_ = $inputcache[$cacheidx];
            # tags like %l00httpd:lnno:(\d+)% records original line number
            # there may be multiple line nummbers per line due to drop line, etc.
            if (@lnnoall = /%l00httpd:lnno:(\d+)%/g) {
                # save for use later so we can remove the tags for normal processing
                if ($lnnoinfo eq '') {
                    $lnnoinfo = join(',', @lnnoall);
                } else {
                    $lnnoinfo .= ',' . join(',', @lnnoall);
                }
                # Remove tags for normal processing
                s/%l00httpd:lnno:(\d+)%//g;
                #line_anchor_debug:
                #Print to show that every source line number has a tag
                #print"$lnnoinfo\n";
            }

            s/\r//g;
            s/\n//g;
            if (/^=/) {
                # headings
                if ($lnnoinfo ne '') {
                    # save tags for phase 2 processing
                    $_ = "%l00httpd:lnno:$lnnoinfo%$_";
                    $lnnoinfo = '';
                }
                $inbuf .= "$_\n";
            } elsif (/^%BOOKMARK%/) {
                # restart bookmarking
                $bkmking = 1;
            } elsif (/^%END%/) {
                # ends bookmarking
                $bkmking = 0;
            } elsif ($bkmking == 0) {
                # not bookmarking
                if ($lnnoinfo ne '') {
                    # save tags for phase 2 processing
                    $_ = "%l00httpd:lnno:$lnnoinfo%$_";
                    $lnnoinfo = '';
                }
                $inbuf .= "$_\n";
            } elsif (/^\*/) {
                # bullets, no linefeed
                $inbuf .= "$_ ";
                $bullet = 1;
            } elsif (($desc, $clip) = /^ *(.*) *\|\|(.+)$/) {
                # clip
                $desc =~ s/ +$//g;
                $bareclip = 0;
                if ($desc eq '') {
		            $desc = $clip;
                    $bareclip = 1;
		        }
if(1){
                # look ahead. If the the current line ends in:
                # \r\n
                # and the next line starts with:
                # ||
                # then we append it as an extended line
                while ($cacheidx < $#inputcache) {
                    # get the next line and remove internal tag
                    $tmp = $inputcache[$cacheidx + 1];
                    if ($tmp =~ /%l00httpd:lnno:([0-9,]+)%/) {
                        # remove internal tag
                        $tmp =~ s/%l00httpd:lnno:([0-9,]+)%//;
                    }
#print "\n\nTHIS: $_\n";
#print "NEXT: $tmp\n";
                    # so $tmp is the next line
                    # Does it look line extended line?
                    if ((/\\r\\n$/) && ($tmp =~ /^\|\|(.*)/)) {
                        # yes
                        $_ = $inputcache[$cacheidx + 1];
                        if (@lnnoall = /%l00httpd:lnno:(\d+)%/g) {
                            # save for use later so we can remove the tags for normal processing
                            if ($lnnoinfo eq '') {
                                $lnnoinfo = join(',', @lnnoall);
                            } else {
                                $lnnoinfo .= ',' . join(',', @lnnoall);
                            }
                        }

#print "EXT0: >$clip<\n";
                        # drop ending \r\n
                        $clip =~ s/\\r\\n$//;
                        # append extension line
                        $clip .= "\n$tmp";
                        # skip forward
#print "EXT1: >$clip<\n";
                        $cacheidx++;
                    } else {
                        # no extension line
                        last;
                    }
                }        
#print "END\n\n";
}

                #http://127.0.0.1:20337/clip.htm?update=Copy+to+clipboard&clip=Asd+ddf
#               $clip =~ s/ /+/g;
                #http://127.0.0.1:20337/clip.htm?update=Copy+to+clipboard&clip=
                #%3A%2F
#               $clip =~ s/:/%3A/g;
#               $clip =~ s/&/%26/g;
#               $clip =~ s/=/%3D/g;
#               $clip =~ s/"/%22/g;
#               $clip =~ s/\//%2F/g;
#               $clip =~ s/\|/%7C/g;
#               $clip =~ s/#/%23/g;
                $clip = &l00httpd::urlencode ($clip);
                $url = "/clip.htm?update=Copy+to+clipboard&clip=$clip";
                $url = "[[$url|$desc]]";
                if ($bareclip) {
                    #$url = "&lt;$url&gt;";
		        }
                if ($last =~ /^\*/) {
                    $inbuf .= "$url";
                } else {
                    $inbuf .= " - $url";
                }
            } elsif (($url) = /^\?\| *(.+)$/) {
                $desc = $url;
                # bookmarks
                $desc =~ s/ +$//g;
                if ($last =~ /^\*/) {
                    $inbuf .= "[[$url|$desc]]";
                } else {
                    $inbuf .= " - [[$url|$desc]]";
                }
            } elsif (($desc, $url) = /^([^&].+) *\| *(.+)$/) {
                # [^&] prevents indented lines with | to be made bookmarks
                # bookmarks; must start in column 0
                $desc =~ s/ +$//g;
                if ($last =~ /^\*/) {
                    $inbuf .= "[[$url|$desc]]";
                } else {
                    $inbuf .= " - [[$url|$desc]]";
                }
            } elsif (/^ *$/) {
                # newline
                if ($lnnoinfo ne '') {
                    # save tags for phase 2 processing
                    $_ = "%l00httpd:lnno:$lnnoinfo%$_";
                    $lnnoinfo = '';
                }
                $inbuf .= "$_\n";
                $bullet = 0;
            } else {
                if ($bullet) {
                    if ($last =~ /^\*/) {
                        $inbuf .= "$_";
                    } else {
                        $inbuf .= " - $_";
                    }
                } else {
                    if ($lnnoinfo ne '') {
                        # save tags for phase 2 processing
                        $_ = "%l00httpd:lnno:$lnnoinfo%$_";
                        $lnnoinfo = '';
                    }
                    $inbuf .= "$_\n";
                }
            }
            $last = $_;
        }
    }
    #print "\n::inbuf::\n$inbuf\n";

    # Start generating HTML output in $oubuf
    $oubuf = "<a name=\"___top___\"></a>";
    $bulvl = 0;
    $toc = '';
    $toccol = '';
    
    $intbl = 0;
    $ispre = 0;
    undef @toclist;
    $lnno = 0;
    $flaged = '';
    $postsit = '';
    $mode0unknown1twiki2markdown = 0;
    $markdownparanobr = 0;
    @inputcache = split ("\n", $inbuf); # allows look forward
    for ($cacheidx = 0; $cacheidx <= $#inputcache; $cacheidx++) {
        $_ = $inputcache[$cacheidx];
        if (/%l00httpd:lnno:([0-9,]+)%/) {
            $lnnoinfo = $1;
            s/%l00httpd:lnno:([0-9,]+)%//;
            #line_anchor_debug:
            #print"$lnnoinfo\n";

            if (($__lineno__) = $lnnoinfo =~ /^(\d+)/) {
                # process %__LINE__%
                s/%__LINE__%/$__lineno__/g;
                # process %__LINE__+1%
                if (($tmp) = /%__LINE__\+(\d+)%/) {
                    # doesn't correctly handle multiple instances per line
                    # print "lnnoinfo $lnnoinfo __lineno__ $__lineno__ tmp $tmp\n";
					# There is no easy answer here because multiple lines were combined
					# into one line. l00httpd:lnno:* does record all the original line 
					# numbers that made up the single line, but we don't know which 
					# line contains the %__LINE__% code
                    $tmp = $__lineno__ + $tmp;
                    s/%__LINE__\+(\d+)%/$tmp/g;
                }
                # process %__LINE__-1%
                if (($tmp) = /%__LINE__-(\d+)%/) {
                    # doesn't correctly handle multiple instances per line
                    $tmp = $__lineno__ - $tmp;
                    s/%__LINE__-(\d+)%/$tmp/g;
                }
            }
        }
        s/\r//g;
        $lnno++;




        # Twiki compatibility
        ## convert '   * '
        ## ls.pl converts leading spaces to &nbsp;
        ## undo for this conversion
        $tmp = $_;
        $tmp =~ s/&nbsp;/ /g;
        if (($lv,$tx) = $tmp =~ /^( +)\* (.*)$/) {
            $lv = length ($lv);
            if (($lv % 3) == 0) {
                $lv /= 3;
                $_ = '*' x $lv . " $tx";
            }
        }
        ## convert ---+++
        if (($lv,$tx) = /^---(\++) (.*)$/) {
            $lv = length ($lv);
            $_ = '=' x $lv . "$tx" . '=' x $lv;
        }
        ## convert [[][]] to [[|]]
        s/\[\[(.*?)\]\[(.*?)\]\]/[[$1|$2]]/g;
        # end Twiki compatibility

        # processing each line
        s/\[\[toc\]\]/%TOC%/;   # converts wikispaces' [toc] to %TOC%

        # --- for <hr>
        if (/^---+ *$/) {
            if ($lnnoinfo ne '') {
                # we have saved tags, now put back as line1 anchors
                if($lnnoinfo =~ /,/) {
                    foreach $tmp (split(',', $lnnoinfo)) {
                        $oubuf .=  "<a name=\"line$tmp\"></a>";
                    }
                } else {
                    $oubuf .=  "<a name=\"line$lnnoinfo\"></a>";
                }
            }
            $oubuf .=  "<hr>\n";
            next;
        }





        # MARKDOWN compatibility
        $mdChanged2Tw = 0;
        # http://daringfireball.net/projects/markdown/basics
        # ====  or ---- style heading
        # or .....
        if ($cacheidx < $#inputcache) {
            # checking up to the second last line in the source
            $tmp = $inputcache[$cacheidx + 1];
            if ($tmp =~ /%l00httpd:lnno:([0-9,]+)%/) {
                # remove internal tag
                $tmp =~ s/%l00httpd:lnno:([0-9,]+)%//;
            }
            # check if we have a Markdown style header (with ===, ---, ... underline)
            if ((length($_) > 0) && (length($_) == length($tmp))) {
                # Making my life simple by requiring heading and == or -- equal length
                # At least one char long
                if ($tmp eq "=" x length($_)) {
                    $_ = "# $_";
                    $cacheidx++; # skip a line
                    # occurance of this form of header says we are in markdown mode
                    $mode0unknown1twiki2markdown = 2;
                    $mdChanged2Tw = 1;
                }
                if ($tmp eq "-" x length($_)) {
                    $_ = "## $_";
                    $cacheidx++; # skip a line
                    # occurance of this form of header says we are in markdown mode
                    $mode0unknown1twiki2markdown = 2;
                    $mdChanged2Tw = 1;
                }
                if ($tmp eq "." x length($_)) {
                    $_ = "### $_";
                    $cacheidx++; # skip a line
                    # occurance of this form of header says we are in markdown mode
                    $mode0unknown1twiki2markdown = 2;
                    $mdChanged2Tw = 1;
                }
            }
        }
        # allow markdown bullet list to span multiple lines. Look ahead
        if (/^\*+ /) {
            while ($cacheidx < $#inputcache) {
                # we are on a bullet line
                # checking up to the second last line in the source
                $tmp = $inputcache[$cacheidx + 1];
                if ($tmp =~ /%l00httpd:lnno:([0-9,]+)%/) {
                    # remove internal tag
                    $tmp =~ s/%l00httpd:lnno:([0-9,]+)%//;
                }
                # is it an extension line?
                if ($tmp =~ /^[0-9A-Za-z'"_\-]/) {
                    $_ .= " $tmp";
                    # consume the line
                    $cacheidx++;
                } else {
                    last;
                }
            }
        }

        # password/ID clipboard
        if (/\* (ID|PW): (\S+) *$/) {
            $clip = &l00httpd::urlencode ($2);
#           $tmp = "[[/clip.htm?update=Copy+to+clipboard&clip=$clip|$2]]";
            $tmp = sprintf ("<a href=\"/clip.htm?update=Copy+to+clipboard&clip=%s\" target=\"newwin\">%s</a>", $clip, $2);
            $_ .= " ($tmp)";
        }

        # ## headings
        if (($mode0unknown1twiki2markdown == 2) && (/^(#+) (\S.*)$/)) {
            # convert only if we are in markdown mode
            $_ = '=' x length($1) . $2 . '=' x length($1) . "\n";
            $mdChanged2Tw = 1;
        }

        # images
        # ![alt text](/path/to/img.jpg "Title")
        s/!\[.+?\]\((.+?) *"(.+?)"\)/<img src="$1">$2/g;
        s/!\[.+?\]\((.+?)\)/<img src="$1">$2/g;
        # links
        # This is an [example link](http://example.com/).
        s/\[(.+?)\]\((.+?)\)/<a href="$2">$1<\/a>/g;
        # mutiple line paragraphs
        if ($mode0unknown1twiki2markdown == 2) {
            # if line start with word, then it must be 
            # normal paragraph. Don't put <br> at the end
            if (/^ *$/) {
                # blank line in markdown is end of paragraph
                $markdownparanobr = 1;
            } else {
                $markdownparanobr = /^\w/;
            }
        }

        # was in a table but not any more, close table
        if (!(/^\|\|/) && ($intbl == 1)) {
            $intbl = 0;
            $oubuf .= "</table>\n";
        }

        # make ^    <pre> for all
        # code, 2 or more indents make <pre>code</pre>
        $tmp = $_;
        $tmp =~ s/&nbsp;/ /g;
        if ($tmp =~ /^  /) {
            # currnet line is indented
            $tbuf = "$tmp\n";
            $ahead = $cacheidx + 1;
            # look forward
            $loop = 1;
            while ($loop) {
                $tmp = $inputcache[$ahead];
                if ($tmp =~ /%l00httpd:lnno:([0-9,]+)%/) {
                    $tmp =~ s/%l00httpd:lnno:([0-9,]+)%//;
                }
                $tmp =~ s/&nbsp;/ /g;
                if ($tmp =~ /^  /) {
                    $tbuf .= "$tmp\n";
                    $ahead++;
                    $mdChanged2Tw = 1;
                } else {
                    $loop = 0;
                }
            }
#                $tbuf =~ s/</&lt;/g;
#                $tbuf =~ s/>/&gt;/g;
#                $tbuf =~ s/&/&amp;/g;
            $tbuf = "<pre>$tbuf</pre>";
            # line $ahead isn't indented and wasn't included
            #print "first     indented is line $cacheidx >$inputcache[$cacheidx]<\n";
            #print "first not indented is line $ahead >$inputcache[$ahead]<\n";
            #print "Proposed changes:\n$tbuf\n";
            $cacheidx = $ahead - 1;
            $oubuf .= $tbuf;
            $_ = '';
            next;
        }
		# blank line, add <p> or not
        if ($_ eq '') {
            if ($mode0unknown1twiki2markdown == 2) {
                # If in markdown mode, blank line is end of paragraph
                if ($markdownparanobr) {
                    $oubuf .=  "<p>\n";
                }
            } else {
                # otherwise blank line is new paragraph
                $oubuf .=  "<p>\n";
            }
            next;
        }



        # %DATETIME% expansion
        if (/%DATETIME%/) {
                # date/time substitution
                $tmp = $ctrl->{'now_string'};
                $tmp =~ s/ /T/;
                s/%DATETIME%/$tmp/g;
                $inbuf .= "$_\n";
        }

        # lines ending in ??? gets a colored Highlight link before TOC
        # aka post it note
        # ???, ???r, ???y, ???l, ???s
        if (/^(.*)\?\?\?([rylsafgo]*)$/) {
            $tmp = $1;
                 if ($2 eq 'r') { $color = 'red';
            } elsif ($2 eq 'y') { $color = 'yellow';
            } elsif ($2 eq 'l') { $color = 'lime';
            } elsif ($2 eq 's') { $color = 'silver';
            } elsif ($2 eq 'a') { $color = 'aqua';
            } elsif ($2 eq 'f') { $color = 'fuchsia';
            } elsif ($2 eq 'g') { $color = 'gray';
            } elsif ($2 eq 'o') { $color = 'olive';
            } else              { $color = 'white';
            }
            
            # drops *
            $tmp =~ s/^\*+ +//;
            # drops ==
            $tmp =~ s/^=+//;
            $tmp =~ s/=+$//;

            # make a sortable TOC entry
            $tmp = "<!-- $tmp --><font style=\"color:black;background-color:$color\"><a href=\"#lnno$lnno\">$tmp</a></font><br>\n";
            $postsit .= $tmp;
            $oubuf .=  "<a name=\"lnno$lnno\">";
            # remove !!!
            s/\?\?\?[rylsafg]*$//;
            if (/^=.+=$/) {
                # '=' interferes with heading shorthand, global replace ____EqSg____ = later
                s/^(=+)([^=]+)(=+)$/$1<font style____EqSg____"color:black;background-color:$color">$2<\/font>$3/g;
            } else {
                $_ = "<font style=\"color:black;background-color:$color\">$_</font>";
            }
            $_ .= " <a href=\"#___top___\">top</a>" .
                  " <a href=\"#__toc__\">toc</a>";
        }

        # lines ending in !!! gets a Highlight link before TOC
        if (/^(.*)!!!$/) {
            $tmp = $1;
            # drops *
            $tmp =~ s/^\*+ +//;
            # drops ==
            $tmp =~ s/^=+//;
            $tmp =~ s/=+$//;
            $flaged .= "<a href=\"#lnno$lnno\">$tmp</a><br>\n";
            $oubuf .=  "<a name=\"lnno$lnno\">";
            # remove !!!
            s/!!!$//;
        }

        # process headings
        if (@el = /^(=+)([^=]+?)(=+)(.*)$/) {
            if ($el[0] eq $el[2]) {
                # is this ==twiki== heading original or from markdown?
                if ($mdChanged2Tw == 0) {
                    # original, we are in Twiki mode
                    $mode0unknown1twiki2markdown = 1;
                }

                $el[1] =~ s/____EqSg____/=/g;
                # left === must match right ===
                # headings must start from column 0
                if ($bulvl > 0) {
                    # generate closing bullets
                    for (; $bulvl > 0; $bulvl--) {
                        $oubuf .=  "</ul>";
                    }
                    $oubuf .= "\n";
                }
                if ($flags & 2) {
                    $thischlvl = length($el[0]);
                    if (defined ($lastchlvl)) {
                        # increment current chapter level
                        if ($lastchlvl == $thischlvl) {
                            # increment current level
                            if (!defined ($chlvls[$thischlvl])) {
                                # 1 if non existent
                                $chlvls[$thischlvl] = 1;
                            } else {
                                # else increment
                                $chlvls[$thischlvl]++;
                            }
                            # create if non existence
                            for ($ii = 1; $ii < $thischlvl; $ii++) {
                                if (!defined ($chlvls[$ii])) {
                                    # 1 if non existent
                                    $chlvls[$ii] = 1;
                                }
                            }
                        } elsif ($lastchlvl > $thischlvl) {
                            # increment higher level
                            $chlvls[$thischlvl]++;
                        } else { # ($lastchlvl < $thischlvl)
                            # increment lower level
                            for ($ii = $lastchlvl + 1; $ii <= $thischlvl; $ii++) {
                                $chlvls[$ii] = 1;
                            }
                        }
                    } else {
                        # this is the first time ever.  Everything starts at 1.1.
                        for ($ii = 1; $ii <= $thischlvl; $ii++) {
                            $chlvls[$ii] = 1;
                        }
                    }
                    $tmp = '';
                    for ($ii = 1; $ii <= $thischlvl; $ii++) {
                        $tmp .= "$chlvls[$ii].";
                    }
                    $lastchlvl = $thischlvl;
                    # no line number in chapter title # $el[1] = "$tmp $el[1] ($lnno)";
                    $el[1] = "$tmp $el[1]";
                }
                # make anchor
                ($jump, $anchor, $tag) = &makeanchor (length($el[0]), $el[1]);
                push (@toclist, length($el[0])."..$el[1]");

                $toc .= $jump;
                $_ = $el[1];
                # wikiword links
#d612                s|([ ])([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1<a href=\"/ls.htm?path=$pname$2.txt\">$2</a>|g;
                s|([ ])([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1<a href=\"/ls.htm/$2.htm?path=$pname$2.txt\">$2</a>|g;
                # special case when wiki word is the first word without leading space
#d612                s|^([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|<a href=\"/ls.htm?path=$pname$1.txt\">$1</a>|;
                s|^([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|<a href=\"/ls.htm/$1.htm?path=$pname$1.txt\">$1</a>|;
                # !not wiki
                s|!([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1|g;
                if ($flags & 4) {
                    # 'bare'
                    $_ = $anchor .
                         sprintf("<h%d>",length($el[0])) .
                         $_ .
                         sprintf("</h%d>",length($el[2])) .
                         $el[3];
                } else {
                    # normal
                    $_ = $anchor .
                         sprintf("<h%d>",length($el[0])) .
                         $_ .
                         " <a href=\"#$tag\">here</a>".
                         " <a href=\"#___top___\">top</a>" .
                         " <a href=\"#__toc__\">toc</a>" .
                         " <a href=\"/blog.htm?path=$pname$fname&afterline=$lnnoinfo\">lg</a>" .
                         " <a href=\"/edit.htm?path=$pname$fname&editline=on&blklineno=$lnnoinfo\">ed</a>" .
                         " <a href=\"/view.htm?path=$pname$fname&update=Skip&skip=$lnnoinfo&maxln=200\">vw</a>" .
                         sprintf("</h%d>",length($el[2])) .
                         "<a name=\"${tag}_\"></a>".
                         $el[3];
                }
                if ($lnnoinfo ne '') {
                    # we have saved tags, now put back as line1 anchors
                    if($lnnoinfo =~ /,/) {
                        foreach $tmp (split(',', $lnnoinfo)) {
                            $oubuf .=  "<a name=\"line$tmp\"></a>";
                        }
                    } else {
                        $oubuf .=  "<a name=\"line$lnnoinfo\"></a>";
                    }
                }
                $oubuf .= "$_\n";
                next;
            }
        }
        # '=' interferes with heading shorthand, global replace ____EqSg____ = later
        s/____EqSg____/=/g;

        # %::INDEX::% processing
        if (/^::.+::$/ &&       # starts and ends with ::
            !/:::/) {           # no :::
            $oubuf .= "<a name=\"$_\"></a>\n";
            $toccol .= "<a href=\"#$_\">$_</a><br>\n";
        }

        # make http links
        s/\n//g;
        s/\r//g;
        # Makes http links a [[wikilink]]
        # For http(s) not preceeded by [|" becomes whatever [[http...]]
        s|([^\[\|"])(https*://[^ ]+)|$1\[\[$2\]\]|g;
        # make it work on column 0 too
#c518        s|^(https*://[^ ]+)|\[\[$1\]\]|;
        s|^(https*://[^ ]+)| \[\[$1\]\]|;
        # process multiple [[ ]] on the line
        @els = split (']]', $_);
        $_ = '';
        foreach $el (@els) {
            if (($tx,$url) = $el =~ /^(.+)\[\[(.+)$/) {
                # now have a line ending in only one pair of [[wikilink]]
                # i.e. $tx[[$url]]
#               ($tx,$url) = split ("]]", $el);

                if (($url =~ /^#/) && !($url =~ /\|/)) {
                    # local anchor
                    ($http) = ($url =~ /^#([^|]+)$/);
                    # i.e. $tx[[#$url]]
                    $_ .= $tx . "<a name=\"$http\">";
                } elsif ((($http, $desc) = ($url =~ /^#([^|]+)\|(.*)$/))) {
                    # i.e. $tx[[$url|desc]]
                    # link to local anchor
                    $_ .= $tx . "<a href=\"\#$http\">$desc</a>";
                } else {
                    if (!(($http, $desc) = ($url =~ /^([^|]+)\|(.*)$/))) {
                        # URL of form [[wikilink]] and not [[http|name]]
                        # description is the URL
                        $http = $url;
                        $desc = $url;
                    }
                    if ($http =~ m|^/|) {
                        # relative URL, use as is
                        # Palm TX wants to see ending in .htm
                        #$http .= '&tx=a.htm';
                        # add /abc.htm
                        $http =~ s|^/(\w+)\.pl|/$1.htm|;
                    } elsif (!($http =~ m|https*://|)) {
                        # make wikilink into l00httpd/ls.pl link
                        $tmp = $http;
                        if ($tmp =~ /^([^&#]+)/) {
                            # '#' to drop anchor
                            $tmp = $1;
                        }
#d612                        $http = "/ls.htm/$tmp?path=".$pname.$http;
                        $http = "/ls.htm/$tmp.htm?path=".$pname.$http;
                    }
                    $_ .= $tx . "<a href=\"$http\">$desc</a>";
                }
            } else {
                # just a bare line without [[wikilink]]
                $_ .= $el;
            }
        }



        # find <hr> and clear bullet level
        #if (/<hr>/) {
        #    if ($bulvl > 0) {
        #        # generate closing bullets
        #        for (; $bulvl > 0; $bulvl--) {
        #            $oubuf .=  "</ul>";
        #        }
        #        $oubuf .= "\n";
        #    }
        #}

        # process font styles
        # **bold**    <strong>bold</strong>
              s/ \*\*([^ *][^*]+[^ *])\*\*$/ <strong> $1 <\/strong> /;# at EOL
              s/^\*\*([^ *][^*]+[^ *])\*\* / <strong> $1 <\/strong> /;# at EOL
              s/^\*\*([^ *][^*]+[^ *])\*\*$/ <strong> $1 <\/strong> /;# at EOL
              s/ \*\*([^ *][^*]+[^ *])\*\* / <strong> $1 <\/strong> /g;
        s/([ >|])\*\*([^ *][^*]+[^ *])\*\*([ <\]])/$1<strong> $2 <\/strong>$3/g;
        # *l*color bold**
#             s/ \*([rylsafgo])\*([^*]+?)\*[rylsafgo]\*$/ <strong><font style="color:black;background-color:$colorlu{$1}">$2<\/font><\/strong> /;# at EOL
#             s/^\*([rylsafgo])\*([^*]+?)\*[rylsafgo]\* / <strong><font style="color:black;background-color:$colorlu{$1}">$2<\/font><\/strong> /;# at EOL
#             s/^\*([rylsafgo])\*([^*]+?)\*[rylsafgo]\*$/ <strong><font style="color:black;background-color:$colorlu{$1}">$2<\/font><\/strong> /;# at EOL
#       s/([ >|])\*([rylsafgo])\*([^*]+?)\*[rylsafgo]\*([ <\]])/$1<strong><font style="color:black;background-color:$colorlu{$2}">$3<\/font><\/strong>$4/g;
              s/ \*([rylsafgo])\*([^*]+?)\*\*$/ <strong><font style="color:black;background-color:$colorlu{$1}">$2<\/font><\/strong> /;# at EOL
              s/^\*([rylsafgo])\*([^*]+?)\*\* / <strong><font style="color:black;background-color:$colorlu{$1}">$2<\/font><\/strong> /;# at EOL
              s/^\*([rylsafgo])\*([^*]+?)\*\*$/ <strong><font style="color:black;background-color:$colorlu{$1}">$2<\/font><\/strong> /;# at EOL
        s/([ >|])\*([rylsafgo])\*([^*]+?)\*\*([ <\]])/$1<strong><font style="color:black;background-color:$colorlu{$2}">$3<\/font><\/strong>$4/g;
        # //italics// <em>italics</em>
              s/ \/\/([^ \/][^\/]+[^ \/])\/\/$/ <em> $1 <\/em> /;    # at EOL
              s/^\/\/([^ \/][^\/]+[^ \/])\/\/ / <em> $1 <\/em> /;    # at EOL
              s/^\/\/([^ \/][^\/]+[^ \/])\/\/$/ <em> $1 <\/em> /;    # at EOL
        s/([ >|])\/\/([^ \/][^\/]+[^ \/])\/\/([ <\]])/$1<em> $2 <\/em>$3/g;
        # __underline__   <u>underline</u>
              s/ __([^ _][^_]+[^ _])__$/ <u> $1 <\/u> /;           # at EOL
              s/^__([^ _][^_]+[^ _])__ / <u> $1 <\/u> /;           # at EOL
              s/^__([^ _][^_]+[^ _])__$/ <u> $1 <\/u> /;           # at EOL
        s/([ >|])__([^ _][^_]+[^ _])__([ <\]])/$1<u>$2<\/u>$3/g;
        # --strike-- <strike>strike</strike>
              s/ --([^ \-][^\-]+[^ \-])--$/ <strike> $1 <\/strike> /;    # at EOL
              s/^--([^ \-][^\-]+[^ \-])-- / <strike> $1 <\/strike> /;    # at EOL
              s/^--([^ \-][^\-]+[^ \-])--$/ <strike> $1 <\/strike> /;    # at EOL
        s/([ >|])--([^ \-][^\-]+[^ \-])--([ <\]])/$1<strike> $2 <\/strike>$3/g;
        # {{monospace}}   <tt>monospace</tt>
        # {{{{{{{{{{{{ match in search pattern so editor match works
              s/ \{\{([^ \}][^\}]+[^ \}])\}\}$/ <tt> $1 <\/tt> /;   # at EOL
              s/^\{\{([^ \}][^\}]+[^ \}])\}\} / <tt> $1 <\/tt> /;   # at EOL
              s/^\{\{([^ \}][^\}]+[^ \}])\}\}$/ <tt> $1 <\/tt> /;   # at EOL
        s/([ >|])\{\{([^ \}][^\}]+[^ \}])\}\}([ <\]])/$1<tt>$2<\/tt>$3/g;

        # table
        if (/^\|\|/) {
            if ($intbl != 1) {
                $intbl = 1;
                if ($bulvl > 0) {
                    # generate closing bullets
                    for (; $bulvl > 0; $bulvl--) {
                        $oubuf .= "</ul>";
                    }
                    $oubuf .= "\n";
                }
                $oubuf .= "    <table border=\"1\" cellpadding=\"1\" cellspacing=\"1\">\n";
            }
            if ($lnnoinfo ne '') {
                # we have saved tags, now put back as line1 anchors
                if($lnnoinfo =~ /,/) {
                    foreach $tmp (split(',', $lnnoinfo)) {
                        $oubuf .=  "<a name=\"line$tmp\"></a>";
                    }
                } else {
                    $oubuf .=  "<a name=\"line$lnnoinfo\"></a>";
                }
            }
            $oubuf .= "<tr>\n";
            # Perl/SL4A doesn't handle split ("\|\|", $_);????
            s/\|\|/``/g;
            @cols = split ("``", $_);
            for ($ii = 1; $ii <= $#cols; $ii++) {
                if ($cols[$ii] =~ /^ *$/) {
                    $oubuf .= "<td>&nbsp;</td>\n";
                } else {
                    $oubuf .= "<td>$cols[$ii]</td>\n";
                }
            }
            $oubuf .= "</tr>\n";
            # skip bullet processing
            next;
        }

        # convert geo: to http links
        s|(geo:[0-9,\.\-\+]+)\?q=(\S+)|<a href=\"$1?q=$2\">$2</a>|g;

        $leadcolor = '';
        if ((($leadcolor,$lv,$tx) = /^(<.+?>)(\*+) (.*)$/)) {
            # special case for colored bullet
            # remove $leadcolor and add it back later
            $_ = "$lv $tx";
        }
        if (($lv,$tx) = /^(\*+) (.*)$/) {
            if ($mode0unknown1twiki2markdown == 2) {
                # markdown multiple line bullet support
                #print "0)>$_<(\n";
                while (($cacheidx + 1) < $#inputcache) {
                    $tmp = $inputcache[$cacheidx + 1];
                    if ($tmp =~ /%l00httpd:lnno:([0-9,]+)%/) {
                        # remove internal tag
                        $tmp =~ s/%l00httpd:lnno:([0-9,]+)%//;
                    }
                    # $tmp is next line (looking ahead)
                    if ($tmp =~ /^$/) {
                        last;
                    } elsif ($tmp =~ /^[^ *=:&|]/) {
                        # looks like a normal line, concatenate it
                        #print "+)>$tmp<(\n";
                        $_ .= " $tmp";
                        # rescan/reparse
                        ($lv,$tx) = /^(\*+) (.*)$/;
                        $cacheidx++;    # point to next line and check again
                    } else {
                        last;
                    }
                }
            }
            # process bullets
            $lvn = length ($lv);
            if ($lvn > $bulvl) {
                for (; $bulvl < $lvn; $bulvl++) {
                    $oubuf .=  "<ul>";
                }
            } elsif ($lvn < $bulvl) {
                for (; $bulvl > $lvn; $bulvl--) {
                    $oubuf .=  "</ul>";
                }
            }
            # wikiword links
            $tx =~ s|([ ])([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1<a href=\"/ls.htm/$2.htm?path=$pname$2.txt\">$2</a>|g;
            # special case when wiki word is the first word without leading space
            $tx =~ s|^([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|<a href=\"/ls.htm/$1.htm?path=$pname$1.txt\">$1</a>|;
            # !not wiki
            $tx =~ s|!([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1|g;
            # rebase: fix wiki base directory when the l00httpd direct has been changed, like viewing on PC
            # in l00httpd.cfg
            #rebasefr^path=/sdcard/
            #rebaseto^path=c:/info/
            if (defined ($ctrl->{'rebasefr'}) &&
                defined ($ctrl->{'rebaseto'})) {
                $tx =~ s/$ctrl->{'rebasefr'}/$ctrl->{'rebaseto'}/g;
            }
            
            if ($lnnoinfo ne '') {
                # we have saved tags, now put back as line1 anchors
                if($lnnoinfo =~ /,/) {
                    foreach $tmp (split(',', $lnnoinfo)) {
                        $oubuf .=  "<a name=\"line$tmp\"></a>";
                    }
                } else {
                    $oubuf .=  "<a name=\"line$lnnoinfo\"></a>";
                }
            }
            $oubuf .=  "<li>$leadcolor$tx</li>\n";
        } else {
            # any non bullet resets bullet level
            if ($bulvl > 0) {
                # generate closing bullets
                for (; $bulvl > 0; $bulvl--) {
                    $oubuf .=  "</ul>";
                }
                #$oubuf .= "\n";
            }
            # wikiword links
            # Palm TX wants to see ending in .htm
            #s|([ ])([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1<a href=\"/ls.htm?path=$pname$2.txt&tx=$2.htm\">$2</a>|g;
#d612            s|([ ])([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1<a href=\"/ls.htm?path=$pname$2.txt\">$2</a>|g;
            s|([ ])([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1<a href=\"/ls.htm/$2.htm?path=$pname$2.txt\">$2</a>|g;
            # special case without space in front
            s|>([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|><a href=\"/ls.htm/$1.htm?path=$pname$1.txt\">$1</a>|g;
            # special case when wiki word is the first word without leading space
            #s|^([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|<a href=\"/ls.htm?path=$pname$1.txt&tx=$1.htm\">$1</a>|;
#d612            s|^([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|<a href=\"/ls.htm?path=$pname$1.txt\">$1</a>|;
            s|^([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|<a href=\"/ls.htm/$1.htm?path=$pname$1.txt\">$1</a>|;
            # !not wiki
            s|!([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1|g;
            if (/<pre>/) {
                $ispre = 1;
            }
            if (defined ($ctrl->{'rebasefr'}) &&
                defined ($ctrl->{'rebaseto'})) {
                s/$ctrl->{'rebasefr'}/$ctrl->{'rebaseto'}/g;
            }

            if ($lnnoinfo ne '') {
                # we have saved tags, now put back as line1 anchors
                if($lnnoinfo =~ /,/) {
                    foreach $tmp (split(',', $lnnoinfo)) {
                        $oubuf .=  "<a name=\"line$tmp\"></a>";
                    }
                } else {
                    $oubuf .=  "<a name=\"line$lnnoinfo\"></a>";
                }
            }
            if ($ispre) {
                $oubuf .=  "$_\n";
            } else {
                if ($markdownparanobr) {
                    # MARKDOWN mode, paragraph not ended yet
                    $oubuf .=  "$_\n";
                } else {
                    $oubuf .=  "$_<br>\n";
                }
            }
            if (/<\/pre>/) {
                $ispre = 0;
            }
        }
    }
    if ($bulvl > 0) {
        # generate closing bullets
        for (; $bulvl > 0; $bulvl--) {
            $oubuf .=  "</ul>";
        }
        $oubuf .= "\n";
    }



    # The next statement overwrites the old style TOC with 
    # collapsible Java TOC.  Uncomment to restore old style TOC
    $toc = &makejavatoc ();
#print $toc;
    if ($flaged ne '') {
        $flaged = "<b><i>BOOKMARKS:</i></b><br>$flaged<hr>\n";
    }
    if ($postsit ne '') {
        $postsit = join ("\n", sort (split ("\n", $postsit)));
        $postsit = "<b><i>POSTS-IT NOTE:</i></b><br>$postsit<hr>\n";
    }
    $toc = "<a name=\"__toc__\"></a>$postsit$flaged$toc<a name=\"__tocend__\"></a>";

    $toc =~ s/<br>$//;

    # Replace special %TOC% tag with the created $toc
    # There are 4 cases:
    #  at the beginning
    #  after \r
    #  after \n
    #  after any HTML tag '>'

    if ($toccol ne '') {
        $toc = "<a href=\"#::INDEX::\">jump to ::INDEX::</a><br>" . $toc;
    }

    $oubuf =~ s/hr>%TOC% *<br>/hr>$toc<hr>/g;
    $oubuf =~ s/br>%TOC% *<br>/br><hr>$toc<hr>/g;
    $oubuf =~ s/\/ul>%TOC% *<br>/\/ul><hr>$toc<hr>/g;
    $oubuf =~ s/\/a>%TOC% *<br>/\/a><hr>$toc<hr>/g;
    $oubuf =~ s/\r%TOC% *<br>/\r<hr>$toc<hr>/g;
    $oubuf =~ s/\n%TOC% *<br>/\n<hr>$toc<hr>/g;

    $oubuf =~ s/hr>%TOC%/hr>$toc<hr>/g;
    $oubuf =~ s/br>%TOC%/br><hr>$toc<hr>/g;
    $oubuf =~ s/\/ul>%TOC%/\/ul><hr>$toc<hr>/g;
    $oubuf =~ s/\/a>%TOC%/\/a><hr>$toc<hr>/g;
    $oubuf =~ s/\r%TOC%/\r<hr>$toc<hr>/g;
    $oubuf =~ s/\n%TOC%/\n<hr>$toc<hr>/g;

    if (($flags & 4) == 0) {
        # not 'bare'
        $oubuf .= " <a href=\"#___top___\">top</a>";
        $oubuf .= " <a href=\"#__toc__\">toc</a>";
    }

    if ($toccol ne '') {
        $toccol = join ("\n", sort (split ("\n", $toccol)));
        $toccol = "<a name=\"::INDEX::\"></a><b><i>INDEX:</i></b>" . $toccol;
#        $oubuf = "<a href=\"#::INDEX::\">jump to ::INDEX::</a><br>" . $oubuf;
        $tmp = '';
        foreach $_  (split ("\n", $oubuf)) {
            s/%::INDEX::%/<hr>$toccol<hr>/;
            if ($tmp eq '') {
                $tmp = "$_";
            } else {
                $tmp .= "\n$_";
            }
        }
        $oubuf = $tmp;
    }

    # \n messes with lineno line count; take out
    #$oubuf =~ s/<a href/\n<a href/g;

# is this superceded by path=./ substitution in ls.pl?
# expand href="... path=./ to current dir
$oubuf =~ s|(href="[^ ]+path=)\.\/([^ ]+)|$1$pname$2|g;

    # expand img src="./ to current dir
    $oubuf =~ s|(img src=")\.\/([^ ]+)|$1$pname$2|g;

    # make all links to open in 'newwin'
    if (($flags & 8) != 0) {
        # make all non local anchor link to open in 'newwin'
        $oubuf =~ s|<a (href="[^#])|<a target="newwin" $1|g;
    }


    $oubuf;
}

1;
