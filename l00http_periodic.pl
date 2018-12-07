use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my ($lastcalled, $perbuf, $percnt, $perltime, $eval);
my %config = (proc => "l00http_periodic_proc",
              desc => "l00http_periodic_desc",
              perio => "l00http_periodic_perio");
my $interval = 0, $lastcalled = 0;
$percnt = 0;
$perltime = 0;
$eval = '';

sub l00http_periodic_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "periodic: A periodic task demo.  Click and change 'Run interval' to non zero";
}

$perbuf = "";

sub l00http_periodic_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data

    # get submitted name and print greeting
    if (defined ($form->{"interval"}) && ($form->{"interval"} >= 0)) {
        $interval = $form->{"interval"};
    }

    if (defined ($form->{"stop"})) {
        $interval = 0;
    }

    if (defined ($form->{"eval"})) {
        $eval = $form->{"eval"};
    }
        
    if (defined ($form->{"paste"})) {
        $eval = &l00httpd::l00getCB($ctrl);
    }


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} - <a href=\"/periodic.htm\">Refresh</a><br> \n";

    print $sock "<form action=\"/periodic.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Run interval (sec):</td>\n";
    print $sock "            <td><input type=\"text\" size=\"6\" name=\"interval\" value=\"$interval\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"paste\" value=\"Paste CB\"> eval:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"10\" name=\"eval\" value=\"$eval\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Submit\">\n";
    print $sock "            <input type=\"submit\" name=\"stop\" value=\"Stop\"></td>\n";
    print $sock "        <td>Note: when phone sleeps, interval may be much longer than specified</td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "Count: $percnt<br><a href=\"#end\">Jump to end</a>\n";
    print $sock "<pre>$perbuf</pre>\n";
    
    print $sock "Windows example: `msg /TIME:1 * The message`<br>\n";
    print $sock "WikiPland/Android example: TBD<br>\n";
    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_periodic_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $buf;

    if (($interval > 0) && 
        (($lastcalled == 0) || (time >= ($lastcalled + $interval)))) {
        $lastcalled = time;

        if (length($perbuf) > 10000) {
            $perbuf = substr($perbuf, 5000, 99999);
        }
        if ($perltime != 0) {
            $buf = sprintf ("$ctrl->{'now_string'},%d\n", time - $perltime);
            print $buf;
            $perbuf .= $buf;
        } else {
            $perbuf = sprintf ("$ctrl->{'now_string'},$perltime\n");
            print $perbuf;
        }
        print eval $eval;
        $perltime = time;
        $percnt++;
    }

    $interval;
}


\%config;
