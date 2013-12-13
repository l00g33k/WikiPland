use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a time log script

my %config = (proc => "l00http_timelog_proc",
              desc => "l00http_timelog_desc");
my ($buffer, $hislen, $justsaved, $lastbuf);
$hislen = 2;
$justsaved = 0;
$lastbuf = '';


sub l00http_timelog_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "timelog: accounting for how you have spent your time";
}


sub l00http_timelog_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno, $ii, $battlvl);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} .$ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a> \n";
        
    if (defined ($form->{'path'})) {
        print $sock "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a> \n";
    }
    print $sock "<a name=\"__top__\"></a> ";
    if ($ctrl->{'os'} eq 'and') {
        $battlvl = $ctrl->{'droid'}->batteryGetLevel(); 
#&l00httpd::dumphash ("battlvl", $battlvl);
#        print $sock "batt=$battlvl->{'result'} % ";
    }
    print $sock "<a href=\"#__end__\">Jump to end</a><br>\n";

    $buffer = "";
    if (defined ($form->{'save'})) {
        if (($justsaved == 0) &&
            (defined ($form->{'buffer'})) &&
            ((defined ($form->{'path'})) && 
            (length ($form->{'path'}) > 0))) {
            if ($form->{'buffer'} ne $lastbuf) {
                $lastbuf = $form->{'buffer'};
#               $justsaved = 1;
#               &l00backup::backupfile ($ctrl, $form->{'path'}, 0, 4);
                &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 9);
                if (open (IN, "<$form->{'path'}")) {
                    local $/;
                    #09/15/10 12:41:56 
                    my $match = substr ($form->{'buffer'}, 0, 17);
                    #print "match )$match(\n";
                    $/ = undef;
                    $buffer = <IN>;
                    close (IN);
                    open (OUT, ">$form->{'path'}");
                    foreach $line (split ("\n", $buffer)) {
                        if ($match eq substr ($line, 0, 17)) {
                            last;
                        }
                        $line =~ s/\r//g;
                        $line =~ s/\n//g;
                        print OUT "$line\n";
                    }
                    foreach $line (split ("\n", $form->{'buffer'})) {
                        $line =~ s/\r//g;
                        $line =~ s/\n//g;
                        print OUT "$line\n";
                    }
                    close (OUT);
                } else {
                    print $sock "Unable to write '$form->{'path'}'<p>\n";
                }
            }
        }
    } else {
        # disallow 2 succesive save in a row; the 2nd save likely is refresh
        # get newtime to reset
#       $justsaved = 0;
    }
#08/09/10  8:54:23 ad tc
#08/09/10  9:35:23 ad em
#08/09/10 10:04:45 mgt joe task
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
    for ($line = 0; $line < $hislen; $line++) {
        $alllines [$line] = '';
    }
    $buffer = '';
    if (open (IN, "<$form->{'path'}")) {
        $line = 0;
        while (<IN>) {
            $alllines [$line] = $_;
            $line++;
            if ($line >= $hislen) {
                $line = 0;
            }
        }
        close (IN);
        for ($ii = 0; $ii < $hislen; $ii++) {
            $buffer .= $alllines [$line];
            $line++;
            if ($line >= $hislen) {
                $line = 0;
            }
        }
    }
    $buffer .= sprintf ("%02d/%02d/%02d %2d:%02d:%02d ", 
        $mon+1, $mday, $year-100, $hour, $min, $sec);

    print $sock "<form action=\"/timelog.htm\" method=\"post\">\n";
    print $sock "<textarea name=\"buffer\" cols=\"$ctrl->{'txtw'}\" rows=\"$ctrl->{'txth'}\">$buffer</textarea>\n";
    print $sock "<p>\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"save\" value=\"Save to file\">\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";

    print $sock "</td><td>\n";

    print $sock "<input type=\"submit\" name=\"newtime\" value=\"New time\">\n";

    print $sock "</td></tr>\n";
    print $sock "</table>\n";
    print $sock "</form>\n";

    # get submitted name and print greeting
    $lineno = 1;
    if (open (IN, "<$form->{'path'}")) {
        print $sock "<pre>\n";
        while (<IN>) {
            s/\r//g;
            s/\n//g;
            print $sock sprintf ("%04d: ", $lineno++) . "$_\n";
        }
        close (IN);
        print $sock "</pre>\n";
    }
    print $sock "<a href=\"#__top__\">Jump to top</a>\n";
    print $sock "<a name=\"__end__\"></a><br>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
