#!/usr/bin/perl
#perl portfwrd.pl fwrd listen_port=60123 to=30 srvr=localhost only=127.0.0.1 server_port=5900
#perl portfwrd.pl fwrd listen_port=60123 to=30 srvr=localhost ctrl_port=60124 only=127.0.0.1 server_port=5900

#http://localhost:60124


use IO::Socket;
use IO::Select;
#use Net::hostent;              # for OO version of gethostbyaddr

$server_ip = "localhost";
$server_port = 20337;
$listen_port = 60123;
$ctrl_port = 60124;
$all = '';
$timeout_mins = 30; # 30 min. timeout
$statusonly = 0;
$selectcnt = 0;

$debug = 0;
$noisy = 0;
$ok2fwrd = 0;
$cliip = 0;

while ($arg = shift) {
    if ($arg =~ /help/) {
        print "Useage:\n";
        print "perl $0 [debug] [noisy] [fwrd] [srvr=# server_port=#] [listen_port=#;60123] [only=#] [to=#min.] [pw=#]\n";
        print "If [srvr=#] is missing, report client address\n";
        exit;
    }
    if ($arg =~ /debug/) {
        $debug++;
        print "ARGS debug\n";
    }
    if ($arg =~ /cliip/) {
        $cliip = 1;
        print "ARSS cliip\n";
    }
    if ($arg =~ /fwrd/) {
        $ok2fwrd = 2;
        print "ARGS fwrd\n";
    }
    if ($arg =~ /noisy/) {
        $noisy = 1;
        print "ARGS noisy\n";
    }
    if ($arg =~ /srvr=(.+)/) {
        $server_ip = $1;
        print "ARGS srvr=$server_ip\n";
    }
    if ($arg =~ /ctrl_port=(.+)/) {
        $ctrl_port = $1;
        print "ARGS ctrl_port=$ctrl_port\n";
    }
    if ($arg =~ /to=(.+)/) {
        $timeout_mins = $1;
        print "ARGS to=$timeout_mins\n";
    }
    if ($arg =~ /only=(.+)/) {
        $only = $1;
        print "ARGS only=$only\n";
    }
    if ($arg =~ /server_port=(.+)/) {
        $server_port = $1;
        print "ARGS server_port=$server_port\n";
    }
    if ($arg =~ /listen_port=(.+)/) {
        $listen_port = $1;
        print "ARGS listen_port=$listen_port\n";
    }
}



$server_socket = 0;
$client_socket = 0;

if ($ok2fwrd) {
    print "PID $$: Forwarding to port $server_port on $server_ip\n";
} else {
    print "PID $$: Reporting client address only on port $listen_port\n";
}

$lstn_sock = IO::Socket::INET->new (
    LocalPort => $listen_port, 
    Listen => 5, 
    Reuse => 1
);
die "Can't create socket for listening: $!" unless $lstn_sock;

$ctrl_lstn_sock = IO::Socket::INET->new (
    LocalPort => $ctrl_port,
    Listen => 5, 
    Reuse => 1
);
die "Can't create socket for listening: $!" unless $ctrl_lstn_sock;

my $readable = IO::Select->new;     # Create a new IO::Select object
$readable->add($lstn_sock);          # Add the lstnsock to it
$readable->add($ctrl_lstn_sock);          # Add the lstnsock to it


sub close_client_sock {
    if ($client_socket != 0) {
        $now_string = localtime;
        print "CLI_CLOSE $now_string: client $client_ip disconnected\n", if ($noisy);
        # close client socket
        $readable->remove($client_socket);
        $client_socket->close;
        $client_socket = 0;
    }
}

sub close_server_sock {
    if ($server_socket != 0) {
        $now_string = localtime;
        print "SVR_CLOSE $now_string: server $server_socketname disconnected\n", if ($noisy);
        # close server socket
        $readable->remove($server_socket);
        $server_socket->close;
        $server_socket = 0;
    }
}

sub debug_info {
    print "CONN_DBG:lstnsock      $lstn_sock\n";
    print "CONN_DBG:client_socket $client_socket\n";
    print "CONN_DBG:server_socket $server_socket\n";
}

$tend = time + $timeout_mins * 60;
$tstart = time + 0;
$tickdelta = 1;
$tick = time + $tickdelta;
$loop = 1;

while($loop) {
    if (time >= $tend) {
        print STDERR "\n\n=== $timeout_mins minutes timeout occured, stop\n\n";
        last;
    }
    if (time >= $tick) {
        $tick = time + $tickdelta;
        $now_string = localtime;
        print STDERR "\r$now_string: PID $$ up ", time - $tstart, " S $selectcnt connections \r";
    }

    # Get a list of sockets that are ready to talk to us.
    my ($ready) = IO::Select->select($readable, undef, undef, $tickdelta);
    $keepalivesleep = 0;
    foreach my $curr_socket (@$ready) {
        # Is it a new connection?
        &debug_info, if ($debug);
        $selectcnt++;
        if($curr_socket == $ctrl_lstn_sock) {
            print "============================ SELECT Control READY $selectcnt =========================\n$now_string\n", if ($noisy);
#---------------------- Form Control Page handler  -----------------------
            $now_string = localtime;
            $ctrl_sock = $ctrl_lstn_sock->accept;
            $addr = $ctrl_sock->peeraddr ();
            if (defined $addr) {
                $client_ip = inet_ntoa ($addr);
            } else {
                $client_ip = "unknown";
            }
            $cliconnected{$client_ip} += 1;
            if ($cliip) {
                print "\nClient connected: $client_ip\n";
            }
            $commands = "";
            $ctrlportcnt++;
            print "---------------------------- CTRL HTML $ctrlportcnt begin ----------------------------\n", if ($noisy);
            while (<$ctrl_sock>) {
                if (/^ *\n*\r*$/) {
                    last;
                }
                print "CTRL $_", if ($noisy);
                if (/GET \/portfwrd_ctrlport\.pl\?([^ ]+) HTTP/) {
                    $commands = $1;
                }
            }
            print "---------------------------- CTRL HTML $ctrlportcnt   end----------------------------\n", if ($noisy);
            print "CTRL parameters: >$commands<\n", if ($noisy);
            print "CTRL $now_string: $client_ip connected to control port\n", if ($noisy);

            # ------------------- parameters input processing
            @cmd_param_pairs = split ('&', $commands);
            undef %params;
            foreach $cmd_param_pair (@cmd_param_pairs) {
                ($name, $param) = split ('=', $cmd_param_pair);
                print "CTRL_CMD $name=$param\n", if ($noisy);
                $params{$name} = $param;
            }

			if (defined ($params{'quit'})) {
                $loop = 0;
                print "Quit requested\n";
            }
			if (defined ($params{'setconfig'})) {
				if ($params{'statusonly'} eq "on") {
					$statusonly = 1;
				} else {
					$statusonly = 0;
				}
				if ($statusonly == 0) {
					if ((defined $params{'server_ip'}) && ($server_ip ne $params{'server_ip'})) {
						$server_ip = $params{'server_ip'};
						&close_server_sock;
						&close_client_sock;
					}
					if ((defined $params{'server_port'}) && ($server_port ne $params{'server_port'})) {
						$server_port = $params{'server_port'};
						&close_server_sock;
						&close_client_sock;
					}
					if ($params{'all'} eq 'on') {
						$all = 'checked';
						&close_server_sock;
						&close_client_sock;
					} else {
						$all = '';
						&close_server_sock;
						&close_client_sock;
					}
					if ((defined $params{'timeout_mins'}) && ($timeout_mins ne $params{'timeout_mins'})) {
						$timeout_mins = $params{'timeout_mins'};
						$tend = time + $timeout_mins * 60;
					}
                    foreach $ip (sort keys %client_ip_code) {
print "IP $ip. $params{$ip}\n";
                        if ($params{$ip} eq "on") {
                            $client_ip_checked{$ip} = 'checked';
                        } else {
                            $client_ip_checked{$ip} = '';
                        }
						&close_server_sock;
						&close_client_sock;
                    }
					if ($params{'forwardmode'} eq "okfwrd") {
						$ok2fwrd = 2;
					} else {
						$ok2fwrd = 0;
						&close_server_sock;
						&close_client_sock;
					}
					if ($params{'debug'} eq "on") {
						$debug = 1;
					} else {
						$debug = 0;
					}
					if ($params{'noisy'} eq "on") {
						$noisy = 1;
					} else {
						$noisy = 0;
					}
				}
			}	













#            print $ctrl_sock "HTTP/1.0 200 OK\r\n\r\n<html><body>\n";
            $htmlout = "<html><body>\n";

            $htmlout .= "$now_string: you have connected to the control port from $client_ip\n";


            $htmlout .= "<form action=\"/portfwrd_ctrlport.pl\" method=\"PUT\">\n";
            $htmlout .= "    <table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

            $htmlout .= "        <tr>\n";
            $htmlout .= "            <td>Parameters</td>\n";
            $htmlout .= "            <td>Descriptions</td>\n";
            $htmlout .= "        </tr>\n";




            if ($ok2fwrd == 2) {
                $ok2fwrdRadio1 = "";
                $ok2fwrdRadio2 = "";
                $ok2fwrdRadio3 = "checked";
            } elsif ($ok2fwrd == 1) {
                $ok2fwrdRadio1 = "";
                $ok2fwrdRadio2 = "checked";
                $ok2fwrdRadio3 = "";
            } else {
                $ok2fwrdRadio1 = "checked";
                $ok2fwrdRadio2 = "";
                $ok2fwrdRadio3 = "";
            }
            $htmlout .= "        <tr>\n";
            $htmlout .= "            <td>";
            $htmlout .= "<input type=\"radio\" $ok2fwrdRadio1 name=\"forwardmode\" value=\"nofwrd\">No forward<br>\n";
            $htmlout .= "<input type=\"radio\" $ok2fwrdRadio3 name=\"forwardmode\" value=\"okfwrd\">Forwarding<br>\n";
            $htmlout .= "</td>\n";
            $htmlout .= "            <td>desc</td>\n";
            $htmlout .= "        </tr>\n";

            $htmlout .= "        <tr>\n";
            $htmlout .= "            <td><input type=\"checkbox\" name=\"all\" $all>all</td>\n";
            $htmlout .= "            <td>check to allow</td>\n";
            $htmlout .= "        </tr>\n";

            foreach $ip (sort keys %client_ip_code) {
                $htmlout .= "        <tr>\n";
                $htmlout .= "            <td><input type=\"checkbox\" name=\"$ip\" $client_ip_checked{$ip}>$ip</td>\n";
                $htmlout .= "            <td>Code: $client_ip_code{$ip}.  Check to allow</td>\n";
                $htmlout .= "        </tr>\n";
            }

            if ($statusonly) {
                $buf = "checked";
            } else {
                $buf = "";
            }
            $htmlout .= "        <tr>\n";
            $htmlout .= "            <td><input type=\"submit\" name=\"setconfig\" value=\"Set Config\">\n";
            $htmlout .= "                <input type=\"submit\" name=\"quit\" value=\"Quit\"></td>\n";
            $htmlout .= "            <td><input type=\"checkbox\" $buf name=\"statusonly\">Update <input type=\"submit\" name=\"statusonly\" value=\"Status Only\"></td>\n";
            $htmlout .= "        </tr>\n";

            $htmlout .= "        <tr>\n";
            $htmlout .= "            <td><input type=\"text\" size=\"20\" name=\"server_ip\" value=\"$server_ip\"></td>\n";
            $htmlout .= "            <td>server_ip</td>\n";
            $htmlout .= "        </tr>\n";

            $htmlout .= "        <tr>\n";
            $htmlout .= "            <td><input type=\"text\" size=\"6\" name=\"server_port\" value=\"$server_port\"></td>\n";
            $htmlout .= "            <td>server_port</td>\n";
            $htmlout .= "        </tr>\n";

            $timeout_left = int (($tend - time) / 60);
            $htmlout .= "        <tr>\n";
            $htmlout .= "            <td><input type=\"text\" size=\"6\" name=\"timeout_mins\" value=\"$timeout_mins\"> ($timeout_left min. left)</td>\n";
            $htmlout .= "            <td>timeout_mins (new value to set)</td>\n";
            $htmlout .= "        </tr>\n";


            if ($debug) {
                $buf = "checked";
            } else {
                $buf = "";
            }
            $htmlout .= "        <tr>\n";
            $htmlout .= "            <td><input type=\"checkbox\" $buf name=\"debug\">debug</td>\n";
            $htmlout .= "            <td>debug</td>\n";
            $htmlout .= "        </tr>\n";

            if ($noisy) {
                $buf = "checked";
            } else {
                $buf = "";
            }
            $htmlout .= "        <tr>\n";
            $htmlout .= "            <td><input type=\"checkbox\" $buf name=\"noisy\">noisy</td>\n";
            $htmlout .= "            <td>noisy</td>\n";
            $htmlout .= "        </tr>\n";

            $out_buf = "";
            foreach $ip (sort keys %client_conn_cnts) {
                if ($out_buf eq "") {
                    $out_buf = "$client_conn_time{$ip} #$client_conn_cnts{$ip} : [$ip]";
                } else {
                    $out_buf .= "<br>$client_conn_time{$ip} #$client_conn_cnts{$ip} : [$ip]";
                }
            }
            if ($out_buf eq "") {
                $out_buf = "none";
            }
            $htmlout .= "        <tr>\n";
            $htmlout .= "            <td>$out_buf</td>\n";
            $htmlout .= "            <td>clients</td>\n";
            $htmlout .= "        </tr>\n";


            $htmlout .= "        <tr>\n";
            $htmlout .= "            <td>$bytesfromsvr bytes</td>\n";
            $htmlout .= "            <td>bytesfromsvr</td>\n";
            $htmlout .= "        </tr>\n";

            $htmlout .= "        <tr>\n";
            $htmlout .= "            <td>$bytesfromcli bytes</td>\n";
            $htmlout .= "            <td>bytesfromcli</td>\n";
            $htmlout .= "        </tr>\n";

            $htmlout .= "        <tr>\n";
            $htmlout .= "            <td>$listen_port</td>\n";
            $htmlout .= "            <td>listen_port</td>\n";
            $htmlout .= "        </tr>\n";

            $htmlout .= "        <tr>\n";
            $htmlout .= "            <td>$ctrl_port</td>\n";
            $htmlout .= "            <td>ctrl_port</td>\n";
            $htmlout .= "        </tr>\n";














            $htmlout .= "        <tr>\n";
            $htmlout .= "            <td>$client_socket</td>\n";
            $htmlout .= "            <td>client_socket</td>\n";
            $htmlout .= "        </tr>\n";

            $htmlout .= "        <tr>\n";
            $htmlout .= "            <td>$server_socket</td>\n";
            $htmlout .= "            <td>server_socket</td>\n";
            $htmlout .= "        </tr>\n";

            $htmlout .= "        <tr>\n";
            $htmlout .= "            <td>param</td>\n";
            $htmlout .= "            <td>desc</td>\n";
            $htmlout .= "        </tr>\n";



            $htmlout .= "    </table>\n";
            $htmlout .= "</form>\n";

            $htmlout .= "Client IP: connect count<br>\n";
            foreach $client_ip (sort keys %cliconnected) {
                $htmlout .= "$client_ip: $cliconnected{$client_ip}<br>\n";
            }


            $htmlout .= "</body></html>";

#            print $ctrl_sock "HTTP/1.0 200 OK\r\n\r\n$htmlout\n";
            $size = length ($htmlout);
            $httphdr = "Content-Type: text/html\r\n";
            $httphdr .= "Content-Length: $size\r\n";
            $httphdr .= "Connection: close\r\n";
            print $ctrl_sock "HTTP/1.1 200 OK\r\n$httphdr\r\n$htmlout";

            $ctrl_sock->close;
            $ctrl_sock = 0;
        } elsif ($curr_socket == $server_socket) {
            print "============================ SELECT Server  READY $selectcnt =========================\n$now_string\n", if ($noisy);
#---------------------- Server Data Relay -----------------------
            # heard from server
            $cnt = sysread ($server_socket, $_, 10240);
            if (defined $cnt) {
                if ($cnt > 0) {
                    $bytesfromsvr += $cnt;
                    if ($debug) {
                        print "RELAY_SVR: $cnt bytes: $_\n";
                    } else {
                        print "RELAY_SVR: $cnt bytes\n", if ($noisy);
                    }
                    # send to client
                    if ($client_socket != 0) {
                        if ($ok2fwrd == 1) {
                            print "svr: ".length ($_)." btyes: \n";
                        }
                        print $client_socket "$_";
                    }
                } else {
                    print "DBG line ".__LINE__." server socket has 0 bytes\n", if ($debug);
                    &close_server_sock;
                    &close_client_sock;
                }
            } else {
                print "DBG line ".__LINE__." server socket failed\n", if ($debug);
                &close_server_sock;
                &close_client_sock;
            }
        } elsif ($curr_socket == $client_socket) {
            print "============================ SELECT Client  READY $selectcnt =========================\n$now_string\n", if ($noisy);
#---------------------- Client Data Relay -----------------------
            # heard from client
            $cnt = sysread ($client_socket, $_, 10240);
            if (defined $cnt) {
                if ($cnt > 0) {
                    $bytesfromcli += $cnt;
                    if ($debug) {
                        print "RELAY_CLI: $cnt bytes: $_\n";
                    } else {
                        print "RELAY_CLI: $cnt bytes\n", if ($noisy);
                    }
                    # send to server
                    if ($server_socket != 0) {
                        if ($ok2fwrd == 1) {
                            print "cli: ".length ($_)." btyes: \n";
                        }
                        print $server_socket "$_";
                    }
                } else {
                    print "DBG line ".__LINE__." client socket has 0 bytes\n", if ($debug);
                    &close_server_sock;
                    &close_client_sock;
                }
            } else {
                print "DBG line ".__LINE__." client socket failed\n", if ($debug);
                &close_server_sock;
                &close_client_sock;
            }
        } elsif ($curr_socket == $lstn_sock) {
            print "============================ SELECT Listen  READY $selectcnt =========================\n$now_string\n", if ($noisy);
#---------------------- Client/Server Startup Listening Socket  -----------------------
            # this is a new connection
            if ($client_socket == 0) {
                # not already connected, accept it
                # open client socket
                $client_socket = $lstn_sock->accept;
                if ($client_socket != 0) {
                    # connection info housekeeping
                    $readable->add($client_socket);
                    $now_string = localtime;
                    $addr = $client_socket->peeraddr ();
                    if (defined $addr) {
                        $client_ip = inet_ntoa ($addr);
                    } else {
                        $client_ip = "unknown";
                    }
                    if ($cliip) {
                        print "\nClient connected: $client_ip\n";
                    }
                    if (!defined($client_ip_code {$client_ip})) {
                        $client_ip_code{$client_ip} = int(rand() * 10000);
                        $client_ip_checked{$client_ip} = '';
                        print "\n$client_ip access code: $client_ip_code{$client_ip}\n";
                    }
                    $client_conn_cnts {$client_ip}++;
                    $client_conn_time {$client_ip} = $now_string;
                    print "LISTEN client $client_ip connected\n", if ($noisy);
                    print "LISTEN server $server_ip server_port $server_port\n", if ($debug);

                    # do we allow?
                    $connallowed = 0;
print "LISTEN server_socket $server_socket - ok2fwrd $ok2fwrd - client_ip >$client_ip<\n";

                    if (($server_socket == 0) && ($ok2fwrd != 0) && 
                        (($client_ip_checked{$client_ip} eq 'checked') || 
                        ($all eq 'checked'))
                        ) { 
                        $connallowed = 1;
                    }
                    if ($connallowed) {
                        # also open connection to server
                        # open server socket
                        $server_socket = IO::Socket::INET->new(PeerAddr => "$server_ip",
                                             PeerPort => "$server_port",
                                             Proto    => 'tcp');
                        if ($server_socket != 0) {
                            $addr = $server_socket->peeraddr ();
                            if (defined $addr) {
                                $server_socketname = inet_ntoa ($addr);
                            } else {
                                $server_socketname = "unknown";
                            }
                            print "LISTEN server connected to $server_socketname\n", if ($noisy);
                            $readable->add($server_socket);
                        } else {
                            # server open failed, close client
                            &close_client_sock;
                        }
                    } else {
                        $now_string = localtime;
                        if ($client_socket != 0) {
                            # receiving from first connect
                            $fname = ":::";
                            while (<$client_socket>) {
                                print "NO RELAY ".length ($_).": $_", if ($noisy);
                                if (/^ *\n*\r*$/) {
                                    last;
                                }
                            }
                            print $client_socket "HTTP/1.0 200 OK\r\n\r\n<html><body>" . 
                                "Welcome!  It is now $now_string.  Your external IP address is $client_ip. " .
                                "Your code is: $client_ip_code{$client_ip}" .
                                "</body></html>";
                        }
                        &close_client_sock;
                    }
                }
            } else {
                # already has a client connected, possibly IE9 opening 
                # multiple keep-alive connections.
                # Pause to allow server to catch up
                $keepalivesleep = 1;
            }
        } else {
#---------------------- Unsupported -----------------------
            # multiple connection?
            print STDERR "ERROR  s $curr_socket\n";
            print STDERR "client_socket $client_socket\n";
            print STDERR "server_socket $server_socket\n";
            print STDERR "lstnsock $lstn_sock\n";
        }
    }
    if ($keepalivesleep) {
        $keepalivesleep = 0;
        select (undef, undef, undef, 0.1);
    }
}
