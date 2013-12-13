
my $form;
$form = $ctrl->{'FORM'};

# -------- start customization


# filename filter
#'2012.+\.txt$'
@matchFilenames = ('2012-09-12-08-22-19.b4npr2.somegoodx3.txt$');

#09-07 07:37:12.809 D/org.npr.android.news.PlaybackService(23237): Preparing: http://public.npr.org/anon.npr-mp3/npr/me/2012/09/20120904_me_14.mp3?sc=18<!--  Burned on demand at 2012-09-07 10:28:02--><!-- LOADED FROM CACHE -->
@matchRecSt = ('.*org.npr.android.news.PlaybackService.*Preparing: (http://.*?)<');

#09-07 07:37:12.809 D/org.npr.android.news.PlaybackService(23237): Preparing: http://public.npr.org/anon.npr-mp3/npr/me/2012/09/20120904_me_14.mp3?sc=18<!--  Burned on demand at 2012-09-07 10:28:02--><!-- LOADED FROM CACHE -->
@matchId = ('.*org.npr.android.news.PlaybackService.*Preparing: (http://.*?)<');

#09-07 07:37:15.511 E/NuHTTPDataSource(  134): connect() redirect http status error
#09-10 18:03:18.360 D/org.npr.android.news.PlaybackService(19318): Prepared
@matchRecEn = ('.*NuHTTPDataSource.*: connect.* redirect http status error',
               '.*NuHTTPDataSource.*: connect.* receive header error',
               '.*org.npr.android.news.PlaybackService.*Prepared');

#09-07 07:37:15.511 E/NuHTTPDataSource(  134): connect() redirect http status error
#09-10 18:03:18.360 D/org.npr.android.news.PlaybackService(19318): Prepared
@matchMarkColor = ('__2__:.*NuHTTPDataSource.*: connect.* redirect http status error',
                   '__2__:.*NuHTTPDataSource.*: connect.* receive header error',
                   '__0__:.*org.npr.android.news.PlaybackService.*Prepared',
                   '__3__:.*org.npr.android.news.PlaybackService.*Preparing: http:\/\/',
                   );



# old

#09-07 07:37:12.809 D/org.npr.android.news.PlaybackService(23237): Preparing: http://public.npr.org/anon.npr-mp3/npr/me/2012/09/20120904_me_14.mp3?sc=18<!--  Burned on demand at 2012-09-07 10:28:02--><!-- LOADED FROM CACHE -->
#                   if (/.*org.npr.android.news.PlaybackService.*Preparing: (http:\/\/.*?)</) {
      @matchStartHlite = '.*org.npr.android.news.PlaybackService.*Preparing: (http:\\\/\\\/.*?)<';
#09-07 07:37:15.511 E/NuHTTPDataSource(  134): connect() redirect http status error
#                    } elsif (/.*NuHTTPDataSource.*: connect.* redirect http status error/) {
      $matchEndBadHlite1 = ".*NuHTTPDataSource.*: connect.* redirect http status error";
#                    } elsif (/.*NuHTTPDataSource.*: connect.* receive header error/) {
      $matchEndBadHlite2 = ".*NuHTTPDataSource.*: connect.* receive header error";
#09-10 18:03:18.360 D/org.npr.android.news.PlaybackService(19318): Prepared
#                    } elsif (/.*org.npr.android.news.PlaybackService.*Prepared/) {
      $matchEndGoodHlite = ".*org.npr.android.news.PlaybackService.*Prepared";


# -------- end customization

$dbg = 0;

#$arg1 = '';
#$arg2 = 200;
if (defined ($form->{'arg1'})) {
	$arg1 = $form->{'arg1'};
}
if (defined ($form->{'arg2'})) {
	$arg2 = $form->{'arg2'};
}
if (defined ($form->{'arg3'})) {
	$arg3 = $form->{'arg3'};
}
if (defined ($form->{'paste'})) {
    $arg1 = $ctrl->{'droid'}->getClipboard()->{'result'};
    print "From clipboard:\n$arg1\n";
}

$mode = 1;
if (defined ($form->{'mode2'})) {
    $mode = 2;
}
$arg1 =~ s|\\|/|g;
if (length ($arg3) > 1) {
    $arg3fil = 1;
    $arg3show = 0;
} else {
    $arg3fil = 0;
    $arg3show = 1;
}


print $sock "<hr><p>\n";
print $sock "Edit <a href=\"/edit.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";


print $sock "<form action=\"/do.htm\" method=\"get\">\n";
print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";

print $sock "<tr><td><input type=\"submit\" name=\"run\" value=\"Run\"></td>\n";
print $sock "    <td>Click here to filter logcat</td></tr>\n";

print $sock "<tr><td>";
$state = '';
print $sock "<input type=\"radio\" $state name=\"filter0\" value=\"#0\">No filter<br>";
print $sock "<input type=\"radio\" $state name=\"filter1\" value=\"#1\">Some filters<br>";
print $sock "</td>\n";
print $sock "    <td>Select preset filter</td></tr>\n";

print $sock "<tr><td><input type=\"submit\" name=\"paste\" value=\"Paste clipboard\"></td>\n";
print $sock "    <td>Click here to filter logcat</td></tr>\n";

print $sock "<tr><td><input type=\"text\" size=\"16\" name=\"arg1\" value=\"$arg1\"></td>\n";
print $sock "    <td>Target directory</td></tr>\n";
print $sock "</table>\n";
print $sock "</form>\n";

print $sock "Processing directory <a href=\"/ls.htm?path=$arg1\">/ls.pl?path=$arg1</a><p>\n";

print $sock "<a href=\"#filejmp_1\">Jump to first results</a><p>\n";

#<font style="color:black;background-color:lime">lime</font>
#<font style="color:black;background-color:yellow">yellow</font>
#<font style="color:black;background-color:red">red</font>
#<font style="color:black;background-color:silver">silver</font>
#<font style="color:black;background-color:gray">gray</font>
#<font style="color:black;background-color:aqua">aqua</font>
#<font style="color:black;background-color:fuchsia">fuchsia</font>
#<font style="color:black;background-color:olive">olive</font>
#<font style="color:black;background-color:teal">teal</font>
#<font style="color:black;background-color:green">green</font>
#<font style="color:white;background-color:blue">blue</font>
#<font style="color:white;background-color:maroon">maroon</font>
#<font style="color:white;background-color:navy">navy</font>
@highlight = (
    "<font style=\"color:black;background-color:lime\">",
    "<font style=\"color:black;background-color:yellow\">",
    "<font style=\"color:black;background-color:red\">",
    "<font style=\"color:black;background-color:silver\">",
    "<font style=\"color:black;background-color:gray\">",
    "<font style=\"color:black;background-color:aqua\">",
    "<font style=\"color:black;background-color:fuchsia\">",
    "<font style=\"color:black;background-color:olive\">",
    "<font style=\"color:black;background-color:teal\">",
    "<font style=\"color:black;background-color:green\">",
    "<font style=\"color:white;background-color:blue\">",
    "<font style=\"color:white;background-color:maroon\">",
    "<font style=\"color:white;background-color:navy\">"
);



@filter = (
    "\\\): Preparing: ",
    "\\\): Waiting for prepare",
    "\\\): connect\\\(\\\) redirect http status error",
    "\\\): error \\\(1, -1004\\\)",
    "\\\): onError\\\(1, -1004\\\)",
    "\\\): info\\\/warning \\\(1, 902\\\)",
    "\\\): Prepared/",
    "is not localhost"
);


#if (($arg2 ne 'a') && ($arg2 ne 'b')) {
#    $jmp = 1;
#    $wget .= "<a name=\"jmp_0\"></a><a href=\"#jmp_1\">jump to first highlight</a>\n";
#}


undef %playresults;
$filejmp = 1;
$outbuf = '';


if (opendir (DIR, $arg1)) {
    $outbuf .= "<pre>\n";
    $filecnt = 0;
    foreach $file (sort readdir (DIR)) {
        $matched = 0;
        foreach $filter (@matchFilenames) {
            if ($file =~ /$filter/) {
                $matched = 1;
            }
        }
        if ($matched) {
            if (open (IN, "<$arg1$file")) {
                $filecnt++;
                $cnt = 0;
                $thisFileOutput = '';
                $show = 0;
                $identification = '';
                if ($dbg) {
                    $outbuf .= "$arg1$file\n";
                }
                $id = '(unknown)';
                while (<IN>) {
                    $cnt++;
                    s/\r//;
                    s/\n//;
                    $line = $_;
                    $line =~ s/</&lt;/;
                    $line =~ s/>/&gt;/;
                    $line = sprintf ("% 6d: %s", $cnt, $line);

if(1){
                    # ---------------------------------------------------------
                    # Find ID
                    $matched = 0;
                    foreach $filter (@matchId) {
                        if (/$filter/) {
                            $idfound = $1;
                            $matched = 1;
                            last;
                        }
                    }
                    if ($matched) {
                        $id = $idfound;
                        if ($id ne '') {
                            $playresults {"$id play"}++;
                        }
                        if ($dbg) {
                            $outbuf .= "ID $id\n";
                        }
                    }


                    # ---------------------------------------------------------
                    # Start recording?
                    $matched = 0;
                    foreach $filter (@matchRecSt) {
                        if (/$filter/) {
                            $matched = 1;
                            last;
                        }
                    }
                    if ($matched) {
                        $recbuf = '';
                        $recording = 1;
                        if ($dbg) {
                            $outbuf .= "Start Recording\n";
                        }
                    }


                    # ---------------------------------------------------------
                    # mark Color
                    $matched = 0;
                    $colormatch = -1;
                    foreach $col_filter (@matchMarkColor) {
                        if (($color,$filter) = ($col_filter =~ /^__(\d+)__:(.+)$/)) {
                            if (/$filter/) {
                                $matched = 1;
                                $colormatch = $color;
                                last;
                            }
                        }
                    }
                    if ($matched) {
                        if ($dbg) {
                            $outbuf .= "Coloring $colormatch\n";
                        }
                    }


                    # ---------------------------------------------------------
                    # add to output buffer
                    if ($colormatch >= 0) {
                        $recbuf .= $highlight[$colormatch] . "$line</font>\n";
                    } else {
                        if ($recording) {
                            if ($mode != 2) {
                                $recbuf .= "$line\n";
                            }
                        }
                    }

                    # ---------------------------------------------------------
                    # End recording?
                    $matched = 0;
                    foreach $filter (@matchRecEn) {
                        if (/$filter/) {
                            $matched = 1;
                            last;
                        }
                    }
                    if ($matched) {
                        $outbuf .= $recbuf;
                        $recbuf = '';
                        $recording = 0;
                        if ($dbg) {
                            $outbuf .= "Stop  Recording\n";
                        }
                    }


                    
} else {
                    if (/$matchStartHlite/) {
                        if ($arg3fil) {
                            if (/$arg3/) {
                                $arg3show = 1;
                            } else {
                                $arg3show = 0;
                            }
                        }
                        $identification = $1;
                        $show = 1;
                        $thisFileOutput .= "$highlight[3]preparing:  $line</font>\n";
#                        $thisHitOutput = "$highlight[3]preparing:  $line</font>\n";
                    } elsif (/$matchEndBadHlite1/) {
                        if ($identification ne '') {
                            $playresults {"$identification fail"}++;
                        }
                        $thisFileOutput .= "$highlight[2]FAIL: conn: $line</font>\n";
                        $identification = '';
                        $show = 0;
                    } elsif (/$matchEndBadHlite2/) {
                        if ($identification ne '') {
                            $playresults {"$identification fail"}++;
                        }
                        $thisFileOutput .= "$highlight[2]FAIL: head: $line</font>\n";
                        $identification = '';
                        $show = 0;
                    } elsif (/$matchEndGoodHlite/) {
                        if ($identification ne '') {
                            $thisFileOutput .= "$highlight[0]PLAY: play: $line</font>\n";
                        }
                        $arg3show = 0;
                        if ($identification ne '') {
                            $playresults {"$identification play"}++;
                        }
                        $identification = '';
                        $show = 0;
                    } elsif ($show && ($arg2 eq 'show')) {
                        if ($arg3show) {
                            $thisFileOutput .= "            $line\n";
                        }
                    }
}
                }
                $filejmpa = $filejmp - 1;
                $filejmpz = $filejmp + 1;
                $outbuf .= sprintf (
                        "$highlight[4]".
                        "<a href=\"#filejmp_$filejmpa\">LAST</a> ".
                        "<a href=\"#filejmp_$filejmpz\">NEXT</a> ".
                        "<a name=\"filejmp_$filejmp\">% 6d lines in $file</a> ".
                        "(file #$filecnt of ___total_file_cnt___) ".
                        "</font>\n",
                        $cnt);
                $outbuf .= $thisFileOutput;
                $filejmp++;
                close (IN);
            }
        }
    }
    close (DIR);
    $outbuf .= "</pre>\n";
} else {
    print $sock "Unable to open opendir: $arg<p>\n";
}
$filejmp--;
$outbuf .= "<a href=\"#filejmp_$filejmp\">Jump to last result</a><p>\n";

$outbuf =~ s/___total_file_cnt___/$filecnt/g;


undef %table;
undef %streamname;
foreach $_ (sort keys %playresults) {
    ($stream, $rst) = split (' ', $_);
    $streamname{$stream} = 1;
    if ($rst eq 'fail') {
        $table{"$stream fail"} = $playresults{$_};
        if (!defined ($table{"$stream play"})) {
            $table{"$stream play"} = 0;
        }
    }
    if ($rst eq 'play') {
        $table{"$stream play"} = $playresults{$_};
        if (!defined ($table{"$stream fail"})) {
            $table{"$stream fail"} = 0;
        }
    }
}

print $sock "<table border=\"1\" cellpadding=\"1\" cellspacing=\"1\">\n";
print $sock "<tr><td>stream</td><td align=\"right\">FAIL</td><td align=\"right\">PLAY</td></tr>\n";
foreach $_ (sort keys %streamname) {
    $fail = $table{"$_ fail"};
    $play = $table{"$_ play"};
    print $sock "<tr><td><a href=\"$_\">$_</a></td><td align=\"right\">$fail</td><td align=\"right\">$play</td></tr>\n";
}
print $sock "</table>\n";

print $sock "<hr><p>\n";
print $sock "$outbuf\n";




1;
