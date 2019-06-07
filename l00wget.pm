# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14
use warnings;
use strict;

package l00wget;

my ($shellwget);
$shellwget = -1;

#&l00httpd::dumphash ("gps", $buf);

#($hdr, $bdy) = &l00wget::wget ($url);
sub wget {
    my ($ctrl, $url, $nmpw, $opentimeout, $readtimeout, $debug) = @_;
    my ($hdr, $bdy);
    my ($buf, $proxy, $finalurl);
    my ($server_socket, $cnt, $hdrlen, $bdylen);
    my ($readable, $ready, $curr_socket, $ret, $mode);
    my ($chunksz, $host, $port, $path, $contlen, $cmd);

    $hdr = '';
    $bdy = '';

    $mode = '';
    if (!defined($readtimeout)) {
        $readtimeout = 20;
    }

    if (!defined($debug)) {
        $debug = 0;
    }

    if ($debug >= 3) {
        l00httpd::dbp('l00wget.pm', "URL: $url\n");
    }

#** [[/wget.htm?url=http%3A%2F%2F127.0.0.1%3A30443%2Fshell.htm%3Fbuffer%3Dwget%2B-O%2Bc%253A%252Fx%252Fram%252Fwget.htm%2B%2522http%253A%252F%252Frss.slashdot.org%252F%257Er%252FSlashdot%252Fslashdot%252F%257E3%252Ffoau9ZEa8tw%252Fmcafee-uses-web-beacons-that-can-be-used-to-track-users-serve-advertising%2522%26exec%3DExec&wgetpath=l00%3A%2F%2Fwget.htm&submit=Fetch+URL|Remote shell to wget]]
#** [[/wget.htm?url=http%3A%2F%2F127.0.0.1%3A30443%2Fls.htm%3Fpath%3Dc%3A%2Fx%2Fram%2Fwget.htm%26raw%3Don&wgetpath=l00%3A%2F%2Fwget.htm&submit=Fetch+URL|Fetch from remote to RAM]]

    # proxy:127.0.0.1:8118:http://www.google.com
    if (($host, $port, $path) = $url =~ m|proxy:(.+?):(\d+):(http://.+)$|i) {
	    # using http proxy
        #print "($host, $port, $path)\n";
    } else {
        $port = 80;
        $host = undef;
        if ($url =~ m|https://|i) {
            if ($debug >= 4) {
                l00httpd::dbp('l00wget.pm', "URL: is HTTPS\n");
            }
        } elsif (($host, $path) = $url =~ m|http://(.+?)(/.*)|i) {
            if ($host =~ m|(.+?):(\d+)|) {
                $host = $1;
                $port = $2;
            }
        } else {
            $host = $url;
            $host =~ s/^http:\/\///i;
            $path = '/';
        }
    }
    if (defined($host)) {
        if (defined($opentimeout)) {
            $server_socket = IO::Socket::INET->new(
                PeerAddr => $host,
                PeerPort => $port,
                Timeout  => $opentimeout,
                Proto    => 'tcp');
        } else {
            $server_socket = IO::Socket::INET->new(
                PeerAddr => $host,
                PeerPort => $port,
                Proto    => 'tcp');
        }
        if (defined($server_socket)) {
            if (defined($nmpw) && (length($nmpw) > 1)) {
                $nmpw = "Authorization: Basic " . &l00base64::b64encode ($nmpw) . "\r\n";
            } else {
                $nmpw = '';
            }
            print $server_socket "GET $path HTTP/1.1\r\n".
                #"Accept: text/html, application/xhtml+xml, */*\r\n".
                $nmpw.
                "Host: $host\r\n\r\n";

            $readable = IO::Select->new;     # Create a new IO::Select object
            $readable->add($server_socket);  # Add the lstnsock to it

            $buf = '';
            $bdy = '';
            $cnt = 0;
            $hdrlen = 0;
            while (1) {
                my ($ready) = IO::Select->select($readable, undef, undef, $readtimeout);
                $ret = undef;
                foreach my $curr_socket (@$ready) {
                    $ret = sysread ($curr_socket, $_, 4 * 1024 * 1024);
                }
                if ((!defined($ret)) || ($ret == 0)) {
                    last;
                }
                $cnt += $ret;
                $buf .= $_;
                if ($hdrlen <= 0) {
                    $hdrlen = index ($buf, "\r\n\r\n");
                    if ($hdrlen > 0) {
                        $hdrlen += 2;
                        # save hdr
                        $hdr = substr ($buf, 0, $hdrlen);
                        # chop hdr
                        substr ($buf, 0, $hdrlen + 2) = '';
                        if ($hdr =~ /Content-Length: *(\d+)/i) {
                            $mode = 'contlen';
                            $contlen = $1;
                        }
                        if ($hdr =~ /Transfer-Encoding: *chunked/i) {
                            $mode = 'chunked';
                            $chunksz = -1;
                        }
                    } else {
                        # not finding HTTP header; 
                        $hdrlen = 1;    # anything > 0
                    }
                }
                if ($hdrlen > 0) {
                    # got header
                    if ($mode eq 'chunked') {
                        while (1) {
                            if ($chunksz < 0) {
                                if ($buf =~ /^([0-9a-fA-F]+)\r/) {
                                    $chunksz = hex ($1);
                                    if ($chunksz == 0) {
                                        last;
                                    }
                                    substr ($buf, 0, length($1) + 2) = '';
                                }
                            }
                            if (($chunksz > 0) && (length ($buf) >= $chunksz)) {
                                $bdy .= substr ($buf, 0, $chunksz);
                                substr ($buf, 0, $chunksz + 2) = '';
                                $chunksz = -1;
                            } else {
                                last;
                            }
                        }
                        if ($chunksz == 0) {
                            last;
                        }
                    } elsif ($mode eq 'contlen') {
                        $bdy .= $buf;
                        $buf = '';
                        if (length ($bdy) >= $contlen) {
                            last;
                        }
                    } else {
                        $bdy .= $buf;
                        $buf = '';
                    }
                }
            }

            $server_socket->close;
        }
    } else {
        # https
        if ($shellwget == -1) {
            $ret = `wget --help`;
            if ($ret =~ /Usage:/ms) {
                # Found Usage: in output so we must have wget
                $shellwget = 1;
            } else {
                $shellwget = 0;
            }
        }
        if ($shellwget == 1) {
            $cmd = "wget \"$url\" -O \"$ctrl->{'plpath'}.wget.tmp\"";
            $hdr = `$cmd`;
            local $/;
            $/ = undef;
            if (open (IN, "<$ctrl->{'plpath'}.wget.tmp")) {
                $bdy = <IN>;
                close (IN);
            } else {
                $bdy = '';
            }
        } else {
            $hdr = 'wget utility is not available in the shell to fetch HTTPS';
            $hdr .= ". Try <a href=\"http://127.0.0.1:20347/mobizoom.htm?url=$url&fetch=Fetch\">http://127.0.0.1:20347/mobizoom.htm</a>";
            $bdy = $hdr;
        }
    }

    ($hdr, $bdy);
}


sub wgetfollow {
    my ($ctrl, $url, $nmpw, $opentimeout, $readtimeout, $debug) = @_;
    my ($hdr, $bdy, $followmoves, $domain, $moved, $journal);

    $hdr = '';
    $bdy = '';
    $journal = '';

    for ($followmoves = 0; $followmoves < 10; $followmoves++) {
        $domain = '';
        $url =~ s/\r//g;
        $url =~ s/\n//g;
        if ($url =~ /https*:\/\/([^\/]+?)\//) {
            $domain = $1;
        }
        ($hdr, $bdy) = &wget ($url, $nmpw, $opentimeout, $readtimeout, $debug);
        $journal .= sprintf("<p>#%d: HDR (%d B), BDY (%d B), URL:>%s<\n", 
            $followmoves, length($hdr), length($bdy), $url);
        $journal .= sprintf ("URL is %3d bytes long and CRC32 is 0x%08x\n",
            length($url), &l00crc32::crc32($url));
        $_ = length($hdr);
        $journal .= "Header length $_ bytes<br>\n";
        $_ = length($bdy);
        $journal .= "Body length $_ bytes<br>\n";
        $journal .= "Header:\n<pre>$hdr</pre>\n";
        if ($_ > 1000) {
            $_ = 1000;
        }
        $_ = substr($bdy, 0, $_);
        s/</&lt;/gs;
        s/>/&gt;/gs;
        $journal .= "First 1000 bytes of body:\n<pre>$_</pre>\n";

        # Find HTTP return code
        $moved = '';
        foreach $_ (split("\n", $hdr)) {
            if (($moved eq '') && (/^HTTP.* 301 /)) {
                $moved = 'moved';
            }
            if (($moved eq 'moved') && (/^location: +(.+)/i)) {
                $url = $1;
                if (!($url =~ /^http:\/\//)) {
                    $url = "http://$domain$url";
                }
                $journal .= "Moved to:$url\n";
                $moved = 'found';
            }
        }
        if ($moved ne 'found') {
            # didn't move, last fetch
            $followmoves = 100;
        }
    }


    ($hdr, $bdy, $journal);
}

1;
