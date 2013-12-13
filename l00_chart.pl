# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

    print $sock "chart.pl:<br>\n";
    $server_socket = IO::Socket::INET->new(PeerAddr => "chart.apis.google.com",
                         PeerPort => "80",
                         Proto    => 'tcp');

    if ($server_socket != 0) {
        $png = "/sdcard/tmp/del.png";

        $iilen = 100;
        $pi = 3.141592653589793;
        for ($ii = 0; $ii < $iilen; $ii++) {
            $xx [$ii] = 1.7 * cos (2 * $pi * $ii / $iilen * 4) * $ii / ($iilen * 2);
            $yy [$ii] = 1.7 * sin (2 * $pi * $ii / $iilen * 4) * $ii / ($iilen * 2);
        }


        $xstr = "";
        $ystr = "";
        $xmin = $xx [0];
        $xmax = $xx [0];
        $ymin = $yy [0];
        $ymax = $yy [0];
        for ($ii = 1; $ii < $iilen; $ii++) {
            if ($xmin > $xx [$ii]) { $xmin = $xx [$ii]; }
            if ($xmax < $xx [$ii]) { $xmax = $xx [$ii]; }
            if ($ymin > $yy [$ii]) { $ymin = $yy [$ii]; }
            if ($ymax < $yy [$ii]) { $ymax = $yy [$ii]; }
            $xstr .= sprintf ("%.2e,", $xx[$ii]);
            $ystr .= sprintf ("%.2e,", $yy[$ii]);
        }
        chop ($xstr);
        chop ($ystr);


        #$api .= "&chd=t:12,87,75,41,23,96,68,71,34,9|98,60,27,34,56,79,58,74,18,76";
        #$api .= "&chm=o,FF0000,0,0:2,10,-1|s,00FF00,0,3:8,10,-1|D,00000066,0,,1,0";
        #$_ = "GET $api HTTP/1.0\r\n\r\n";

        $api = "/chart?cht=s";
        $api .= "&chd=t:$xstr|$ystr";
        $api .= "&chds=$xmin,$xmax,$ymin,$ymax";
        $api .= "&chxr=0,$xmin,$xmax|1,$ymin,$ymax";
        $api .= "&chxt=x,y";
        $api .= "&chs=320x240";
        $api .= "&chm=o,FF0000,0,,10,-1|D,00000066,0,,1,0";

        $apilen = length ($api) - 7;
        $api = substr ($api, 7, $apilen);
        $_ = "POST /chart HTTP/1.0\r\nContent-Length:$apilen\r\n\r\n$api";

        print $sock "Sending message: $_<p>\n";
        print $server_socket "$_";

        print $sock "Waiting for return message<br>\n";
        $hdrsz = 0;
        $datsz = 0;
        $gotsz = 0;
        $_ = "";
if (1) {
        while (($hdrsz == 0) || ($gotsz < ($hdrsz + $datsz))) {
            $cnt = sysread ($server_socket, $buf, 10240);
            if (($cnt == undef) || ($cnt == 0)) {
                last;
            }
            $_ .= $buf;
            $gotsz += $cnt;
            if ($hdrsz == 0) {
                $hdrsz = index ($_, "\r\n\r\n");
                if ($hdrsz <= 0) {
                    $hdrsz = 0;
                } else {
                    $hdrsz += 4;
                    $header = substr ($_, 0, $hdrsz);
                    $tmp = index ($header, "Content-Length:");
                    if ($tmp >= 0) {
                        if (substr ($header, $tmp + 15, 8)  =~ /(\d+)/) {
                            $datsz = $1;
                            print $sock "Content-Length = $datsz<br>\n";
                        }
                    }
                    $header =~ s/</&lt;/g;
                    $header =~ s/>/&gt;/g;
                    print $sock "Header:<br><pre>$header</pre><p>\n";
                    $tmp = index ($header, "Content-Length:");
                }
            }
            print $sock "Received: header $hdrsz, total $gotsz<br>\n";
        }
}
        print $sock "Writing $datsz bytes to $png<br>\n";
        open (PNG, ">$png");
        binmode (PNG);
        print PNG substr ($_, $hdrsz, $datsz);
        close (PNG);
        print $sock "Closing connection<br>\n";
        $server_socket->close;
    }

1;
