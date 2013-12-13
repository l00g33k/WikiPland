use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my ($lastcalled, $perbuf, $percnt, $perltime);
my %config = (proc => "l00http_perionetstat_proc",
              desc => "l00http_perionetstat_desc",
              perio => "l00http_perionetstat_perio");
my (%socklog, %sockstat, $path, $savedpath);
my $interval = 0, $lastcalled = 0;
$percnt = 0;
$perltime = 0;
$path = '';
$savedpath = '';

sub l00http_perionetstat_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "perionetstat: Periodic logging of netstat";
}

$perbuf = '';

sub l00http_perionetstat_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($tmp);
 
    # get submitted name and print greeting
    if (defined ($form->{"interval"}) && ($form->{"interval"} >= 0)) {
        $interval = $form->{"interval"};
    }
    if (defined ($form->{"stop"})) {
        $interval = 0;
    }
    if (defined ($form->{"clear"})) {
        $perbuf = '';
        undef %sockstat;
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
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">QUICK</a> <a href=\"/perionetstat.htm\">Refresh</a><p> \n";

    print $sock "<form action=\"/perionetstat.htm\" method=\"get\">\n";
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

    print $sock "<form action=\"/perionetstat.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"save\" value=\"Save\"></td>\n";
    $tmp = "$ctrl->{'workdir'}del/$ctrl->{'now_string'}_netstat.csv";
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

sub l00http_perionetstat_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($buf, $tempe, $proto, $RxQ, $TxQ, $local, $remote, $sta, $key, %seennow);

    if (($interval > 0) && 
        (($lastcalled == 0) || (time >= ($lastcalled + $interval)))) {
        $lastcalled = time;

        $tempe = '';
        undef %socklog;
        undef %seennow;
        if ($ctrl->{'os'} eq 'and') {
#            $tempe = "$ctrl->{'now_string'} is the time now\n";
#           foreach $_ (split ("\n", `busybox netstat -an`)) {
#netstat
#Proto Recv-Q Send-Q Local Address          Foreign Address        State
# tcp       0      0 127.0.0.1:55555        0.0.0.0:*              LISTEN
# tcp       0      0 0.0.0.0:20337          0.0.0.0:*              LISTEN
# tcp       0      0 10.10.10.18:46869      64.4.61.208:443        ESTABLISHED
# tcp       0      0 127.0.0.1:53033        127.0.0.1:53171        ESTABLISHED
#tcp6       0      0 :::20339               :::*                   LISTEN
#tcp6       0      0 ::ffff:127.0.0.1:8182  :::*                   LISTEN
#tcp6       0      0 ::ffff:127.0.0.1:53171 ::ffff:127.0.0.1:53033 ESTABLISHED
            foreach $_ (split ("\n", `netstat`)) {
#$tempe .= "$_\n";
#                if (($proto, $RxQ, $TxQ, $local, $remote, $sta) = /^([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+)/) {
                if (($proto, $RxQ, $TxQ, $local, $remote, $sta) = split (' ', $_)) {
                    $local =~ s/:(\d+)$/,$1/;
                    $remote =~ s/:(\d+)$/,$1/;
                    $seennow{"$local->$remote"} = 1;
                    #LISTEN
                    #TIME_WAIT
                    #ESTABLISHED
                    #CLOSE_WAIT
                    if (!($local =~ /127\.0\.0\.1/) || !($remote =~ /127\.0\.0\.1/)) {
                        if ($sta =~ /ESTABLISHED/) {
                            # socket is currently connected
                            if (defined ($sockstat{"$local->$remote"})) {
                                # we have seen it before
                                if ($sockstat{"$local->$remote"} eq '') {
                                    # it was disconnected, and now connected
                                    $sockstat{"$local->$remote"} = $_;    # connected state
                                    # record as just connected
                                    $buf = "$ctrl->{'now_string'},net,$proto,local,remote,$local,$remote,conn";
                                    $socklog{$buf} = 1;
                                } else {
                                    # it was connected, and still connected
                                    # nothing changed, do nothing
                                }
                            } else {
                                # never seen connected
                                $sockstat{"$local->$remote"} = $_;    # connected state
                                # record as just connected
                                $buf = "$ctrl->{'now_string'},net,$proto,local,remote,$local,$remote,conn";
                                $socklog{$buf} = 1;
                            }
                        } else {
                            # socket is currently not connected
                            if (defined ($sockstat{"$local->$remote"})) {
                                # we have seen it before
                                if ($sockstat{"$local->$remote"} eq '') {
                                    # it was disconnected, and still disconnected
                                    # not interested, do nothing
                                } else {
                                    # it was connected, and still not disconnected
                                    $sockstat{"$local->$remote"} = '';    # disconnected state
                                    # record as just disconnected
                                    $buf = "$ctrl->{'now_string'},net,$proto,local,remote,$local,$remote,disc";
                                    $socklog{$buf} = 0;
                                }
                            } else {
                                # not connected, and never seen connected
                                # not interested, do nothing
                            }
                        }
                    }
                } else {
$tempe .= "LOCAL: $_\n";
                }
            }
            foreach $key (keys %sockstat) {
                if (!defined($seennow{$key})) {
                    # connection no longer exist
                    if (($proto, $RxQ, $TxQ, $local, $remote, $sta) = $sockstat{"$key"} =~ /^([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+) +([^ ]+)/) {
                        $buf = "$ctrl->{'now_string'},net,$proto,local,remote,$local,$remote,disc";
                        $socklog{$buf} = 0;
                    }
                    $sockstat{"$key"} = '';    # disconnected state
                }
            }

            foreach $key (sort keys %socklog) {
                $tempe .= "$key\n";
            }
        }
#        if (length ($path) > 5) {
#            if (open (OU, ">$path")) {
#                print OU $tempe;
#                close (OU);
#            }
#        }
        if ($perltime != 0) {
            # subsequently
            $perbuf .= $tempe;
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
