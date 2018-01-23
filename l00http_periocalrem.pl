use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my %config = (proc => "l00http_periocalrem_proc",
              desc => "l00http_periocalrem_desc",
              perio => "l00http_periocalrem_perio");
my($lastchkdate, %calremcolor, %calremfont);
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
    print $sock "$ctrl->{'home'} - <a href=\"/periocalrem.htm\">Refresh</a> \n";

    print $sock "Calendar reminder.\n";

    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_periocalrem_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($date, $len, $todo, $eventnear, $days);
    my ($thisweek, $julian, $juliannow, $color, $font);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst, $nowstamp);

    $days = 2;
    if (defined($ctrl->{'calremdays'})) {
        $days = $ctrl->{'calremdays'};
	}



    l00httpd::dbp($config{'desc'}, "CALREM $lastchkdate\n"), if ($ctrl->{'debug'} >= 2);
    if (!&l00httpd::l00freadOpen($ctrl, 'l00://calrem.txt')) {
        # rescan if extracted result was deleted
        $lastchkdate = '';
        l00httpd::dbp($config{'desc'}, "No calrem.txt\n"), if ($ctrl->{'debug'} >= 5);
    }
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
	# a nowstamp that changes 4 times a day for more frequent reminder
    $nowstamp = sprintf ("%4d%02d%02d %d", $year + 1900, $mon+1, $mday, int ($hour / 6));
    if ($lastchkdate ne $nowstamp) {
        l00httpd::dbp($config{'desc'}, "$lastchkdate is old\n"), if ($ctrl->{'debug'} >= 5);
        $lastchkdate = $nowstamp;
		if (open (IN, "<$ctrl->{'workdir'}l00_cal.txt")) {
            ($year, $mon, $mday) = $lastchkdate =~ /(\d\d\d\d)(\d\d)(\d\d)/;
            $year -= 1900;
            ($thisweek, $juliannow) = &l00mktime::weekno ($year, $mon, $mday);
            $eventnear = '';
            undef %calremcolor;
            undef %calremfont;
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
                if ($todo =~ /^ *\./) {
                    # leading . hides item
                    $todo = "#$todo";
                }
                if (defined ($date) && defined ($len) && defined ($todo)) {
                    ($year,$mon, $mday,) = split ('/', $date);
                    $year -= 1900;
                    ($thisweek, $julian) = &l00mktime::weekno ($year, $mon, $mday);
                    if (($julian - $juliannow >= -15)  &&
                        ($julian - $juliannow <= $days))  {
                        l00httpd::dbp($config{'desc'}, "found >$todo<\n"), if ($ctrl->{'debug'} >= 5);
                        $eventnear .= "$todo\n";
                        if ($julian - $juliannow <= 0) {
                            $calremcolor{$todo} = 'red';
                            $calremfont{$todo} = 'yellow';
                        } elsif ($julian - $juliannow <= 1) {
                            $calremcolor{$todo} = 'yellow';
                            $calremfont{$todo} = 'black';
                        } elsif ($julian - $juliannow <= 2) {
                            $calremcolor{$todo} = 'lime';
                            $calremfont{$todo} = 'black';
                        } elsif ($julian - $juliannow <= 3) {
                            $calremcolor{$todo} = 'aqua';
                            $calremfont{$todo} = 'black';
                        }
                        #print "  $date $todo $juliannow ($thisweek, $julian) ($year, $mon, $mday)\n";
                    }
		    	}
			}
		    close (IN);

            if ($eventnear ne '') {
                $eventnear = "* CLEAR_THIS_STOPS_ALL\n".
                             "* To refresh, [[/edit.htm?path=l00://calrem.txt&save=on&clear=on|delete calrem.txt]]\n".
                             "* [[/cal.htm?path=$ctrl->{'workdir'}l00_cal.txt&today=on|View calendar]]\n".
                             "* List of current calendar events:\n\n".
                             "$eventnear\n".
                             "* End of list\n";
                &l00httpd::l00fwriteOpen($ctrl, 'l00://calrem.txt');
		     	&l00httpd::l00fwriteBuf($ctrl, $eventnear);
			    &l00httpd::l00fwriteClose($ctrl);
			}
		}
    }
    undef $ctrl->{'BANNER:periocalrem'};
    if ((!defined($ctrl->{'calremBannerDisabled'})) && 
        &l00httpd::l00freadOpen($ctrl, 'l00://calrem.txt')) {
        $eventnear = '';
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            l00httpd::dbp($config{'desc'}, "CALREM calrem all: $_\n"), if ($ctrl->{'debug'} >= 5);
            chop;
            if (/#\* CLEAR_THIS_STOPS_ALL/) {
			    # special key
                $eventnear = '';
			    last;
			}
            if ((!/^#/) && (!/^\*+ /)) {
                if (/\* CLEAR_THIS_STOPS_ALL/) {
				    # skip special key
				    next;
				}
                l00httpd::dbp($config{'desc'}, "CALREM calrem event: >$_<\n"), if ($ctrl->{'debug'} >= 4);
                if (defined($calremcolor{$_})) {
                    $color = $calremcolor{$_};
                    $font = $calremfont{$_};
                } else {
                    $color = 'olive';
                    $font = 'black';
                }
                if ($eventnear eq '') {
                    $eventnear = "<font style=\"color:$font;background-color:$color\">$_</font>";
				} else {
                    $eventnear .= " - <font style=\"color:$font;background-color:$color\">$_</font>";
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
