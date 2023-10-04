package l00wikihtml; 
use l00httpd;
my (@toclist, $java, $showalljava);


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

$showalljava = "\n".
"<script type=\"text/javascript\">\n".
"var dge=document.getElementById;\n".
"function cl_showall(){\n".
"    if(!dge)return;\n".
"    var hidx = 1;\n".
"    var doc;\n".
"    while (doc = document.getElementById('hide'+hidx)) {\n".
"        doc.style.display = \n".
"            (doc.style.display=='none') ? 'block':'block';\n".
"        hidx++;\n".
"    }\n".
"}\n".
"</script>\n\n";


my (%colorlu, %colorfg);
$colorlukeys = '_rylsafgoOdGDbSpLTBhu0123456789';
$colorlu{'_'} = 'white';            $colorfg{'r'} = 'black';
$colorlu{'r'} = 'red';              $colorfg{'r'} = 'yellow';
$colorlu{'y'} = 'yellow';           $colorfg{'y'} = 'black';
$colorlu{'l'} = 'lime';             $colorfg{'l'} = 'black';
$colorlu{'s'} = 'silver';           $colorfg{'s'} = 'black';
$colorlu{'a'} = 'aqua';             $colorfg{'a'} = 'black';
$colorlu{'f'} = 'fuchsia';          $colorfg{'f'} = 'yellow';
$colorlu{'g'} = 'gray';             $colorfg{'g'} = 'white';
$colorlu{'o'} = 'olive';            $colorfg{'o'} = 'white';
$colorlu{'O'} = 'orange';           $colorfg{'O'} = 'black';
$colorlu{'d'} = 'gold';             $colorfg{'d'} = 'black';
$colorlu{'G'} = 'green';            $colorfg{'G'} = 'LightGray';
$colorlu{'D'} = 'DeepPink';         $colorfg{'D'} = 'white';
$colorlu{'b'} = 'Brown';            $colorfg{'b'} = 'yellow';
$colorlu{'S'} = 'DeepSkyBlue';      $colorfg{'S'} = 'black';
$colorlu{'p'} = 'Purple';           $colorfg{'p'} = 'black';
$colorlu{'L'} = 'LightGray';        $colorfg{'L'} = 'black';
$colorlu{'T'} = 'Teal';             $colorfg{'T'} = 'white';
$colorlu{'B'} = 'SandyBrown';       $colorfg{'B'} = 'black';
$colorlu{'h'} = 'HotPink';          $colorfg{'h'} = 'black';
$colorlu{'u'} = 'blue';             $colorfg{'u'} = 'black';

$colorlu{'0'} = 'Salmon';           $colorfg{'0'} = 'black';
$colorlu{'1'} = 'Khaki';            $colorfg{'1'} = 'black';
$colorlu{'2'} = 'YellowGreen';      $colorfg{'2'} = 'black';
$colorlu{'3'} = 'Aquamarine';       $colorfg{'3'} = 'black';
$colorlu{'4'} = 'Plum';             $colorfg{'4'} = 'black';

$colorlu{'5'} = 'LightSalmon';      $colorfg{'5'} = 'black';
$colorlu{'6'} = 'Moccasin';         $colorfg{'6'} = 'black';
$colorlu{'7'} = 'DarkSeaGreen';     $colorfg{'7'} = 'black';
$colorlu{'8'} = 'LightSteelBlue';   $colorfg{'8'} = 'black';
$colorlu{'9'} = 'MediumPurple';     $colorfg{'9'} = 'black';


sub l00wikihtml_fontsty {
    my ($buf) = @_;

    # **bold**    <strong>bold</strong>
    # i608: changing [^*]+ to [^*]* so **ab** would work. Any side effect?
    $buf =~       s/ \*\*([^ *][^*]*[^ *])\*\*$/ <strong> $1 <\/strong> /;# at EOL
    $buf =~       s/^\*\*([^ *][^*]*[^ *])\*\* / <strong> $1 <\/strong> /;# at EOL
    $buf =~       s/^\*\*([^ *][^*]*[^ *])\*\*$/ <strong> $1 <\/strong> /;# at EOL
    $buf =~       s/ \*\*([^ *][^*]*[^ *])\*\* / <strong> $1 <\/strong> /g;
    $buf =~ s/([ >|])\*\*([^ *][^*]*[^ *])\*\*([ <\]])/$1<strong> $2 <\/strong>$3/g;
    # *l*color bold**
    $buf =~       s/ \*([$colorlukeys])\*([^*]+?)\*\*$/ <strong><font style="color:$colorfg{$1};background-color:$colorlu{$1}">$2<\/font><\/strong> /;# at EOL
    $buf =~       s/^\*([$colorlukeys])\*([^*]+?)\*\* / <strong><font style="color:$colorfg{$1};background-color:$colorlu{$1}">$2<\/font><\/strong> /;# at EOL
    $buf =~       s/^\*([$colorlukeys])\*([^*]+?)\*\*$/ <strong><font style="color:$colorfg{$1};background-color:$colorlu{$1}">$2<\/font><\/strong> /;# at EOL
    $buf =~ s/([ >|])\*([$colorlukeys])\*([^*]+?)\*\*([ <\]])/$1<strong><font style="color:$colorfg{$2};background-color:$colorlu{$2}">$3<\/font><\/strong>$4/g;
    # //italics// <em>italics</em>
    $buf =~       s/ \/\/([^ \/][^\/]*[^ \/])\/\/$/ <em> $1 <\/em> /;    # at EOL
    $buf =~       s/^\/\/([^ \/][^\/]*[^ \/])\/\/ / <em> $1 <\/em> /;    # at EOL
    $buf =~       s/^\/\/([^ \/][^\/]*[^ \/])\/\/$/ <em> $1 <\/em> /;    # at EOL
    $buf =~ s/([ >|])\/\/([^ \/][^\/]*[^ \/])\/\/([ <\]])/$1<em> $2 <\/em>$3/g;
    # __underline__   <u>underline</u>
    $buf =~       s/ __([^ _][^_]*[^ _])__$/ <u> $1 <\/u> /;           # at EOL
    $buf =~       s/^__([^ _][^_]*[^ _])__ / <u> $1 <\/u> /;           # at EOL
    $buf =~       s/^__([^ _][^_]*[^ _])__$/ <u> $1 <\/u> /;           # at EOL
    $buf =~ s/([ >|])__([^ _][^_]*[^ _])__([ <\]])/$1<u>$2<\/u>$3/g;
    # --strike-- <strike>strike</strike>
    $buf =~       s/ --([^ \-][^\-]*[^ \-])--$/ <strike> $1 <\/strike> /;    # at EOL
    $buf =~       s/^--([^ \-][^\-]*[^ \-])-- / <strike> $1 <\/strike> /;    # at EOL
    $buf =~       s/^--([^ \-][^\-]*[^ \-])--$/ <strike> $1 <\/strike> /;    # at EOL
    $buf =~ s/([ >|])--([^ \-][^\-]*[^ \-])--([ <\]])/$1<strike> $2 <\/strike>$3/g;
    # {{monospace}}   <tt>monospace</tt>
    # {{{{{{{{{{{{ match in search pattern so editor match works
    $buf =~       s/ \{\{([^ \}][^\}]*[^ \}])\}\}$/ <tt> $1 <\/tt> /;   # at EOL
    $buf =~       s/^\{\{([^ \}][^\}]*[^ \}])\}\} / <tt> $1 <\/tt> /;   # at EOL
    $buf =~       s/^\{\{([^ \}][^\}]*[^ \}])\}\}$/ <tt> $1 <\/tt> /;   # at EOL
    $buf =~ s/([ >|])\{\{([^ \}][^\}]*[^ \}])\}\}([ <\]])/$1<tt>$2<\/tt>$3/g;

    $buf;
}


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

        # make an anchor as section jump target
        $anchor =~ s/name="/name="toc_/;
        $output .= '  ' x $thislvl . "<li>$jump$anchor\n";
        $needclose = 1;
        $order++;
    }
    for ($thislvl; $thislvl >= 0; $thislvl--) {
        $output .= '  ' x $thislvl . "</li>\n";
        $output .= '  ' x $thislvl . "</ul>\n";
    }

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

    # Handle !NonWikiWord
    $ttl =~ s|!([A-Z]+[0-9a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1|g;

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
    #       16=newline is always <br>
    #       32=if link is graphics, embedded instead of linking to it
    #       64=markdown
    # $ctrl: system variables
    # $pname: current path for relateive wikiword links
    my ($ctrl, $pname, $inbuf, $flags, $fname) = @_;
    my ($oubuf, $bulvl, $tx, $lvn, $desc, $http, $toc, $toccol);
    my ($intbl, @cols, $ii, $lv, $el, $url, @el, @els, $__lineno__);
    my ($jump, $anchor, $last, $tmp, $ahead, $tbuf, $color, $colorfg, $tag, $bareclip);
    my ($desc, $url, $bullet, $bkmking, $clip, $bookmarkkeyfound);
    my ($lnno, $flaged, $postsit, @chlvls, $thischlvl, $lastchlvl);
    my ($lnnoinfo, @lnnoall, $leadcolor, @inputcache, $cacheidx, $seenEqualStar);
    my ($mode0unknown1twiki2markdown, $mdChanged2Tw, $markdownparanobr, $loop);
    my ($hideBlkActive, $hideBlkId, $pnameurl, $fnameurl, $target);

    undef @chlvls;
    undef $lastchlvl;

    $hideBlkActive = 0;
    $hideBlkId = 0;

    if (!defined($fname)) {
        $fname = '(undef)';
    }

    # escape + for URL
    $pnameurl = $pname;
    $fnameurl = $fname;
    $pnameurl =~ s/\+/%2B/g;
    $fnameurl =~ s/\+/%2B/g;


    $bookmarkkeyfound = 0;
    if (($flags & 1) == 0) {
        # not specified for BOOKMARK
        # search %BOOKMARK% in first 8000 lines
        $tmp = 0;
        foreach $_  (split ("\n", $inbuf)) {
            # Erase tags for normal processing
            s/%l00httpd:lnno:(\d+)%//;
            if (/^%BOOKMARK%/) {
                $bookmarkkeyfound = 1;
                last;
            }
            if ($tmp++ > 8000) {
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
            } elsif (($desc, $clip) = /^ *(.*) *\|\|\|(.+)$/) {
                # short hand send URL to Android's Activity or Windows' start: desc |||URL

                # clip
                $desc =~ s/ +$//g;
                $bareclip = 0;
                if ($desc eq '') {
		            $desc = $clip;
                    $bareclip = 1;
		        }

                #http://127.0.0.1:20337/clip.htm?update=Copy+to+clipboard&clip=
                #%3A%2F
                $clip = &l00httpd::urlencode ($clip);
                $url = "/activity.htm?path=$clip";
                $url = "[[$url|$desc&#8227;&#8227;]]";
                if ($bareclip) {
                    #$url = "&lt;$url&gt;";
		        }
                if ($last =~ /^\*/) {
                    $inbuf .= "$url";
                } else {
                    $inbuf .= " - $url";
                }
            } elsif (($desc, $clip) = /^ *(.*) *\|\|(.+)$/) {
                # clip
                $desc =~ s/ +$//g;
                $bareclip = 0;
                if ($desc eq '') {
		            $desc = $clip;
                    $bareclip = 1;
		        }

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

                        # drop ending \r\n
                        $clip =~ s/\\r\\n$//;
                        # append extension line
                        $clip .= "\n$tmp";
                        # skip forward
                        $cacheidx++;
                    } else {
                        # no extension line
                        last;
                    }
                }        

                #http://127.0.0.1:20337/clip.htm?update=Copy+to+clipboard&clip=
                #%3A%2F
                $clip = &l00httpd::urlencode ($clip);
                $url = "/clip.htm?update=Copy+to+clipboard&clip=$clip";
                $url = "[[$url|$desc&#8227;]]";
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
            } elsif (($desc, $url) = /^(&nbsp;) *\| *(.+)$/) {
                # special case of above with only one space (&nbsp;), case b
                # bookmarks; must start in column or 1
                $desc =~ s/ +$//g;
                if ($last =~ /^\*/) {
                    $inbuf .= "[[$url|$desc]]";
                } else {
                    $inbuf .= " - [[$url|$desc]]";
                }
            } elsif (($desc, $url) = /^(&nbsp;[^&].+) *\| *(.+)$/) {
                # special case of above with only one space (&nbsp;), case a
                # bookmarks; must start in column or 1
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
    if (($flags & 64) == 0) {
        $mode0unknown1twiki2markdown = 0;
    } else {
        $mode0unknown1twiki2markdown = 2;
    }
    $markdownparanobr = 0;
    @inputcache = split ("\n", $inbuf); # allows look forward
    $seenEqualStar = 0;
    for ($cacheidx = 0; $cacheidx <= $#inputcache; $cacheidx++) {
        $_ = $inputcache[$cacheidx];
        # translate all %L00HTTP<plpath>% to $ctrl->{'plpath'}
        if (/%L00HTTP<(.+?)>%/) {
            if (defined($ctrl->{$1})) {
                s/%L00HTTP<(.+?)>%/$ctrl->{$1}/g;
            }
        }
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


        # verbatim
        if (/^%VERBATIM%/) {
            # restart verbatim
            $verbatimActive = 1;
            next;
        } elsif (/^%VERBATIMEND%/) {
            # ends verbatim
            $verbatimActive = 0;
            next;
        } elsif ($verbatimActive != 0) {
            # verbatim
            $oubuf .=  "$_\n";
            next;
        }



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
                # Markdown link: [example link](http://example.com/).
                if ($tmp =~ /\[(.+?)\]\((.+?)\)/) {
                    # occurance of markdwon link says we are in markdown mode
                    $mode0unknown1twiki2markdown = 2;
                    $mdChanged2Tw = 1;
                }
                # markdown bullets
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
                $tmp =~ s/[\n\r]//g;
                # is it an extension line?
                # i608: line continues unless it's:
                # * for bullet
                # = for paragrap
                # | for table
                # " for hide paragraph
                # % for wiki commands
                                                # if not
                if (($tmp !~ /^[=\*\|%]/) &&    # starts with =*|"%
                    ($tmp !~ /^""/) &&          # """" paragraph hiding
                    ($tmp !~ /^ *$/) &&         # blank line
                    ($tmp !~ /^  /)) {          # indent
                    $_ .= " $tmp";
                    # consume the line
                    $cacheidx++;
                } else {
                    last;
                }
            }
        }

        # password/ID clipboard
        # send code to clipboard: * ALLCAP: xyz
#if (/\* (ID|PW): (\S+) *$/)
        if (/\* ([A-Z]{2,16}): (\S+) *$/) {
            $clip = &l00httpd::urlencode ($2);
            $tmp = sprintf ("<a href=\"/clip.htm?update=Copy+to+clipboard&clip=%s\" target=\"_blank\">%s&#8227;</a>", $clip, $2);
            $_ .= " ($tmp)";
        }

        #"""" alone in a line brackets a block to be hidden by
        # default and to be shown when clicked.
        # The first """" should be after a paragraph heading
        # The second """" should be before a paragraph heading
        if (/^""""[v^]*$/) {
            if ($hideBlkActive) {
                $hideBlkActive = 0;
                $oubuf .= "</div>\n";
            } else {
                $hideBlkActive = 1;
                $hideBlkId++;
                if ($hideBlkId == 1) {
                    $oubuf .= "$java";
                }
                $oubuf .= "<a href=\"javascript:cl_expcol('hide$hideBlkId');\">[show]</a>\n";
                $oubuf .= "<div id=\"hide$hideBlkId\" style=\"display:none\">\n";
            }
            next;
        }



        # ## headings
        if (($mode0unknown1twiki2markdown == 2) && (/^(#+) (\S.*)$/)) {
            # convert only if we are in markdown mode
            $_ = '=' x length($1) . $2 . '=' x length($1) . "\n";
            $mdChanged2Tw = 1;
        }
        # - bullets
        if ($mode0unknown1twiki2markdown == 2) {
            # handle - as bullet
            $tmp = $_;
            while ($tmp =~ s/^( *)&nbsp;/$1 /) {
            }
            if ($tmp =~ /^( *)- (.+)$/) {
                $_ = '*' x (length($1) / 2 + 1) . " $2";
                $mdChanged2Tw = 1;
            }
            # handle table wit one |
            if (/^\|.*\|$/) {
                s/\|/\|\|/g;
            }
        }

        # images
        # ![alt text](/path/to/img.jpg "Title")
        s/!\[.+?\]\((.+?) *"(.+?)"\)/<img src="$1">$2/g;
        s/!\[.+?\]\((.+?)\)/<img src="$1">$2/g;
        # links
        # This is an [example link](http://example.com/).
        s/\[(.+?)\]\((.+?)\)/<a href="$2">$1<\/a>/g;
        # mutiple line paragraphs

        # if line start with word, then it must be 
        # normal paragraph. Don't put <br> at the end
        # Do this for non markdown too. h630
        if (($flags & 16) == 0) {
            # do so only if not set: 16=newline is always <br>
            if (/^ *$/) {
                # blank line in markdown is end of paragraph
                $markdownparanobr = 1;
            } else {
                # this is a non-blank line
                if ($seenEqualStar == 0) {
                    # if we haven't seen ^* or ^=, then newline is <br>
                    $markdownparanobr = 0;
                } else {
                    # if we have seen ^* or ^=, then do not 
                    # add <br> if this line starts with non-blank
                    $markdownparanobr = /^[^ ]/;
                }
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
            $tmp =~ s/[\r\n]//g;
            # process font color short hand
            $tmp = &l00wikihtml_fontsty($tmp);
            # currnet line is indented
            $tbuf = "$tmp\n";
            $ahead = $cacheidx + 1;
            # look forward
            $loop = 1;
            while (($loop) && ($ahead <= $#inputcache)) {
                # $#inputcache prevents run away mismatch
                $tmp = $inputcache[$ahead];
                if ($tmp =~ /%l00httpd:lnno:([0-9,]+)%/) {
                    $tmp =~ s/%l00httpd:lnno:([0-9,]+)%//;
                }
                $tmp =~ s/&nbsp;/ /g;
                if ($tmp =~ /^  /) {
                    $tmp =~ s/[\r\n]//g;
                    # process font color short hand
                    $tmp = &l00wikihtml_fontsty($tmp);
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
#gc11 - format %TXTDOPL.*%
        # Print %TXTDOPL.*% in <pre>
        if (/^\%TXTDOPL[^<>]*\%/) {
            $tbuf = "$_\n";
            $ahead = $cacheidx + 1;
            # look forward
            $loop = 1;
            while (($loop) && ($ahead <= $#inputcache)) {
                # $#inputcache prevents run away mismatch
                $tmp = $inputcache[$ahead];
                if ($tmp =~ /%l00httpd:lnno:([0-9,]+)%/) {
                    $tmp =~ s/%l00httpd:lnno:([0-9,]+)%//;
                }
                $tmp =~ s/&nbsp;/ /g;
                $tbuf .= "$tmp\n";
                if ($tmp =~ /^\%TXTDOPL[^<>]*\%/) {
                    $loop = 0;
                } else {
                    $ahead++;
                    $mdChanged2Tw = 1;
                }
            }
            $tbuf =~ s/</&lt;/g;
            $tbuf =~ s/>/&gt;/g;
            $tbuf =~ s/&/&amp;/g;
            $tbuf = "<pre>$tbuf</pre>";
            $cacheidx = $ahead;
            $oubuf .= $tbuf;
            $_ = '';
            next;
        }
#gc11 - format %TXTDOPL.*%



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
        if (/^(.*)\?\?\?([$colorlukeys]*)$/) {
            $tmp = $1;
            if (defined($colorlu{$2})) {
                $color = $colorlu{$2};
                $colorfg = $colorfg{$2};
            } else {
                $color = 'white';
                $colorfg = 'black';
            }
            
            # drops *
            $tmp =~ s/^\*+ +//;
            # drops ==
            $tmp =~ s/^=+//;
            $tmp =~ s/=+$//;

            # make a sortable TOC entry
            $tmp = "<!-- $tmp --><font style=\"color:$colorfg;background-color:$color\"><a href=\"#lnno$lnno\">$tmp</a></font><br>\n";
            $postsit .= &l00wikihtml_fontsty($tmp);
            $oubuf .=  "<a name=\"lnno$lnno\">";
            # remove !!!
            s/\?\?\?[$colorlukeys]*$//;
            if (/^=.+=$/) {
                # '=' interferes with heading shorthand, global replace ____EqSg____ = later
                s/^(=+)([^=]+)(=+)$/$1 <font style____EqSg____"color:$colorfg;background-color:$color">$2<\/font> $3/g;
            } elsif (/^(\*+) (.+)$/) {
                # Preserve '*'
                $_ = "$1 <font style=\"color:$colorfg;background-color:$color\">$2</font> ";
            } else {
                $_ = " <font style=\"color:$colorfg;background-color:$color\">$_</font> ";
            }
            $_ .= " <a href=\"#___top___\">^</a>" .
                  " <a href=\"#__toc__\">toc</a>";
        }

        if ($hideBlkActive && /=(.+)=$/) {
            # gray out chapter hidden by """"
            # '=' interferes with heading shorthand, global replace ____EqSg____ = later
            s/^(=+)([^=]+)(=+)$/$1<font style____EqSg____"color:black;background-color:silver">$2<\/font>$3/g;
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
            $seenEqualStar = 1;
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
                # process font style in headings
                $el[1] = &l00wikihtml_fontsty($el[1]);

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
                s|([ ])([A-Z]+[0-9a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1<a href=\"/ls.htm/$2.htm?path=$pnameurl$2.txt\">$2</a>|g;
                # special case when wiki word is the first word without leading space
                    s|^([A-Z]+[0-9a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|<a href=\"/ls.htm/$1.htm?path=$pnameurl$1.txt\">$1</a>|;
                # !not wiki
                s|!([A-Z]+[0-9a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1|g;
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
                        #" <a href=\"#$tag\">@</a>".
                         " <a href=\"#___top___\">^</a>" .
                         " <a href=\"#__toc__\">toc</a>" .
                          "<a href=\"#toc_$tag\">@</a>" .   # jump to this entry in TOC
                         " <a href=\"/blog.htm?path=$pnameurl$fnameurl&afterline=$lnnoinfo\">lg</a>" .
                         " <a href=\"/edit.htm?path=$pnameurl$fnameurl&editline=on&blklineno=$lnnoinfo\">ed</a>" .
                         " <a href=\"/view.htm?path=$pnameurl$fnameurl&update=Skip&skip=$lnnoinfo&maxln=200\">$lnnoinfo</a>" .
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
        # Make [[[http://...jpg]]] <img src...>
        s/\[\[\[(https*:\/\/[^ ]+\.)(jpg|png|bmp|gif|svg|jpeg|wmf)\]\]\]/<img src=\"$1$2\">/g;
        # Makes http links a [[wikilink]]
        # For http(s) not preceeded by [|" becomes whatever [[http...]]
        s|([^\[\|"])(https*://[^ ]+)|$1\[\[$2\]\]|g;
        # make it work on column 0 too
        s|^(https*://[^ ]+)| \[\[$1\]\]|;
        # process multiple [[ ]] on the line
        @els = split (']]', $_);
        $_ = '';
        foreach $el (@els) {
            if (($tx,$url) = $el =~ /^(.+)\[\[(.+)$/) {
                # now have a line ending in only one pair of [[wikilink]]
                # i.e. $tx[[$url]]

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
                    $target = '';
                    if (($http, $desc) = ($url =~ /^([^|]+)\|\|(.*)$/)) {
                        $target = ' target="_blank"';
                    } else {
                        if (!(($http, $desc) = ($url =~ /^([^|]+)\|(.*)$/))) {
                            # URL of form [[wikilink]] and not [[http|name]]
                            # description is the URL
                            $http = $url;
                            $desc = $url;
                        }
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
                    # 32=if link is graphics, embedded instead of linking to it
                    if ($flags & 32) {
                        if (($url !~ /\|/) && 
                            ($http =~ /(\.jpg|\.png|\.bmp|\.gif|\.svg|\.jpeg|\.wmf)/i)) {
                            # make [[*.jpg]]
                            $_ .= $tx . "<img src=\"$http\">";
                        } else {
                            $_ .= $tx . "<a href=\"$http\">$desc</a>";
                        }
                    } else {
                        $_ .= $tx . "<a href=\"$http\"$target>$desc</a>";
                    }
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
        $_ = &l00wikihtml_fontsty($_);


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
            # wikiword
            $oubuf .= "<tr>\n";
            # Perl/SL4A doesn't handle split ("\|\|", $_);????
            s/\|\|/``/g;
            @cols = split ("``", $_);
            for ($ii = 1; $ii <= $#cols; $ii++) {
                # wikiword links
                $cols[$ii] =~ s|([ ])([A-Z]+[0-9a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1<a href=\"/ls.htm/$2.htm?path=$pnameurl$2.txt\">$2</a>|g;
                # special case when wiki word is the first word without leading space
                $cols[$ii] =~ s|^([A-Z]+[0-9a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|<a href=\"/ls.htm/$1.htm?path=$pnameurl$1.txt\">$1</a>|;
                # !not wiki
                $cols[$ii] =~ s|!([A-Z]+[0-9a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1|g;

                if ($cols[$ii] =~ /^ *$/) {
                    $oubuf .= "<td>&nbsp;</td>\n";
                } else {
                    $oubuf .= "<td valign=\"top\">$cols[$ii]</td>\n";
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
            $seenEqualStar = 1;
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
                    } elsif ($tmp =~ /^[^ *=:&|\-]/) {
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
            $tx =~ s|([ ])([A-Z]+[0-9a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1<a href=\"/ls.htm/$2.htm?path=$pnameurl$2.txt\">$2</a>|g;
            # special case when wiki word is the first word without leading space
            $tx =~ s|^([A-Z]+[0-9a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|<a href=\"/ls.htm/$1.htm?path=$pnameurl$1.txt\">$1</a>|;
            # !not wiki
            $tx =~ s|!([A-Z]+[0-9a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1|g;
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
            s|([ ])([A-Z]+[0-9a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1<a href=\"/ls.htm/$2.htm?path=$pnameurl$2.txt\">$2</a>|g;
            # special case without space in front
            s|>([A-Z]+[0-9a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|><a href=\"/ls.htm/$1.htm?path=$pnameurl$1.txt\">$1</a>|g;
            # special case when wiki word is the first word without leading space
            s|^([A-Z]+[0-9a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|<a href=\"/ls.htm/$1.htm?path=$pnameurl$1.txt\">$1</a>|;
            # !not wiki
            s|!([A-Z]+[0-9a-z]+[A-Z]+[0-9a-zA-Z_\-]*)|$1|g;
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

    if ($hideBlkId > 0) {
        if ($oubuf =~ /%TOC%/) {
            $toc = "$showalljava<a href=\"javascript:cl_showall();\">[show all hidden text]</a><br>$toc";
            $oubuf = "$showalljava$oubuf";
        } else {
            $oubuf = "$showalljava<br>$showalljava<a href=\"javascript:cl_showall();\">[show all hidden text]</a>$oubuf";
        }
        if ($hideBlkActive) {
            $oubuf .= "</div>There are odd number of \"\"\"\" block hide controls. Some text may be hidden unexpectedly.\n";
        }
    }


    if ($flaged ne '') {
        $flaged = &l00wikihtml_fontsty($flaged);
        $flaged = "<b><i><a href=\"__toctoc__\">BOOKMARKS</a>:</i></b><br>$flaged<hr>\n";
    }
    if ($postsit ne '') {
        $postsit = join ("\n", sort (split ("\n", $postsit)));
        $postsit = "<b><i><a href=\"__toctoc__\">POSTS-IT NOTE</a>:</i></b><br>$postsit<hr>\n";
    }
    $toc = "<a name=\"__toc__\"></a>$postsit$flaged<a name=\"__toctoc__\"></a>$toc<a name=\"__tocend__\"></a>";

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
        $oubuf .= " <a href=\"#___top___\">^</a>";
        $oubuf .= " <a href=\"#__toc__\">toc</a>";
    }

    if ($toccol ne '') {
        $toccol = join ("\n", sort (split ("\n", $toccol)));
        $toccol = "<a name=\"::INDEX::\"></a><b><i>INDEX:</i></b><br>" . $toccol;
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
        $oubuf =~ s|<a (href="[^#])|<a target="_blank" $1|g;
    }


    $oubuf;
}

1;
