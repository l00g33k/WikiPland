use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my ($lastcalled, $netiflog, $netifcnt, $netifnoln, $perltime, %ifrxtx, %ifbase, $totalifcon);
my %config = (proc => "l00http_periobattery_proc",
              desc => "l00http_periobattery_desc",
              perio => "l00http_periobattery_perio");
my (%netstatout, %allsocksever, $savedpath);
my (%ifsrx, %ifstx, $isp, %alwayson, %seennow);
my $interval = 0, $lastcalled = 0;
$netifcnt = 0;
$perltime = 0;
$savedpath = '';
$totalifcon = 0;
$netiflog = '';
$netifnoln = 0;
$isp = 0;

sub l00http_periobattery_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    " C: periobattery: Periodic logging of battery by dmesg";
}


sub l00http_periobattery_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($tmp);
 
    # get submitted name and print greeting
    if (defined ($form->{"interval"}) && ($form->{"interval"} >= 0)) {
        $interval = $form->{"interval"};
    }
    if (defined ($form->{"ispadj"})) {
        $isp = $form->{"ispadj"};
    }
    if (defined ($form->{"stop"})) {
        $interval = 0;
    }
    if (defined ($form->{"clear"})) {
        $netifcnt = 0;
        $netiflog = '';
        $totalifcon = 0;
        $netifnoln = 0;
        $savedpath = '';
        undef %allsocksever;
        undef %alwayson;
    }
    # save path
    if (defined ($form->{"save"}) && defined ($form->{'savepath'}) && (length ($form->{'savepath'}) > 0)) {
        if (open (OU, ">$form->{'savepath'}")) {
            foreach $_ (keys %alwayson) {
                if ($alwayson{$_} ne '') {
                    print OU "$alwayson{$_}\n";
                }
            }
            print OU $netiflog;
            close (OU);
            $savedpath = $form->{'savepath'};
        }
    }
    if (defined ($form->{"overwrite"}) && defined ($form->{'owpath'}) && (length ($form->{'owpath'}) > 0)) {
        if (open (OU, ">$form->{'owpath'}")) {
            print OU $netiflog;
            close (OU);
            $savedpath = $form->{'owpath'};
        }
    }


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">QUICK</a> <a href=\"/periobattery.htm\">Refresh</a><p> \n";

    print $sock "Battery. <a href=\"#end\">end</a>\n";

    print $sock "<form action=\"/periobattery.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td>Run interval (sec):</td>\n";
    print $sock "        <td><input type=\"text\" size=\"6\" name=\"interval\" value=\"$interval\"></td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Submit\"> \n";
    print $sock "         <input type=\"submit\" name=\"stop\" value=\"Stop\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"clear\" value=\"Clear\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "<form action=\"/periobattery.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"save\" value=\"Save new\"></td>\n";
    $tmp = "$ctrl->{'workdir'}del/$ctrl->{'now_string'}_battery.csv";
    $tmp =~ s/ /_/g;
    print $sock "        <td><input type=\"text\" size=\"16\" name=\"savepath\" value=\"$tmp\"></td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"overwrite\" value=\"Overwrite\"></td>\n";
    print $sock "        <td><input type=\"text\" size=\"16\" name=\"owpath\" value=\"$savedpath\"></td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "</table>\n";
    print $sock "</form>\n";

    if (length ($savedpath) > 5) {
        print $sock "Launcher to last saved: <a href=\"/launcher.htm?path=$savedpath\">$savedpath</a><p>\n";
    }

    print $sock "<pre>\n";
    $tmp = 0;
    foreach $_ (split("\n", $netiflog)) {
        $tmp++;
        if ($tmp < 100) {
            printf $sock ("%3d: $_\n", $tmp);
        } elsif ($tmp == 100) {
            printf $sock ("%3d: $_\n", $tmp);
            print $sock "\nskipping ".($netifnoln - 100 * 2)." lines\n\n";
        } elsif ($tmp > ($netifnoln - 100)) {
            printf $sock ("%3d: $_\n", $tmp);
        }
    }
    print $sock "</pre>\n";
    print $sock "<p><a href=\"#top\">Jump to top</a><p>\n";
    print $sock "<p>Lines: $netifnoln\n";
    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_periobattery_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($buf, $tempe, $proto, $RxQ, $TxQ, $local, $remote, $sta, $key);
    my ($tmp, $thisif, $rxb, $txb, $if, $vals, @val, $total, $ifoutput);

    if (($interval > 0) && 
        (($lastcalled == 0) || (time >= ($lastcalled + $interval)))) {
        $lastcalled = time;

        $tempe = '';
        if ($ctrl->{'os'} eq 'and') {
            $netifnoln++;
            $tempe = "$ctrl->{'now_string'}\n";
        }
        if ($perltime != 0) {
            # subsequently
            $netiflog .= $tempe;
        } else {
            # first time
            $netiflog = $tempe;
        }
        $perltime = time;
        $netifcnt++;
    }

    $interval;
}


\%config;
