use strict;
use warnings;
use l00httpd;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


#l00httpd::dbp($config{'desc'}, "2 contextln $contextln\n");
my %config = (proc => "l00http_dash_proc",
              desc => "l00http_dash_desc");

my ($dash_all, $hdronly, $listbang, $newbang, $newwin, $crlfchk, $crlf, $freefmt, $filtime, $fildesc,
$smallhead, $catflt, $cat2find, $outputsort, $dashwidth, $onlybang, $onlyhat, $target, $fildesc0itm1cat);

$dash_all = 'past';
$hdronly = 0;
$listbang = '';
$newwin = '';
$target = '';
$newbang = '';
$freefmt = '';
$smallhead = '';
$catflt = '.';
$cat2find = '';
$outputsort = '';
$dashwidth = 18;
$onlybang = '';
$onlyhat = '';
$filtime = '';
$fildesc = '';
$crlf = '';
$crlfchk = '';
$fildesc0itm1cat = '';

sub l00http_dash_linewrap {
    my ($buffer) = @_;
    my ($ii, $idx, $len, $newbuf, $inangle, $insquare, $width);

    $len = length($buffer);
    if ($len > 2) {
        # looking from the tail for '\n' or start (hence at least 3 bytes)
        for($idx = $len - 2; $idx >= 0; $idx--) {
            if (substr($buffer, $idx, 2) eq '\n') {
                # found last '\n'
                last;
            }
        }

        if ($idx > 0) {
            # found '\n' from the end, skip pass this '\n'
            $idx += 2;
        } else {
            # else $idx is 0 at the start
            $idx = 0;
        }
        if ($idx > 0) {
            # copy content before '\n'
            $newbuf .= substr($buffer, 0, $idx);
        }

        $inangle = 0;   # flag to exclude counting <tags>
        $insquare = 0;  # flag to exclude counting [[url|desc]]
        $width = 0;     # currently accumulated width
        for ($ii = $idx; $ii < $len; $ii++) {
            if (substr($buffer, $ii, 1) eq '<') {
                # found '<', to skip to '>'
                $inangle = 1;
            }
            if (substr($buffer, $ii, 2) eq '[[') {
                # found '[[', to skip to ']]'
                $insquare = 1;
            }
            if (($inangle == 0) && ($insquare == 0)) {
                # not in <> nor [[]], accounting width
                $width++;
                if (($width > $dashwidth) && 
                    (substr($buffer, $ii, 1) eq ' ')) {
                    # too wide, add newline
                    $newbuf .= ' \n';
                    $width = 1;
                }
            }
            if ($insquare) {
                if (substr($buffer, $ii - 1, 2) eq ']]') {
                    # in '[[' and found ']]', reset
                    $insquare = 0;
                }
            }
            if ($inangle) {
                if (substr($buffer, $ii, 1) eq '>') {
                    # in '<' and found '>', reset
                    $inangle = 0;
                }
            }
            # accumulate line
            $newbuf .= substr($buffer, $ii, 1);
        }
        $buffer = $newbuf;
    }

    $buffer;
}


sub l00http_dash_outputsort {
    my ($retval, $acat1, $bcat1, $acat2, $bcat2, $aa, $bb);

    if ($outputsort eq '') {
        $retval = $b cmp $a;
    } else {
        ($acat1, $acat2) = $a =~ /^\|\|.+?\|\|(.+?)\|\|(.+?)\|\|/;
        ($bcat1, $bcat2) = $b =~ /^\|\|.+?\|\|(.+?)\|\|(.+?)\|\|/;
        $acat1 =~ s/<.+?>//g;
        $bcat1 =~ s/<.+?>//g;
        $acat1 =~ s/^ //;
        $bcat1 =~ s/^ //;
        $acat1 =~ s/!//g;
        $bcat1 =~ s/!//g;
        $acat1 =~ s/\*\*//g;
        $bcat1 =~ s/\*\*//g;
        $acat1 =~ s/\*[a-zA-Z]\*//g;
        $bcat1 =~ s/\*[a-zA-Z]\*//g;

        $acat2 =~ s/<.+?>//g;
        $bcat2 =~ s/<.+?>//g;
        $acat2 =~ s/^ //;
        $bcat2 =~ s/^ //;
        $acat2 =~ s/!//g;
        $bcat2 =~ s/!//g;
        $acat2 =~ s/\*\*//g;
        $bcat2 =~ s/\*\*//g;
        $bcat2 =~ s/\*[a-zA-Z]\*//g;
        $acat2 =~ s/\*[a-zA-Z]\*//g;

        $aa = lc("$acat1 $acat2");
        $bb = lc("$bcat1 $bcat2");
       #print "$aa  cmp  $bb\n";

        $retval = $aa cmp $bb;
    }

    $retval;
}

sub l00http_dash_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition

    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "dash: color text file";
}

sub l00http_dash_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($buf, $pname, $fname, @alllines, $buffer, $line, $ii, $eqlvl, @wikiword, $lineevalln, %lineevallns);
    my (%tasksTime, %tasksLine, %tasksDesc, %tasksSticky, %countBang, %firstTime, %logedTime, %tasksCat2);
    my ($cat1, $cat2, $timetoday, $time_start, $jmp, $dbg, $this, $dsc, $cnt, $help, $tmp, $tmp2, %nowbuf, $nowbuf, $nowbuf2);
    my (@tops, $out, $fir, @tops2, $anchor, $cat1cat2, $bang, %tops, $tim, $updateLast, %updateAge, %updateAgeVal);
    my ($lnnostr, $lnno, $hot, $hide, $key, $desc, $clip, $cat1font1, $cat1font2, $cat1ln, %displaying);
    my (%addtimeval, @blocktime, $modified, $addtime, $checked, $tasksTimeKey, $part1, $part2, $jumphrefs, $jumphrefstop);
    my ($jumpcnt, @jumpname, @jumpcat, $jumpmarks, $includefile, $pnameup, %desccats, $barekey, $access);
    my ($lineevalst, $lineevalen, %cat2tolnno, %cat1tolnno, $hidedays, %cat1s, $nowCatFil, $nowItemFil, $timecolor);
    my (@descfind, @cat2find, $moving, $color, $dashbanner, %cat1colorsaw);


    $timecolor = '';
    $nowCatFil = '';
    $nowItemFil = '';
    $dashbanner = '';

    $jumpcnt = 0;
    undef @jumpname;
    undef @jumpcat;
    undef %cat1tolnno;
    undef %cat2tolnno;
    undef %cat1s;
    undef %desccats;
    undef @descfind;
    undef @cat2find;
    undef %cat1colorsaw;

    $dbg = 0;
    if (defined($ctrl->{'dashwidth'})) {
        $dashwidth = $ctrl->{'dashwidth'};
    }

    # reset button
    if (defined($form->{'reset'})) {
        $form->{'listbang'} = '';
        $form->{'process'} = 'Process';
        $form->{'outputsort'} = '';
        $form->{'dash_all'} = 'past';
        $form->{'hdronly'} = '';
        $form->{'catflt'} = '.';
        $form->{'filtime'} = '';
        $form->{'fildesc'} = '';
        $form->{'fildesc0itm1cat'} = '';
        $form->{'crlf'} = '';
        $form->{'cat2find'} = '';
    }

    if (defined($form->{'futurebtn'})) {
        $form->{'process'} = 'Process';
        $form->{'dash_all'} = 'future';
    }


    if (defined($form->{'dash_all'})) {
        if ($form->{'dash_all'} eq 'all') {
            $dash_all = 'all';
        } elsif ($form->{'dash_all'} eq 'future') {
            $dash_all = 'future';
        } else { $dash_all = 'past';
        }
    }
    if (defined($form->{'hdronly'})) {
        if ($form->{'hdronly'} eq 'hdr') {
            $hdronly = 1;
        } else {
            $hdronly = 0;
        }
    }

    if ((defined ($form->{'onlybang'})) && ($form->{'onlybang'} eq 'on')) {
        $onlybang = 'checked';
    } else {
        $onlybang = '';
    }

    if ((defined ($form->{'onlyhat'})) && ($form->{'onlyhat'} eq 'on')) {
        $onlyhat = 'checked';
    } else {
        $onlyhat = '';
    }
    if ((defined ($form->{'listbang'})) && ($form->{'listbang'} eq 'on')) {
        $listbang = 'checked';
    } else {
        $listbang = '';
    }
    if ((defined ($form->{'newbang'})) && ($form->{'newbang'} eq 'on')) {
        $newbang = 'checked';
    } else {
        $newbang = '';
    }
    if ((defined ($form->{'freefmt'})) && ($form->{'freefmt'} eq 'on')) {
        $freefmt = 'checked';
    } else {
        $freefmt = '';
    }
    if ((defined ($form->{'outputsort'})) && ($form->{'outputsort'} eq 'on')) {
        $outputsort = 'checked';
    } else {
        $outputsort = '';
    }
    if (defined ($form->{'process'})) {
        if ((defined ($form->{'smallhead'})) && ($form->{'smallhead'} eq 'on')) {
            $smallhead = 'checked';
        } else {
            $smallhead = '';
        }
        if ((defined ($form->{'catflt'})) && (length($form->{'catflt'}) > 0)) {
            $catflt = $form->{'catflt'};
        } else {
            $catflt = '.';
        }
        if ((defined ($form->{'newwin'})) && ($form->{'newwin'} eq 'on')) {
            $newwin = 'checked';
            $target = 'target="_blank"';
        } else {
            $newwin = '';
            $target = '';
        }
        if ((defined ($form->{'crlf'})) && ($form->{'crlf'} eq 'on')) {
            $crlf = " <br>";
            $crlfchk = 'checked';
        } else {
            $crlf = '';
            $crlfchk = '';
        }
        if ((defined ($form->{'cat2find'})) && ($form->{'cat2find'} eq 'on')) {
            $cat2find = 'checked';
        } else {
            $cat2find = '';
        }

        if ((defined ($form->{'filtime'})) && ($form->{'filtime'} eq 'on')) {
            $filtime = 'checked';
        } else {
            $filtime = '';
        }
        if ((defined ($form->{'fildesc'})) && ($form->{'fildesc'} eq 'on')) {
            $fildesc = 'checked';
        } else {
            $fildesc = '';
        }
        if ((defined ($form->{'fildesc0itm1cat'})) && ($form->{'fildesc0itm1cat'} eq 'on')) {
            $fildesc0itm1cat = 'checked';
        } else {
            $fildesc0itm1cat = '';
        }
    }
    if (defined ($form->{'dbg'})) {
        $dbg = $form->{'dbg'};
    }

    $pname = '';
    $fname = '';
    if (defined ($form->{'path'})) {
        ($pname, $fname) = $form->{'path'} =~ /^(.+[\\\/])([^\\\/]+)$/;
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";

    if ($smallhead ne 'checked') {
        print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
        print $sock "<a href=\"#end\">Jump to end</a>\n";
        if (defined ($form->{'path'})) {
            # clip.pl with \ on Windows
            $_ = $form->{'path'};
            if (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
                $_ =~ s/\//\\/g;
            }
            print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$_\" target=\"_blank\">Path</a>: ";
            print $sock " <a href=\"/ls.htm?path=$pname\">$pname</a>";
            print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$fname</a> \n";
            print $sock "- <a href=\"/ls.htm?path=$form->{'path'}#__toctoc__\">TOC</a>/";
            print $sock "<a href=\"/view.htm?path=$form->{'path'}\">Vw</a> \n";
            print $sock "- <a href=\"/edit.htm?path=$form->{'path'}\">Ed</a>/";
            print $sock "<a href=\"/ls.htm?path=$form->{'path'}&exteditor=on\">ext</a>\n";
            print $sock "- <font style=\"color:black;background-color:lime\"><a href=\"#vvv\">vvv</a></font> \n";
            print $sock "- <font style=\"color:black;background-color:lime\"><a href=\"#hot\">hot</a></font> \n";
            print $sock "- <font style=\"color:black;background-color:lime\"><a href=\"#see\">see</a></font> \n";
            print $sock "- <font style=\"color:black;background-color:LightGray\"><a href=\"/dash.htm?process=Process&path=$form->{'path'}&dash_all=all\#quickcut\">(Jump marks</a></font> \n";
            print $sock "- <font style=\"color:black;background-color:LightGray\"><a href=\"/dash.htm?process=Process&path=$form->{'path'}&dash_all=all\#cat1\">cat1)</a></font> \n";
            print $sock "- <font style=\"color:black;background-color:gold\"     ><a href=\"/dash.htm?process=Process&path=$form->{'path'}&dash_all=all\#bangbang\">Jump out</a></font> \n";
            print $sock "- <font style=\"color:black;background-color:aqua\"     ><a href=\"/dash.htm?process=Process&path=$form->{'path'}&dash_all=all\#descfind\">Desc find</a></font> \n";
#           print $sock "- <font style=\"color:black;background-color:LightGray\"><a href=\"/dash.htm?process=Process&path=$form->{'path'}&dash_all=all\#taskjump\">taskjump</a></font> \n";
            print $sock "- <font style=\"color:black;background-color:LightGray\"><a href=\"#taskjump\">taskjump</a></font> \n";
        }
    }
    print $sock "<p>\n";

    # new section with new timestamp
    $out = $ctrl->{'now_string'};
    $out =~ s/ /+/g;
    $out = "<a href=\"/clip.htm?update=Copy+to+CB&url=&clip=%3D%3Dx%3D%3D%0D%0A*+$out+%0D%0A\" target=\"_blank\">new sect</a>";
    if ($smallhead eq 'checked') {
        print $sock "<form action=\"/dash.htm\" method=\"get\">\n";
        print $sock "<a href=\"#end\">end</a> - \n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
        print $sock "<input type=\"checkbox\" name=\"smallhead\" $smallhead>";
        if ($smallhead ne 'checked') {
            print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&smallhead=on\">small header</a>.\n";
        } else {
            print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}\">small header</a>.\n";
        }
        print $sock "$out.\n";
    
        print $sock "<input type=\"submit\" name=\"process\" value=\"P&#818;rocess\" accesskey=\"p\"> \n";
        print $sock "</form>\n";
    } else {
        print $sock "<form action=\"/dash.htm\" method=\"get\">\n";
        print $sock "(<input type=\"checkbox\" name=\"fildesc\" $fildesc>desc";
        if ($fildesc eq 'checked') {
            print $sock "<input type=\"checkbox\" name=\"fildesc0itm1cat\" $fildesc0itm1cat>all)";
            print $sock "<input type=\"hidden\" name=\"filtime\" value=\"\">";
        }
        print $sock " Cat1F&#818;lt ";
        print $sock "<input type=\"checkbox\" name=\"cat2find\" $cat2find>2 ";
        print $sock "<input type=\"text\" size=\"4\" name=\"catflt\" value=\"$catflt\" accesskey=\"f\"> \n";
        if ($fildesc ne 'checked') {
            print $sock "<input type=\"hidden\" name=\"fildesc0itm1cat\" value=\"\">";
            print $sock "<input type=\"checkbox\" name=\"filtime\" $filtime>time)";
        }
        print $sock "<input type=\"submit\" name=\"process\" value=\"P&#818;rocess\" accesskey=\"p\"> \n";
        print $sock "<input type=\"text\" size=\"10\" name=\"path\" value=\"$form->{'path'}\">\n";
        if (($dash_all ne 'all') && ($dash_all ne 'future')) {
            $_ = 'checked';
        } else {
            $_ = '';
        }
        print $sock "(<input type=\"checkbox\" name=\"onlybang\" $onlybang>";
        if ($onlybang ne 'checked') {
            print $sock "<strong><a href=\"/dash.htm?process=Process&path=$form->{'path'}&onlybang=on&outputsort=&dash_all=past&hdronly=\">cat!</a></strong> - ";
        } else {
            print $sock "<strong><a href=\"/dash.htm?process=Process&path=$form->{'path'}&outputsort=&dash_all=past&hdronly=\">cat!</a></strong> - ";
        }
        print $sock "<input type=\"checkbox\" name=\"onlyhat\" $onlyhat>";
        if ($onlyhat ne 'checked') {
            print $sock "<strong><a href=\"/dash.htm?process=Process&path=$form->{'path'}&onlyhat=on&outputsort=&dash_all=past&hdronly=\">^~itm</a></strong> - ";
        } else {
            print $sock "<strong><a href=\"/dash.htm?process=Process&path=$form->{'path'}&outputsort=&dash_all=past&hdronly=\">^~itm</a></strong> - ";
        }
        print $sock  "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&outputsort=on&dash_all=all&hdronly=hdr\"><strong>hdr</strong></a> -\n";
       #print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&outputsort=&dash_all=past&hdronly=\">reset</a>)\n";
        print $sock "<input type=\"submit\" name=\"reset\" value=\"R&#818;eset\" accesskey=\"r\">)\n";

        print $sock "<input type=\"radio\" name=\"dash_all\" value=\"past\" $_>";
        print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&dash_all=past\">past</a>\n";
        if ($dash_all eq 'future') {
            $_ = 'checked';
        } else {
            $_ = '';
        }
        print $sock "(<input type=\"radio\" name=\"dash_all\" value=\"future\" $_>";
        print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&dash_all=future\">future</a>\n";
        print $sock "<input type=\"submit\" name=\"futurebtn\" value=\"Fu&#818;ture\" accesskey=\"u\">)\n";
        if ($dash_all eq 'all') {
            $_ = 'checked';
        } else {
            $_ = '';
        }
        print $sock "<input type=\"radio\" name=\"dash_all\" value=\"all\" $_>";
        print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&dash_all=all\">all</a>.\n";
        print $sock "<input type=\"checkbox\" name=\"listbang\" $listbang>list '!'.\n";
        print $sock "<input type=\"checkbox\" name=\"newwin\" $newwin>new win.\n";
#       print $sock "<input type=\"checkbox\" name=\"crlf\" $crlfchk>crlf\n";
        if ($crlfchk eq 'checked') {
            $_ = '';
        } else {
            $_ = '&crlf=on';
        }
        print $sock "<input type=\"checkbox\" name=\"crlf\" $crlfchk><a href=\"/dash.htm?process=Process&path=$form->{'path'}$_\">crlf</a>\n";
        print $sock "<input type=\"checkbox\" name=\"freefmt\" $freefmt>";
        if ($freefmt ne 'checked') {
            print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&freefmt=on\">free format</a>.\n";
        } else {
            print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}\">free format</a>.\n";
        }
        print $sock "<input type=\"checkbox\" name=\"outputsort\" $outputsort>";
        if ($outputsort ne 'checked') {
            print $sock "(<a href=\"/dash.htm?process=Process&path=$form->{'path'}&outputsort=on&dash_all=&hdronly=\">cat1 sort</a>,\n";
            print $sock  "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&outputsort=on&dash_all=all&hdronly=\">all</a>).\n";
        } else {
            print $sock "(<a href=\"/dash.htm?process=Process&path=$form->{'path'}&outputsort=&dash_all=past&hdronly=\">cat1 sort</a>,\n";
            print $sock  "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&outputsort=&dash_all=all&hdronly=\">all</a>).\n";
        }
        print $sock "<input type=\"checkbox\" name=\"smallhead\" $smallhead>";
        if ($smallhead ne 'checked') {
            print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&smallhead=on\">small header</a>.\n";
        } else {
            print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}\">small header</a>.\n";
        }
        print $sock "$out.\n";
        print $sock "<input type=\"submit\" name=\"move\" value=\"Move\">\n";
    
        print $sock "</form>\n";
    }

    if (defined ($form->{'path'})) {
        undef %tasksTime;
        undef %tasksLine;
        undef %tasksDesc;
        undef %tasksSticky;
        undef %countBang;
        undef %updateAge;
        undef %updateAgeVal;
        undef %firstTime;
        undef %logedTime;
        undef %tasksCat2;
        undef @wikiword;
        undef %lineevallns;
        undef @blocktime;

        # read BLOGTIME tags    
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            $buffer = &l00httpd::l00freadAll($ctrl);
        }
        $buffer =~ s/\r//g;
        @alllines = split ("\n", $buffer);

        undef %addtimeval;
        $includefile = '';
        for ($ii = 0; $ii <= $#alllines; $ii++) {
            # %DASHCATFIL:\/now\/
            if ($alllines[$ii] =~ /^%DASHCATFIL:(.+)/) {
                # filter to show whole category in 'now'
                $nowCatFil = $1;
            }
            # %DASHITEMFIL:\/nmi\/
            if ($alllines[$ii] =~ /^%DASHITEMFIL:(.+)/) {
                $nowItemFil = $1;
            }
            # %DESCFIND:'''%
            if ($alllines[$ii] =~ /^%DESCFIND:(.+)%$/) {
                push(@descfind, $1);
            }
            # %CAT2FIND:'''%
            if ($alllines[$ii] =~ /^%CAT2FIND:(.+)%$/) {
                push(@cat2find, $1);
            }
            # %DASHBANNER:[[#abc|jump to abc]]%
            if ($alllines[$ii] =~ /^%DASHBANNER:(.+)%$/) {
                # concatenate
                $dashbanner .= $1;
            }

            if ($alllines[$ii] =~ /^%BLOGTIME:(.+?)%/) {
                $tmp = $1;
                $addtimeval{$tmp} = 0;
                if ($tmp =~ /(-*\d+)m/) {
                    $addtimeval{$tmp} = 60 * $1;
                }
                if ($tmp =~ /(-*\d+)h/) {
                    $addtimeval{$tmp} = 3600 * $1;
                }
                if ($tmp =~ /(-*\d+)d/) {
                    $addtimeval{$tmp} = 24 * 3600 * $1;
                }
                push(@blocktime, $tmp);
            }
            # %INCLUDE<./xxx.txt>%
            if ($alllines[$ii] =~ /%INCLUDE<(.+?)>%/) {
                $includefile = $1;
                # subst %INCLUDE<./xxx.txt> as 
                #       %INCLUDE</absolute/path/xxx.txt>
                $includefile =~ s/^\.[\\\/]/$pname/;
                # drop last directory from $pname for:
                # subst %INCLUDE<../xxx.txt> as 
                #       %INCLUDE</absolute/path/../xxx.txt>
                $pnameup = $pname;
                $pnameup =~ s/([\\\/])[^\\\/]+[\\\/]$/$1/;
                $includefile =~ s/^\.\.\//$pnameup\//;
            }
        }
        # handle include
        if (($includefile ne '') && 
            (&l00httpd::l00freadOpen($ctrl, $includefile))) {
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                s/\r//;
                s/\n//;

                # %DASHCATFIL:\/now\/
                if ($_ =~ /^%DASHCATFIL:(.+)/) {
                    # filter to show whole category in 'now'
                    $nowCatFil = $1;
                }
                # %DASHITEMFIL:\/nmi\/
                if ($_ =~ /^%DASHITEMFIL:(.+)/) {
                    $nowItemFil = $1;
                }
                # %DESCFIND:'''%
                if ($_ =~ /^%DESCFIND:(.+)%$/) {
                    push(@descfind, $1);
                }
                # %CAT2FIND:'''%
                if ($_ =~ /^%CAT2FIND:(.+)%$/) {
                    push(@cat2find, $1);
                }

                if (/^%BLOGTIME:(.+?)%/) {
                    $tmp = $1;
                    $addtimeval{$tmp} = 0;
                    # remove underline
                    $tmp2 = $tmp;
                    $tmp2 =~ s/&#818;//;
                    if ($tmp2 =~ /(-*\d+)m/) {
                        $addtimeval{$tmp} = 60 * $1;
                    }
                    if ($tmp2 =~ /(-*\d+)h/) {
                        $addtimeval{$tmp} = 3600 * $1;
                    }
                    if ($tmp2 =~ /(-*\d+)d/) {
                        $addtimeval{$tmp} = 24 * 3600 * $1;
                    }
                    push(@blocktime, $tmp);
                }
            }
        }

        if ($dashbanner ne '') {
            print $sock &l00wikihtml::wikihtml ($ctrl, '', " $dashbanner ", 4);
        }

        if (defined ($form->{'newtime'})) {
            $_ = $form->{'newtime'};
            # revert character back to html entity 
            s/\xcc\xb2/&#818;/;
            # new time
            $addtime = $addtimeval{$_};
        } else {
            $addtime = 0;
        }

        $modified = 0;
        # move
        if (defined($form->{"movefrom"}) && ($form->{"movefrom"} =~ /^\d+$/) &&
            defined($form->{"moveto"}) && ($form->{"moveto"} =~ /^\d+$/)) {
            # move movefrom to moveto
            $tmp = $alllines[$form->{"movefrom"} - 1];
            $alllines[$form->{"movefrom"} - 1] = "#$tmp";
            splice (@alllines, $form->{"moveto"}, 0, $tmp);
            $modified = 1;
        }
        $out = '';
        # insert heading
        if ((defined($form->{"inscat2at"})) && 
            (($tmp) = $form->{"inscat2at"} =~ /(\d+)/)) {
            $tmp--;
            $color = 'g';
            for ($ii = 0; $ii < $tmp; $ii++) {
                $out .= "$alllines[$ii]\n";
                # look for color
                if ($alllines[$ii] =~ /^=\*([a-zA-Z0-9])\*.+=/) {
                    $color = $1;
                }
            }
            $_ = 'newcat';
            if (defined($form->{"newtcat"})) {
                $_ = $form->{"newtcat"};
            }
            if (defined($form->{"hilite"} && ($form->{"hilite"} eq 'on'))) {
                $out .= "==*$color*$_**==\@\@\@\n";
            } else {
                $out .= "==*$color*$_**==\n";
            }
            my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = 
                localtime (time);
            $out .= sprintf ("* %4d%02d%02d %02d%02d%02d \n", 
                $year + 1900, $mon+1, $mday, $hour, $min, $sec);
            for (; $ii <= $#alllines; $ii++) {
                $out .= "$alllines[$ii]\n";
            }
            $modified = 1;
        } else {
            # update date through checkbox
            for ($ii = 0; $ii <= $#alllines; $ii++) {
                if ((defined($form->{"ln$ii"})) &&          # selected line
                    ($ii > 0) &&                            # there is a line before this
                    ($alllines[$ii - 1] =~ /^==[^=]/)) {     # and is level 2 ==
                    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = 
                        localtime (time + $addtime);
                    $out .= sprintf ("* %4d%02d%02d %02d%02d%02d \n", 
                        $year + 1900, $mon+1, $mday, $hour, $min, $sec);
                    $modified++;
                }
                $out .= "$alllines[$ii]\n";
            }
        }
        if ($modified) {
            # modify, backup and write update
            &l00backup::backupfile ($ctrl, $form->{'path'}, 0, 5);
            &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
            &l00httpd::l00fwriteBuf($ctrl, $out);
            &l00httpd::l00fwriteClose($ctrl);
        }


        print $sock "<form action=\"/dash.htm\" method=\"post\">\n";

        $cat1 = 'cat1';
        $cat2 = 'cat2';
        undef %nowbuf;
        $nowbuf = '';
        $nowbuf2 = '';
        $timetoday = 0;
        $time_start = 1;
        $jmp = '';
        $cat1ln = -1;
        $cat1font1 = '';
        $cat1font2 = '';
        if ($dbg) {
            print $sock "<pre>Read input file to collect newest and >>> entries\n";
        }


        $lnno = 0;
        $buffer = '';
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            $buffer = &l00httpd::l00freadAll($ctrl);
        }
        $buffer =~ s/\r//g;
        @alllines = split ("\n", $buffer);
        $hide = 0;
        $eqlvl = 0;
        foreach $this (@alllines) {
            $lnno++;

            # %DASHHIDE:ON% and %DASHHIDE:OFF% hides bracketted secsions
            if ($this =~ /^%DASHHIDE:ON%/) {
                $hide = 1;
                next;
            }
            if ($this =~ /^%DASHHIDE:OFF%/) {
                $hide = 0;
                next;
            }
            if ($hide) {
                next;
            }

            $hot = '';
            if ($this =~ /^(=+)[^=]/) {
                $eqlvl = length($1);
            }
            if ($this =~ /^%DASHCOLOR:(.+?):(.+?)%/) {
                $cat1font1 = "<font style=\"color:$1;background-color:$2\">";
                $cat1font2 = "<\/font>";
                $cat1ln = $lnno;
            } elsif ($this =~ /^=([^=]+)=/) {
                $cat1 = $1;
                if ($cat1 =~ /^\*(.)\*/) {
                    # remember cat1 color used
                    $cat1colorsaw{$1} = $cat1;
                }
                $tmp = $cat1;
                $tmp =~ s/\*\*$//;
                $tmp =~ s/^\*.\*//;
                if (!defined($cat1s{$tmp})) {
                    $cat1s{$tmp} = $cat1;
                }
                if ($cat1ln + 1 != $lnno) {
                    #what is $1 and $2: $cat1font1 = "<font style=\"color:$1;background-color:$2\">";
                    $cat1font1 = "<font style=\"color:black;background-color:white\">";
                    $cat1font2 = "<\/font>";
                }
            } elsif ($this =~ /^==([^=]+)==(.*)/) {
                #status age calculation
                $updateLast = undef;

                $cat2 = $1;
                l00httpd::dbp($config{'desc'}, "cat2 >$cat2<\n"), if ($ctrl->{'debug'} >= 5);
                $jmp = $1;
                $jmp =~ s/\*\*/_/g;  # remove ** highlight
                $jmp =~ s/\*.\*/_/g;
                $jmp =~ s/[^0-9A-Za-z]/_/g;
                if ($dbg) {
                    print $sock "  $cat1  $cat2\n";
                }
                $time_start = 0;
                # Make a hot item include if $cat2 is a wikiword 
                # alone and target exist (to be checked later)
                if ($cat2 =~ /^[A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*$/) {
                    $hot = $cat2;
                }
                # make a link to lineeval at the target line
                $lineevalln = $lnno;    # next entry line number but it's zero based
                $lineevalst = $lnno - 5;
                if ($lineevalst < 0) {
                    $lineevalst = 1;
                }
                $lineevalen = $lnno + 50;
                $cat2 = "<a href=\"#top\">^</a> <a href=\"/lineeval.htm?anchor=line$lnno&path=$form->{'path'}&rngst=${lineevalst}&rngen=${lineevalen}&rngln=${lineevalln}&run=run&useform=keep#line$lnno\" target=\"_blank\">$cat2</a>";

                # jump mark
                if (($this =~ /\?\?\?$/) || ($this =~ /\@\@\@$/)) {
                    $tmp = $cat2;
                    $tmp =~ s/<.+?>//g;
                    push (@jumpname, "$tmp???jump$jumpcnt");

                    # jump cat2 for jump marks
                    $jumpcat[$jumpcnt] = $jmp;  # cat2 anchor for jumps
                    #print "jumpname $jmp: $tmp???jump$jumpcnt\n";
                    $cat2 = "<a name=\"jump$jumpcnt\"></a>$cat2";
                    $jumpcnt++;
                }
                # jump target when hdr only
                $cat2 .= "<a name=\"cat2$jmp\"></a>";
                if (!defined($cat1tolnno{"$cat1"}) ||
                    ($cat1tolnno{"$cat1"} > $lnno)) {
                    $cat1tolnno{"$cat1"} = $lnno;
                }
                $cat2tolnno{"cat2$jmp"} = $lnno;
                $cat1tolnno{"cat2$jmp"} = $cat1tolnno{"$cat1"};
            } elsif (($tim, $dsc) = $this =~ /^\* (\d{8,8} \d{6,6}) *(.*)/) {
                # cat1 = ---- cat2 = DESCFIND, desc is DESCFIND regex
                if (($cat1 =~ /----/) && ($cat2 =~ /DESCFIND/) && ($dsc !~ /^ *$/)) {
                   #print $sock "cat1 $cat1 cat2 $cat2 dsc $dsc<br>";
                    push(@descfind, $dsc);
                }

                # find wikiwords. make a copy to zap [] and <> and http
                $tmp = $dsc;
                $tmp =~ s/\[\[.+?\]\]//g;
                $tmp =~ s/<.+?>//g;
                $tmp =~ s/https*:\/\/[^ ]+//g;

                if (@_ = $tmp =~ /([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)/g) {
                    # save them
                    push(@wikiword, @_);
                    if ($dsc =~ /@@([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)/) {
                        $dsc =~ s/@@([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*?)[ !]/ -&gt; \[\[\/dash.htm?path=.\/$1.txt|$1\]\] /g;
                    }
                }
                # ^ color fushcia/yellow for do now
                if ($dsc =~ /^(\+\d+ *)\^([^\[\]]+?)(\|+[^\[\]]+)$/) {
                    # special case : "desc | URL" and "desc ||clipboard"
                    # but not [[URL|desc]]
                    $dsc = "$1^<strong><font style=\"color:yellow;background-color:fuchsia\">$2</font></strong>$3";
                } elsif ($dsc =~ /^\^([^\[\]]+?)(\|+[^\[\]]+)$/) {
                    # special case : "desc | URL" and "desc ||clipboard"
                    # but not [[URL|desc]]
                    $dsc = "^<strong><font style=\"color:yellow;background-color:fuchsia\">$1<\/font><\/strong>$2";
                } elsif ($dsc =~ /^(\+\d+ *)\^(.+)$/) {
                    $dsc = "$1^<strong><font style=\"color:yellow;background-color:fuchsia\">$2</font></strong>";
                } else {
                    $dsc =~ s/^\^(.+)$/^<strong><font style="color:yellow;background-color:fuchsia">$1<\/font><\/strong>/;
                }
                # ~ color fushcia/yellow for do now
                if ($dsc =~ /^(\+\d+ *)~([^\[\]]+?)(\|+[^\[\]]+)$/) {
                    # special case : "desc | URL" and "desc ||clipboard"
                    # but not [[URL|desc]]
                    $dsc = "$1~<strong><font style=\"color:black;background-color:yellow\">$2</font></strong>$3";
                } elsif ($dsc =~ /^~([^\[\]]+?)(\|+[^\[\]]+)$/) {
                    # special case : "desc | URL" and "desc ||clipboard"
                    # but not [[URL|desc]]
                    $dsc = "~<strong><font style=\"color:black;background-color:yellow\">$1<\/font><\/strong>$2";
                } elsif ($dsc =~ /^(\+\d+ *)~(.+)$/) {
                    $dsc = "$1~<strong><font style=\"color:black;background-color:yellow\">$2</font></strong>";
                } else {
                    $dsc =~ s/^~(.+)$/~<strong><font style="color:black;background-color:yellow">$1<\/font><\/strong>/;
                }
                # ` color silver for do now
                if ($dsc =~ /^(\+\d+ *)`([^\[\]]+?)(\|+[^\[\]]+)$/) {
                    # special case : "desc | URL" and "desc ||clipboard"
                    # but not [[URL|desc]]
                    $dsc = "$1`<strong><font style=\"color:black;background-color:silver\">$2</font></strong>$3";
                } elsif ($dsc =~ /^`([^\[\]]+?)(\|+[^\[\]]+)$/) {
                    # special case : "desc | URL" and "desc ||clipboard"
                    # but not [[URL|desc]]
                    $dsc = "`<strong><font style=\"color:black;background-color:silver\">$1<\/font><\/strong>$2";
                } elsif ($dsc =~ /^(\+\d+ *)`(.+)$/) {
                    $dsc = "$1`<strong><font style=\"color:black;background-color:silver\">$2</font></strong>";
                } else {
                    $dsc =~ s/^`(.+)$/`<strong><font style="color:black;background-color:silver">$1<\/font><\/strong>/;
                }
                # . color aqua for do now
                if ($dsc =~ /^\.([^\[\]]+?)(\|+[^\[\]]+)$/) {
                    # special case : "desc | URL" and "desc ||clipboard"
                    # but not [[URL|desc]]
                    $dsc = ".<strong><font style=\"color:black;background-color:aqua\">$1<\/font><\/strong>$2";
                } else {
                    $dsc =~ s/^\.(.+)$/.<strong><font style="color:black;background-color:aqua">$1<\/font><\/strong>/;
                }
                if ((($cat1 =~ /$catflt/i) || 
                    ($filtime eq 'checked') || 
                    ($fildesc eq 'checked') ||
                    ($cat2find eq 'checked')) && 
                    ($eqlvl == 2)) {
                    # only if match cat1 filter
                    # or time
                    # and ^==cat2==

                    # compute time.stop - time.start
                    if ($dsc =~ /time\.stop/) {
                        if ($timecolor eq '') {
                            $timecolor = 'silver';
                        }
                    }
                    if ($dsc =~ /time\.start/) {
                        if ($timecolor eq '') {
                            $timecolor = 'hotpink';
                        }
                    }
                    if (($time_start == 0) && ($dsc =~ /time\.stop/)) {
                        $time_start = &l00httpd::now_string2time($tim);
                    }
                    $key = "||$cat1font1<a href=\"/ls.htm?path=$form->{'path'}#$jmp\" $target>$cat1</a>$cat1font2||$cat2 ";
                    if (($time_start > 0) && ($dsc =~ /time\.start/)) {
                        $time_start -= &l00httpd::now_string2time($tim);

                        if (!defined($logedTime{$key})) {
                                     $logedTime{$key}  = $time_start;
                        } else {
                                     $logedTime{$key} += $time_start;
                        }
                        if (substr($ctrl->{'now_string'}, 0, 8) eq 
                            substr($tim                 , 0, 8)) {
                            $timetoday += $time_start;
                        }

                        $time_start = 0;
                    }
                    #last update age
                    if (defined($dsc) && length($dsc)) {
                        # calculate days since last entry
                        $updateLast = int((time - &l00httpd::now_string2time($tim)) / (3600*24) + 0.5);
                        if (!defined($updateAgeVal{$key}) || 
                            ($updateAgeVal{$key} > $updateLast)) {
                            # no age or age is older the current age
                            $updateAgeVal{$key} = $updateLast;
                            if ($updateLast > 1) {
                                # report only for 2 or more days old
                                $updateAge{$key} = "<font style=\"color:black;background-color:silver\">${updateLast}d</font>";
                            } else {
                                # no age field
                                undef $updateAge{$key};
                            }
                        }
                    }


                    # handle: link text [[#anchor]]
                    if ($dsc =~ / *(.+) +\[\[#(.+)\]\] */) {
                       $dsc = "$1 [[#$2]] | /ls.htm?path=$form->{'path'}#$2";
                    }

                    # convert desc||clip to clipboard link
                    if (!($dsc =~ /\[\[.+\|.+\]\]/)) {
                        # do so only when we don't have [[URL|desc]] shortcuts
                        if (($desc, $clip) = $dsc =~ /^ *(.+) *\|\|(.+)$/) {
                            $clip = &l00httpd::urlencode ($clip);
                            $bang = '';
                            # preserve ! or !! as leading
                            if ($desc =~ /^(!+ *)/) {
                                $bang = $1;
                                $desc =~ s/^!+//;
                            }
                            $dsc = "$bang<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$clip\" target=\"_blank\">$desc&#8227;</a>";
                        } elsif (($desc, $clip) = $dsc =~ /^ *(.+) *\| *(.+) *$/) {
                            $bang = '';
                            # preserve ! or !! as leading
                            if ($desc =~ /^(!+ *)/) {
                                $bang = $1;
                                $desc =~ s/^!+//;
                            }
                            # this translation need protection so that the parameter https*://
                            # isn't translated into another URL
                            #yahoo|/activity.htm?path=https://finance.yahoo.com/
                            #<a href="/activity.htm?path=https://finance.yahoo.com/" target="_blank">yahoo</a>
#4409                       if ($clip =~ /https*:\/\//) {
#4409                                $clip =~ s/(https*):\/\//$1%3A%2F%2F/g;
#4409                       }

                            # put target before href so it renders correctly
                            $dsc = "$bang<a target=\"_blank\" href=\"$clip\">$desc</a>";
                        }
                    }

                    # save timestamp of first (newest entered) entry
                    if (!defined($firstTime{$key})) {
                                 $firstTime{$key} = $tim;
                                 if ($dbg) {
                                    print $sock "    FIRST $cat1    $cat2    $tim    $this\n";
                                 }
                                 $barekey = $key;
                                 $barekey =~ s/<.+?>//g;
                                 $tasksLine{$barekey} = $lnno - 1;
                    }

                    # filter matching item
                    if (($nowItemFil ne '') &&
                        ($dsc =~ /$nowItemFil/)) {
                        $tmp = $cat2;
                        $tmp =~ s/<a name=.+?>.+?<\/a>//g;
                        $tmp =~ s/<.+?>//g;
                        $tmp =~ s/\^ //;
                        $tmp =~ s/\*\*/_/g;  # remove ** highlight
                        $tmp =~ s/\*.\*/_/g;
                        $tmp =~ s/[^0-9A-Za-z]/_/g;
                        # 3b05: not sure about the number of leading _
                        # make it 1 to make R:dash jump work
                        $tmp =~ s/^_+/_/g;

                        $nowbuf .= " $crlf&#9670; $dsc <a href=\"/dash.htm?process=Process&path=$form->{'path'}&dash_all=all#cat2$tmp\">$lnno</a>";
                    }

                    if ($fildesc eq 'checked') {
                        # skip if description doesn't match filter
                        if ($fildesc0itm1cat ne 'checked') {
                            # itemized cat filter is checked, 
                            # so we skip item if not matching filter
                            if ($dsc !~ /$catflt/i) {
                                # special regex to display full category
                                if ($catflt !~ /\(.+\)/) {
                                    # i.e. add ( and ) to display full cat
                                    next;
                                }
                            } else {
                                # else we matched and display full category
                                $desccats{$key} = 1;
                            }
                        } elsif ($dsc =~ /$catflt/i) {
                            # remember to display this cat2
                            $desccats{$key} = 1;
                        }
                    }
                    if ($cat2find eq 'checked') {
                        if ($cat2 =~ /$catflt/i) {
                            # remember to display this cat2
                            $desccats{$key} = 1;
                        } else {
                            next;
                        }
                    }
                    #[[/ls.htm?path=$form->{'path'}#$jmp|$cat1]]
                    #<a href=\"/ls.htm?path=$form->{'path'}#$jmp\">$cat1</a>
                    if (!defined($tasksTime{$key})) {
                                 $tasksTime{$key} = $tim;
                                 $tasksDesc{$key} = " $dsc";
                                 $countBang{$key} = 0;
                                 $tasksCat2{$key} = $cat2;
                                if ($dbg) {
                                    print $sock "    TIME  $tim    $key\n";
                                }
                    }
                    if (($this =~ />>>$/) && ($hdronly == 0)) {
                                 $lnnostr = sprintf("%3d", $lnno);
                                 $tasksTime{"||<a href=\"/ls.htm?path=$form->{'path'}#$jmp\">$cat1</a>||$lnnostr $cat2 "} = "!!$tim";
                                 $tasksDesc{"||<a href=\"/ls.htm?path=$form->{'path'}#$jmp\">$cat1</a>||$lnnostr $cat2 "} = "<a name=\"taskjump\"></a>".&l00http_dash_linewrap($dsc);
                                if ($dbg) {
                                    print $sock "    >>> $this\n";
                                }
                    }
                    if (!defined($tasksSticky{$key})) {
                                 $tasksSticky{$key} = '';
                                 $lineevallns{$key} = $lineevalln;
                    }

                    # drop if prefixed by ^~
                    if ($onlyhat eq 'checked') {
                        if ($tmp !~ /[\^~]/) {
                            next;
                        }
                    }

                    if (defined($form->{'move'})) {
                        $moving = "<font style=\"color:black;background-color:lime\"><a href=\"/dash.htm?path=$form->{'path'}&movefrom=$lnno&process=Process&outputsort=on&dash_all=all&hdronly=hdr\">mv</a><\/font> ";
                    } else {
                        $moving = '';
                    }

                    if ($listbang eq '') {
                        # not listing all !, i.e. listing !! only
                        if ($dsc =~ /^[^!]/) {
                            l00httpd::dbp($config{'desc'}, "dsc >$dsc<\n"), if ($ctrl->{'debug'} >= 5);
                            if ($dsc =~ /^\+(\d+) /) {
                                # hide for +# days
                                $hidedays = int((&l00httpd::now_string2time($ctrl->{'now_string'}) - 
                                       &l00httpd::now_string2time($tim)) / (24 * 3600)) - $1;
                                if ($dash_all eq 'all') {
                                    $hidedays = undef;
                                }
                            } else {
                                $hidedays = undef;
                            }
                            if (!defined($hidedays) || ($hidedays >= 0)) {
                                # show days past hide, e.g. 3 days past: (3+)+5 do stuff
                                if (defined($hidedays)) {
                                    $tasksSticky{$key} = &l00http_dash_linewrap($tasksSticky{$key} . " $crlf&#9670; $moving(<font style=\"color:red;background-color:silver\"><strong>$hidedays+</strong></font>)$dsc");
                                } else {
                                    $tasksSticky{$key} = &l00http_dash_linewrap($tasksSticky{$key} . " $crlf&#9670; $moving$dsc");
                                }
                            }
                        }
                    } else {
                        # listing all !, i.e. listing ! and !!
                        if ($dsc =~ /^!{0,1}[^!]/) {
                            $tasksSticky{$key} .= " <br>$moving$dsc";
                        }
                    }
                    if ($dsc =~ /^![^!]/) {
                                 $countBang{$key}++;
                    }
                    if ($dbg) {
                        print $sock "          $cat1    $cat2    $tim    $this\n";
                    }
                }
            } else {
                if ($dbg) {
                    print $sock "      Ignore: $this\n";
                }
            }
            # Link from 'hot item include' filename
            if (($hot ne '') && defined($pname)) {
                if (open(IN, "<${pname}$hot.txt")) {
                    $cnt = 0;
                   #($tim) = $ctrl->{'now_string'} =~ /20\d\d(\d+ \d\d\d\d)\d\d/;
                    ($tim) = $ctrl->{'now_string'} =~ /20\d\d\d\d(\d+ \d\d\d\d)\d\d/;
                    while (<IN>) {
                        s/[\n\r]//g;
                        $cnt++;
                        if (/^#/) {
                            next;
                        }

                        # convert || shortcut to clip.htm link
                        # convert | shortcut to HTTP link
                        if (($desc, $clip) = /^ *(.+) *\|\|(.+)$/) {
                            $clip = &l00httpd::urlencode ($clip);
                            $_ = "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$clip\" target=\"_blank\">$desc&#8227;</a>";
                        } elsif (($desc, $clip) = /^ *(.+) *\| *(.+) *$/) {
                            $_ = "<a href=\"$clip\" target=\"_blank\">$desc</a>";
                        }

                        $lnnostr = sprintf("%3d", $cnt);
                        #[[/ls.htm?path=$form->{'path'}#$jmp|iHot]]
                        #<a href=\"/ls.htm?path=$form->{'path'}#$jmp\">iHot</a>
                        $tasksTime{"||<a href=\"/ls.htm?path=$form->{'path'}#$jmp\">iHot</a> ||$lnnostr <a href=\"/recedit.htm?record1=.&path=${pname}$hot\">INC</a> "} = "!!\@$tim";
                        $tasksDesc{"||<a href=\"/ls.htm?path=$form->{'path'}#$jmp\">iHot</a> ||$lnnostr <a href=\"/recedit.htm?record1=.&path=${pname}$hot\">INC</a> "} = "$_";
                        $tasksCat2{"||<a href=\"/ls.htm?path=$form->{'path'}#$jmp\">iHot</a> ||$lnnostr <a href=\"/recedit.htm?record1=.&path=${pname}$hot\">INC</a> "} = "";
                    }
                    close(IN);
                }
            }
        }



        undef @tops;
        # add a row representing now
        if ($dbg) {
            print $sock "Sort by time\n";
        }

        if (defined ($form->{'chkall'})) {
            $checked = 'checked';
        } else {
            $checked = '';
        }

        # insert from RAM file
        $nowbuf2 = '';
        if (&l00httpd::l00freadOpen($ctrl, "l00://dash.txt")) {
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                if (/^#/) {
                    next;
                }
                s/[\r\n]//g;
                if ($nowbuf2 eq '') {
                    $nowbuf2 = $_;
                } else {
                    $nowbuf2 .= " $crlf&#9670; $_";
                }
            }
        }
        foreach $_ (sort keys %tasksTime) {
            if (($nowCatFil ne '') &&
                defined($tasksSticky{$_}) && 
                ($tasksSticky{$_} =~ /$nowCatFil/)) {
                $nowbuf .= " $crlf&#9670; $tasksSticky{$_}";
            }
        }
        foreach $_ (keys %nowbuf) {
            $nowbuf .= $nowbuf{$_};
        }
        if (($nowbuf ne '') && ($nowbuf2 ne '')) {
            $nowbuf = "$nowbuf  *y*RAM:**  $nowbuf2";
		} else {
            $nowbuf = "$nowbuf$nowbuf2";
		}
        $nowbuf = &l00http_dash_linewrap($nowbuf);

        # insert a list of now item in current time
        push (@tops, "||$ctrl->{'now_string'}|| *y*<a href=\"#bangbang\">now</a>** ".
            "||<a href=\"/blog.htm?path=l00://dash.txt&stylecurr=blog&setnewstyle=Bare+style+add&stylenew=bare\" target=\"_blank\">R:dash</a> ".
                    "||$nowbuf ``tasksTime``");

        $cnt = 0;
        foreach $_ (sort keys %tasksTime) {
            $cnt++;
            if (defined($countBang{$_}) && ($countBang{$_} > 0)) {
                # if ($countBang{$_} > 0)
                if ($listbang eq '') {
                    # not listing all !, i.e. listing !! only
                    $bang = "<font style=\"color:black;background-color:gold\">".
                    "<a name=\"row$cnt\"></a><a href=\"/dash.htm?process=Process&path=$form->{'path'}&listbang=on#row$cnt\">!#$countBang{$_}</a></font>";
                } else {
                    # listing all !, i.e. listing ! and !!
                    $bang = "<font style=\"color:black;background-color:gold\">".
                    "<a name=\"row$cnt\"></a><a href=\"/dash.htm?process=Process&path=$form->{'path'}&listbang=#row$cnt\">!#$countBang{$_}</a></font>";
                }
            } else {
                $bang = '';
            }
            if (defined($updateAge{$_})) {
                if ($bang ne '') {
                    $bang .= ' ';
                }
                $bang .= "$updateAge{$_}";
            }
            if (defined($logedTime{$_})) {
                if ($bang ne '') {
                    $bang .= ' ';
                }
                $bang .= sprintf("<font style=\"color:black;background-color:silver\">%3.1fh</font>", 
                    int($logedTime{$_} / 3600 * 10 + 0.5) / 10);
            }
            if ((defined($tasksSticky{$_})) && ($hdronly == 0)) {
                if ($dbg) {
                    print $sock "    sticky: $_: $tasksTime{$_}  $tasksDesc{$_}\n";
                }
                $tmp = $tasksSticky{$_};
                $tmp2 = "<input type=\"checkbox\" name=\"ln$lineevallns{$_}\" $checked>#$lineevallns{$_}";
                if ($onlybang eq 'checked') {
                    if (/\|\|.+?\|\|.+?!\*\*/) {
                        # cat2 ends in !**
                        push (@tops, "||$tasksTime{$_}$_||$tmp2 $bang".           "$tmp ||``$_``");
                    }
                }
                if ($onlyhat eq 'checked') {
                    if ($tmp =~ /[\^~]/) {
                        # cat2 ends in !**
                        push (@tops, "||$tasksTime{$_}$_||$tmp2 $bang".           "$tmp ||``$_``");
                    }
                }
                if (($onlybang ne 'checked') && ($onlyhat ne 'checked')) {
                    push (@tops, "||$tasksTime{$_}$_||$tmp2 $bang".           "$tmp ||``$_``");
                }
            } else {
                if ($dbg) {
                    print $sock "          : $_: $tasksTime{$_}  $tasksDesc{$_}\n";
                }
                # strip line number for sticky tasks
                # ||*f*KIV**||1179 ^ *s*bkmk**
                # ||*f*KIV**||^ *s*bkmk**
                $tasksTimeKey = $_;
                $tasksTimeKey =~ s/^(\|\|.+?\|\|)\d+ /$1/;
                if ($hdronly == 0) {
                    push (@tops, "||$tasksTime{$_}$_||$bang$tasksDesc{$_}``$tasksTimeKey``");
                } else {
                    # create matching jump anchor when hdr only
                    #$cat2 .= "<a name=\"cat2$jmp\">$jmp</a>";
                    $tmp = '';
                    if (defined($tasksCat2{$_})) {
                        $jmp = $tasksCat2{$_};
                        if ($jmp =~ /a name="(cat2.+?)"/) {
                            $jmp = $1;
                        }

                        if (defined($cat2tolnno{"$jmp"})) {
                            $tmp = '&inscat2form='.$cat2tolnno{"$jmp"};
                            $tmp2 = $cat2tolnno{"$jmp"};
                        } else {
                            $tmp = '';
                            $tmp2 = '';
                        }
                        # jump to cat1 if available
                        if (defined($cat1tolnno{"$jmp"})) {
                            $tmp = '&inscat2form='.$cat1tolnno{"$jmp"};
                            $tmp2 = $cat1tolnno{"$jmp"};
                        }
                        $jmp = " <a href=\"/dash.htm?process=Process&path=$form->{'path'}&outputsort=&dash_all=all&hdronly=#$jmp\">vw:$jmp</a>";
                        $jmp .= " -- <a href=\"/dash.htm?path=$form->{'path'}$tmp&process=Process&outputsort=on&dash_all=all&hdronly=hdr\">+cat2:$tmp2</a>";
                    } else {
                        $jmp = '';
                    }
		            # ckechkbox for mass update
		            #print "$lineevallns{$_}\" $checked>#$lineevallns{$_}\n";
                    if (defined($lineevallns{$_})) {
                        $tmp2 = "<input type=\"checkbox\" name=\"ln$lineevallns{$_}\" $checked>#$lineevallns{$_}";
                    } else {
                        $tmp2 = "";
                    }
                    if (defined($form->{'movefrom'})) {
                        $moving = "<font style=\"color:black;background-color:lime\"><a href=\"/dash.htm?path=$form->{'path'}&moveto=$lineevallns{$_}&movefrom=$form->{'movefrom'}&process=Process&outputsort=&dash_all=past&hdronly=\">here</a><\/font> ";
                    } else {
                        $moving = '';
                    }
                    push (@tops, "||$tasksTime{$_}$_||$moving$tmp2$bang$jmp||``$tasksTimeKey``");
                }
            }
        }

        $out  = '';
        undef @tops2;
        undef %displaying;
        if ($dbg) {
            print $sock "Sort and hide for output\n";
        }
        foreach $_ (sort {$b cmp $a} @tops) {
            if ($dbg) {
                print $sock "    $_\n";
            }
            # drop year
            if (s/^(\|\| *!*)(20\d\d)(\d+ \d\d\d\d)(\d\d)(.+)``(.+)``$/$1$2$3$4$5``$6``/) {
                $tim = "$2$3$4";
                $fir = "$6";
            } else {
                $tim = "0";
                $fir = "0";
            }
            if (defined($firstTime{$fir})) {
                # $fir is newest entry time
                $fir = $firstTime{$fir};
            } else {
                # if not available, just use recorded time
                $fir = $tim;
            }
            if ($dbg) {
                print $sock "  tim $tim fir $fir\n";
            }
            if ($dash_all ne 'all') {
                if ($dash_all eq 'future') {
                    # hide past based on newest entry
                    if ("$fir" lt $ctrl->{'now_string'}) {
                        next;
                    }
                } else {
                    # hide future based on newest entry
                    if ("$fir" gt $ctrl->{'now_string'}) {
                        next;
                    }
                }
            }
            if ($dbg) {
                print $sock "  disp $_\n";
            }

            # find cat lable for those being displayed    
            @_ = split('\|\|', $_);
            if ($_[2] =~ /#(.+)"/) {
                $displaying{$1} = 1;
                #print "disp cat2 $1\n";
            }

            push(@tops2, $_);
        }

        $anchor = '<a name="bangbang"></a>';
        $jumpmarks = 'Jump marks: ';
        foreach $_ (sort l00http_dash_outputsort @tops2) {
            # drop seconds, print month as hex
            s/^(\|\|!*)\d\d\d\d(\d\d)(\d\d) (\d\d\d\d)\d\d\|\|/sprintf("${1}%x${3}_$4||",$2)/e;
            if (($filtime eq 'checked') && (($tmp) = /^\|\|!*(.+?)\|\|/)) {
                # apply $catflt on timestamp
                if ($tmp !~ /$catflt/) {
                    next;
                }
            }

            if (($fildesc0itm1cat eq 'checked') && ($fildesc eq 'checked')) {
                if (($key) = /^\|\|.+?(\|\|.+?\|\|.+?)\|\|/) {
                    # find key
                    # itemized cat filter is not checked, 
                    # so we skip category only if non matching filter
                    if (!defined($desccats{$key})) {
                        # skip if never matched filter
                        next;
                    }
                }
            }

            # if filtering desc, may display full category too
            if (($fildesc0itm1cat ne 'checked') && ($fildesc eq 'checked')) {
                if (($key) = /^\|\|.+?(\|\|.+?\|\|.+?)\|\|/) {
                    # find key
                    # display full category if asked to
                    if (!defined($desccats{$key})) {
                        # skip if never matched filter
                        next;
                    }
                }
            }

            # insert bangbang anchor
            if (/^\|\|!!(.+)/) {
                $_ = "||!!$anchor$1";
                $anchor = '';
            }
            # remove !
            s/^\|\|!+(.+?)\|\|/||<font style=\"color:black;background-color:silver\">$1<\/font>||/;

            s/``(.+)``$//;
            $key = $1;
            $barekey = $key;
            $barekey =~ s/<.+?>//g;
            if (defined($tasksLine{$barekey})) {
                $cat1cat2 = $barekey;
                #print $sock "$tasksLine{$cat1cat2} $barekey          ";
                # '!!' marks jump out lines and could have an anchor resulting in one of
                # ||a22_0953||
                # ||<font style="color:black;background-color:silver"><a name="bangbang"></a>618_2226</font>||
                # ||<font style="color:black;background-color:silver">615_1529</font>||
                # so we search for the a22_0953 pattern: ([0-9abc]\d\d_\d\d\d\d)
                if (($part1, $part2) = /^(\|\|.+?\|\|)(.+)\|\|$/) {
                    $part1 =~ s/^(\|\|.*)([0-9abc]\d\d_\d\d\d\d)(.*\|\|)/$1<a href="\/blog.htm?path=$form->{'path'}&afterline=$tasksLine{$cat1cat2}&setnewstyle=yes&stylenew=star">$2<\/a>$3/;
                    $_ = "$part1$part2";
                }
                #print $sock "$_\n";
            }

            # link to clipboard for all items
            $clip = $_;
            # keep tail (items) after last ||
            $clip =~ s/^.+\|\|//;
            # remove prefix
            # $tmp2 = "<input type=\"checkbox\" name=\"ln$lineevallns{$_}\" $checked>#$lineevallns{$_}";
            # <input type="checkbox" name="ln191" >#191 <font style="color:black;background-color:silver">12d</font> 
            $clip =~ s/^<.+?checkbox.+?>#\d+ +//;
            # !#2 : hidden count
            $clip =~ s/^<font.+?>.+?<\/font> *//;
            # 4d : days old
            $clip =~ s/^<font.+?>.+?<\/font> *//;

            # <br> -> \n
            $clip =~ s/ *\\n *//gm;
            $clip =~ s/ *&#9670; */\n/gm;
            $clip =~ s/ *&#8227; *//gm;
            $clip =~ s/\[\[.+?\|(.+?)\]\]/ $1 /gm;
            $clip =~ s/<.+?>/ /gm;
            $clip =~ s/\*\*//gm;
            $clip =~ s/\*[a-zA-Z]\*//gm;
            $clip =~ s/\n */\n/gm;
            $clip =~ s/^ *\n *//;
            $clip = &l00httpd::urlencode ($clip);
            $clip = "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$clip\" target=\"_blank\">&gt;&gt;&gt;</a>";
            $_ .= " $clip||";

            $out .= "$_\n";
            # [[#name]] is a shortcut for anchor in the list
            # let's make a jump list for them; 1 per line max
            if(/\[\[#(.+?)\]\]/) {
                $jumpmarks .= "<a href=\"#$1\">$1</a> - ";
            }
        }

        $out =~ s/\\n/<br>/gm;
        if ($smallhead ne 'checked') {
            if (($hdronly != 0) && 
                (defined($form->{"inscat2form"}) &&
                ($form->{"inscat2form"} =~ /^\d+$/))) {
                $out =  "<form action=\"/dash.htm\" method=\"get\">".
                        "cat2: <input type=\"text\" size=\"10\" name=\"newtcat\" value=\"newcat\" accesskey=\"e\">".
                        " at line ".$form->{'inscat2form'}.
                        "<input type=\"checkbox\" name=\"hilite\"> append \@\@\@ - ".
                        "<input type=\"submit\" name=\"process\" value=\"A&#818;dd\" accesskey=\"a\"> ".
                        "<input type=\"hidden\" name=\"inscat2at\" value=\"$form->{'inscat2form'}\">".
                        "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">".
                        "</form>\n".
                        $out;
            }

            if ($timecolor eq '') {
                $timecolor = 'gray';
            }
            $out = sprintf("<font style=\"color:black;background-color:$timecolor\">Today: %d min</font>\n", 
                   int($timetoday / 60 + 0.5)) . $out;
        }
        $out .= " \n";
        # subs path=$ to target file
        $out =~ s/path=\$/path=$pname$fname/gsm;

        $out = &l00wikihtml::wikihtml ($ctrl, $pname, $out, 6);
        $out =~ s/ +(<\/td>)/$1/mg;

        if ($freefmt ne 'checked') {
            $out = "<pre>$out</pre>\n";
        }

        if ($dbg) {
            print $sock "</pre>\n";
        }

        # jump mark
        $jumphrefs = "";
        $jumphrefs .= "<a name=\"quickcut\"></a>";
        $jumphrefstop = '';
        if ($jumpcnt > 0) {
            $tmp = $jumpmarks;
            @jumpname = sort {
                    my($aa,$bb); 
                    $aa=$a; 
                    $bb=$b; 
                    $aa=~ s/\*\*//; 
                    $aa=~ s/\*.\*//; 
                    $bb=~ s/\*\*//; 
                    $bb=~ s/\*.\*//; 
                    lc($aa) cmp lc($bb);
                } (@jumpname);
            for ($ii = 0; $ii <= $#jumpname; $ii++) {
                if ($ii > 0) {
                    $tmp .= " - ";
                }
                ($desc, $anchor) = split ('\?\?\?', $jumpname[$ii]);
                $tmp .= "<a href=\"#$anchor\">$desc</a>";

                if ($anchor =~ /(\d+)/) {
                    if (defined($displaying{$jumpcat[$1]})) {
                        $jumphrefstop .= "<a href=\"#$anchor\">$desc</a>";
                        #print "DISPLAYING --- ";
                    }
                    #print "#$anchor : $jumpcat[$1] : $desc\n";
                }
            }
            $tmp = &l00wikihtml::wikihtml ($ctrl, $pname, $tmp, 6);

            $jumphrefstop = &l00wikihtml::wikihtml ($ctrl, $pname, $jumphrefstop, 6);

            $jumphrefs .= "$tmp<p>\n";
        }

        # put displayed jumhref at the top
        print $sock $jumphrefstop;

        # print main table
        print $sock $out;

        # cat1 color used
        if (($hdronly != 0) && ($outputsort ne '')) {
            $out = '';
            print $sock "Available cat1 color: $l00wikihtml::colorlukeys<br>\n";
            for ($ii = 0; $ii < length($l00wikihtml::colorlukeys); $ii++) {
                $tmp = substr($l00wikihtml::colorlukeys, $ii, 1);
                if (!defined($cat1colorsaw{$tmp})) {
                    $out .= "* *$tmp*This color is not used --- $tmp**\n";
                }
            }
            for ($ii = 0; $ii < length($l00wikihtml::colorlukeys); $ii++) {
                $tmp = substr($l00wikihtml::colorlukeys, $ii, 1);
                if (defined($cat1colorsaw{$tmp})) {
                    $out .= "* $cat1colorsaw{$tmp}\n";
                }
            }
            print $sock &l00wikihtml::wikihtml ($ctrl, $pname, $out, 6);
            print $sock "<p>\n";
        }

        # put full jumphref at the bottom
        print $sock $jumphrefs;



        # form elements
        print $sock "<a href=\"#top\">top</a> - <a name=\"end\"></a>Add ";
        $tmp = 'style="height:1.7em; width:2.0em"';
        foreach $_ (@blocktime) {
            $access = '';
            if (/(.)&#818;/) {
                $access = "accesskey=\"$1\"";
            }
            print $sock "<input type=\"submit\" name=\"newtime\" value=\"$_\" $tmp $access> ";
        }
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">";
        if ($fildesc eq 'checked') {
            print $sock "<input type=\"hidden\" name=\"fildesc\" value=\"on\">";
        }
        if ($filtime eq 'checked') {
            print $sock "<input type=\"hidden\" name=\"filtime\" value=\"on\">";
        }
        print $sock "to checked items<p>\n";
        $tmp = 'style="height:1.7em; width:6.0em"';
        print $sock "<a name=\"descfind\"></a>\n";
        print $sock "<input type=\"submit\" name=\"chkall\" value=\"Check A&#818;ll\" accesskey=\"a\" $tmp> ";
        print $sock "<input type=\"submit\" name=\"chknone\" value=\"Check N&#818;one\" accesskey=\"n\" $tmp> ";
        print $sock "</form>\n";


        $out = '';
       #if (($#wikiword >= 0) && ($smallhead ne 'checked')) {
       #    $tmp = '';
       #    $out .= "* Wikiwords found on this page: ";
       #    foreach $_ (sort @wikiword) {
       #        if ($tmp ne $_) {
       #            $out .= " &#9670; $_";
       #        }
       #        $tmp = $_;
       #    }
       #    $out .= "<br>\n";
       #}

        $help  = "<a name=\"end\"></a>";
        $help  = "";
        if ($smallhead ne 'checked') {
            if ($#descfind >= 0) {
                $help .= "* <font style=\"color:black;background-color:aqua\">Desc find</font>: ";
                foreach $_ (sort @descfind) {
                    if (($desc, $key) = /^([^|]+)\|\|(.+)$/) {
                        $key =~ s/\+/%2B/g;
                    } else {
                        $desc = $_;
                        $key = $_;
                        $key =~ s/\+/%2B/g;
                    }
                    $help .= "(<a href=\"/dash.htm?fildesc=on&catflt=$key&process=Process&path=$form->{'path'}&dash_all=all\">$desc</a> - ";
                    $help .=  "<a href=\"/dash.htm?fildesc=on&catflt=($key)&process=Process&path=$form->{'path'}&dash_all=all\">...</a>) ";
                    $help .= "-- ";
                }
                $help .= "\n";
            }

            if ($#cat2find >= 0) {
                $help .= "* <font style=\"color:black;background-color:aqua\">Cat2 find</font>: ";
                foreach $_ (sort @cat2find) {
                    if (($desc, $key) = /^([^|]+)\|\|(.+)$/) {
                        $key =~ s/\+/%2B/g;
                    } else {
                        $desc = $_;
                        $key = $_;
                        $key =~ s/\+/%2B/g;
                    }
                    $help .= "(<a href=\"/dash.htm?cat2find=on&catflt=$key&process=Process&path=$form->{'path'}&dash_all=all\">$desc</a> - ";
                    $help .=  "<a href=\"/dash.htm?cat2find=on&catflt=($key)&process=Process&path=$form->{'path'}&dash_all=all\">...</a>) ";
                    $help .= "-- ";
                }
                $help .= "\n";
            }


            $help .= "* Change 'dashwidth' using eval: ";
            $help .= "<a href=\"/eval.htm?submit=Ev%CC%B2al&eval=%24ctrl-%3E%7B%27dashwidth%27%7D%3D18\" target=\"_blank\">18</a> - ";
            $help .= "<a href=\"/eval.htm?submit=Ev%CC%B2al&eval=%24ctrl-%3E%7B%27dashwidth%27%7D%3D24\" target=\"_blank\">24</a> - ";
            $help .= "<a href=\"/eval.htm?submit=Ev%CC%B2al&eval=%24ctrl-%3E%7B%27dashwidth%27%7D%3D30\" target=\"_blank\">30</a> - ";
            $help .= "<a href=\"/eval.htm?submit=Ev%CC%B2al&eval=%24ctrl-%3E%7B%27dashwidth%27%7D%3D40\" target=\"_blank\">40</a> - ";
            $help .= "<a href=\"/eval.htm?submit=Ev%CC%B2al&eval=%24ctrl-%3E%7B%27dashwidth%27%7D%3D50\" target=\"_blank\">50</a> - ";
            $help .= "<a href=\"/eval.htm?submit=Ev%CC%B2al&eval=%24ctrl-%3E%7B%27dashwidth%27%7D%3D80\" target=\"_blank\">80</a> - ";
            $help .= "<a href=\"/eval.htm?submit=Ev%CC%B2al&eval=%24ctrl-%3E%7B%27dashwidth%27%7D%3D90\" target=\"_blank\">90</a> - ";
            $help .= "<a href=\"/eval.htm?submit=Ev%CC%B2al&eval=%24ctrl-%3E%7B%27dashwidth%27%7D%3D100\" target=\"_blank\">100</a> - ";
            $help .= "<a href=\"/eval.htm?submit=Ev%CC%B2al&eval=%24ctrl-%3E%7B%27dashwidth%27%7D%3D110\" target=\"_blank\">110</a> - ";
            $help .= "<a href=\"/eval.htm?submit=Ev%CC%B2al&eval=%24ctrl-%3E%7B%27dashwidth%27%7D%3D120\" target=\"_blank\">120</a> - ";
            $help .= "Now $dashwidth\n";

            $help .= "\n\n<a name=\"cat1\">Cat1 filter:</a>\n";
            foreach $cat1 (sort (keys %cat1s)) {
                $help .= "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&dash_all=all&catflt=$cat1\"> $cat1s{$cat1} </a> - ";
            }
            $help .= "\n\nHighlighting:\n";
            $help .= "* ^: *r*red**\n";
            $help .= "* ~: *y*yellow**\n";
            $help .= "* `: *L*lightGray**\n";
            $help .= "* .: *a*cyan**\n";
        }
        print $sock &l00wikihtml::wikihtml ($ctrl, $pname, "$out$help", 6);

        print $sock "<hr>";

        if ($smallhead eq 'checked') {
            print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
            print $sock "<a href=\"#end\">Jump to end</a>\n";
            # clip.pl with \ on Windows
            $_ = $form->{'path'};
            if (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
                $_ =~ s/\//\\/g;
            }
            print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$_\" target=\"_blank\">Path</a>: ";
            print $sock " <a href=\"/ls.htm?path=$pname\">$pname</a>";
            print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$fname</a> \n";
            print $sock " <a href=\"/launcher.htm?path=$form->{'path'}\">Launcher</a>\n";
            print $sock "- <a href=\"#quickcut\">quickcut</a> \n";
            print $sock "- <font style=\"color:black;background-color:LightGray\"><a href=\"#bangbang\">sticky items</a></font> \n";
            print $sock "<p>\n";
            print $sock "<form action=\"/dash.htm\" method=\"get\">\n";
            print $sock "<input type=\"submit\" name=\"process\" value=\"Process\"> \n";
            print $sock "<input type=\"text\" size=\"10\" name=\"path\" value=\"$form->{'path'}\">\n";
            if (($dash_all ne 'all') && ($dash_all ne 'future')) {
                $_ = 'checked';
            } else {
                $_ = '';
            }
            print $sock "Display <input type=\"radio\" name=\"dash_all\" value=\"past\" $_>past";
            if ($dash_all eq 'future') {
                $_ = 'checked';
            } else {
                $_ = '';
            }
            print $sock "<input type=\"radio\" name=\"dash_all\" value=\"future\" $_>future";
            if ($dash_all eq 'all') {
                $_ = 'checked';
            } else {
                $_ = '';
            }
            print $sock "<input type=\"radio\" name=\"dash_all\" value=\"all\" $_>all. ";
            print $sock "<input type=\"checkbox\" name=\"listbang\" $listbang>list '!'.\n";
            print $sock "<input type=\"checkbox\" name=\"newwin\" $newwin>new win.\n";
            print $sock "<input type=\"checkbox\" name=\"freefmt\" $freefmt>";
            if ($freefmt ne 'checked') {
                print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&freefmt=on\">free format</a>.\n";
            } else {
                print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}\">free format</a>.\n";
            }
            print $sock "<input type=\"checkbox\" name=\"outputsort\" $outputsort>";
            if ($outputsort ne 'checked') {
                print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&outputsort=on\">cat1 sort</a>.\n";
            } else {
                print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}\">cat1 sort</a>.\n";
            }
            print $sock "<input type=\"checkbox\" name=\"smallhead\" $smallhead>";
            if ($smallhead ne 'checked') {
                print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&smallhead=on\">small header</a>.\n";
            } else {
                print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}\">small header</a>.\n";
            }
    
            print $sock "</form>\n";
        }

        if (defined($ctrl->{'sshsync'}) &&
            (($tmp, $tmp2) = $ctrl->{'sshsync'} =~ /^(.+?):(.+)$/)) {
            $tmp2 .= '/';
        } else {
            $tmp = 'ssh user@host';
            $tmp2 = '';
        }
        print $sock "<p>sshsync.pl command line:\n<pre>".
            "echo -e \"\\\n".
            "$tmp  \\`  $form->{'path'}  \\`  bash -c  \\`  $fname \\n\\\n".
            "\" | perl ${tmp2}sshsync.pl</pre>\n";


        print $sock "<a href=\"#top\">top</a>\n";
    }


    # send HTML footer and ends
    if (defined ($ctrl->{'FOOT'})) {
        print $sock "$ctrl->{'FOOT'}\n";
    }
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
