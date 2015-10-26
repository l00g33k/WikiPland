use IO::Socket;

# wakeonlan example

# operating parameters
$port = 9;


# create the payload
# magic packet header
$buf = pack ("C6", 0xff, 0xff, 0xff, 0xff, 0xff, 0xff);
if (defined($ctrl->{'FORM'}->{'arg1'})) {
    $ctrl->{'FORM'}->{'arg1'} =~ s/-/:/g;
    @_ = split(":", $ctrl->{'FORM'}->{'arg1'});
    print $sock "Arg1 defined : ";
    for ($_ = 0; $_ <= $#_; $_++) {
        $_[$_] = hex($_[$_]);
        print $sock sprintf("%02X ", $_[$_]);
    }
    $buf .= pack ("C6", @_) x 16;
} else {
    # magic packet payload: MAC 16 times
    print $sock "Arg1 not defined, using example MAC";
    $buf .= pack ("C6", 0x00, 0x21, 0x9b, 0x03, 0x18, 0xc9) x 16;
}

# report the size of the actual payload
$hostnet = $ctrl->{'myip'};
$hostnet =~ s/\.\d+$//;

print $sock "<P>My IP $ctrl->{'myip'}<br>\n";
print $sock "<P>Sub net $hostnet<p>\n";

if ($ctrl->{'os'} eq 'and') {
    $ret = $ctrl->{'droid'}->checkWifiState();
    if ($ret->{'result'}) {
        print $sock "wifi is on<p>\n";
        $turnwifioff = 0;
        $ip = 1;
} else {
        print $sock "wifi is off<p>\n";
        $turnwifioff = 1;
        print $sock "Turning on wifi<p>";
        $ret = $ctrl->{'droid'}->toggleWifiState(true);

        for (0..10) {
            sleep (1);
            $ip = $ctrl->{'droid'}->wifiGetConnectionInfo()->{'result'}->{'ip_address'};
            print $sock "$_: Waiting for wifi IP: $ip<br>\n";
            if ($ip) {
               last;
            }
        }
    }
} else {
    $ip = 1;
}

if ($ip) {
    # open UDP
    $server_socket = IO::Socket::INET->new(
        PeerAddr => "$hostnet.255",
        PeerPort => "$port",
        Proto    => 'udp',
        Broadcast => 1
    );     # or TCP: Proto    => 'udp');

    if ($server_socket != 0) {
        $server_socket->sockopt(SO_BROADCAST, 1);
        print $server_socket $buf;
        $server_socket->close;
        print $sock "Magic packet broadcast to $hostnet.255<p>";
    }
}

if ($turnwifioff) {
    print $sock "Turning off wifi<p>";
    sleep (2);
    # we turned on, now turn it off
    $ret = $ctrl->{'droid'}->toggleWifiState(false);
}

print $sock "<p>DONE";
