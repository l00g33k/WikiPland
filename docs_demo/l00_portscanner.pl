use IO::Socket;     # for networking
use IO::Select;     # for networking

my(@pids, $t, $preend, $upper24, $ipst, $ipen, $port);
$t = time;
undef @pids;

if(!defined($sock)) {
    $sock = STDOUT;
    $preend = '';
    $upper24 = '192.168.1.';
    $ipst = 2;
    $ipen = 254;
} else {
    print $sock "<pre>\n";
    print $sock "Arg1=upper24, Arg2=IP start-end, Arv3=port\n";
    $preend = "</pre>\n";
    $upper24 = '192.168.1.';
    $ipst = 2;
    $ipen = 254;
    if (defined($ctrl->{'FORM'}->{'arg1'})) {
        $upper24 = $ctrl->{'FORM'}->{'arg1'};
    }
    if (defined($ctrl->{'FORM'}->{'arg2'})) {
        ($ipst, $ipen) = $ctrl->{'FORM'}->{'arg2'} =~ /(\d+)-(\d+)/;;
    }
    if (defined($ctrl->{'FORM'}->{'arg3'})) {
        $port = $ctrl->{'FORM'}->{'arg3'};
    }
}
foreach $ip ($ipst..$ipen) {
    my ($pid);
    if ($pid = fork) {
        #print "MAIN: \$\$=$$ \$pid=$pid ip=$ip\n";
        push(@pids, $pid);
    } else {
        # http://www.oreilly.com/openbook/cgi/ch10_10.html
        # child process
        my ($readable, $host, $server_socket, $readbytes);

        $readable = IO::Select->new;     # Create a new IO::Select object
        $host = "$upper24$ip";
        #print "CHILD: \$\$=$$ \$pid=$pid ip=$ip \$host=$host\n";
        $server_socket = IO::Socket::INET->new(
            PeerAddr => $host,
            PeerPort => $port,
            Timeout  => 1,
            Proto    => 'tcp');
        if (defined($server_socket)) {
            print $server_socket "\n";
            $readable->add($server_socket);  # Add the lstnsock to it
            my ($ready) = IO::Select->select($readable, undef, undef, 1);
            foreach my $curr_socket (@$ready) {
                # don't expect more than 1 to be ready
                sysread ($curr_socket, $_, 120);
                s/[\n\r]/ /g;
                print $sock "$host: $_\n";
            }
            $server_socket->close();
        }
        exit (0);
    }
}
foreach $pid (@pids) {
    waitpid($pid,0);
}
$t = int(time - $t + 0.5);
print $sock "\nCompleted in $t seconds\n$preend";
