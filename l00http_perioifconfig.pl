use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my ($lastcalled, $perbuf, $percnt, $perltime, %ifrxtx, %ifbase);
my %config = (proc => "l00http_perioifconfig_proc",
              desc => "l00http_perioifconfig_desc",
              perio => "l00http_perioifconfig_perio");
my ($path, $savedpath, %ifsrx, %ifstx);
my $interval = 0, $lastcalled = 0;
$percnt = 0;
$perltime = 0;
$path = '';
$savedpath = '';

sub l00http_perioifconfig_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "perioifconfig: Periodic logging of ifconfig";
}

$perbuf = "";

sub l00http_perioifconfig_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($tmp);
 
    # get submitted name and print greeting
    if (defined ($form->{"interval"}) && ($form->{"interval"} >= 0)) {
        $interval = $form->{"interval"};
        undef %ifrxtx;
    }
    if (defined ($form->{"stop"})) {
        $interval = 0;
    }
    if (defined ($form->{"clear"})) {
        $perbuf = '';
    }
    # save path
    if (defined ($form->{"path"}) && (length ($form->{"path"}) > 0)) {
        $path = $form->{"path"};
    }
    if (defined ($form->{"save"}) && (length ($path) > 5)) {
        if (open (OU, ">$path")) {
            print OU $perbuf;
            close (OU);
            $savedpath = $path;
        }
    }


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">QUICK</a> <a href=\"/perioifconfig.htm\">Refresh</a><p> \n";

    print $sock "<form action=\"/perioifconfig.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td>Run interval (sec):</td>\n";
    print $sock "        <td><input type=\"text\" size=\"6\" name=\"interval\" value=\"$interval\"></td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Submit\"> \n";
    print $sock "         <input type=\"submit\" name=\"stop\" value=\"Stop\"></td>\n";
    print $sock "        <td>Note: when phone sleeps, interval may be much longer than specified.\n";
    print $sock "        <input type=\"submit\" name=\"clear\" value=\"Clear\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "<form action=\"/perioifconfig.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"save\" value=\"Save\"></td>\n";
    $tmp = "$ctrl->{'workdir'}del/$ctrl->{'now_string'}_ifconfig.csv";
    $tmp =~ s/ /_/g;
    print $sock "        <td><input type=\"text\" size=\"16\" name=\"path\" value=\"$tmp\"></td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "</table>\n";
    print $sock "</form>\n";

    if (length ($savedpath) > 5) {
        print $sock "<a href=\"/ls.htm?path=$savedpath\">$savedpath</a><p>\n";
    }
    print $sock "Count: $percnt - <a href=\"#end\">Jump to end</a>\n";
    print $sock "<pre>$perbuf</pre>\n";
    print $sock "<p><a href=\"#top\">Jump to top</a><p>\n";
    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

my (%ifs, %sockstat, $key);

sub l00http_perioifconfig_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($tmp, $buf, $tempe, $thisif, $rxb, $txb, $if, $vals, @val, $total);

    if (($interval > 0) && 
        (($lastcalled == 0) || (time >= ($lastcalled + $interval)))) {
        $lastcalled = time;

        $thisif = '';
        if (open (IN, "</proc/net/dev")) {
#Inter-|   Receive                                                |  Transmit
# face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
#    lo: 51918626  105904    0    0    0     0          0         0 51918626  105904    0    0    0     0       0          0
#dummy0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet0:  983996     826    0    0    0     0          0         0    54607     563    0    0    0     0       0          0
#rmnet1:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet2:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet3:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet4:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet5:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet6:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet7:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#  usb0:  762160    2508    0    0    0     0          0         0   752385    1835    0    0    0     0       0          0
#  sit0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#ip6tnl0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#gannet0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#   tun:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#  eth0: 32919217  366817    0    0    0     0          0         0 49776541  544949    0    0    0     0       0          0
            $tempe = "$ctrl->{'now_string'},if,rx,tx";
            $total = 0;
            while (<IN>) {
                if (($if, $vals) = /^ *(\w+): *(.+)$/) {
                    if ($if eq 'lo') {
                        next;
                    }
                    @val = split (' ', $vals);
                    if (($val[0] > 0) && ($val[8] > 0)) {
                        # save starting values
                        if (!defined($ifbase{"rx_$if"})) {
                            $ifbase{"rx_$if"} = $val[0];
                        }
                        if (!defined($ifbase{"tx_$if"})) {
                            $ifbase{"tx_$if"} = $val[8];
                        }


                        if (!defined($ifrxtx{"rx_$if"})) {
                            $ifrxtx{"rx_$if"} = 0;
                        }
                        $tmp = ($val[0] - $ifbase{"rx_$if"}) - $ifrxtx{"rx_$if"};
                        $total += $tmp;
                        $tempe .= ",$if,$tmp";
                        $ifrxtx{"rx_$if"} = $val[0] - $ifbase{"rx_$if"};
                        # accumulate tx bytes
                        if (!defined($ifrxtx{"tx_$if"})) {
                            $ifrxtx{"tx_$if"} = 0;
                        }
                        $tmp = ($val[8] - $ifbase{"tx_$if"}) - $ifrxtx{"tx_$if"};
                        $total += $tmp;
                        $tempe .= ",$tmp";
                        $ifrxtx{"tx_$if"} = $val[8] - $ifbase{"tx_$if"};

                    }
                }
            }
            $tempe .= "\n";
            close (IN);
        }

        if ($perltime != 0) {
            # subsequently
            if ($total > 0) {
                $perbuf .= $tempe;
            }
        } else {
            # first time
            $perbuf = $tempe;
        }
        $perltime = time;
        $percnt++;
    }

    $interval;
}


\%config;
