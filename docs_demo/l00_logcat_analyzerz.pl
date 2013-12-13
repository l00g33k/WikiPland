my $form;
$form = $ctrl->{'FORM'};

# -------- start customization



#09-07 07:37:12.809 D/org.npr.android.news.PlaybackService(23237): Preparing: http://public.npr.org/anon.npr-mp3/npr/me/2012/09/20120904_me_14.mp3?sc=18<!--  Burned on demand at 2012-09-07 10:28:02--><!-- LOADED FROM CACHE -->
#                   if (/.*org.npr.android.news.PlaybackService.*Preparing: (http:\/\/.*?)</) {
      $matchStartHlite = ".*org.npr.android.news.PlaybackService.*Preparing: (http:\\\/\\\/.*?)<";
#09-07 07:37:15.511 E/NuHTTPDataSource(  134): connect() redirect http status error
#                    } elsif (/.*NuHTTPDataSource.*: connect.* redirect http status error/) {
      $matchEndBadHlite1 = ".*NuHTTPDataSource.*: connect.* redirect http status error";
#                    } elsif (/.*NuHTTPDataSource.*: connect.* receive header error/) {
      $matchEndBadHlite2 = ".*NuHTTPDataSource.*: connect.* receive header error";
#09-10 18:03:18.360 D/org.npr.android.news.PlaybackService(19318): Prepared
#                    } elsif (/.*org.npr.android.news.PlaybackService.*Prepared/) {
      $matchEndGoodHlite = ".*org.npr.android.news.PlaybackService.*Prepared";


# -------- end customization

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
$arg1 =~ s|\\|/|g;
if (length ($arg3) > 1) {
    $arg3fil = 1;
    $arg3show = 0;
} else {
    $arg3fil = 0;
    $arg3show = 1;
}

print $sock "<a href=\"#filejmp_1\">Jump to first results</a><p>\n";

print $sock "Processing directory <a href=\"/ls.htm?path=$arg1\">/ls.pl?path=$arg1</a><p>\n";


#<font style="color:black;background-color:lime">more words</font>
#<font style="color:black;background-color:yellow">more words</font>
#<font style="color:black;background-color:red">more words</font>
#<font style="color:black;background-color:silver">more words</font>
#<font style="color:black;background-color:gray">more words</font>
#<font style="color:black;background-color:aqua">more words</font>
#<font style="color:black;background-color:fuchsia">more words</font>
#<font style="color:black;background-color:olive">more words</font>
#<font style="color:black;background-color:teal">more words</font>
#<font style="color:black;background-color:green">more words</font>
#<font style="color:white;background-color:blue">more words</font>
#<font style="color:white;background-color:maroon">more words</font>
#<font style="color:white;background-color:navy">more words</font>
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


undef %playrst;
$filejmp = 1;
$outbuf = '';


if (opendir (DIR, $arg1)) {
    $outbuf .= "<pre>\n";
    $filecnt = 0;
    foreach $file (sort readdir (DIR)) {
        if ($file =~ /2012.+\.txt$/i) {
            if (open (IN, "<$arg1$file")) {
                $filecnt++;
                $cnt = 0;
                $thisFileOutput = '';
                $show = 0;
                $identification = '';
                while (<IN>) {
                    $cnt++;
                    s/\r//;
                    s/\n//;
                    $line = $_;
                    $line =~ s/</&lt;/;
                    $line =~ s/>/&gt;/;
                    $line = sprintf ("% 6d: %s", $cnt, $line);

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
                            $playrst {"$identification fail"}++;
                        }
                        $thisFileOutput .= "$highlight[2]FAIL: conn: $line</font>\n";
                        $identification = '';
                        $show = 0;
                    } elsif (/$matchEndBadHlite2/) {
                        if ($identification ne '') {
                            $playrst {"$identification fail"}++;
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
                            $playrst {"$identification play"}++;
                        }
                        $identification = '';
                        $show = 0;
                    } elsif ($show && ($arg2 eq 'show')) {
                        if ($arg3show) {
                            $thisFileOutput .= "            $line\n";
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
foreach $_ (sort keys %playrst) {
    ($stream, $rst) = split (' ', $_);
    $streamname{$stream} = 1;
    if ($rst eq 'fail') {
        $table{"$stream fail"} = $playrst{$_};
        if (!defined ($table{"$stream play"})) {
            $table{"$stream play"} = 0;
        }
    }
    if ($rst eq 'play') {
        $table{"$stream play"} = $playrst{$_};
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


print $sock "<hr><p>\n";
print $sock "Edit <a href=\"/edit.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";


print $sock "<form action=\"/do.htm\" method=\"get\">\n";
print $sock "<input type=\"submit\" name=\"paste\" value=\"CB paste\"> Paste cliboard to Arg1\n";
print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
print $sock "</form>\n";

print $sock "Arg1: directory containing logcat files<br>\n";
print $sock "Arg2: 'show' to show details<br>\n";
print $sock "Arg3: regex to filter results based on match on the line 'D/org.npr.android.news.PlaybackService(30488): Preparing: http://'<br>\n";

1;
