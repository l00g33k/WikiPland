use strict;
use warnings;
use l00svg;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# GPS map without data connection

my $lon = 0;
my $lat = 0;
my $path = '';
my $map = '';
my $marker = 'X';
my $color = 'ff0000';
my $movestep = 10;
my $waypts = '';
my $waycolor = '0000ff';
my $lastpath = '';
my $lastgps = 0;
my $lastres = '';
my $marklon = 0;
my $marklat = 0;
my $scale = 100;
my $pcx5mk = 'a';
my $skipxgpstrk = 0;

my $maptlx = 0;
my $maptly = 0;
my $mapbrx = 99;
my $mapbry = 99;

my $maptllon = -1;
my $maptllat = 1;
my $mapbrlon = 1;
my $mapbrlat = -1;

my ($fname);

my %config = (proc => "l00http_gpsmapsvg_proc",
              desc => "l00http_gpsmapsvg_desc");



sub ll2xysvg {
    my ($lonhtm, $lathtm) = @_;
    my ($pixx, $pixy, $notclip);
    $notclip = 1;

#print ",,,($lonhtm > $mapbrlon) { $lonhtm = $mapbrlon; \n";
#print ",,,($lonhtm < $maptllon) { $lonhtm = $maptllon; \n";
#print ",,,($lathtm > $maptllat) { $lathtm = $maptllat; \n";
#print ",,,($lathtm < $mapbrlat) { $lathtm = $mapbrlat; \n";


    if ($lonhtm > $mapbrlon) { $lonhtm = $mapbrlon; $notclip = 0; print "point over the right\n";}
    if ($lonhtm < $maptllon) { $lonhtm = $maptllon; $notclip = 0; print "point over the left\n";}
    if ($lathtm > $maptllat) { $lathtm = $maptllat; $notclip = 0; print "point over the top\n";}
    if ($lathtm < $mapbrlat) { $lathtm = $mapbrlat; $notclip = 0; print "point over the bottom\n";}
    $pixx = $maptlx + int (($lonhtm - $maptllon) / ($mapbrlon - $maptllon) * $mapbrx * $scale / 100);
    $pixy = int ($mapbry * $scale / 100) 
                    - int (($lathtm - $mapbrlat) / ($maptllat - $mapbrlat) * $mapbry * $scale / 100);

    ($pixx, $pixy, $notclip);
}

sub xy2llsvg {
    my ($pixx, $pixy) = @_;
    my ($lonhtm, $lathtm);

    $lonhtm = $maptllon + ($pixx - $maptlx) / ($mapbrx - $maptlx) * ($mapbrlon - $maptllon) * 100 / $scale;
    $lathtm = $maptllat - ($pixy - $maptly) / ($mapbry - $maptly) * ($maptllat - $mapbrlat) * 100 / $scale;
#print ",,, $lonhtm = $maptllon + ($pixx - $maptlx) / ($mapbrx - $maptlx) * ($mapbrlon - $maptllon) * 100 / $scale; \n";
#print ",,, $lathtm = $maptllat - ($pixy - $maptly) / ($mapbry - $maptly) * ($maptllat - $mapbrlat) * 100 / $scale; \n";

    ($lonhtm, $lathtm);
}

sub l00http_gpsmapsvg_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/

    "gpsmapsvg: GPS mapping wothout data connection using SVG overlay";
}

sub l00http_gpsmapsvg_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($pixx, $pixy, $buf, $lonhtm, $lathtm, $dist, $xx, $yy);
    my ($mapwd, $mapht, $lond, $lonm, $lonc, $latd, $latm, $latc);
    my ($notclip, $coor, $tmp, $nogpstrks, $svgout, $svg, $state);

    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        ($fname) = $path =~ /\/([^\/]+)$/;
        $map = $path;
        $map =~ s/\.[^\.]+$/.map/;
    }
    # map clicked
    if (defined ($form->{'x'})) {
        ($lon, $lat) = &xy2llsvg ($form->{'x'}, $form->{'y'});
    }
    # mark point
    if (defined ($form->{'mark'})) {
        $marklon = $lon;
        $marklat = $lat;
    }

    if (defined ($form->{'movestep'})) {
        $movestep = $form->{'movestep'};
    }
    if (defined ($form->{'movec'})) {
        $lon = ($mapbrlon + $maptllon) / 2;
        $lat = ($maptllat + $mapbrlat) / 2;
    }
    if (defined ($form->{'movelu'})) {
        $lon -= ($mapbrlon - $maptllon) / $movestep;
        $lat += ($maptllat - $mapbrlat) / $movestep;
    }
    if (defined ($form->{'moveu'})) {
        $lat += ($maptllat - $mapbrlat) / $movestep;
    }
    if (defined ($form->{'moveru'})) {
        $lon += ($mapbrlon - $maptllon) / $movestep;
        $lat += ($maptllat - $mapbrlat) / $movestep;
    }
    if (defined ($form->{'movel'})) {
        $lon -= ($mapbrlon - $maptllon) / $movestep;
    }
    if (defined ($form->{'mover'})) {
        $lon += ($mapbrlon - $maptllon) / $movestep;
    }
    if (defined ($form->{'moveld'})) {
        $lon -= ($mapbrlon - $maptllon) / $movestep;
        $lat -= ($maptllat - $mapbrlat) / $movestep;
    }
    if (defined ($form->{'moved'})) {
        $lat -= ($maptllat - $mapbrlat) / $movestep;
    }
    if (defined ($form->{'moverd'})) {
        $lon += ($mapbrlon - $maptllon) / $movestep;
        $lat -= ($maptllat - $mapbrlat) / $movestep;
    }
    if (defined ($form->{'scale'})) {
        $scale = $form->{'scale'};
    }
    if (defined ($form->{'skipxgpstrk'})) {
        $skipxgpstrk = $form->{'skipxgpstrk'};
    }
    if (defined ($form->{'dispwaypts'})) {
        if (defined ($form->{'waypts'})) {
            $waypts = $form->{'waypts'};
        }
        if (defined ($form->{'waycolor'})) {
            $waycolor = $form->{'waycolor'};
        }
    }
    if (defined ($form->{'set'})) {
        if (defined ($form->{'lon'})) {
            $lon = $form->{'lon'};
        }
        if (defined ($form->{'lat'})) {
            $lat = $form->{'lat'};
        }
        if (defined ($form->{'marker'})) {
            $marker = $form->{'marker'};
        }
        if (defined ($form->{'color'})) {
            $color = $form->{'color'};
        }
    }
    if (defined ($form->{'submit'})) {
        if ($ctrl->{'os'} eq 'and') {
            $buf = $ctrl->{'droid'}->getLastKnownLocation();
        }
        #$buf=$ctrl->{'droid'}->readLocation();
        if (ref $buf->{'result'}->{'network'} eq 'HASH') {
            $coor = $buf->{'result'}->{'network'};
        }
        # 'network' is always available whenever phone is on GSM network
        # put 'gps' second so as to always use gps even when network
        # is available.^M
        if (ref $buf->{'result'}->{'gps'} eq 'HASH') {
            $coor = $buf->{'result'}->{'gps'};
        }

        $lastgps = time;
        $lastres = "Timestamp when GPS was read  : " . $lastgps;
        $lastres .= " = $ctrl->{'now_string'}\n";
        $lastres .= "Timestamp of GPS record: $buf->{'result'}->{'gps'}->{'provider'} @ $buf->{'result'}->{'gps'}->{'time'}\n";

        $lon = $coor->{'longitude'};
        $lat = $coor->{'latitude'};
    }

    if (open (IN, "<$map")) {

        $_ = <IN>; s/\n//; s/\r//; ($maptlx) = / *([^ ]+) */;
        $_ = <IN>; s/\n//; s/\r//; ($maptly) = / *([^ ]+) */;
        $_ = <IN>; s/\n//; s/\r//; ($maptllon) = / *([^ ]+) */;
        $_ = <IN>; s/\n//; s/\r//; ($maptllat) = / *([^ ]+) */;
        $_ = <IN>; s/\n//; s/\r//; ($mapbrx) = / *([^ ]+) */;
        $_ = <IN>; s/\n//; s/\r//; ($mapbry) = / *([^ ]+) */;
        $_ = <IN>; s/\n//; s/\r//; ($mapbrlon) = / *([^ ]+) */;
        $_ = <IN>; s/\n//; s/\r//; ($mapbrlat) = / *([^ ]+) */;
        $_ = <IN>; s/\n//; s/\r//;
        if (/^IMG_WD_HT/) {
            ($mapwd, $mapht) = /^IMG_WD_HT=(\d+),(\d+)/;
            $mapwd = int ($mapwd * $scale / 100);
            $mapht = int ($mapht * $scale / 100);
		} else {
            $mapwd = int (($mapbrx + 1) * $scale / 100);
            $mapht = int (($mapbry + 1) * $scale / 100);
		}
        close (IN);
        l00httpd::dbp($config{'desc'}, "mapwd $mapwd mapht $mapht\n");
    }


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>gpsmapsvg</title>" . $ctrl->{'htmlhead2'};

    if (open (IN, "<$path")) {
        close (IN);
        if ($lastpath ne $path) {
            $lastpath = $path;
            $lon = ($mapbrlon + $maptllon) / 2;
            $lat = ($maptllat + $mapbrlat) / 2;
        }

#        print $sock "<img width=\"$mapwd\" height=\"$mapht\" src=\"/ls.htm$path?path=$path".'&'."raw=on\">\n";

        ($pixx, $pixy, $notclip) = &ll2xysvg ($lon, $lat);
#print ",,,left:$pixx"."px; top:$pixy"."px $notclip\n";
        if ($notclip) {
            print $sock "<div style=\"position: absolute; left:$pixx"."px; top:$pixy"."px;\">\n";
            print $sock "<font color=\"$color\">$marker</font></div>\n";
        }

        $svg = '';
        $state = 0; # 0=nothing, 1=in track, 2=track ends
        if (open (WAY, "<$waypts")) {
            $pcx5mk = 'a';
            $nogpstrks = 0;
            while (<WAY>) {
                s/\n//g;
                s/\r//g;
                #H LATITUDE LONGITUDE D 
                #T N3349.55432 W11802.27042 16-Aug-10 07:11:57 -9
                #my $pcx5mk = 'a';
                if (/^H +LATITUDE +LONGITUDE /) {
                    $pcx5mk++;
                    $nogpstrks++;
                }
                if (/^T +([NS])(\d\d)([0-9.\-]+) +([EW])(\d\d\d)([0-9.\-]+)/) {
                    # 0=nothing, 1=in track, 2=track ends
                    if ($state == 2) {
                        # more than one track
                        $svg .= '::';
                    }
                    if ($state != 1) {
                        $state = 1;
                    }

                    #print "$1 $2 $3 $4 $5 $6  ";
                    my ($plon, $plat);
                    $plon = $5 + $6 / 60;
                    $plat = $2 + $3 / 60;
                    if ($4 eq 'W') {
                        $plon = -$plon;
                    }
                    if ($1 eq 'S') {
                        $plat = -$plat;
                    }
                    ($pixx, $pixy, $notclip) = &ll2xysvg ($plon, $plat);
                    #print "$1 $4 $plat $plon ";
                    #print "$pcx5mk $pixx $pixy $notclip\n";
                    if ($notclip) {
                        if (($skipxgpstrk == 0) || ($nogpstrks > $skipxgpstrk)) {
                            $pixy = $mapht - $pixy;     # y axis inverted
                            $svg .= "$pixx,$pixy ";
                        }
                    }
                } else {
                    if ($state == 1) {
                        # track ends
                        $state = 2;
                    }
                }
                if (/^([0-9.\-]+),([0-9.\-]+)[ ,]+([^ ].*)$/) {
                    ##long,lat,name
                    #121.386309,31.171295,Huana
                    ($pixx, $pixy, $notclip) = &ll2xysvg ($1, $2);
                    if ($notclip) {
                        print $sock "<div style=\"position: absolute; left:$pixx"."px; top:$pixy"."px;\">\n";
                        print $sock "<font color=\"$waycolor\">$3</font></div>\n";
                    }
                }
            }
            close (WAY);

            &l00svg::plotsvgmapoverlay ($fname, $svg, $mapwd, $mapht, $path);
            $svgout = '';
            $svgout .= "<svg  x=\"0\" y=\"0\" width=\"$mapwd\" height=\"$mapht\"xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" xml:space=\"preserve\" viewBox=\"0 0 $mapwd $mapht\" preserveAspectRatio=\"xMidYMid meet\">";
            $svgout .= "<g id=\"bitmap\" style=\"display:online\"> ";
            $svgout .= "<image x=\"0\" y=\"0\" width=\"$mapwd\" height=\"$mapht\" xlink:href=\"/ls.htm$path?path=$path\" /> ";
            $svgout .= "</g> ";
            $svgout .= "<g id=\"$fname\" style=\"display:online\"> <g transform=\"translate(0 0)\"> <g transform=\"scale(1.0)\"> <image x=\"0\" y=\"0\" width=\"$mapwd\" height=\"$mapht\" xlink:href=\"/svg.htm?graph=$fname\"/> </g> </g> </g>";
            $svgout .= "</svg>\n";
            print $sock "$svgout<br>\n";
            # the following doesn't work (see l00svg.pm)
            #print $sock "<img src=\"/svg.htm/svg.svg?graph=${fname}.ovly.svg\"><br>\n";
        } else {
            # no overlaid track. .png will do
            print $sock "<img src=\"/ls.htm$path?path=$path".'&'."raw=on\"><br>\n";
        }

        print $sock "<hr>";
        print $sock "<a href=\"#ctrl\">Jump to control</a>.  \n";
        print $sock "Click map below to move cursor:<br>\n";
        print $sock "<form action=\"/gpsmapsvg.htm\" method=\"get\">\n";
        print $sock "<input type=image width=$mapwd height=$mapht src=\"/ls.htm$path?path=$path".'&'."raw=on\">\n";
        # the following doesn't work (see l00svg.pm)
        #print $sock "<input type=image width=$mapwd height=$mapht src=\"/svg.htm/svg.svg?graph=singapore.png.ovly.svg\">\n";
        print $sock "</form>\n";
    }

    print $sock "<p>pixel (x,y): $pixx,$pixy<br>\n";
    print $sock "Co-or (lat,long): $lat,$lon<br>\n";
    print $sock "Marker (lat,long): $marklat,$marklon<br>\n";
    $xx = abs ($lon - $marklon) * cos (($lat + $marklat) / 2 / 180 * 3.141592653589793) / 360 * 40000;
    $yy = abs ($lat - $marklat) / 360 * 40000;
    $dist = sqrt ($xx * $xx + $yy * $yy);
    print $sock "Distance (km): $dist<br>\n";

    print $sock "Map: $map\n";
    if (defined ($form->{'x'})) {
        print $sock "<br>Clicked pixel (x,y): $form->{'x'},$form->{'y'}\n";
    }
    if ($lon < 0) {
        $lond = -$lon;
        $lonc = 'W';
    } else {
        $lond = $lon;
        $lonc = 'E';
    }
    if ($lat < 0) {
        $latd = -$lat;
        $latc = 'S';
    } else {
        $latd = $lat;
        $latc = 'N';
    }
    #N33 49.510 W118 02.351
    $lonm = ($lond - int ($lond)) * 60;
    $lond = int ($lond);
    $latm = ($latd - int ($latd)) * 60;
    $latd = int ($latd);
    print $sock "<br><pre>". sprintf ("%s%d %06.3f %s%d %06.3f", 
        $latc, $latd, $latm, $lonc, $lond, $lonm) ."\n$lastres</pre>\n";




    print $sock "<p>$ctrl->{'home'} \n";
    print $sock "$ctrl->{'HOME'} \n";
    print $sock "<a href=\"/ls.htm?path=$map\">$map</a>\n";
    print $sock "<a name=\"ctrl\"></a><p>\n";

    print $sock "<form action=\"/gpsmapsvg.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td>lon:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"lon\" value=\"$lon\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>lat:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"lat\" value=\"$lat\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>path:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"path\" value=\"$path\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Marker:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"marker\" value=\"$marker\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Color:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"color\" value=\"$color\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Scale:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"scale\" value=\"$scale\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Read GPS\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"set\" value=\"Set\"> <input type=\"submit\" name=\"movec\" value=\"Ctr\"> <input type=\"submit\" name=\"mark\" value=\"Mark\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "<p>Waypoints:<br>\n";

    print $sock "<form action=\"/gpsmapsvg.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";
    print $sock "        <tr>\n";
    print $sock "            <td>Waypoint files:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"waypts\" value=\"$waypts\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Color:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"waycolor\" value=\"$waycolor\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Skip # GPS tracks:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"skipxgpstrk\" value=\"$skipxgpstrk\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"dispwaypts\" value=\"Display waypoints\"></td>\n";
    print $sock "        <td>Load from file</td>\n";
    print $sock "    </tr>\n";
    print $sock "</table>\n";
    print $sock "</form>\n";

    if ($waypts ne '') {
        print $sock "There are $nogpstrks GPS tracks<br>\n";
        print $sock "Edit waypoint/track file: <a href=\"/edit.htm?path=$waypts\">$waypts</a><p>\n";
    }

    if (open (IN, "<$map")) {
        print $sock "Map file: $map<pre>\n";
        print $sock "maptlx $maptlx";
        print $sock "maptly $maptly";
        print $sock "maptllon $maptllon";
        print $sock "maptllat $maptllat";
        print $sock "mapbrx $mapbrx";
        print $sock "mapbry $mapbry";
        print $sock "mapbrlon $mapbrlon";
        print $sock "mapbrlat $mapbrlat";

        print $sock "(dumping $map)\n";

        while (<IN>) {
            print $sock "$_";
        }
        print $sock "</pre>\n";
        close (IN);
    }

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
