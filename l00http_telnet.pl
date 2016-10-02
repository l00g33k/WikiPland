use strict;
use warnings;
use l00httpd;
use IO::Socket;
use IO::Select;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# telnet get clone to download target

my %config = (proc => "l00http_telnet_proc",
              desc => "l00http_telnet_desc");
my ($telnetpath, $url);
$url = "http://www.google.com";

sub trans {
    my ($line) = @_;

    # translate \\, \r, \n to \\, 0x0D, and 0x0A
    $line =~ tr/\\rn0/\\\r\n\x00/;

    $line;
}

sub l00http_telnet_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "telnet: 'Expect'-like connection";
}


sub l00http_telnet_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($buf, $pname, $fname, $exec);
    my ($addr, $port, $to, $expect, $toend);
    my ($server_socket, $curr_socket, $readable, $ready, $readbytes);


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#end\">Jump to end</a>\n";

    if (defined ($form->{'path'})) {
        ($pname, $fname) = $form->{'path'} =~ /^(.+[\\\/])([^\\\/]+)$/;
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=:hide+edit+$form->{'path'}%0D\">Path</a>: ";
        print $sock " <a href=\"/ls.htm?path=$pname\">$pname</a>";
        print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$fname</a>\n";
    }
    print $sock "<p>\n";


    if (defined ($form->{'url'})) {
        $url = $form->{'url'}
    }


    print $sock "<form action=\"/telnet.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"execute\" value=\"Execute\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"10\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";
    print $sock "</table>\n";
    print $sock "</form>\n";


    if (defined ($form->{'execute'})) {
        $exec = 1;
    } else {
        $exec = 0;
    }


    if (defined ($form->{'path'})) {
        print $sock "<p><pre>\n";
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            undef $server_socket;
            undef $readable;
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                s/\r//;
                s/\n//;
                print $sock "<font style=\"color:black;background-color:silver\">$_</font>\n";
                if (/^ADDR\.(\d+):(.+?):(\d+)/) {
                    $to = $1;
                    $addr = $2;
                    $port = $3;
                    &l00httpd::dbp($config{'desc'}, "ADDR:$addr:$port ${to}s\n");

                    if ($exec) {
                        $server_socket = IO::Socket::INET->new(
                            PeerAddr => $addr,
                            PeerPort => $port,
                            Timeout  => $to,
                            Proto    => 'tcp');
                        if (defined($server_socket)) {
                            $readable = IO::Select->new;     # Create a new IO::Select object
                            $readable->add($server_socket);  # Add the lstnsock to it
                        }
                        &l00httpd::dbp($config{'desc'}, "new socket $server_socket\n");
                    }
                }
                if (/^SEND:(.+)/) {
                    $_ = $1;
                    # translate \\, \r, \n
                    s/\\([\\rn])/&trans($1)/seg;
                    if ($exec && defined ($server_socket)) {
                        print $server_socket $_;
                        &l00httpd::dbp($config{'desc'}, "SENt:$_\n");
                    } else {
                        &l00httpd::dbp($config{'desc'}, "SEND:$_\n");
                    }
                }
                if (/^EXPECT\.(\d+):(.*)/) {
                    $to = $1;
                    $expect = $2;
                    if ($exec && defined ($server_socket)) {
                        $toend = time + $to;
                        &l00httpd::dbp($config{'desc'}, "EXPECTimg:$expect ${to}s\n");
                        while ($toend >= time) {
                            my ($ready) = IO::Select->select($readable, undef, undef, 0.1);
                            $readbytes = undef;
                            foreach my $curr_socket (@$ready) {
                                # don't expect more than 1 to be ready
                                $readbytes = sysread ($curr_socket, $_, 4 * 1024 * 1024);

                                if ((!defined($readbytes)) || ($readbytes == 0)) {
                                    next;
                                }
                                &l00httpd::dbp($config{'desc'}, "EXPECTgot:$_\n");
                                print $sock $_;
                                if (($expect ne '') && (/$expect/)) {
                                    # match
                                    &l00httpd::dbp($config{'desc'}, "EXPECTmatch:$expect\n");
                                    $toend = 0; # ends loop
                                }
                            }
                        }
                        print $sock "\n";
                    } else {
                        &l00httpd::dbp($config{'desc'}, "EXPECT:$expect ${to}s\n");
                    }
                }
            }
            if ($exec && defined ($server_socket)) {
                $server_socket->close;
            }
            print $sock "</pre>\n";
        }
    }


    # send HTML footer and ends
    print $sock "<hr><a name=\"end\"></a>";
    print $sock "<a href=\"#top\">top</a>\n";

    print $sock $ctrl->{'htmlfoot'};
}


\%config;
