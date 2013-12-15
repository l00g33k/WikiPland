
use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my ($lastcalled, $netiflog, $netifcnt, $netifnoln, $perltime, %ifrxtx, %ifbase, $totalifcon);
my %config = (proc => "l00http_perionetifcon_proc",
              desc => "l00http_perionetifcon_desc",
              perio => "l00http_perionetifcon_perio");
my (%netstatout, %allsocksever, $savedpath);
my (%ifsrx, %ifstx);
my $interval = 0, $lastcalled = 0;
$netifcnt = 0;
$perltime = 0;
$savedpath = '';
$totalifcon = 0;
$netiflog = '';
$netifnoln = 0;

sub l00http_perionetifcon_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "perionetifcon: Periodic logging of netstat";
}


sub l00http_perionetifcon_proc {
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
        $netifcnt = 0;
        $netiflog = '';
        $totalifcon = 0;
        $netifnoln = 0;
        $savedpath = '';
        undef %allsocksever;
    }
    # save path
    if (defined ($form->{"save"}) && defined ($form->{'path'}) && (length ($form->{'path'}) > 0)) {
        if (open (OU, ">$form->{'path'}")) {
            print OU $netiflog;
            close (OU);
            $savedpath = $form->{'path'};
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
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">QUICK</a> <a href=\"/perionetifcon.htm\">Refresh</a><p> \n";

    $tmp = $totalifcon;
    $tmp =~ s/(\d)(\d\d\d)$/$1,$2/;
    $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
    $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
    print $sock "Total ifconfig $tmp bytes. Lines: $netifnoln : <a href=\"#end\">Jump to end</a>\n";

    print $sock "<form action=\"/perionetifcon.htm\" method=\"get\">\n";
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

    print $sock "<form action=\"/perionetifcon.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"save\" value=\"Save new\"></td>\n";
    $tmp = "$ctrl->{'workdir'}del/$ctrl->{'now_string'}_netifcon.csv";
    $tmp =~ s/ /_/g;
    print $sock "        <td><input type=\"text\" size=\"16\" name=\"path\" value=\"$tmp\"></td>\n";
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
    $tmp = $totalifcon;
    $tmp =~ s/(\d)(\d\d\d)$/$1,$2/;
    $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
    $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
    print $sock "<p>Total ifconfig $tmp bytes. Lines: $netifnoln\n";
    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_perionetifcon_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($buf, $tempe, $proto, $RxQ, $TxQ, $local, $remote, $sta, $key, %seennow);
    my ($tmp, $thisif, $rxb, $txb, $if, $vals, @val, $total);

    if (($interval > 0) && 
        (($lastcalled == 0) || (time >= ($lastcalled + $interval)))) {
        $lastcalled = time;

        # netstat

        $tempe = '';
        undef %netstatout;
        undef %seennow;
        if ($ctrl->{'os'} eq 'and') {
#netstat
#Proto Recv-Q Send-Q Local Address          Foreign Address        State
# tcp       0      0 127.0.0.1:55555        0.0.0.0:*              LISTEN
# tcp       0      0 0.0.0.0:20337          0.0.0.0:*              LISTEN
# tcp       0      0 10.10.10.18:46869      64.4.61.208:443        ESTABLISHED
# tcp       0      0 127.0.0.1:53033        127.0.0.1:53171        ESTABLISHED
#tcp6       0      0 :::20339               :::*                   LISTEN
#tcp6       0      0 ::ffff:127.0.0.1:8182  :::*                   LISTEN
#tcp6       0      0 ::ffff:127.0.0.1:53171 ::ffff:127.0.0.1:53033 ESTABLISHED
open(LG,">>/sdcard/l00httpd/del/0.log");
print LG "--------\n";
            foreach $_ (split ("\n", `netstat`)) {
                if (($proto, $RxQ, $TxQ, $local, $remote, $sta) = split (' ', $_)) {
                    #LISTEN
                    #SYN_SENT
                    #ESTABLISHED
                    #TIME_WAIT
                    #FIN_WAIT1
                    #CLOSE_WAIT
                    if ((!($local =~ /127\.0\.0\.1/) || 
                        !($remote =~ /127\.0\.0\.1/)) && 
                        (!($remote =~ /0\.0\.0\.0/)) &&
                        (!($sta =~ /LISTEN/)) &&
                        (!($sta =~ /CLOSE_WAIT/))) {
print LG "$_\n";
                        $local =~ s/:(\d+)$/,$1/;
                        $remote =~ s/:(\d+)$/,$1/;
                        $seennow{"$local->$remote"} = 1;    # remember socket pair reported in this loop

#                        if (($sta =~ /SYN_SENT/) ||
#                            ($sta =~ /ESTABLISHED/) ||
#                            ($sta =~ /TIME_WAIT/)) {
                            # a socket is listed because it was connected, is connected, or just disconnected
                            # for us just consider it being connected
                            # socket is currently connected
                            if (defined ($allsocksever{"$local->$remote"})) {
                                # we have seen it before
                                if ($allsocksever{"$local->$remote"} eq '') {
                                    # it was disconnected, and now connected
                                    $allsocksever{"$local->$remote"} = $_;    # connected state
                                    # record as just connected
                                    $buf = "$ctrl->{'now_string'},net,$proto,local,remote,$local,$remote,conn";
                                    $netstatout{$buf} = 1;
                                } else {
                                    # it was connected, and still connected
                                    # nothing changed, do nothing
                                }
                            } else {
                                # never seen connected
                                $allsocksever{"$local->$remote"} = $_;    # connected state
                                # record as just connected
                                $buf = "$ctrl->{'now_string'},net,$proto,local,remote,$local,$remote,conn";
                                $netstatout{$buf} = 1;
                            }
#                        } else {
#                            # socket is currently not about to be connected
#                            # socket is currently not connected
#                            # socket is currently not just disconnected
#                            if (defined ($allsocksever{"$local->$remote"})) {
#                                # we have seen it before
#                                if ($allsocksever{"$local->$remote"} eq '') {
#                                    # it was disconnected, and still disconnected
#                                    # not interested, do nothing
#                                } else {
#                                    # it was connected, and now not disconnected
#                                    $allsocksever{"$local->$remote"} = '';    # disconnected state
#                                    # record as just disconnected
#                                    $buf = "$ctrl->{'now_string'},net,$proto,local,remote,$local,$remote,disc";
#                                    $netstatout{$buf} = 0;
#                                }
#                            } else {
#                                # not connected, and never seen connected
#                                # not interested, do nothing
#                            }
#                        }
                    }
                } else {
                    $tempe .= "LOCAL: $_\n";
                    $netifnoln++;
                }
            }
close(LG);
            foreach $key (keys %allsocksever) {
                # %allsocksever remembers all socket pairs ever seen. "$_" denotes connected; '' otherwise
                # key of the form {"$local->$remote"}
                if (!defined($seennow{$key})) {
                    # socket pair $key not seen now, connection no longer exist
                    if (($proto, $RxQ, $TxQ, $local, $remote, $sta) = split (' ', $allsocksever{"$key"})) {
                        $buf = "$ctrl->{'now_string'},net,$proto,local,remote,$local,$remote,disc";
                        $netstatout{$buf} = 0;
                    }
                    $allsocksever{"$key"} = '';    # disconnected state
                }
            }

            foreach $key (sort keys %netstatout) {
                $tempe .= "$key\n";
                $netifnoln++;
            }


            # ifconfig

            $thisif = '';
            if (open (IN, "</proc/net/dev")) {
#Inter-|   Receive                                                |  Transmit
#    if        0       1    2    3    4     5          6         7        8       9   10   11   12    13      14         15
# face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
#    lo:51918626  105904    0    0    0     0          0         0 51918626  105904    0    0    0     0       0          0
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
#ip6tnl0:      0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#gannet0:      0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#   tun:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#  eth0:32919217  366817    0    0    0     0          0         0 49776541  544949    0    0    0     0       0          0
                $tempe .= "$ctrl->{'now_string'},if,rx,tx";
                $total = 0;
                while (<IN>) {
                    if (($if, $vals) = /^ *(\w+): *(.+)$/) {
                        if ($if eq 'lo') {
                            next;
                        }
                        @val = split (' ', $vals);
                        if (($val[0] > 0) && ($val[8] > 0)) {
                            # non-zero rx and tx count

                            # save starting values
                            if (!defined($ifbase{"rx_$if"})) {
                                $ifbase{"rx_$if"} = $val[0];
                            }
                            if (!defined($ifbase{"tx_$if"})) {
                                $ifbase{"tx_$if"} = $val[8];
                            }

                            # accumulate rx bytes
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
                $totalifcon += $total;
                $tempe .= "\n";
                $netifnoln++;
                close (IN);
            }
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
