use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_sleep_proc",
              desc => "l00http_sleep_desc");
my ($buffer);



sub l00http_sleep_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "sleep: Sleep logger: Log sleep/wake time and screen brightness control";
}

sub l00http_sleep_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} .$ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<br>\n";
    if (defined ($form->{'path'})) {
        print $sock "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";
    }

    $buffer = "";
    if (defined ($form->{'save'})) {
        if (defined ($form->{'buffer'}) &&
            defined ($form->{'path'}) && 
            (length ($form->{'buffer'}) > 0) && 
            (length ($form->{'path'}) > 0)) {
            $buffer = '';
            open (IN, "<$form->{'path'}");
            $buffer = <IN>;
            while (<IN>) {
                $buffer .= $_;
            }
            close (IN);
            $buffer = "$ctrl->{'now_string'} $form->{'buffer'}\n$buffer";
            &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 9);
            if (open (OUT, ">$form->{'path'}")) {
                print OUT $buffer;
                close (OUT);
            } else {
                print $sock "Unable to write '$form->{'path'}'<p>\n";
            }
        }
        if (defined ($form->{'bright'})) {
            if (($form->{'bright'} >= 0) && 
                ($form->{'bright'} <= 255)) {
                $ctrl->{'droid'}->setScreenBrightness ($form->{'bright'});
                $ctrl->{'screenbrightness'} = $form->{'bright'};
            }
        }
        if (($ctrl->{'os'} eq 'and') &&
            defined ($form->{'offwakelock'}) && 
            ($form->{'offwakelock'} eq 'on')) {
            $ctrl->{'droid'}->wakeLockRelease();
        }
        if (defined ($form->{'iamsleeping'}) && 
            ($form->{'iamsleeping'} eq 'on')) {
            $ctrl->{'iamsleeping'} = 'yes';
        } else {
            $ctrl->{'iamsleeping'} = 'no';
        }
    }

    print $sock "<form action=\"/sleep.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "Log file:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Log message:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"10\" name=\"buffer\" value=\"\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Brightness:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"6\" name=\"bright\" value=\"\"> 0-255\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Wakelock:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"checkbox\" name=\"offwakelock\">Turn off wakelock\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"save\" value=\"Save to file\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"checkbox\" name=\"iamsleeping\">I am sleeping\n";
    print $sock "</td></tr>\n";
    print $sock "</table>\n";
    print $sock "</form>\n";
    print $sock "Do once and copy and edit URL<p>\n";

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

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
