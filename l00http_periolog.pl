use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my ($lastcalled, $perbuf, $percnt, $perltime);
my %config = (proc => "l00http_periolog_proc",
              desc => "l00http_periolog_desc",
              perio => "l00http_periolog_perio");
my $interval = 0, $lastcalled = 0;
$percnt = 0;
$perltime = 0;



sub l00http_periolog_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "periolog: Periodic logging task";
}

$perbuf = "";

sub l00http_periolog_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data

    # get submitted name and print greeting
    if (defined ($form->{"interval"}) && ($form->{"interval"} >= 0)) {
        $interval = $form->{"interval"};
    }

        


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} - <a href=\"/periolog.htm\">Refresh</a><br> \n";

    print $sock "<form action=\"/periolog.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Run interval (sec):</td>\n";
    print $sock "            <td><input type=\"text\" size=\"6\" name=\"interval\" value=\"$interval\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Submit\"></td>\n";
    print $sock "        <td>Note: when phone sleeps, interval may be much longer than specified</td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "Count: $percnt<br><a href=\"#end\">Jump to end</a>\n";
    print $sock "<pre>$perbuf</pre>\n";
    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_periolog_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($buf, $tempe);

    if (($interval > 0) && 
        (($lastcalled == 0) || (time >= ($lastcalled + $interval)))) {
        $lastcalled = time;

        if ($ctrl->{'os'} eq 'and') {
#$ctrl->{'droid'}->batteryStartMonitoring();
            $tempe = $ctrl->{'droid'}->batteryGetTemperature();
#        $tempe = $ctrl->{'droid'}->batteryGetStatus();
        }
&l00httpd::dumphash ('tempe', $tempe);
        $tempe = $tempe->{'result'};
        if ($perltime != 0) {
            # subsequently
            $buf = sprintf ("$ctrl->{'now_string'},%d,$tempe C\n", time - $perltime);
            print $buf;
            $perbuf .= $buf;
        } else {
            # first time
            $perbuf = sprintf ("$ctrl->{'now_string'},$perltime,$tempe C\n");
            print $perbuf;
        }
        $perltime = time;
        $percnt++;
    }

    $interval;
}


\%config;
