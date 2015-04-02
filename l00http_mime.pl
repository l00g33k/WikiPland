use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_mime_proc",
              desc => "l00http_mime_desc");


sub l00http_mime_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "mime: Simple blogger: must be invoked through ls.pl file view";
}

sub l00http_mime_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($path, $fname, $header, $httphdr, $ttlbytes);

    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        ($fname) = $path =~ /[\\\/]([^\\\/]+)$/;
    } else {
        $path = '(none)';
        $fname = '(none)';
    }

    if (!defined($form->{'ext'})) {
        $form->{'ext'} = '.png';
    }
    if (!defined($form->{'header'})) {
        $form->{'header'} = "Content-Type: image/png\r\n";
    }
    $header = &l00httpd::urlencode ($form->{'header'});

    if (defined ($form->{'get'})) {
                my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
                 $size, $atime, $mtime, $ctime, $blksize, $blocks, $buf, $len);
                ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
                 $size, $atime, $mtime, $ctime, $blksize, $blocks)
                 = stat($path);
        if (open (FILE, "<$path")) {
            $httphdr = "$form->{'header'}\r\n";
            $httphdr .= "Content-Length: $size\r\n";
            $httphdr .= "Connection: close\r\nServer: l00httpd\r\n";
            print $sock "HTTP/1.1 200 OK\r\n$httphdr\r\n";
            binmode (FILE);
            binmode ($sock);
            $ttlbytes = 0;
            # send file in block of 0x10000 bytes
            do {
                $len = read (FILE, $buf, 0x10000);
                if ($len > 0) {
                    $ttlbytes += $len;
                }
                syswrite ($sock, $buf, $len);
                select (undef, undef, undef, 0.001);    # 1 ms delay. Without it Android looses data
            } until ($len < 0x10000);
            $sock->close;
        }
    } else {
        # Send HTTP and HTML headers
        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>MIME $fname</title>" .$ctrl->{'htmlhead2'};
        print $sock "<a name=\"__top__\"></a>";
        print $sock "$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"#end\">Jump to end</a><br>\n";
        print $sock "Path: <a href=\"/ls.htm?path=$path\">$path</a><br>\n";

        print $sock "<p><a href=\"/mime.pl/$fname$form->{'ext'}?path=$path&get=on&header=$header&ext=$form->{'ext'}\">$path$form->{'ext'}</a><br>\n";

        print $sock "<form action=\"/mime.htm\" method=\"get\">\n";
        print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";

        print $sock "<tr><td>\n";
        print $sock "<input type=\"submit\" name=\"submit\" value=\"Generate link\">\n";
        print $sock "</td><td>\n";
        print $sock "<input type=\"text\" size=\"16\" name=\"path\" value=\"$path\"><br>\n";
        print $sock "</td></tr>\n";

        print $sock "<tr><td>\n";
        print $sock "Header\n";
        print $sock "</td><td>\n";
        print $sock "<input type=\"text\" size=\"16\" name=\"header\" value=\"$form->{'header'}\">\n";
        print $sock "</td></tr>\n";

        print $sock "<tr><td>\n";
        print $sock "Extension\n";
        print $sock "</td><td>\n";
        print $sock "<input type=\"text\" size=\"6\" name=\"ext\" value=\"$form->{'ext'}\">\n";
        print $sock "</td></tr>\n";

        print $sock "</table>\n";
        print $sock "</form>\n";

        print $sock "<hr><a name=\"end\"></a>";
        print $sock "<a href=\"#__top__\">top</a>\n";
        print $sock "<br>\n";

        print $sock "<pre>\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+application%2Fx-zip&ext=.zip\"                       >.zip</a>    Content-Type: application/x-zip\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+application%2Fx-zip&ext=.kmz\"                       >.kmz</a>    Content-Type: application/x-zip\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+application%2Fvnd.google-earth.kml%2Bxml&ext=.kml\"  >.kml</a>    Content-Type: application/vnd.google-earth.kml+xml\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+application%2Fvnd.android.package-archive&ext=.apk\" >.apk</a>    Content-Type: application/vnd.android.package-archive\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+image%2Fjpeg&ext=.jpeg\"                             >.jpeg</a>   Content-Type: image/jpeg\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+image%2Fjpeg&ext=.jpg\"                              >.jpg</a>    Content-Type: image/jpeg\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+audio%2Fx-ms-wma&ext=.wma\"                          >.wma</a>    Content-Type: audio/x-ms-wma\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+audio%2F3gp&ext=.3gp\"                               >.3gp</a>    Content-Type: audio/3gp\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+application%2Fpdf&ext=.pdf\"                         >.pdf</a>    Content-Type: application/pdf\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+audio%2Fmpeg&ext=.mp3\"                              >.mp3</a>    Content-Type: audio/mpeg\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+video%2Fmp4&ext=.mp4\"                               >.mp4</a>    Content-Type: video/mp4\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+image%2Fgif&ext=.gif\"                               >.gif</a>    Content-Type: image/gif\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+image%2Fsvg%2Bxml&ext=.svg\"                         >.svg</a>    Content-Type: image/svg+xml\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+image%2Fpng&ext=.png\"                               >.png</a>    Content-Type: image/png\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+text%2Fhtml&ext=.html\"                              >.html</a>   Content-Type: text/html\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+text%2Fhtml&ext=.htm\"                               >.htm</a>    Content-Type: text/html\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+text%2Fhtml&ext=.bak\"                               >.bak</a>    Content-Type: text/html\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+text%2Fhtml&ext=.txt\"                               >.txt</a>    Content-Type: text/html\n";
        print $sock "<a href=\"/mime.htm?submit=yes&path=$path&header=Content-Type%3A+application%2Foctet-octet-stream&ext=.bin\"          >( )</a>     Content-Type: application/octet-octet-stream\n";

        print $sock "</pre>\n";


        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
    }

}


\%config;
