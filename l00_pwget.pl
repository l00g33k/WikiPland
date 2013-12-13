# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

    print $sock "hello<br>\n";


    $server_socket = IO::Socket::INET->new(PeerAddr => "www.google.com",
                         PeerPort => "80",
                         Proto    => 'tcp');

    if ($server_socket != 0) {

        $_ = "GET / HTTP/1.0\r\n\r\n";
    
    print $sock "Sending message: <pre>$_</pre><br>\n";
    
    print $server_socket "$_";


        print $sock "Waiting for return message<br>\n";
        $cnt = sysread ($server_socket, $_, 10240);
$hdrsize = index ($_, "\r\n\r\n");
    
    s/</&lt;/g;
    
    s/>/&gt;/g;
    
    print $sock "Received (hdr $hdrsize / $cnt bytes): <pre>$_</pre>\n";


        print $sock "Closing connection<br>\n";
    
    $server_socket->close;

    }

1;
