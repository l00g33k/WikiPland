use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_kml_proc",
              desc => "l00http_kml_desc");

my ($kmlheader, $kmlfooter);

$kmlheader = 
    "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n".
    "<kml xmlns=\"http://www.opengis.net/kml/2.2\" xmlns:gx=\"http://www.google.com/kml/ext/2.2\" xmlns:kml=\"http://www.opengis.net/kml/2.2\" xmlns:atom=\"http://www.w3.org/2005/Atom\">\n".
    "<Document>\n".
    "	<name>kml.kml</name>\n".
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
    my ($lat, $lon, $name);
    $rawkml = 0;

    # create HTTP and HTML headers
    $httphdr = "$ctrl->{'httphead'}$ctrl->{'htmlhead'}$ctrl->{'htmlttl'}$ctrl->{'htmlhead2'}";
    $httphdr .= "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a><br>\n";
    if (defined ($form->{'path'})) {
        $httphdr .= "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";
    }


    if ((defined ($form->{'path'})) && 
        (length ($form->{'path'}) > 0)) {
        if ($form->{'path'} =~ /\.kmz$/) {
            # .kmz
            if (open (IN, "<$form->{'path'}")) {
                local ($/);
                my ($slash);
                $slash = $/;
                $/ = undef;
                $buffer = <IN>;
                close (IN);
                $/ = $slash;

                $size = length ($buffer);
                $httphdr = "Content-Type: application/vnd.google-earth.kml+xml\r\n";
                $httphdr .= "Content-Length: $size\r\n";
                $httphdr .= "Connection: close\r\nServer: l00httpd\r\n";
                print $sock "HTTP/1.1 200 OK\r\n$httphdr\r\n";
                print $sock $buffer;
                $sock->close;
                $rawkml = 1;
            }
        } elsif (open (IN, "<$form->{'path'}")) {
            local ($/);
            my ($slash, $phase, $lonlat, $name);
            $slash = $/;
            $/ = undef;
            $buffer = <IN>;
            close (IN);
            # Maverick has only \r as line endings. So convert DOS \r\n to Unix \n
            # then convert Maverick's \r to Unix \n
            $buffer =~ s/\r\n/\n/g;
            $buffer =~ s/\r/\n/g;
            $/ = $slash;
            $phase = 0;
            if ($buffer =~ /^<\?xml/) {
                # reading real .kml file
                print $sock "$httphdr<pre>\n";
                $httphdr = '';
                foreach $_ (split ("\n", $buffer)) {
                    s/\r//g;
                    s/\n//g;
                    if (/<Placemark>/) {
                        $phase++;
                    } elsif (/<\/Placemark>/) {
                        print $sock "$lonlat,$name\n";
                    } elsif ((/<name>(.+)<\/name>/) && ($phase != 0)) {
                        $name = $1;
                    } elsif ((/<coordinates>(.+),(.+),0<\/coordinates>/) && ($phase != 0)) {
                        $lonlat = "$1,$2";
                    } elsif (/Style id/) {
                        s/</&lt;/g;
                        s/>/&gt;/g;
                    }
                }
                print $sock "<\/pre>\n";
            } elsif ($buffer =~ /^H  SOFTWARE NAME & VERSION/) {
                my ($tracks, $phase, $lat_, $lon_, $desc, $debug, $trackno);
                my ($ns, $lat_d, $lad_m, $ew, $lon_d, $lon_m, $dtstamp);
                $tracks = '';
                $phase = 'find_header';
                $debug = 1;
                $trackno = 1;
                # gps track, convert to .kml
                $kmlbuf = $kmlheader;

                foreach $_ (split ("\n", $buffer)) {
                    #H  LATITUDE    LONGITUDE    DATE      TIME     ALT    ;track
            	    if ((($phase eq 'find_header') ||
                         ($phase eq 'find_more_point')) && 
                        (/^H  LATITUDE    LONGITUDE/)) {
                        $phase = 'found_header';
                    #T  N3110.27551 E12123.28069 10-Apr-11 05:57:36    7 ; gps 20110410 135759
                    } elsif (($phase eq 'found_header') && 
                        (/^T +[NS]/)) {
                        $phase = 'find_more_point';
		                # track or new track
		                if ($tracks ne '') {
			                # not first time
			                $tracks = $tracks . "\t\t</coordinates></LineString></Placemark>\n";
		                }
		                $tracks = $tracks . 
			                "\t\t<Placemark><name>Track $trackno</name>\n" .
			                "\t\t\t<Style id=\"lc\"><LineStyle><color>ffffff00</color></LineStyle></Style>\n" .
			                "\t\t\t<LineString><styleUrl>#lc</styleUrl>\n" .
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
		                    $tracks = $tracks . "\t\t\t$lon_,$lat_\n";
                        }
                    }
                }
	            $tracks = $tracks . "\t\t</coordinates></LineString></Placemark>\n";
                $kmlbuf .= $tracks;
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
                $kmlbuf = $kmlheader;
                foreach $_ (split ("\n", $buffer)) {
                    s/\r//g;
                    s/\n//g;
                    #-118.0347581348814,33.80816583075773,Place1
                    if (/^#/) {
                        next;
                    } elsif (($lon, $lat, $name) = /^([^,]+),([^,]+)[, ]+(.+)$/) {
                        $kmlbuf .= 
		                "\t\t<Placemark>\n".
			            "\t\t\t<name>$name</name>\n".
			            "\t\t\t<styleUrl>#msn_hospitals</styleUrl>\n".
			            "\t\t\t<Point>\n".
				        "\t\t\t\t<coordinates>$lon,$lat,0</coordinates>\n".
			            "\t\t\t</Point>\n".
		                "\t\t</Placemark>\n";
                    }
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
        print $sock "Google Earth .kml processor\n";
        print $sock "</td></tr>\n";
        print $sock "</table>\n";
        print $sock "</form>\n";

        # get submitted name and print greeting
        $lineno = 1;
        if (open (IN, "<$form->{'path'}")) {
            print $sock "<pre>\n";
            while (<IN>) {
                s/\r//g;
                s/\n//g;
                s/</&lt;/g;
                s/>/&gt;/g;
                print $sock sprintf ("%04d: ", $lineno++) . "$_\n";
            }
            close (IN);
            print $sock "</pre>\n";
        }

        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
    }
}


\%config;
