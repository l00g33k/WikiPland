# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14
use warnings;
use strict;

package l00wget;


#&l00httpd::dumphash ("gps", $buf);

#($hdr, $bdy) = &l00wget::wget ($url);
sub wget {
    my ($url, $nmpw) = @_;
    my ($hdr, $bdy);
    my ($buf);
    my ($server_socket, $cnt, $hdrlen, $bdylen);
    my ($readable, $ready, $curr_socket, $ret, $mode);
    my ($chunksz, $host, $port, $path, $contlen);

    $hdr = undef;
    $bdy = undef;

    $port = 80;
    if (($host, $path) = $url =~ m|http://(.+?)(/.*)|i) {
        if ($host =~ m|(.+?):(/.*)|) {
            $host = $1;
            $port = $2;
        }
    } else {
        $host = 'www.google.com';
        $path = '/';
    }
    $server_socket = IO::Socket::INET->new(
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp');
    if ($server_socket != 0) {
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
        while (1){
            my ($ready) = IO::Select->select($readable, undef, undef, 20);
            $ret = 0;
            foreach my $curr_socket (@$ready) {
                $ret = sysread ($curr_socket, $_, 4 * 1024 * 1024);
            }
            if ($ret == 0) {
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

    ($hdr, $bdy);
}


1;

