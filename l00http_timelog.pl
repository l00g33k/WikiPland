use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a time log script

my %config = (proc => "l00http_timelog_proc",
              desc => "l00http_timelog_desc");
my ($buffer, $bufhislen, $justsaved, $lastbuf);
$bufhislen = 2;
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
    my (@bufhistory, $line, $lineno, $ii, $filecontent);
    my (@quicktext, $reminder);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} .$ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
        
    if (defined ($form->{'path'})) {
        print $sock "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a> \n";
    }
    print $sock "<a name=\"__top__\"></a> ";
    print $sock "<a href=\"#__end__\">Jump to end</a><br>\n";

    $buffer = "";
    if (defined ($form->{'save'}) || defined ($form->{'quick'})) {
        # button clicked: 'Save to file', quick cuts,
        if (($justsaved == 0) &&
            (defined ($form->{'buffer'})) &&
            ((defined ($form->{'path'})) && 
            (length ($form->{'path'}) > 0)) && 
            ($form->{'buffer'} ne $lastbuf)) {
            # not repeat, got buffer and path
            if (defined ($form->{'quick'})) {
                $form->{'buffer'} .= $form->{'quick'};
            }
            $lastbuf = $form->{'buffer'};
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
    } else {
        # disallow 2 succesive save in a row; the 2nd save likely is refresh
        # get newtime to reset
    }

    # scan time entries for the last $bufhislen (2) lines.
    #08/09/10  8:54:23 ad tc
    #08/09/10  9:35:23 ad em
    #08/09/10 10:04:45 mgt joe task
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
    # clear buffer history
    undef @bufhistory;
    $buffer = '';   # edit buffer content
    if (open (IN, "<$form->{'path'}")) {
        while (<IN>) {
            push(@bufhistory, $_);
            if ($#bufhistory >= $bufhislen) {
                shift(@bufhistory);
            }
        }
        close (IN);
        $buffer .= join('', @bufhistory);
    }
    $buffer .= sprintf ("%02d/%02d/%02d %2d:%02d:%02d ", 
        $mon+1, $mday, $year-100, $hour, $min, $sec);

    # dump file content
    $filecontent = '';
    $lineno = 1;
    undef @quicktext;
    $reminder = '';
    if (open (IN, "<$form->{'path'}")) {
        $filecontent = "<pre>\n";
        while (<IN>) {
            s/\r//g;
            s/\n//g;
            if (/^\d{8,8} \d{6,6} (.+)/) {
                if ($reminder eq '') {
                    $reminder = "$1";
                } else {
                    $reminder .= "\n$1";
                }
            }
            if (/^#\d{8,8} \d{6,6} (.+)/) {
                # skip deleted item
            } elsif (/^#(.+)/) {
                # else # is quick text
                push (@quicktext, $1);
            }
            $filecontent .= sprintf ("%04d: ", $lineno++) . "$_\n";
        }
        close (IN);
        $filecontent .= "</pre>\n";
    }
    if ($reminder ne '') {
        print $sock "<pre><font style=\"color:black;background-color:yellow\">$reminder</font></pre>\n";
    }

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
    $lineno = 0;
    foreach $_ (@quicktext) {
        print $sock "<input type=\"submit\" name=\"quick\" value=\"$_\">\n";
    }
    print $sock "</form>\n";


    print $sock $filecontent;
    print $sock "<a href=\"#__top__\">Jump to top</a>\n";
    print $sock "<a name=\"__end__\"></a><br>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
