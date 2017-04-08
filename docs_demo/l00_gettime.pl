use IO::Socket;
use IO::Select;

# read 4 bytes from time.nist.gov:37 which is time
$server_socket = IO::Socket::INET->new(
    PeerAddr => 'time.nist.gov',
    PeerPort => 37,
    Timeout  => 2,
    Proto    => 'tcp');
if (defined($server_socket)) {
    $readable = IO::Select->new;     # Create a new IO::Select object
    $readable->add($server_socket);  # Add the lstnsock to it
    my ($ready) = IO::Select->select($readable, undef, undef, 2);
    $readbytes = 0;
    foreach my $curr_socket (@$ready) {
        $readbytes = sysread ($curr_socket, $buf, 4);
    }
    $server_socket->close;
    print $sock "Read $readbytes bytes from time.nist.gov<p>\n";
    if ($readbytes == 4) {
        $time = unpack("N", $buf);
        # -2208988800 to convert to unix epoch
        ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime ($time - 2208988800);
        $now_string = sprintf ("%4d%02d%02d %02d%02d%02d", $year + 1900, $mon+1, $mday, $hour, $min, $sec);
        print $sock "It is now Unix time $time or $now_string<p>\n";
        if (defined($last)) {
            print $sock "Previous read of time.nist.gov:37 was ", $time - $last, " sec ago<p>\n";
        }
        $last = $time;
    }
} else {
    print $sock "Unable to open socket";
    $server_socket->close;
}

1;
