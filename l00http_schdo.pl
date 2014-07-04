#use strict;
#use warnings;

use l00mktime;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my ($runtime, $dopl, $wake, $vmsec, $theline);
my %config = (proc => "l00http_schdo_proc",
              desc => "l00http_schdo_desc",
              perio => "l00http_schdo_perio");
$runtime = 0x7fffffff;
$dopl = '';
$wake = 0;
$vmsec = 60;
$theline = '';

sub l00http_schdo_date2j {
# convert from date to seconds
    my $temp = pop;
    my $secs = 0;
    my ($yr, $mo, $da, $hr, $mi, $se);

    $temp =~ s/ //g;
    $temp =~ s/\///g;
    $temp =~ s/://g;
    if (($yr, $mo, $da, $hr, $mi, $se) = ($temp =~ /(....)(..)(..)(..)(..)(..)/)) {
        $yr -= 1900;
        $mo--;
        $secs = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
    }
    
    $secs;
}

sub l00http_schdo_find {
# find active schdo (oldest)
    my $ctrl = pop;
    my ($st, $pl, $ln, $st0, $pl0, $ln0);

    $runtime = 0x7fffffff;
    if (open (IN, "<$ctrl->{'workdir'}l00_schdo.txt")) {
        $st0 = 0;
        while (<IN>) {
            chop;
            if (($st, $pl) = /^([ 0-9]+):(.*)$/) {
                $st = &l00http_schdo_date2j ($st);
                $ln = $_;
                if (($st0 == 0) || ($st < $st0)) {
                    ($st0, $pl0) = ($st, $pl);
                    $ln0 = $ln;
                }
            }
        }
        if ($st0 > 0) {
            $runtime = $st0;
            $dopl = $pl0;
            $theline = $ln0;
        }
        close (IN);
    }
}


sub l00http_schdo_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/

    &l00http_schdo_find ($ctrl);

    "schdo: A scheduled do task demo.";
}

sub l00http_schdo_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my $temp;
    my ($yr, $mo, $da, $hr, $mi, $se);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);

    if ((defined ($form->{'paste'})) && ($ctrl->{'os'} eq 'and')) {
        $dopl = $ctrl->{'droid'}->getClipboard()->{'result'};
    }
    if (defined ($form->{"dopl"})) {
        $dopl = $form->{"dopl"};
    }
    if (defined ($form->{"set"})) {
        if ($wake != 0) {
            $wake = 0;
            $ctrl->{'droid'}->wakeLockRelease();
        }
        if (defined ($form->{"runtime"})) {
            $runtime = &l00http_schdo_date2j ($form->{"runtime"});
            if ($runtime != 0) {
                $temp = $runtime - time;
                print "Starting in $temp secs\n";
                if (open (OU, ">>$ctrl->{'workdir'}l00_schdo.txt")) {
                    print OU "$form->{'runtime'}:$dopl\n";
                    close (OU);
                }
            }
        }
        # find earliest schdo
        &l00http_schdo_find ($ctrl);
    }


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"/schdo.htm\">Refresh</a> \n";
    print $sock "<a href=\"#end\">Jump to end</a> \n";
    print $sock "<a href=\"/ls.htm?path=$ctrl->{'workdir'}l00_schdo.txt\">$ctrl->{'workdir'}l00_schdo.txt</a><p> \n";

    print $sock "<form action=\"/schdo.htm\" method=\"post\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Run time:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"runtime\" value=\"$ctrl->{'now_string'}\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>(do).pl :</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"dopl\" value=\"$dopl\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"set\" value=\"Set\"> <input type=\"submit\" name=\"paste\" value=\"Paste\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"newtime\" value=\"New time\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "<br>Do pl: $dopl<br>\n";
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime ($runtime);
    print $sock sprintf ("Start: %04d/%02d/%02d %2d:%02d:%02d<br>\n", 
        $year+1900, $mon+1, $mday, $hour, $min, $sec);

    if (open (IN, "<$ctrl->{'workdir'}l00_schdo.txt")) {
        print $sock "<pre>\n";
        while (<IN>) {
            print $sock $_;
        }
        close (IN);
        print $sock "</pre>\n";
    }
    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_schdo_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($retval, $buf, $rethash);

    if (time >= $runtime) {
        #
        print "running $runtime $dopl\n";
        $rethash  = do $dopl;
        if (!defined ($rethash)) {
            if ($!) {
                print "Can't read module: $dopl: $!\n";
            } elsif ($@) {
                print "Can't parse module: $@\n";
            }
        } else {
            # default to disabled to non local clients^M
            print "Completed: do $dopl\n";
        }

        $buf = '';
        # mark pl done
        if (open (IN, "<$ctrl->{'workdir'}l00_schdo.txt")) {
            while (<IN>) {
                s/\r//;
                s/\n//;
                if ($_ eq $theline) {
                    $buf .= "#$_\n";
                } else {
                    $buf .= "$_\n";
                }
            }
            close (IN);
        }
        if (open (OU, ">$ctrl->{'workdir'}l00_schdo.txt")) {
            print OU $buf;
            close (OU);
        }
        $runtime = 0x7fffffff;
        &l00http_schdo_find ($ctrl);

        $retval = 0;
    } else {
        $retval = $runtime - time;
    }

    $retval;
}


\%config;
