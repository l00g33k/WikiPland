use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_kml_proc",
              desc => "l00http_kml_desc");

my ($kmlheader1, $kmlheader2, $kmlfooter, $trackheight, $trackmark);
my ($latoffset, $lonoffset, $applyoffset);

$trackheight = 30;
$trackmark = 0;

$latoffset = 0;
$lonoffset = 0;
$applyoffset = '';

$kmlheader1 = 
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n".
    "<kml xmlns=\"http://www.opengis.net/kml/2.2\" xmlns:gx=\"http://www.google.com/kml/ext/2.2\" xmlns:kml=\"http://www.opengis.net/kml/2.2\" xmlns:atom=\"http://www.w3.org/2005/Atom\">\n".
    "<Document>\n".
    "	<name>";
$kmlheader2 = "</name>\n".
    "	<open>1</open>\n".
    "	<StyleMap id=\"msn_hospitals\">\n".
    "		<Pair>\n".
    "			<key>normal</key>\n".
    "			<styleUrl>#sn_hospitals</styleUrl>\n".
    "		</Pair>\n".
    "		<Pair>\n".
    "			<key>highlight</key>\n".
    "			<styleUrl>#sh_hospitals</styleUrl>\n".
    "		</Pair>\n".
    "	</StyleMap>\n".
    "	<Style id=\"sn_hospitals\">\n".
    "		<IconStyle>\n".
    "			<scale>1.2</scale>\n".
    "			<Icon>\n".
    "				<href>http://maps.google.com/mapfiles/kml/shapes/hospitals.png</href>\n".
    "			</Icon>\n".
    "			<hotSpot x=\"0.5\" y=\"0\" xunits=\"fraction\" yunits=\"fraction\"/>\n".
    "		</IconStyle>\n".
    "	</Style>\n".
    "	<Style id=\"sh_hospitals\">\n".
    "		<IconStyle>\n".
    "			<scale>1.4</scale>\n".
    "			<Icon>\n".
    "				<href>http://maps.google.com/mapfiles/kml/shapes/hospitals.png</href>\n".
    "			</Icon>\n".
    "			<hotSpot x=\"0.5\" y=\"0\" xunits=\"fraction\" yunits=\"fraction\"/>\n".
    "		</IconStyle>\n".
    "	</Style>\n".
    "	<Style id=\"sn_circle\">\n".
    "		<IconStyle>\n".
    "			<scale>1.2</scale>\n".
    "			<Icon>\n".
    "				<href>http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png</href>\n".
    "			</Icon>\n".
    "		</IconStyle>\n".
    "		<ListStyle>\n".
    "		</ListStyle>\n".
    "	</Style>\n".
    "	<Style id=\"sh_circle\">\n".
    "		<IconStyle>\n".
    "			<scale>1.2</scale>\n".
    "			<Icon>\n".
    "				<href>http://maps.google.com/mapfiles/kml/shapes/placemark_circle_highlight.png</href>\n".
    "			</Icon>\n".
    "		</IconStyle>\n".
    "		<ListStyle>\n".
    "		</ListStyle>\n".
    "	</Style>\n".
    "	<StyleMap id=\"msn_circle\">\n".
    "		<Pair>\n".
    "			<key>normal</key>\n".
    "			<styleUrl>#sn_circle</styleUrl>\n".
    "		</Pair>\n".
    "		<Pair>\n".
    "			<key>highlight</key>\n".
    "			<styleUrl>#sh_circle</styleUrl>\n".
    "		</Pair>\n".
    "	</StyleMap>\n".
    "	<Folder>\n".
    "		<name>Temporary Places</name>\n".
    "		<open>1</open>\n";

$kmlfooter = "\t</Folder>\n</Document>\n</kml>\n";

sub l00http_kml_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "kml: GEarth processor/translator";
}

sub l00http_kml_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno, $buffer, $rawkml, $httphdr, $kmlbuf, $size);
    my ($lat, $lon, $name, $trkname, $trkmarks, $lnno, $pointno);
    my ($gpxtime, $fname, $curlatoffset, $curlonoffset);

    $rawkml = 0;

    if (defined($form->{'cb2file'})) {
        $form->{'path'} = &l00httpd::l00getCB($ctrl);
    }

    # create HTTP and HTML headers
    $httphdr = "$ctrl->{'httphead'}$ctrl->{'htmlhead'}$ctrl->{'htmlttl'}$ctrl->{'htmlhead2'}";
    $httphdr .= "$ctrl->{'home'} $ctrl->{'HOME'}\n";
    $httphdr .= "<a href=\"/kml.htm\">Refresh</a><br>\n";
    $fname = '(unknown)';
    if (defined ($form->{'path'})) {
        $httphdr .= "Path: <a href=\"/view.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";
        if ($form->{'path'} =~ /([^\/\\]+)$/) {
            $fname = $1;
        }
    }


    if (defined($form->{'set'})) {
        if (defined ($form->{'kml_trackheight'}) && 
            ($form->{'kml_trackheight'} =~ /(\d+)/)) {
            $trackheight = $1;
        }
        if (defined ($form->{'trackmark'}) && 
            ($form->{'trackmark'} =~ /(\d+)/)) {
            $trackmark = $1;
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
        if ($form->{'path'} =~ /\.kmz$/) {
            # .kmz
			if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
                $buffer = &l00httpd::l00freadAll($ctrl);

                $size = length ($buffer);
                $httphdr = "Content-Type: application/vnd.google-earth.kml+xml\r\n";
                $httphdr .= "Content-Length: $size\r\n";
                $httphdr .= "Connection: close\r\nServer: l00httpd\r\n";
                print $sock "HTTP/1.1 200 OK\r\n$httphdr\r\n";
                print $sock $buffer;
                $sock->close;
                $rawkml = 1;
            }
        } elsif (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            my ($slash, $phase, $lonlat, $name);
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
            if ($form->{'path'} =~ /\.csv$/) {
                # The input file may have been concatnated.
                # First line in each file is:
                #   "Name","Activity type","Description"
                # Each track has an incrementing segment number which is the first field
                #   "1","1","51.481289","-0.607417","42.0","","38","0","2015-08-14T10:26:48.952Z","","",""

                my ($tracks, $phase, $lat_, $lon_, $desc, $debug, $trackno, $lastseg, $stamp);
                my ($ns, $lat_d, $lad_m, $ew, $lon_d, $lon_m, $dtstamp, @fields);
                $tracks = '';
                $phase = 'find_header';
                $debug = 1;
                $trackno = 1;
                # gps track, convert to .kml
                $kmlbuf = "$kmlheader1$fname$kmlheader2";
                $trkmarks = '';

                $lastseg = -1;
                $lnno = 0;
                $pointno = -1;
                foreach $_ (split ("\n", $buffer)) {
                    $lnno++;
                    $pointno++;
                    s/"//g;
                    @fields = split(",", $_);
                    # try to find timestamp as valid indicator
                    if (defined($fields[8]) &&
                        ($fields[8] =~ /(\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d+Z)/)) {
                        # found it
                        $stamp = $1;
                        $stamp =~ s/:/_/g;
                    } else {
                        $stamp = '';
                    }

                    #"Name","Activity type","Description"
            	    if ((($phase eq 'find_header') ||
                         ($phase eq 'find_more_point')) && 
                        ($fields[1] =~ /Activity type/)) {
                        $phase = 'found_header';
                        $lastseg = -1;
                        $pointno = 0;
                    } elsif (($phase eq 'found_header') && ($stamp ne '')) {
                        #"Segment","Point","Latitude (deg)","Longitude (deg)","Altitude (m)","Bearing (deg)","Accuracy (m)","Speed (m/s)","Time","Power (W)","Cadence (rpm)","Heart rate (bpm)"
                        #"1","1","51.481289","-0.607417","42.0","","38","0","2015-08-14T10:26:48.952Z","","",""
                        $phase = 'find_more_point';
                        $lastseg = $fields[0];
		                # track or new track
		                if ($tracks ne '') {
			                # not first time
			                $tracks = $tracks . "\t\t</coordinates></LineString></Placemark>\n";
		                }
                        $trkname = "Track $stamp";
		                $tracks = $tracks . 
			                "\t\t<Placemark><name>$trkname</name>\n" .
			                "\t\t\t<Style id=\"lc\"><LineStyle><color>ffffff00</color><width>4</width></LineStyle></Style>\n" .
			                "\t\t\t<LineString><styleUrl>#lc</styleUrl>\n" .
			                "\t\t\t<altitudeMode>relativeToGround</altitudeMode>\n" .
			                "\t\t\t<coordinates>\n";
                        $trackno++;
                        $pointno = 0;
                    }
                    if (($phase eq 'find_more_point') && ($stamp ne '')) {
                        if ($lastseg != $fields[0]) {
                            # new segment
                            $lastseg = $fields[0];
		                    # track or new track
		                    if ($tracks ne '') {
			                    # not first time
			                    $tracks = $tracks . "\t\t</coordinates></LineString></Placemark>\n";
		                    }
                            $trkname = "Track $stamp";
		                    $tracks = $tracks . 
			                    "\t\t<Placemark><name>$trkname</name>\n" .
			                    "\t\t\t<Style id=\"lc\"><LineStyle><color>ffffff00</color><width>4</width></LineStyle></Style>\n" .
			                    "\t\t\t<LineString><styleUrl>#lc</styleUrl>\n" .
			                    "\t\t\t<altitudeMode>relativeToGround</altitudeMode>\n" .
			                    "\t\t\t<coordinates>\n";
                            $trackno++;
                            $pointno = 0;
                        }

                        #"1","1","51.481289","-0.607417","42.0","","38","0","2015-08-14T10:26:48.952Z","","",""
                        $fields[2] += $curlatoffset;
                        $fields[3] += $curlonoffset;
		                $tracks = $tracks . "\t\t\t$fields[3],$fields[2],$trackheight\n";
                        if (($trackmark > 0) && (($pointno % $trackmark) == 0)) {
                            $trkmarks .=
                            "\t\t\t<Placemark>\n".
                            "\t\t\t\t<name>$lnno</name>\n".
                            "\t\t\t\t<styleUrl>#msn_circle</styleUrl>\n".
                            "\t\t\t\t<Point>\n".
                            "\t\t\t\t\t<coordinates>$fields[3],$fields[2],0</coordinates>\n".
                            "\t\t\t\t</Point>\n".
                            "\t\t\t</Placemark>\n";
                        }
                    }
                }
	            $tracks = $tracks . "\t\t</coordinates></LineString></Placemark>\n";
                $kmlbuf .= $tracks;
                if ($trackmark > 0) {
                    $kmlbuf .=  "		<Folder>\n".
                                "			<name>Timemark</name>\n".
                                "			<open>1</open>\n".
                                $trkmarks.
                                "		</Folder>\n";
                }
                $kmlbuf .= $kmlfooter;

                $size = length ($kmlbuf);
                $httphdr = "Content-Type: application/vnd.google-earth.kml+xml\r\n";
                $httphdr .= "Content-Length: $size\r\n";
                $httphdr .= "Connection: close\r\nServer: l00httpd\r\n";
                print $sock "HTTP/1.1 200 OK\r\n$httphdr\r\n";
                print $sock $kmlbuf;
                $sock->close;
                $rawkml = 1;
            } elsif ($form->{'path'} =~ /\.gpx$/) {
                my ($tracks, $phase, $lat_, $lon_, $desc, $debug, $trackno);
                my ($ns, $lat_d, $lad_m, $ew, $lon_d, $lon_m, $dtstamp);
                $tracks = '';
                $phase = 'find_track';
                $debug = 1;
                $trackno = 1;
                # gps track, convert to .kml
                $kmlbuf = "$kmlheader1$fname$kmlheader2";
                $trkmarks = '';

                $lnno = 0;
                $pointno = -1;
                foreach $_ (split ("\n", $buffer)) {
                    $lnno++;
                    $pointno++;
                    #<trkseg>
            	    if (($phase eq 'find_track') && 
                        (/<trkseg>/)) {
                        $phase = 'found_new_header';
                        $pointno = 0;
                    }
                    # <trkpt lat="25.106161" lon="121.529244">
                    if (/<trkpt lat="(.+?)" lon="(.+?)">/) {
                        $lat = $1;
                        $lon = $2;
                        $lat += $curlatoffset;
                        $lon += $curlonoffset;
                    }
                    # <time>2015-11-30T23:30:28Z</time>
                    if (/<time>(.+)<\/time>/) {
                        $gpxtime = $1;
                    }
                    # </trkpt>
                    if (/<\/trkpt>/) {
                        if ($phase eq 'found_new_header') {
                            $phase = 'find_track';
		                    if ($tracks ne '') {
			                    # not first time
			                    $tracks = $tracks . "\t\t</coordinates></LineString></Placemark>\n";
		                    }
		                    $tracks = $tracks . 
			                    "\t\t<Placemark><name>Track $gpxtime</name>\n" .
			                    "\t\t\t<Style id=\"lc\"><LineStyle><color>ffffff00</color><width>4</width></LineStyle></Style>\n" .
			                    "\t\t\t<LineString><styleUrl>#lc</styleUrl>\n" .
			                    "\t\t\t<altitudeMode>relativeToGround</altitudeMode>\n" .
			                    "\t\t\t<coordinates>\n";
                            $trackno++;
                        }
		                $tracks = $tracks . "\t\t\t$lon,$lat,$trackheight\n";
                        if (($trackmark > 0) && (($pointno % $trackmark) == 0)) {
                            $trkmarks .=
                            "\t\t\t<Placemark>\n".
                            "\t\t\t\t<name>$lnno</name>\n".
                            "\t\t\t\t<styleUrl>#msn_circle</styleUrl>\n".
                            "\t\t\t\t<Point>\n".
                            "\t\t\t\t\t<coordinates>$lon,$lat,0</coordinates>\n".
                            "\t\t\t\t</Point>\n".
                            "\t\t\t</Placemark>\n";
                        }
                    }
                }
	            $tracks = $tracks . "\t\t</coordinates></LineString></Placemark>\n";
                $kmlbuf .= $tracks;
                if ($trackmark > 0) {
                    $kmlbuf .=  "		<Folder>\n".
                                "			<name>Timemark</name>\n".
                                "			<open>1</open>\n".
                                $trkmarks.
                                "		</Folder>\n";
                }
                $kmlbuf .= $kmlfooter;
                #l00httpd::dbp($config{'desc'}, "kmlbuf: \n$kmlbuf\n");

                $size = length ($kmlbuf);
                $httphdr = "Content-Type: application/gpx+xml\r\n";
                $httphdr .= "Content-Length: $size\r\n";
                $httphdr .= "Connection: close\r\nServer: l00httpd\r\n";
                print $sock "HTTP/1.1 200 OK\r\n$httphdr\r\n";
                print $sock $kmlbuf;
                $sock->close;
                $rawkml = 1;
            } elsif ($buffer =~ /^<\?xml/) {
                # reading real .kml file
                print $sock "$httphdr<br>\n";
                print $sock "Extracted waypoints: <a href=\"/view.htm?path=l00://way.txt\">l00://way.txt</a>\n<pre>";
                $httphdr = '';
                &l00httpd::l00fwriteOpen($ctrl, 'l00://way.txt');
                foreach $_ (split ("\n", $buffer)) {
                    s/\r//g;
                    s/\n//g;
                    if (/<Placemark>/) {
                        $phase++;
                    } elsif (/<\/Placemark>/) {
                        print $sock "$lonlat $name\n";
                        &l00httpd::l00fwriteBuf($ctrl, "$lonlat $name\n");
                    } elsif ((/<name>(.+)<\/name>/) && ($phase != 0)) {
                        $name = $1;
                    } elsif ((/<coordinates>(.+),(.+),[0-9\-]*<\/coordinates>/) && ($phase != 0)) {
                        $lat = $1;
                        $lon = $2;
                        $lat += $curlatoffset;
                        $lon += $curlonoffset;
                        $lonlat = "$lon,$lat";
                    } elsif (/Style id/) {
                        s/</&lt;/g;
                        s/>/&gt;/g;
                    }
                }
                &l00httpd::l00fwriteClose($ctrl);
                print $sock "<\/pre>\n";
            } elsif ($buffer =~ /^H  SOFTWARE NAME & VERSION/) {
                my ($tracks, $phase, $lat_, $lon_, $desc, $debug, $trackno);
                my ($ns, $lat_d, $lad_m, $ew, $lon_d, $lon_m, $dtstamp);
                $tracks = '';
                $phase = 'find_header';
                $debug = 1;
                $trackno = 1;
                # gps track, convert to .kml
                $kmlbuf = "$kmlheader1$fname$kmlheader2";
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
		                if ($tracks ne '') {
			                # not first time
			                $tracks = $tracks . "\t\t</coordinates></LineString></Placemark>\n";
		                }
                        $trkname = "Track $trackno";
                        if (/^T +[NS].+; (.+)/) {
                            $trkname = "Track $1";
                        }
		                $tracks = $tracks . 
			                "\t\t<Placemark><name>$trkname</name>\n" .
			                "\t\t\t<Style id=\"lc\"><LineStyle><color>ffffff00</color><width>4</width></LineStyle></Style>\n" .
			                "\t\t\t<LineString><styleUrl>#lc</styleUrl>\n" .
			                "\t\t\t<altitudeMode>relativeToGround</altitudeMode>\n" .
			                "\t\t\t<coordinates>\n";
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
		                    $tracks = $tracks . "\t\t\t$lon_,$lat_,$trackheight\n";
                            if (($trackmark > 0) && (($pointno % $trackmark) == 0)) {
                                $trkmarks .=
                                "\t\t\t<Placemark>\n".
                                "\t\t\t\t<name>$lnno</name>\n".
                                "\t\t\t\t<styleUrl>#msn_circle</styleUrl>\n".
                                "\t\t\t\t<Point>\n".
                                "\t\t\t\t\t<coordinates>$lon_,$lat_,0</coordinates>\n".
                                "\t\t\t\t</Point>\n".
                                "\t\t\t</Placemark>\n";
                            }
                        }
                    }
                }
	            $tracks = $tracks . "\t\t</coordinates></LineString></Placemark>\n";
                $kmlbuf .= $tracks;
                if ($trackmark > 0) {
                    $kmlbuf .=  "		<Folder>\n".
                                "			<name>Timemark</name>\n".
                                "			<open>1</open>\n".
                                $trkmarks.
                                "		</Folder>\n";
                }
                $kmlbuf .= $kmlfooter;

                $size = length ($kmlbuf);
                $httphdr = "Content-Type: application/vnd.google-earth.kml+xml\r\n";
                $httphdr .= "Content-Length: $size\r\n";
                $httphdr .= "Connection: close\r\nServer: l00httpd\r\n";
                print $sock "HTTP/1.1 200 OK\r\n$httphdr\r\n";
                print $sock $kmlbuf;
                $sock->close;
                $rawkml = 1;
            } else {
                # reading long,lat,name file
                $kmlbuf = "$kmlheader1$fname$kmlheader2";
                foreach $_ (split ("\n", $buffer)) {
                    s/\r//g;
                    s/\n//g;
                    #-118.0347581348814,33.80816583075773,Place1
                    if (/^#/) {
                        next;
                    } elsif (($lat, $lon) = /google\.com.*maps.*@([0-9.+-]+),([0-9.+-]+),/) {
                        # Parse coordinate from Google Maps URL
                        # https://www.google.com/maps/@31.1956864,121.3522793,15z
                        # https://www.google.com/maps/place/30%C2%B012'26.5%22N+115%C2%B002'06.5%22E/@30.206403,115.0352586,19z?hl=en Sent from Maxthon Mobile : null :: action / type android.intent.action.SEND text/plain null all fail
                        if (/maps(.+)@/) {
                            # use whatever as name
                            $name = $1;
                        }
                        # match, falls thru
                    } elsif (($lat, $lon, $name) = /^([^,]+?),([^,]+?)[, ]+(.+)$/) {
                        # match, falls thru
                    } else {
                        next;
                    }
                    $lat += $curlatoffset;
                    $lon += $curlonoffset;
                    $kmlbuf .= 
		            "\t\t<Placemark>\n".
			        "\t\t\t<name>$name</name>\n".
			        "\t\t\t<styleUrl>#msn_hospitals</styleUrl>\n".
			        "\t\t\t<Point>\n".
				    "\t\t\t\t<coordinates>$lon,$lat,0</coordinates>\n".
			        "\t\t\t</Point>\n".
		            "\t\t</Placemark>\n";
                }
                $kmlbuf .= $kmlfooter;

                $size = length ($kmlbuf);
                $httphdr = "Content-Type: application/vnd.google-earth.kml+xml\r\n";
                $httphdr .= "Content-Length: $size\r\n";
                $httphdr .= "Connection: close\r\nServer: l00httpd\r\n";
                print $sock "HTTP/1.1 200 OK\r\n$httphdr\r\n";
                print $sock $kmlbuf;
                $sock->close;
                $rawkml = 1;
            }
        }
    }
    if (($rawkml == 0) && ($httphdr ne '')) {
        print $sock $httphdr;
    }


    if ($rawkml == 0) {
        print $sock "<form action=\"/kml.htm\" method=\"get\">\n";
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
        print $sock "</form>\n";


        print $sock "<form action=\"/kml.htm\" method=\"get\">\n";
        print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";

        print $sock "<tr><td>\n";
        print $sock "Track height (m):\n";
        print $sock "</td><td>\n";
        print $sock "<input type=\"text\" name=\"kml_trackheight\" value=\"$trackheight\">\n";
        print $sock "</td></tr>\n";

        print $sock "<tr><td>\n";
        print $sock "Mark every Nth (0=off):\n";
        print $sock "</td><td>\n";
        print $sock "<input type=\"text\" name=\"trackmark\" value=\"$trackmark\">\n";
        print $sock "</td></tr>\n";

        print $sock "<tr><td>\n";
        print $sock "<input type=\"submit\" name=\"set\" value=\"Set\">\n";
        print $sock "</td><td>\n";
        print $sock "<input type=\"checkbox\" name=\"applyoffset\" $applyoffset>Apply offset</td>\n";
        print $sock "</td></tr>\n";

        print $sock "<tr><td>\n";
        print $sock "Latitude offset:\n";
        print $sock "</td><td>\n";
        print $sock "<input type=\"text\" name=\"latoffset\" value=\"$latoffset\">\n";
        print $sock "</td></tr>\n";

        print $sock "<tr><td>\n";
        print $sock "Longitude offset:\n";
        print $sock "</td><td>\n";
        print $sock "<input type=\"text\" name=\"lonoffset\" value=\"$lonoffset\">\n";
        print $sock "</td></tr>\n";

        print $sock "</table>\n";
        print $sock "</form>\n";

        print $sock "Google Earth .kml processor<p>\n";

        # get submitted name and print greeting
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
}


\%config;
