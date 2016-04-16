use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_trk2way_proc",
              desc => "l00http_trk2way_desc");

my ($trackheight);
my ($latoffset, $lonoffset, $applyoffset);

$trackheight = 30;

$latoffset = 0;
$lonoffset = 0;
$applyoffset = '';



sub l00http_trk2way_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "trk2way: Convert GPS track to waypoints";
}

sub l00http_trk2way_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno, $buffer, $httphdr, $kmlbuf, $size);
    my ($lat, $lon, $name, $trkname, $trkmarks, $lnno, $pointno);
    my ($gpxtime, $fname, $curlatoffset, $curlonoffset, $thisfile);
    my ($toKmlCnt, $frKmlCnt);


    if (defined($form->{'cb2file'})) {
        $form->{'path'} = &l00httpd::l00getCB($ctrl);
    }

    # create HTTP and HTML headers
    print $sock "$ctrl->{'httphead'}$ctrl->{'htmlhead'}$ctrl->{'htmlttl'}$ctrl->{'htmlhead2'}";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<br>\n";
    $fname = '';
    if (defined ($form->{'path'})) {
        print $sock "Path: <a href=\"/view.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";
        if ($form->{'path'} =~ /([^\/\\]+)$/) {
            $fname = $1;
        }
    }


    if (defined($form->{'set'})) {
        if (defined ($form->{'kml_trackheight'}) && 
            ($form->{'kml_trackheight'} =~ /(\d+)/)) {
            $trackheight = $1;
        }
        if (defined ($form->{'latoffset'}) && 
            ($form->{'latoffset'} =~ /([0-9.+-]+)/)) {
            $latoffset = $1;
        }
        if (defined ($form->{'lonoffset'}) && 
            ($form->{'lonoffset'} =~ /([0-9.+-]+)/)) {
            $lonoffset = $1;
        }
        if (defined ($form->{'applyoffset'}) && 
            ($form->{'applyoffset'} eq 'on')) {
            $applyoffset = 'checked';
        } else {
            $applyoffset = '';
        }
    }


    if ((defined ($form->{'path'})) && 
        (length ($form->{'path'}) > 0)) {
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
#$thisfile
            my ($slash, $phase, $lonlat, $name);
            $toKmlCnt = 0;
            $frKmlCnt = 0;

            $buffer = &l00httpd::l00freadAll($ctrl);

            if ($applyoffset eq 'checked') {
                $curlatoffset = $latoffset;
                $curlonoffset = $lonoffset;
            } else {
                $curlatoffset = 0;
                $curlonoffset = 0;
            }

            # Maverick has only \r as line endings. So convert DOS \r\n to Unix \n
            # then convert Maverick's \r to Unix \n
            $buffer =~ s/\r\n/\n/g;
            $buffer =~ s/\r/\n/g;
            $phase = 0;
            if ($buffer =~ /^H  SOFTWARE NAME & VERSION/) {
                $toKmlCnt++;
                my ($tracks, $phase, $lat_, $lon_, $desc, $debug, $trackno);
                my ($ns, $lat_d, $lad_m, $ew, $lon_d, $lon_m, $dtstamp);
                $tracks = '';
                $phase = 'find_header';
                $debug = 1;
                $trackno = 1;
                # gps track, convert to .kml
        $kmlbuf = "";
                $trkmarks = '';

                $lnno = 0;
                $pointno = -1;
                foreach $_ (split ("\n", $buffer)) {
                    $lnno++;
                    $pointno++;
                    #H  LATITUDE    LONGITUDE    DATE      TIME     ALT    ;track
            	    if ((($phase eq 'find_header') ||
                         ($phase eq 'find_more_point')) && 
                        (/^H  LATITUDE    LONGITUDE/)) {
                        $phase = 'found_header';
                        $pointno = 0;
                    #T  N3110.27551 E12123.28069 10-Apr-11 05:57:36    7 ; gps 20110410 135759
                    } elsif (($phase eq 'found_header') && 
                        (/^T +[NS]/)) {
                        $phase = 'find_more_point';
		                # track or new track
                        $trkname = "Track $trackno";
                        if (/^T +[NS].+; (.+)/) {
                            $trkname = "Track $1";
                        }
		                $tracks = $tracks . "#$trackno: $trkname\n";
                        $trackno++;
                    }
                    if (($phase eq 'find_more_point') && 
                        (/^T +[NS]/)) {
                        #T  N36 46.0095 W119 33.3582 Tue Sep 24 23:18:28 2002
                        if (($ns, $lat_d, $lad_m, $ew, $lon_d, $lon_m, $dtstamp) 
                            = /T +([NS])(\d\d)([\d.]+) ([WE])(\d\d\d)([\d.]+) (.+)/) {
                            $lat_ = $lat_d + $lad_m / 60.0;
                            if ($ns eq 'S') {
                                $lat_ = -$lat_;
                            }
                            $lon_ = $lon_d + $lon_m / 60.0;
                            if ($ew eq 'W') {
                                $lon_ = -$lon_;
                            }
                            $lat_ += $curlatoffset;
                            $lon_ += $curlonoffset;
                            # shorten timestamp:
                            # 07-Apr-16 07:09:04  -25 ; gps 20160407 000905
                            if ($dtstamp =~ /gps \d{6,6}(\d\d) (\d{4,4})\d\d/) {
                                $dtstamp = "$1$2";
                            }
		                    $tracks = $tracks . "$lat_,$lon_ $dtstamp\n";
                        }
                    }
                }
                $kmlbuf .= $tracks;

                &l00httpd::l00fwriteOpen($ctrl, 'l00://trk2way.txt');
                &l00httpd::l00fwriteBuf($ctrl, $kmlbuf);
                &l00httpd::l00fwriteClose($ctrl);
            }
        }
    }


    print $sock "<form action=\"/trk2way.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "Filename:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"process\" value=\"Process\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"submit\" name=\"cb2file\" value=\"CB to Filename\">\n";
    print $sock "</td></tr>\n";
    print $sock "</table>\n";
    print $sock "</form><br>\n";


    print $sock "Converted: <a href=\"/view.htm?path=l00://trk2way.txt\">l00://trk2way.txt</a><br>\n";

    $lineno = 1;
    if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
        print $sock "<pre>\n";
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            s/\r//g;
            s/\n//g;
            s/</&lt;/g;
            s/>/&gt;/g;
            print $sock sprintf ("%04d: ", $lineno++) . "$_\n";
        }
        print $sock "</pre>\n";
    }

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
