use strict;
use warnings;
use l00httpd;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


#l00httpd::dbp($config{'desc'}, "2 contextln $contextln\n");
my %config = (proc => "l00http_dash_proc",
              desc => "l00http_dash_desc");

my ($dash_all, $hdronly, $listbang, $newbang, $newwin, $freefmt, 
$smallhead, $catflt, $outputsort, $dashwidth, $onlybang, $onlyhat);
$dash_all = 'past';
$hdronly = 0;
$listbang = '';
$newwin = '';
$newbang = '';
$freefmt = '';
$smallhead = '';
$catflt = '.';
$outputsort = '';
$dashwidth = 18;;
$onlybang = '';
$onlyhat = '';


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
    my ($cat1, $cat2, $timetoday, $time_start, $jmp, $dbg, $this, $dsc, $cnt, $help, $tmp, $tmp2, $tmpbuf);
    my (@tops, $out, $fir, @tops2, $anchor, $cat1cat2, $bang, %tops, $tim, $updateLast, %updateAge, %updateAgeVal);
    my ($lnnostr, $lnno, $hot, $hide, $key, $target, $desc, $clip, $cat1font1, $cat1font2, $cat1ln);
    my (%addtimeval, @blocktime, $modified, $addtime, $checked);
    my ($jumpcnt, @jumpname, $jumpmarks);

    $jumpcnt = 0;
    undef @jumpname;

    $dbg = 0;
    if (defined($ctrl->{'dashwidth'})) {
        $dashwidth = $ctrl->{'dashwidth'};
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
    if ((defined ($form->{'newwin'})) && ($form->{'newwin'} eq 'on')) {
        $newwin = 'checked';
        $target = 'target="_blank"';
    } else {
        $newwin = '';
        $target = '';
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
            print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=:hide+edit+$form->{'path'}%0D\">Path</a>: ";
            print $sock " <a href=\"/ls.htm?path=$pname\">$pname</a>";
            print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$fname</a> \n";
            print $sock " <a href=\"/launcher.htm?path=$form->{'path'}\">Launcher</a>\n";
            print $sock "- <font style=\"color:black;background-color:LightGray\"><a href=\"#quickcut\">Jump here</a></font> \n";
            print $sock "- <font style=\"color:black;background-color:gold\"><a href=\"#bangbang\">Jump out</a></font> \n";
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
        print $sock "CatFlt<input type=\"text\" size=\"4\" name=\"catflt\" value=\"$catflt\">\n";
        print $sock "<input type=\"submit\" name=\"process\" value=\"P&#818;rocess\" accesskey=\"p\"> \n";
        print $sock "<input type=\"text\" size=\"10\" name=\"path\" value=\"$form->{'path'}\">\n";
        if (($dash_all ne 'all') && ($dash_all ne 'future')) {
            $_ = 'checked';
        } else {
            $_ = '';
        }
        print $sock "(<input type=\"checkbox\" name=\"onlybang\" $onlybang>";
        if ($onlybang ne 'checked') {
            print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&onlybang=on&outputsort=&dash_all=past&hdronly=\">cat!</a> - ";
        } else {
            print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&outputsort=&dash_all=past&hdronly=\">cat!</a> - ";
        }
        print $sock "<input type=\"checkbox\" name=\"onlyhat\" $onlyhat>";
        if ($onlyhat ne 'checked') {
            print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&onlyhat=on&outputsort=&dash_all=past&hdronly=\">^itm</a> - ";
        } else {
            print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&outputsort=&dash_all=past&hdronly=\">^itm</a> - ";
        }
        print $sock  "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&outputsort=on&dash_all=all&hdronly=hdr\"><strong>hdr</strong></a> -\n";
        print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&outputsort=&dash_all=past&hdronly=\">reset</a>)\n";

        print $sock "<input type=\"radio\" name=\"dash_all\" value=\"past\" $_>";
        print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&dash_all=past\">past</a>\n";
        if ($dash_all eq 'future') {
            $_ = 'checked';
        } else {
            $_ = '';
        }
        print $sock "<input type=\"radio\" name=\"dash_all\" value=\"future\" $_>";
        print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&dash_all=future\">future</a>\n";
        if ($dash_all eq 'all') {
            $_ = 'checked';
        } else {
            $_ = '';
        }
        print $sock "<input type=\"radio\" name=\"dash_all\" value=\"all\" $_>";
        print $sock "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&dash_all=all\">all</a>.\n";
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
            print $sock "(<a href=\"/dash.htm?process=Process&path=$form->{'path'}&outputsort=on&dash_all=&hdronly=\">cat1 sort</a>,\n";
            print $sock  "<a href=\"/dash.htm?process=Process&path=$form->{'path'}&outputsort=on&dash_all=all&hdronly=\">all</a>, \n";
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
        for ($ii = 0; $ii <= $#alllines; $ii++) {
            if ($alllines[$ii] =~ /^%BLOGTIME:(.+?)%/) {
                $tmp = $1;
                $addtimeval{$tmp} = 0;
                if ($tmp =~ /(\d+)m/) {
                    $addtimeval{$tmp} = 60 * $1;
                }
                if ($tmp =~ /(\d+)h/) {
                    $addtimeval{$tmp} = 3600 * $1;
                }
                if ($tmp =~ /(\d+)d/) {
                    $addtimeval{$tmp} = 24 * 3600 * $1;
                }
                push(@blocktime, $tmp);
            }
        }

        if (defined ($form->{'newtime'})) {
            # new time
            $addtime = $addtimeval{$form->{'newtime'}};
        } else {
            $addtime = 0;
        }

        $out = '';
        $modified = 0;
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
        if ($modified) {
            # modify, backup and write update
            &l00backup::backupfile ($ctrl, $form->{'path'}, 0, 5);
            &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
            &l00httpd::l00fwriteBuf($ctrl, $out);
            &l00httpd::l00fwriteClose($ctrl);
        }


        print $sock "<form action=\"/dash.htm\" method=\"post\">\n";
        if ($freefmt ne 'checked') {
            print $sock "<pre>";
        }

        $cat1 = 'cat1';
        $cat2 = 'cat2';
        $timetoday = 0;
        $time_start = 0;
        $jmp = '';
        $cat1ln = -1;
        $cat1font1 = '';
        $cat1font2 = '';
        if ($dbg) {
            print $sock "Read input file to collect newest and !!! entries\n";
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
                if ($cat1ln + 1 != $lnno) {
                    #what is $1 and $2: $cat1font1 = "<font style=\"color:$1;background-color:$2\">";
                    $cat1font1 = "<font style=\"color:black;background-color:white\">";
                    $cat1font2 = "<\/font>";
                }
            } elsif ($this =~ /^==([^=]+)==(.*)/) {
                #status age calculation
                $updateLast = undef;

                $cat2 = $1;
                l00httpd::dbp($config{'desc'}, "cat2 >$cat2<\n"), if ($ctrl->{'debug'} >= 5);;
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
                $cat2 = "<a href=\"#top\">^</a> <a href=\"/lineeval.htm?anchor=line$lnno&path=$form->{'path'}#line$lnno\" target=\"_blank\">$cat2</a>";

                # jump mark
                if ($this =~ /\?\?\?$/) {
                    $tmp = $cat2;
                    $tmp =~ s/<.+?>//g;
                    push (@jumpname, $tmp);
                    $cat2 .= "<a name=\"jump$jumpcnt\"></a>";
                    $jumpcnt++;
                }
                # jump target when hdr only
                $cat2 .= "<a name=\"cat2$jmp\"></a>";
            } elsif (($tim, $dsc) = $this =~ /^\* (\d{8,8} \d{6,6}) *(.*)/) {
                # find wikiwords. make a copy to zap [] and <> and http
                $tmp = $dsc;
                $tmp =~ s/\[\[.+?\]\]//g;
                $tmp =~ s/<.+?>//g;
                $tmp =~ s/https*:\/\/[^ ]+//g;
                if (@_ = $tmp =~ /([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)/g) {
                    # save them
                    push(@wikiword, @_);
                    if ($dsc =~ /@@([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*)/) {
                        $dsc =~ s/@@([A-Z]+[a-z]+[A-Z]+[0-9a-zA-Z_\-]*).*$/$1|\/dash.htm?path=.\/$1.txt/;
                    }
                }
                # ^ color fushcia/yellow for do now
                if ($dsc =~ /^\^([^\[\]]+)(\|+[^\[\]]+)$/) {
                    # special case : "desc | URL" and "desc ||clipboard"
                    # but not [[URL|desc]]
                    $dsc = "^<strong><font style=\"color:yellow;background-color:fuchsia\">$1<\/font><\/strong>$2";
                } else {
                    $dsc =~ s/^\^(.+)$/^<strong><font style="color:yellow;background-color:fuchsia">$1<\/font><\/strong>/;
                }
                # ~ color fushcia/yellow for do now
                if ($dsc =~ /^~([^\[\]]+)(\|+[^\[\]]+)$/) {
                    # special case : "desc | URL" and "desc ||clipboard"
                    # but not [[URL|desc]]
                    $dsc = "~<strong><font style=\"color:black;background-color:yellow\">$1<\/font><\/strong>$2";
                } else {
                    $dsc =~ s/^~(.+)$/~<strong><font style="color:black;background-color:yellow">$1<\/font><\/strong>/;
                }
                # . color lightGray/black for do now
                if ($dsc =~ /^\.([^\[\]]+)(\|+[^\[\]]+)$/) {
                    # special case : "desc | URL" and "desc ||clipboard"
                    # but not [[URL|desc]]
                    $dsc = ".<strong><font style=\"color:black;background-color:lightGray\">$1<\/font><\/strong>$2";
                } else {
                    $dsc =~ s/^\.(.+)$/.<strong><font style="color:black;background-color:lightGray">$1<\/font><\/strong>/;
                }
                if (($cat1 =~ /$catflt/i) && 
                    ($eqlvl == 2)) {
                    # only if match cat1 filter
                    # and ^==cat2==

                    # compute time.stop - time.start
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
                            $dsc = "$bang<a href=\"$clip\" target=\"_blank\">$desc</a>";
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
                    # save timestamp of first (newest entered) entry
                    if (!defined($firstTime{$key})) {
                                 $firstTime{$key} = $tim;
                                if ($dbg) {
                                    print $sock "    FIRST $cat1    $cat2    $tim    $this\n";
                                }
                                 $tasksLine{$key} = $lnno - 1;
                    }
                    if ($this =~ /!!!$/) {
                                 $lnnostr = sprintf("%3d", $lnno);
                                 $tasksTime{"||<a href=\"/ls.htm?path=$form->{'path'}#$jmp\">$cat1</a>||$lnnostr $cat2 "} = "!!$tim";
                                 $tasksDesc{"||<a href=\"/ls.htm?path=$form->{'path'}#$jmp\">$cat1</a>||$lnnostr $cat2 "} = &l00http_dash_linewrap($dsc);
                                if ($dbg) {
                                    print $sock "    !!! $this\n";
                                }
                    }
                    if (!defined($tasksSticky{$key})) {
                                 $tasksSticky{$key} = '';
                                 $lineevallns{$key} = $lineevalln;
                    }


                    if ($listbang eq '') {
                        # not listing all !, i.e. listing !! only
                        if ($dsc =~ /^[^!]/) {
                            l00httpd::dbp($config{'desc'}, "dsc >$dsc<\n"), if ($ctrl->{'debug'} >= 5);
                            if ($dsc =~ /^\+(\d+) /) {
                                # hide for +# days
                                $tmp = int((&l00httpd::now_string2time($ctrl->{'now_string'}) - 
                                       &l00httpd::now_string2time($tim)) / (24 * 3600));
                                if (($tmp >= $1) || ($dash_all eq 'all')) {
                                    # but don't hide if displaying all
                                    $tmp = 1;
                                } else {
                                    $tmp = 0;
                                }
                            } else {
                                $tmp = 1;
                            }
                            if ($tmp) {
                                $tasksSticky{$key} = &l00http_dash_linewrap($tasksSticky{$key} . " - $dsc");
                            }
                        }
                    } else {
                        # listing all !, i.e. listing ! and !!
                        if ($dsc =~ /^!{0,1}[^!]/) {
                            $tasksSticky{$key} .= "<br>$dsc";
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
        $tmpbuf = '';
        if (&l00httpd::l00freadOpen($ctrl, "l00://dash.txt")) {
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                s/[\r\n]//g;
                if ($tmpbuf eq '') {
                    $tmpbuf = $_;
                } else {
                    if ($tmpbuf =~ /\\n([^\\]+?)$/m) {
                        $tmp = $1;
                    } else {
                        $tmp = $tmpbuf;
                    }
                    if (length($tmp) > $dashwidth) {
                        $tmpbuf .= '\\n';
                    }

                    # ^ color fushcia/yellow for do now
                    if ($dsc =~ /^\^([^\[\]]+)(\|+[^\[\]]+)$/) {
                        # special case : "desc | URL" and "desc ||clipboard"
                        # but not [[URL|desc]]
                        $dsc = "^<strong><font style=\"color:yellow;background-color:fuchsia\">$1<\/font><\/strong>$2";
                    } else {
                        $dsc =~ s/^\^(.+)/^<strong><font style="color:yellow;background-color:fuchsia">$1<\/font><\/strong>/;
                    }
                    # ~ color fushcia/yellow for do now
                    if ($dsc =~ /^~([^\[\]]+)(\|+[^\[\]]+)$/) {
                        # special case : "desc | URL" and "desc ||clipboard"
                        # but not [[URL|desc]]
                        $dsc = "~<strong><font style=\"color:black;background-color:yellow\">$1<\/font><\/strong>$2";
                    } else {
                        $dsc =~ s/^~(.+)$/~<strong><font style="color:black;background-color:yellow">$1<\/font><\/strong>/;
                    }
                    # . color lightGray/black for do now
                    if ($dsc =~ /^\.([^\[\]]+)(\|+[^\[\]]+)$/) {
                        # special case : "desc | URL" and "desc ||clipboard"
                        # but not [[URL|desc]]
                        $dsc = ".<strong><font style=\"color:black;background-color:lightGray\">$1<\/font><\/strong>$2";
                    } else {
                        $dsc =~ s/^\.(.+)$/~<strong><font style="color:black;background-color:lightGray">$1<\/font><\/strong>/;
                    }
                    $tmpbuf .= " - $_";
                }
            }
        }

        push (@tops, "||$ctrl->{'now_string'}|| *y*<a href=\"#bangbang\">now</a>** ".
            "||<a href=\"/blog.htm?path=l00://dash.txt&stylecurr=blog&setnewstyle=Bare+style+add&stylenew=bare\" target=\"_blank\">R:dash</a> ".
            "||$tmpbuf ||``tasksTime``");

        $cnt = 0;
        foreach $_ (sort keys %tasksTime) {
            $cnt++;
            if ($dbg) {
                print $sock "    $_: $tasksTime{$_}  $tasksDesc{$_}\n";
            }
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
                $tmp = $tasksSticky{$_};
                $tmp2 = "<input type=\"checkbox\" name=\"ln$lineevallns{$_}\" $checked>#$lineevallns{$_}";
                if ($onlybang eq 'checked') {
                    if (/\|\|.+?\|\|.+?!\*\*/) {
                        # cat2 ends in !**
                        push (@tops, "||$tasksTime{$_}$_||$tmp2 $bang".           "$tmp ||``$_``");
                    }
                }
                if ($onlyhat eq 'checked') {
                    if ($tmp =~ /\^/) {
                        # cat2 ends in !**
                        push (@tops, "||$tasksTime{$_}$_||$tmp2 $bang".           "$tmp ||``$_``");
                    }
                }
                if (($onlybang ne 'checked') && ($onlyhat ne 'checked')) {
                    push (@tops, "||$tasksTime{$_}$_||$tmp2 $bang".           "$tmp ||``$_``");
                }
            } else {
                if ($hdronly == 0) {
                    push (@tops, "||$tasksTime{$_}$_||$bang$tasksDesc{$_}||``$_``");
                } else {
                    # create matching jump anchor when hdr only
                    #$cat2 .= "<a name=\"cat2$jmp\">$jmp</a>";
                    if (defined($tasksCat2{$_})) {
                        $jmp = $tasksCat2{$_};
                        $jmp =~ s/<a name=.+?>.+?<\/a>//g;
                        $jmp =~ s/<.+?>//g;
                        $jmp =~ s/\^ //;
                        $jmp =~ s/\*\*/_/g;  # remove ** highlight
                        $jmp =~ s/\*.\*/_/g;
                        $jmp =~ s/[^0-9A-Za-z]/_/g;
                        $jmp = " --&gt; <a href=\"/dash.htm?process=Process&path=$form->{'path'}&outputsort=&dash_all=all&hdronly=#cat2$jmp\">$jmp</a>";
                    } else {
                        $jmp = '';
                    }
                    push (@tops, "||$tasksTime{$_}$_||$bang$jmp||``$_``");
                }
            }
        }

        $out  = '';
        undef @tops2;
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

            push(@tops2, $_);
        }
        $anchor = '<a name="bangbang"></a>';
        $jumpmarks = 'Jump marks: ';
        foreach $_ (sort l00http_dash_outputsort @tops2) {
            # drop seconds, print month as hex
            s/^(\|\|!*)\d\d\d\d(\d\d)(\d\d) (\d\d\d\d)\d\d\|\|/sprintf("${1}%x${3}_$4||",$2)/e;
            # insert bangbang anchor
            if (/^\|\|!!(.+)/) {
                $_ = "||!!$anchor$1";
                $anchor = '';
            }
            # remove !
            s/^\|\|!+(.+?)\|\|/||<font style=\"color:black;background-color:silver\">$1<\/font>||/;

            s/``(.+)``$//;
            if (defined($tasksLine{$1})) {
                $cat1cat2 = $1;
                #print $sock "$tasksLine{$cat1cat2} $1          ";
                s/^\|\|(.+?)\|\|/||<a href="\/blog.htm?path=$form->{'path'}&afterline=$tasksLine{$cat1cat2}&setnewstyle=yes&stylenew=star" $target>$1<\/a>||/;
                #print $sock "$_\n";
            }
            $out .= "$_\n";
            # [[#name]] is a shortcut for anchor in the list
            # let's make a jump list for them; 1 per line max
            if(/\[\[#(.+?)\]\]/) {
                $jumpmarks .= "<a href=\"#$1\">$1</a> - ";
            }
        }
        $out =~ s/\\n/<br>/gm;
        if ($smallhead ne 'checked') {
            $out = sprintf("<font style=\"color:black;background-color:silver\">Today: %d min</font>\n", 
                   int($timetoday / 60 + 0.5)) . $out;
        }
        $out .= " \n";
        $out = &l00wikihtml::wikihtml ($ctrl, $pname, $out, 6);
        $out =~ s/ +(<\/td>)/$1/mg;
        print $sock $out;


        if ($freefmt ne 'checked') {
            print $sock "</pre>\n";
        }

        # jump mark
        print $sock "<a name=\"quickcut\"></a>";
        if ($jumpcnt > 0) {
            $tmp = $jumpmarks;
            for ($ii = 0; $ii <= $#jumpname; $ii++) {
                if ($ii > 0) {
                    $tmp .= " - ";
                }
                $tmp .= "<a href=\"#jump$ii\">$jumpname[$ii]</a>";
            }
            $tmp = &l00wikihtml::wikihtml ($ctrl, $pname, $tmp, 6);
            print $sock "$tmp<p>\n";
        }

        # form elements
        print $sock "Add ";
        $tmp = 'style="height:1.4em; width:2.0em"';
        foreach $_ (@blocktime) {
            print $sock "<input type=\"submit\" name=\"newtime\" value=\"$_\" $tmp> ";
        }
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">";
        print $sock "to checked items<p>\n";
        $tmp = 'style="height:1.4em; width:6.0em"';
        print $sock "<input type=\"submit\" name=\"chkall\" value=\"Check All\" $tmp> ";
        print $sock "<input type=\"submit\" name=\"chknone\" value=\"Check None\" $tmp> ";
        print $sock "</form>\n";


        $out = '';
        if (($#wikiword >= 0) && ($smallhead ne 'checked')) {
            $tmp = '';
            $out .= "* Wikiwords found on this page: ";
            foreach $_ (sort @wikiword) {
                if ($tmp ne $_) {
                    $out .= " - $_";
                }
                $tmp = $_;
            }
            $out .= "<p>\n";
        }

        $help  = '';
        if ($smallhead ne 'checked') {
            $help .= "* Suggested color scheme (you don't have to use all):\n";
            $help .= "** Highest priority: review these first\n";
            $help .= "*** *r*r: red** : Preempts all, not recommended for project\n";
            $help .= "*** *f*f: fuchsia** : KIV Q\n";
            $help .= "*** *h*h: hotPink** : Do @\n";
            $help .= "** Filler tasks: something to do to fill time\n";
            $help .= "*** *T*T: teal** *G*G: green**\n";
            $help .= "** Projects: when you are ready for project work\n";
            $help .= "*** *d*d: gold** : priority project\n";
            $help .= "*** *l*l: lime**  *a*a: aqua**  *y*y: yellow**  *S*S: deepSkyBlue**  *B*B: sandyBrown** \n";
            $help .= "** Visual markers:\n";
            $help .= "*** *L*L: lightGray**  *s*s: silver**  *g*g: gray**\n";
            $help .= "** To be ignored:\n";
            $help .= "*** *b*b: brown**  *o*o: olive**\n";
            $help .= "* Custom category color:\n";
            $help .= "** %DASHCOLOR:black:Gold% for black on gold; use web color\n";
            $help .= "* ===chapter=== to hide low priority tasks\n";
            $help .= "* !!! at the end of comment to make a sticky note at the bottom (& in BOOKMARKS)\n";
            $help .= "* !! at start to hide in the latest\n";
            $help .= "* ! at start to hide but add to !# count\n";
            $help .= "* +# hides for # days from timestamp\n";
            $help .= "* Make comment date in the future to hide it\n";
            $help .= "* \\n are converted to newlines\n";
            $help .= "* Just timestamp is ok to mark new date, e.g. * 20171005 001200\n";
            $help .= "* * 20171005 001200 time.start and * 20171005 001200 time.stop to record time spent\n";
            $help .= "* ^text, to mark a do now item, in yellow on fuchsia\n";
            $help .= "* ~text, to mark a do next item, in black on yellow\n";
            $help .= "* .text, to mark a watch item, in black on silver\n";
            $help .= "* View <a href=\"/view.htm?path=$form->{'path'}\">$form->{'path'}</a>\n";
            $help .= "* Change 'dashwidth' using eval: ";
            $help .= "<a href=\"/eval.htm?submit=Ev%CC%B2al&eval=%24ctrl-%3E%7B%27dashwidth%27%7D%3D18\" target=\"_blank\">18</a> - ";
            $help .= "<a href=\"/eval.htm?submit=Ev%CC%B2al&eval=%24ctrl-%3E%7B%27dashwidth%27%7D%3D24\" target=\"_blank\">24</a> - ";
            $help .= "<a href=\"/eval.htm?submit=Ev%CC%B2al&eval=%24ctrl-%3E%7B%27dashwidth%27%7D%3D30\" target=\"_blank\">30</a> - ";
            $help .= "<a href=\"/eval.htm?submit=Ev%CC%B2al&eval=%24ctrl-%3E%7B%27dashwidth%27%7D%3D40\" target=\"_blank\">40</a> - ";
            $help .= "<a href=\"/eval.htm?submit=Ev%CC%B2al&eval=%24ctrl-%3E%7B%27dashwidth%27%7D%3D50\" target=\"_blank\">50</a> - ";
            $help .= "<a href=\"/eval.htm?submit=Ev%CC%B2al&eval=%24ctrl-%3E%7B%27dashwidth%27%7D%3D80\" target=\"_blank\">80</a> - ";
            $help .= "<a href=\"/eval.htm?submit=Ev%CC%B2al&eval=%24ctrl-%3E%7B%27dashwidth%27%7D%3D120\" target=\"_blank\">120</a> - ";
            $help .= "Now $dashwidth\n";
        }
        print $sock &l00wikihtml::wikihtml ($ctrl, $pname, "$out$help", 6);

        print $sock "<hr><a name=\"end\"></a>";

        print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
        print $sock "<a href=\"#end\">Jump to end</a>\n";
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=:hide+edit+$form->{'path'}%0D\">Path</a>: ";
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


        print $sock "<a href=\"#top\">top</a>\n";
    }


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
