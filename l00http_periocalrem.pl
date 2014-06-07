use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my %config = (proc => "l00http_periocalrem_proc",
              desc => "l00http_periocalrem_desc",
              perio => "l00http_periocalrem_perio");
my($lastchkdate);
$lastchkdate = '';


sub l00http_periocalrem_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "periocalrem: Calendar reminder";
}


sub l00http_periocalrem_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} - <a href=\"/periocalrem.htm\">Refresh</a><br> \n";

    print $sock "Calendar reminder.\n";

    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_periocalrem_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($date, $len, $todo, $eventnear, $days);
    my ($thisweek, $julian, $juliannow);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst, $nowstamp);

    $days = 2;
    if (defined($ctrl->{'calremdays'})) {
        $days = $ctrl->{'calremdays'};
	}

    $ctrl->{'BANNER:periocalrem'} = '<center><font style="color:black;background-color:yellow">periocalrem</font></center>';
    undef $ctrl->{'BANNER:periocalrem'};


    l00httpd::dbp($config{'desc'}, "CALREM $lastchkdate\n"), if ($ctrl->{'debug'} >= 5);
    if (!&l00httpd::l00freadOpen($ctrl, 'l00://calrem.txt')) {
        # rescan if extracted result was deleted
        $lastchkdate = '';
        l00httpd::dbp($config{'desc'}, "No calrem.txt\n"), if ($ctrl->{'debug'} >= 5);
    }
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
	# a nowstamp that changes 4 times a day for more frequent reminder
    $nowstamp = sprintf ("%4d%02d%02d %d", $year + 1900, $mon+1, $mday, int ($hour / 6));
#   if ($lastchkdate ne substr($ctrl->{'now_string'},0,8)) {
    if ($lastchkdate ne $nowstamp) {
        l00httpd::dbp($config{'desc'}, "$lastchkdate is old\n"), if ($ctrl->{'debug'} >= 5);
        $lastchkdate = $nowstamp;
#       $lastchkdate = substr($ctrl->{'now_string'},0,8);
		if (open (IN, "<$ctrl->{'workdir'}l00_cal.txt")) {
            ($year, $mon, $mday) = $lastchkdate =~ /(\d\d\d\d)(\d\d)(\d\d)/;
            $year -= 1900;
            ($thisweek, $juliannow) = &l00mktime::weekno ($year, $mon, $mday);
            $eventnear = '';
		    while (<IN>) {
                chop;
                if (/^#/) {
	            # # in column 1 is remark
                    next;
                }
                if (!/^\d/) {
	            # must start with numeric
                    next;
                }
                ($date, $len, $todo) = split (',', $_);
                if (defined ($date) && defined ($len) && defined ($todo)) {
                    ($year,$mon, $mday,) = split ('/', $date);
                    $year -= 1900;
                    ($thisweek, $julian) = &l00mktime::weekno ($year, $mon, $mday);
                    if (($julian - $juliannow >= 0)  &&
                        ($julian - $juliannow <= $days))  {
                        l00httpd::dbp($config{'desc'}, "found $todo\n"), if ($ctrl->{'debug'} >= 5);
                        $eventnear .= "$todo\n";
                        #print "  $date $todo $juliannow ($thisweek, $julian) ($year, $mon, $mday)\n";
                    }
		    	}
			}
		    close (IN);

            if ($eventnear ne '') {
                $eventnear = "* CLEAR_THIS_STOPS_ALL\n$eventnear";
#               $eventnear .= "* makes wiki\n";
                $ctrl->{'BANNER:periocalrem'} = "<center><font style=\"color:black;background-color:yellow\">cal: $eventnear</font></center>";
                &l00httpd::l00fwriteOpen($ctrl, 'l00://calrem.txt');
		     	&l00httpd::l00fwriteBuf($ctrl, $eventnear);
			    &l00httpd::l00fwriteClose($ctrl);
			}
		}
    }
    undef $ctrl->{'BANNER:periocalrem'};
    if (&l00httpd::l00freadOpen($ctrl, 'l00://calrem.txt')) {
        $eventnear = '';
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            l00httpd::dbp($config{'desc'}, "CALREM calrem all: $_\n"), if ($ctrl->{'debug'} >= 5);
            chop;
            if (/#\* CLEAR_THIS_STOPS_ALL/) {
			    # special key
                $eventnear = '';
			    last;
			}
            if (!/^[#*]/) {
                if (/\* CLEAR_THIS_STOPS_ALL/) {
				    # skip special key
				    next;
				}
                l00httpd::dbp($config{'desc'}, "CALREM calrem event: $_\n"), if ($ctrl->{'debug'} >= 3);
                if ($eventnear eq '') {
                    $eventnear = "<font style=\"color:black;background-color:yellow\">$_</font>";
				} else {
                    $eventnear .= " - <font style=\"color:black;background-color:yellow\">$_</font>";
				}
            }
            if ($eventnear ne '') {
                $ctrl->{'BANNER:periocalrem'} = "<center><a href=\"/recedit.pl?record1=.&path=l00://calrem.txt\">cal</a>: $eventnear</center>";
            }
        }
    }

    0;  # not a periodic task; just take advantage so we get call on page load
}


\%config;
