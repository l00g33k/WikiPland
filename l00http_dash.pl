use strict;
use warnings;
use l00httpd;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


#l00httpd::dbp($config{'desc'}, "2 contextln $contextln\n");
my %config = (proc => "l00http_dash_proc",
              desc => "l00http_dash_desc");

my ($dash_all, $listbang, $newwin, $freefmt, $smallhead);
$dash_all = 'past';
$listbang = '';
$newwin = '';
$freefmt = '';
$smallhead = '';

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
    my ($buf, $pname, $fname, @alllines, $buffer, $line, $ii);
    my (%tasksTime, %tasksLine, %tasksDesc, %tasksSticky, %countBang, %firstTime, %logedTime);
    my ($cat1, $cat2, $timetoday, $time_start, $jmp, $dbg, $this, $dsc, $cnt);
    my (@tops, $out, $fir, @tops2, $anchor, $cat1cat2, $bang, %tops, $tim, $updateLast, %updateAge);
    my ($lnnostr, $lnno, $hot, $hide, $key, $target, $desc, $clip, $jmp1, $cat1font1, $cat1font2, $cat1ln);

    $dbg = 0;

    if (defined($form->{'dash_all'})) {
        if ($form->{'dash_all'} eq 'all') {
            $dash_all = 'all';
        } elsif ($form->{'dash_all'} eq 'future') {
            $dash_all = 'future';
        } else { $dash_all = 'past';
        }
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
    if ((defined ($form->{'freefmt'})) && ($form->{'freefmt'} eq 'on')) {
        $freefmt = 'checked';
    } else {
        $freefmt = '';
    }
    if (defined ($form->{'process'})) {
        if ((defined ($form->{'smallhead'})) && ($form->{'smallhead'} eq 'on')) {
            $smallhead = 'checked';
        } else {
            $smallhead = '';
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
    
        print $sock "<input type=\"submit\" name=\"process\" value=\"Process\"> \n";
        print $sock "</form>\n";
    } else {
        print $sock "<form action=\"/dash.htm\" method=\"get\">\n";
        print $sock "<input type=\"submit\" name=\"process\" value=\"Process\"> \n";
        print $sock "<input type=\"text\" size=\"10\" name=\"path\" value=\"$form->{'path'}\">\n";
        if (($dash_all ne 'all') && ($dash_all ne 'future')) {
            $_ = 'checked';
        } else {
            $_ = '';
        }
        print $sock "Display <input type=\"radio\" name=\"dash_all\" value=\"past\" $_>";
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
        undef %firstTime;
        undef %logedTime;

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
                $jmp1 = $1;
                $jmp1 =~ s/[^0-9A-Za-z]/_/g;
            } elsif ($this =~ /^==([^=]+)==/) {
                #statu age calculation
                $updateLast = '';

                $cat2 = $1;
                $jmp = $1;
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
                $cat2 = "<a href=\"/lineeval.htm?path=$form->{'path'}#line$lnno\" target=\"_blank\">$cat2</a>";
            } elsif (($tim, $dsc) = $this =~ /^\* (\d{8,8} \d{6,6}) *(.*)/) {
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
                if (($updateLast eq '') && defined($dsc) && length($dsc)) {
                    # calculate days since last entry
                    $updateLast = int((time - &l00httpd::now_string2time($tim)) / (3600*24) + 0.5);
                    if ($updateLast > 1) {
                        # report only for 2 or more days old
                        $updateAge{$key} = "<font style=\"color:black;background-color:silver\">${updateLast}d</font>";
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
                        $dsc = "$bang<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$clip\" target=\"_blank\">$desc</a>";
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
                if (!defined($tasksTime{$key}) ||
                            ($tasksTime{$key} lt $tim)) {
                             $tasksTime{$key} = $tim;
                             $dsc =~ s/^\^(.+)/^<strong><font style="color:yellow;background-color:fuchsia">$1<\/font><\/strong>/;
                             $tasksDesc{$key} = $dsc;
                             $countBang{$key} = 0;
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
                             $lnnostr = sprintf("%02d", $lnno);
                             $tasksTime{"||<a href=\"/ls.htm?path=$form->{'path'}#$jmp\">$cat1</a>|| $lnnostr $cat2 "} = "!!$tim";
                             $tasksDesc{"||<a href=\"/ls.htm?path=$form->{'path'}#$jmp\">$cat1</a>|| $lnnostr $cat2 "} = $dsc;
                            if ($dbg) {
                                print $sock "    !!! $this\n";
                            }
                }
                if (!defined($tasksSticky{$key})) {
                             $tasksSticky{$key} = '';
                }
                if ($listbang eq '') {
                    # not listing all !, i.e. listing !! only
                    if ($dsc =~ /^!!/) {
                                 $tasksSticky{$key} .= " - $dsc";
                    }
                } else {
                    # listing all !, i.e. listing ! and !!
                    if ($dsc =~ /^!/) {
                                 $tasksSticky{$key} .= "<br>$dsc";
                    }
                }
                if ($dsc =~ /^![^!]/) {
                             $countBang{$key}++;
                }
                if ($dbg) {
                    print $sock "          $cat1    $cat2    $tim    $this\n";
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
                    ($tim) = $ctrl->{'now_string'} =~ /20\d\d(\d+ \d\d\d\d)\d\d/;
                    while (<IN>) {
                        s/[\n\r]//g;
                        $cnt++;
                        if (/^#/) {
                            next;
                        }
                        $lnnostr = sprintf("%02d", $cnt);
                        #[[/ls.htm?path=$form->{'path'}#$jmp|iHot]]
                        #<a href=\"/ls.htm?path=$form->{'path'}#$jmp\">iHot</a>
                        $tasksTime{"||<a href=\"/ls.htm?path=$form->{'path'}#$jmp\">iHot</a> || $lnnostr <a href=\"/recedit.htm?record1=.&path=${pname}$hot\">INC</a> "} = "!!$tim";
                        $tasksDesc{"||<a href=\"/ls.htm?path=$form->{'path'}#$jmp\">iHot</a> || $lnnostr <a href=\"/recedit.htm?record1=.&path=${pname}$hot\">INC</a> "} = "$_";
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
        $cnt = 0;
        push (@tops, "||$ctrl->{'now_string'}|| *y*<a href=\"#bangbang\">now</a>** || || ||``tasksTime``");
        foreach $_ (sort keys %tasksTime) {
            $cnt++;
            if ($dbg) {
                print $sock "    $_: $tasksTime{$_}  $tasksDesc{$_}\n";
            }
            if (defined($countBang{$_}) && ($countBang{$_} > 0)) {
                # if ($countBang{$_} > 0)
                if ($listbang eq '') {
                    # not listing all !, i.e. listing !! only
                    $bang = "<font style=\"color:black;background-color:silver\">".
                    "<a name=\"row$cnt\"></a><a href=\"/dash.htm?process=Process&path=$form->{'path'}&listbang=on#row$cnt\">!#$countBang{$_}</a></font>";
                } else {
                    # listing all !, i.e. listing ! and !!
                    $bang = "<font style=\"color:black;background-color:silver\">".
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
            if (defined($tasksSticky{$_})) {
                if (index($tasksSticky{$_}, $tasksDesc{$_}) >= 0) {
                    # current is also sticky, skip current
                    push (@tops, "||$tasksTime{$_}$_||".           "$bang$tasksSticky{$_} ||``$_``");
                } else {
                    push (@tops, "||$tasksTime{$_}$_||$bang$tasksDesc{$_}$tasksSticky{$_} ||``$_``");
                }
            } else {
                push (@tops, "||$tasksTime{$_}$_||$bang$tasksDesc{$_} ||``$_``");
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
            if (s/^(\|\| *!*)(20\d\d)(\d+ \d\d\d\d)(\d\d)(.+)``(.+)``$/$1$3$4$5``$6``/) {
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

            # ``tasksTime``
#            s/``.+$//;

# do not high this hour or today date/time stamp
#           if (/^\|\|!!(.+)/) {
#               # special with leading !! which are either iHot or !!!
#               # highlight this hour
#               /^(\|\|!!*)(\d\d\d\d \d\d)/;
#               if ($2 ne substr($ctrl->{'now_string'}, 4, 7)) {
#                   # highlight !!! because all iHot has current time
#                   s/^(\|\| *!*)(\d\d\d\d) (\d\d\d\d)/$1<strong>$2_$3<\/strong>/;
#               }
#           }
#           if (/^\|\|\d/) {
#               # special with leading !! which are either iHot or !!!
#               # highlight this hour
#               /^\|\|(\d\d\d\d) \d\d/;
#               if ($1 eq substr($ctrl->{'now_string'}, 4, 4)) {
#                   # highlight !!! because all iHot has current time
#                   s/^(\|\|)(\d\d\d\d) (\d\d\d\d)/$1<strong>$2 $3<\/strong>/;
#               }
#           }
            push(@tops2, $_);
        }
        $anchor = '<a name="bangbang"></a>';
        foreach $_ (sort {$b cmp $a} @tops2) {
            # drop seconds
            s/^(\|\|!*\d\d\d\d \d\d\d\d)\d\d\|\|/$1||/;
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
        }
        $out =~ s/\\n/<br>/gm;
        $out = sprintf("<font style=\"color:black;background-color:silver\">Today: %d min</font>\n", 
               int($timetoday / 60 + 0.5)) . $out;

        $out .= "* Color in section: *l*now** , *s*next** , *g*near** . Last updated first.\n";
        $out .= "* List: <a href=\"/txtdopl.htm?runbare=RunBare&arg=&sel=&path=$form->{'path'}&arg=all\">all</a>; ";
        $out .= "<a href=\"/txtdopl.htm?runbare=RunBare&arg=&sel=&path=$form->{'path'}&arg=new\">new only</a>; ";
        $out .= "<a href=\"/txtdopl.htm?runbare=RunBare&arg=&sel=&path=$form->{'path'}\">old only</a>\n";
        $out .= "* ===chapter=== to hide low priority tasks\n";
        $out .= "* !!! at the end of comment to make a sticky note at the bottom (& in BOOKMARKS)\n";
        $out .= "* !! at start to also show in the latest\n";
        $out .= "* ! at start to add to !# count\n";
        $out .= "* Make comment date in the future to hide it\n";
        $out .= "** arg eq 'new' displays only future dates\n";
        $out .= "** arg eq 'old' displays only older dates (default)\n";
        $out .= "* \\n are converted to newlines\n";
        $out .= "* Just timestamp is ok to mark new date, e.g. * 20171005 001200\n";
        $out .= "* * 20171005 001200 time.start and * 20171005 001200 time.stop to record time spent\n";
        $out .= "* ^now, to mark a hot KIV item, until newer entry is posted\n";
        $out .= "* View <a href=\"/view.htm?path=$form->{'path'}\">$form->{'path'}</a>\n";
        $out .= "* Send shortcut [[/clip.htm?update=Copy+to+CB&clip=*+%5B%5B%2Fls.htm%3Ffind%3DFind%26findtext%3D%255E%255C%253D%253D%253D%26block%3D.%26prefmt%3Don%26path%3D%24%7C%3D%3D%3Dhidden+%3D%3D%3D%5D%5D+-+%5B%5B%2Fdash.htm%3Fpath%3D%24%7CProcessed+table%5D%5D%0D%0A&url=|to clipboard]]\n";

        $out = &l00wikihtml::wikihtml ($ctrl, $pname, $out, 6);
        $out =~ s/ +(<\/td>)/$1/mg;
        print $sock $out;

        if ($freefmt ne 'checked') {
            print $sock "</pre>\n";
        }
        print $sock "<hr><a name=\"end\"></a>";

        print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
        print $sock "<a href=\"#end\">Jump to end</a>\n";
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=:hide+edit+$form->{'path'}%0D\">Path</a>: ";
        print $sock " <a href=\"/ls.htm?path=$pname\">$pname</a>";
        print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$fname</a> \n";
        print $sock " <a href=\"/launcher.htm?path=$form->{'path'}\">Launcher</a>\n";
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
