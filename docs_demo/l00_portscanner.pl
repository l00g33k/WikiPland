use warnings;
use IO::Socket;     # for networking
use IO::Select;     # for networking

my(@pids, $t, $preend, $upper24, $ipst, $ipen, $ip, $pid, @ports, $port, $debug);
$t = time;
undef @pids;
undef @ports;
$debug = 0;

$upper24 = '192.168.1.';
$ipst = 100;
$ipen = 120;
$ports[0] = 22;

if(!defined($sock)) {
    $sock = STDOUT;
    $preend = '';
} else {
    print $sock "<pre>\n";
    print $sock "Arg1=upper24, Arg2=IP start-end, Arv3=port[,port]\n";
    $preend = "</pre>\n";
    if (defined($ctrl->{'FORM'}->{'arg1'})) {
        $upper24 = $ctrl->{'FORM'}->{'arg1'};
    }
    if (defined($ctrl->{'FORM'}->{'arg2'})) {
        ($ipst, $ipen) = $ctrl->{'FORM'}->{'arg2'} =~ /(\d+)-(\d+)/;;
    }
    if (defined($ctrl->{'FORM'}->{'arg3'})) {
        @ports = split(',', $ctrl->{'FORM'}->{'arg3'});
    }
    if (defined($ctrl->{'FORM'}->{'debug'})) {
        $debug = $ctrl->{'FORM'}->{'debug'};
    }
}
print $sock "Scanning port ".join(',', @ports)," in IP range $upper24$ipst-$ipen\n";
foreach $ip ($ipst..$ipen) {
    foreach $port (@ports) {
        my ($pid);
        if ($pid = fork) {
            #print "MAIN: \$\$=$$ \$pid=$pid ip=$ip\n";
            push(@pids, $pid);
        } else {
            # http://www.oreilly.com/openbook/cgi/ch10_10.html
            # child process
            my ($readable, $host, $server_socket, $readbytes);

            $host = "$upper24$ip";
            print $sock "Scan ($host:$port)\n", if($debug);
if(1){
            $readable = IO::Select->new;     # Create a new IO::Select object
            $server_socket = IO::Socket::INET->new(
                PeerAddr => $host,
                PeerPort => $port,
                Timeout  => 1,
                Proto    => 'tcp');
            if (defined($server_socket)) {
                 print $server_socket "GET /\r\n\r\n";
                $readable->add($server_socket);  # Add the lstnsock to it
                my ($ready) = IO::Select->select($readable, undef, undef, 1);
                foreach my $curr_socket (@$ready) {
                    # don't expect more than 1 to be ready
                    sysread ($curr_socket, $_, 120);
                    s/[\n\r]/ /g;
                    s/</&lt;/g;
                    s/>/&gt;/g;
                    print $sock "<a href=\"http://$host:$port\">$host:$port</a> $_\n";
                }
                $server_socket->close();
            }
}
            exit (0);
        }
    }
}
foreach $pid (@pids) {
    waitpid($pid,0);
}
$t = int(time - $t + 0.5);
print $sock "\nCompleted in $t seconds\n$preend";
