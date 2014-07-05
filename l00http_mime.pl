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
        print $sock "<input type=\"submit\" name=\"submit\" value=\"Path\">\n";
        print $sock "<input type=\"text\" size=\"16\" name=\"path\" value=\"$path\"><br>\n";
        print $sock "Header: <input type=\"text\" size=\"16\" name=\"header\" value=\"$form->{'header'}\"><br>\n";
        print $sock "Extension: <input type=\"text\" size=\"6\" name=\"ext\" value=\"$form->{'ext'}\">\n";
        print $sock "</form>\n";

        print $sock "<hr><a name=\"end\"></a>";
        print $sock "<a href=\"#__top__\">top</a>\n";
        print $sock "<br>\n";

        print $sock "<pre>\n";
        print $sock ".zip    Content-Type: application/x-zip\n";
        print $sock ".kmz    Content-Type: application/x-zip\n";
        print $sock ".kml    Content-Type: application/vnd.google-earth.kml+xml\n";
        print $sock ".apk    Content-Type: application/vnd.android.package-archive\n";
        print $sock ".jpeg   Content-Type: image/jpeg\n";
        print $sock ".jpg    Content-Type: image/jpeg\n";
        print $sock ".wma    Content-Type: audio/x-ms-wma\n";
        print $sock ".3gp    Content-Type: audio/3gp\n";
        print $sock ".pdf    Content-Type: application/pdf\n";
        print $sock ".mp3    Content-Type: audio/mpeg\n";
        print $sock ".mp4    Content-Type: video/mp4\n";
        print $sock ".gif    Content-Type: image/gif\n";
        print $sock ".svg    Content-Type: image/svg+xml\n";
        print $sock ".png    Content-Type: image/png\n";
        print $sock ".html   Content-Type: text/html\n";
        print $sock ".htm    Content-Type: text/html\n";
        print $sock ".bak    Content-Type: text/html\n";
        print $sock ".txt    Content-Type: text/html\n";
        print $sock "( )     Content-Type: application/octet-octet-stream\n";

        print $sock "</pre>\n";


        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
    }

}


\%config;
