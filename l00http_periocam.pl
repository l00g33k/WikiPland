use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my %config = (proc => "l00http_periocam_proc",
              desc => "l00http_periocam_desc",
              perio => "l00http_periocam_perio");

my ($lastcalled, $perbuf, $percnt, $perltime);
my ($interval, $repeat);
$interval = 0;
$lastcalled = 0;
$repeat = 1;
$percnt = 0;
$perltime = 0;

my ($jpgpath);

sub l00http_periocam_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition

    $jpgpath = "$ctrl->{'workdir'}pub/";

    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "periocam: periodic cam capture";
}

$perbuf = "";

sub l00http_periocam_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
 
    # get submitted name and print greeting
    if (defined ($form->{"submit"})) {
        if (defined ($form->{"interval"}) && ($form->{"interval"} >= 0)) {
            $interval = $form->{"interval"};
        }
        if (defined ($form->{"repeat"}) && ($form->{"repeat"} >= 0)) {
            $repeat = $form->{"repeat"};
        }
    }
    if (defined ($form->{"stop"})) {
        $interval = 0;
    }


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">QUICK</a> <a href=\"/periocam.htm\">Refresh</a><p> \n";

    print $sock "<form action=\"/periocam.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td>Run interval (sec):</td>\n";
    print $sock "        <td><input type=\"text\" size=\"6\" name=\"interval\" value=\"$interval\"></td> + ~5 secs capture time\n";
    print $sock "    </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td>Repeat:</td>\n";
    print $sock "        <td><input type=\"text\" size=\"6\" name=\"repeat\" value=\"$repeat\"></td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Submit\"> \n";
    print $sock "         <input type=\"submit\" name=\"stop\" value=\"Stop\"></td>\n";
    print $sock "        <td>Note: when phone sleeps, interval may be much longer than specified</td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "<a href=\"/ls.htm?path=$jpgpath\">see .jpg dir. </a> \n";

    print $sock "Count: $percnt - <a href=\"#end\">Jump to end</a>\n";
    print $sock "<pre>$perbuf</pre>\n";
    print $sock "<p><a href=\"#top\">Jump to top</a><p>\n";
    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

my (%ifs, %sockstat, $key);

sub l00http_periocam_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($buf, $tempe, $thisif, $rxb, $txb, $fname);


    if (($interval > 0) && 
        (($lastcalled == 0) || (time >= ($lastcalled + $interval)))) {
        $lastcalled = time;

        $tempe = '';
        $thisif = '';
        if ($ctrl->{'os'} eq 'and') {
            $ctrl->{'droid'}->wakeLockAcquireDim();
            $ctrl->{'droid'}->cameraCapturePicture("$jpgpath"."periocam.jpg");
#           $ctrl->{'droid'}->wakeLockRelease();
            $ctrl->{'droid'}->wakeLockAcquirePartial();
            if (open (IN, "<$jpgpath"."periocam.jpg")) {
                binmode (IN);
                sysread (IN, $_, 10000000);
                close (IN);
                $fname = "$jpgpath"."periocam_$ctrl->{'now_string'}.jpg";
                $fname =~ s / /_/g;
                if (open (OU, ">$fname")) {
                    binmode (OU);
                    print OU $_;
                    close (OU);
                }
            }
            $tempe = "<a href=\"/ls.htm?path=$jpgpath"."periocam_$ctrl->{'now_string'}.jpg\">periocam_$ctrl->{'now_string'}.jpg</a>\n";
        }
        if ($perltime != 0) {
            # subsequently
            $perbuf .= $tempe;
        } else {
            # first time
            $perbuf = $tempe;
        }
        $perltime = time;
        $percnt++;
        if ($percnt >= $repeat) {
            $interval = 0;
        }
    }

    $interval;
}


\%config;
