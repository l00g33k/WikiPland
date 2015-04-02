use IO::Socket;

# wakeonlan example

# operating parameters
$hostnet = '192.168.0';
$port = 9;

# create the payload
# magic packet header
$buf = pack ("C6", 0xff, 0xff, 0xff, 0xff, 0xff, 0xff);
# magic packet payload: MAC 16 times
$buf .= pack ("C6", 0x00, 0x21, 0x9b, 0x03, 0x18, 0xc9) x 16;

# report the size of the actual payload
print $sock "<P>My IP $ctrl->{'myip'}<br>\n";

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

print $sock "DONE";
