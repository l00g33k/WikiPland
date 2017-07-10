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
my $waycolor = '00ff00';
my $lastpath = '';
my $lastgps = 0;
my $lastres = '';
my $marklon = 0;
my $marklat = 0;
my $scale = 100;
my $pcx5mk = 'a';

# track filter
my $starttrack = 1;
my $startpoint = 0;
my $stoptrack = 9999;
my $stoppoint = 99999;
my $marktrack = 1;
my $markpoint = 1;

# long/lat to screen X/Y conversion parameters
# There are read from .map file
my $maptlx = 0;
my $maptly = 0;
my $mapbrx = 99;
my $mapbry = 99;

# The scales of the map
# Initially read from .map file.
# Modify if 'Force map to fit track
my $maptllon = -1;
my $maptllat = 1;
my $mapbrlon = 1;
my $mapbrlat = -1;

# The extends of the map
my $mapextend_tllon = -1;
my $mapextend_tllat = 1;
my $mapextend_brlon = 1;
my $mapextend_brlat = -1;

my $setlatlonvals = '';

my ($fname, $mapwd, $mapht, $fitmapphase);

$fitmapphase = 0;
# 0: normal
# 1: initialize for bounds search
# 2: bounds search completed
# -1: use bounds search results

my %config = (proc => "l00http_gpsmapsvg_proc",
              desc => "l00http_gpsmapsvg_desc");


# converts lon/lat to screen x/y coordinate
sub ll2xysvg {
    my ($lonhtm, $lathtm) = @_;
    my ($pixx, $pixy, $notclip);
    $notclip = 1;

    if ($lonhtm > $mapextend_brlon) { $lonhtm = $mapextend_brlon; $notclip = 0; }
    if ($lonhtm < $mapextend_tllon) { $lonhtm = $mapextend_tllon; $notclip = 0; }
    if ($lathtm > $mapextend_tllat) { $lathtm = $mapextend_tllat; $notclip = 0; }
    if ($lathtm < $mapextend_brlat) { $lathtm = $mapextend_brlat; $notclip = 0; }
    $pixx = $maptlx + int (($lonhtm - $maptllon) / ($mapbrlon - $maptllon) * ($mapbrx - $maptlx) * $scale / 100);
    $pixy = int ($mapbry * $scale / 100) 
                    - int (($lathtm - $mapbrlat) / ($maptllat - $mapbrlat) * ($mapbry - $maptly) * $scale / 100);

    ($pixx, $pixy, $notclip);
}

# converts screen x/y coordinate to lon/lat
sub xy2llsvg {
    my ($pixx, $pixy) = @_;
    my ($lonhtm, $lathtm);

    $lonhtm = $maptllon + ($pixx - $maptlx) / ($mapbrx - $maptlx) * ($mapbrlon - $maptllon) * 100 / $scale;
    $lathtm = $maptllat - ($pixy - $maptly) / ($mapbry - $maptly) * ($maptllat - $mapbrlat) * 100 / $scale;
    #print ",,, $lonhtm = $maptllon + ($pixx - $maptlx) / ($mapbrx - $maptlx) * ($mapbrlon - $maptllon) * 100 / $scale; \n";
    #print ",,, $lathtm = $maptllat - ($pixy - $maptly) / ($mapbry - $maptly) * ($maptllat - $mapbrlat) * 100 / $scale; \n";

    #print "x,y ($pixx, $pixy) -> lat,long ($lathtm, $lonhtm)\n";

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
    my ($pixx, $pixy, $pixx0, $pixy0, $buf, $lonhtm, $lathtm, $dist, $xx, $yy);
    my ($lond, $lonm, $lonc, $latd, $latm, $latc, $trackmark, $trackmarkcnt);
    my ($notclip, $coor, $tmp, $nogpstrks, $svgout, $svg, $state, $lnno);
    my ($tracknpts, $nowyptthistrack, $displaypt, $rawstartstop, $firstptsintrack);
    my ($fitmapmaxlon, $fitmapminlon, $fitmapmaxlat, $fitmapminlat);
    my ($plon, $plat, $needredraw);

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
    # start and stop track/points
    if (defined ($form->{'starttrack'}) &&
        ($form->{'starttrack'} =~ /(\d+)/)) {
        $starttrack = $1;
    }
    if (defined ($form->{'startpoint'}) &&
        ($form->{'startpoint'} =~ /(\d+)/)) {
        $startpoint = $1;
    }
    if (defined ($form->{'stoptrack'}) &&
        ($form->{'stoptrack'} =~ /(\d+)/)) {
        $stoptrack = $1;
    }
    if (defined ($form->{'stoppoint'}) &&
        ($form->{'stoppoint'} =~ /(\d+)/)) {
        $stoppoint = $1;
    }
    if (defined ($form->{'dispwaypts'})) {
        if (defined ($form->{'waypts'})) {
            $waypts = $form->{'waypts'};
        }
        if (defined ($form->{'waycolor'})) {
            $waycolor = $form->{'waycolor'};
        }
        $fitmapphase = 0;
        if (defined ($form->{'fittrack'}) && ($form->{'fittrack'} eq 'on')) {
            $fitmapphase = 1;
        }
    }
    # mark point
    if (defined ($form->{'marktrack'}) &&
        ($form->{'marktrack'} =~ /(\d+)/)) {
        $marktrack = $1;
        $form->{'markpointdo'} = 'simulated';
    }
    if (defined ($form->{'markpoint'}) &&
        ($form->{'markpoint'} =~ /(\d+)/)) {
        $markpoint = $1;
        $form->{'markpointdo'} = 'simulated';
    }
    if (defined ($form->{'markleftleft'})) {
        $markpoint -= 500;
        if ($markpoint < 0) {
            $markpoint = 0;
        }
        $form->{'markpointdo'} = 'simulated';
    }
    if (defined ($form->{'markleft'})) {
        $markpoint -= 1;
        if ($markpoint < 0) {
            $markpoint = 0;
        }
        $form->{'markpointdo'} = 'simulated';
    }
    if (defined ($form->{'markright'})) {
        $markpoint += 1;
    }
    if (defined ($form->{'markrightright'})) {
        $markpoint += 500;
    }

    if (defined ($form->{'cb2wfile'})) {
        $waypts = &l00httpd::l00getCB($ctrl);
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


    if (defined ($form->{'cbpaste'})) {
        if (($lat,$lon) = &l00httpd::l00getCB($ctrl) =~ /([0-9\.\+\-]+) *, *([0-9\.\+\-]+)/) {
            $setlatlonvals = "$lat,$lon";
        }
    }
    if (defined ($form->{'settl'}) &&
        defined ($form->{'setlatlon'}) &&
        (($lat,$lon) = $form->{'setlatlon'} =~ /([0-9\.\+\-]+) *, *([0-9\.\+\-]+)/)) {
        # set cursor as Top Left in .map
        if (&l00httpd::l00fwriteOpen($ctrl, $map)) {
            &l00httpd::l00fwriteBuf($ctrl, 
                "$form->{'x'}      # line 1: x of top left of graphic map\n".
                "$form->{'y'}      # line 2: y of top left of graphic map\n".
                "$lon    # line 3: longitude of top left of map\n".
                "$lat    # line 4: latitude of top left of map\n".
                "$mapbrx      # line 5: x of bottom right of graphic map\n".
                "$mapbry      # line 6: y of bottom right of graphic map\n".
                "$mapbrlon    # line 7: longitude of bottom right of map\n".
                "$mapbrlat    # line 8: latitude of bottom right of map\n".
                "IMG_WD_HT=$mapwd,$mapht\n"
                );
            &l00httpd::l00fwriteClose($ctrl);
        }
        $setlatlonvals = '';
    }
    if (defined ($form->{'setbr'}) &&
        defined ($form->{'setlatlon'}) &&
        (($lat,$lon) = $form->{'setlatlon'} =~ /([0-9\.\+\-]+) *, *([0-9\.\+\-]+)/)) {
        # set cursor as Top Left in .map
        if (&l00httpd::l00fwriteOpen($ctrl, $map)) {
            &l00httpd::l00fwriteBuf($ctrl, 
                "$maptlx      # line 1: x of top left of graphic map\n".
                "$maptly      # line 2: y of top left of graphic map\n".
                "$maptllon    # line 3: longitude of top left of map\n".
                "$maptllat    # line 4: latitude of top left of map\n".
                "$form->{'x'}      # line 5: x of bottom right of graphic map\n".
                "$form->{'y'}      # line 6: y of bottom right of graphic map\n".
                "$lon    # line 7: longitude of bottom right of map\n".
                "$lat    # line 8: latitude of bottom right of map\n".
                "IMG_WD_HT=$mapwd,$mapht\n"
                );
            &l00httpd::l00fwriteClose($ctrl);
        }
        $setlatlonvals = '';
    }

    if ($fitmapphase == 0) {
        if (&l00httpd::l00freadOpen($ctrl, $map)) {
            $_ = &l00httpd::l00freadLine($ctrl); s/\n//; s/\r//; ($maptlx) = / *([^ ]+) */;
            $_ = &l00httpd::l00freadLine($ctrl); s/\n//; s/\r//; ($maptly) = / *([^ ]+) */;
            $_ = &l00httpd::l00freadLine($ctrl); s/\n//; s/\r//; ($maptllon) = / *([^ ]+) */;
            $_ = &l00httpd::l00freadLine($ctrl); s/\n//; s/\r//; ($maptllat) = / *([^ ]+) */;
            $_ = &l00httpd::l00freadLine($ctrl); s/\n//; s/\r//; ($mapbrx) = / *([^ ]+) */;
            $_ = &l00httpd::l00freadLine($ctrl); s/\n//; s/\r//; ($mapbry) = / *([^ ]+) */;
            $_ = &l00httpd::l00freadLine($ctrl); s/\n//; s/\r//; ($mapbrlon) = / *([^ ]+) */;
            $_ = &l00httpd::l00freadLine($ctrl); s/\n//; s/\r//; ($mapbrlat) = / *([^ ]+) */;
            $_ = &l00httpd::l00freadLine($ctrl); s/\n//; s/\r//;
            if (/^IMG_WD_HT/) {
                ($mapwd, $mapht) = /^IMG_WD_HT=(\d+),(\d+)/;
                $mapwd = int ($mapwd * $scale / 100);
                $mapht = int ($mapht * $scale / 100);
		    } else {
                $mapwd = int (($mapbrx + 1) * $scale / 100);
                $mapht = int (($mapbry + 1) * $scale / 100);
		    }
            # compute map extends
            $mapextend_tllon = $maptllon - ($maptlx)              / ($mapbrx - $maptlx) * ($mapbrlon - $maptllon);
            $mapextend_tllat = $maptllat + ($maptly)              / ($mapbry - $maptly) * ($maptllat - $mapbrlat);
            $mapextend_brlon = $mapbrlon + ($mapwd - 1 - $mapbrx) / ($mapbrx - $maptlx) * ($mapbrlon - $maptllon);
            $mapextend_brlat = $mapbrlat - ($mapht - 1 - $mapbry) / ($mapbry - $maptly) * ($maptllat - $mapbrlat);

            #print "scale : tl lat,lon: $maptllat, $maptllon\n";
            #print "scale : br lat,lon: $mapbrlat, $mapbrlon\n";
            #print "extent: tl lat,lon: $mapextend_tllat, $mapextend_tllon\n";
            #print "extent: br lat,lon: $mapextend_brlat, $mapextend_brlon\n";

        } else {
            # .map file doesn't exist, create it.
            if (&l00httpd::l00fwriteOpen($ctrl, $map)) {
                &l00httpd::l00fwriteBuf($ctrl, 
                    "10      # line 1: x of top left of graphic map\n".
                    "10      # line 2: y of top left of graphic map\n".
                    "-180    # line 3: longitude of top left of map\n".
                    "90      # line 4: latitude of top left of map\n".
                    "390     # line 5: x of bottom right of graphic map\n".
                    "290     # line 6: y of bottom right of graphic map\n".
                    "180     # line 7: longitude of bottom right of map\n".
                    "-90     # line 8: latitude of bottom right of map\n".
                    "IMG_WD_HT=400,300\n"
                    );
                &l00httpd::l00fwriteClose($ctrl);
            }
        }
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

        ($pixx, $pixy, $notclip) = &ll2xysvg ($lon, $lat);
        #print ",,,left:$pixx"."px; top:$pixy"."px $notclip\n";
        if ($notclip) {
            print $sock "<div style=\"position: absolute; left:$pixx"."px; top:$pixy"."px;\">\n";
            print $sock "<font color=\"$color\">$marker</font></div>\n";
        }

        $svg = '';
        $state = 0; # 0=nothing, 1=in track, 2=track ends
        if (&l00httpd::l00freadOpen($ctrl, $waypts)) {
            $pcx5mk = 'a';
            $nogpstrks = 0;
            $tracknpts = '';
            $nowyptthistrack = 0;
            $rawstartstop = '';
            $firstptsintrack = 0;
            $pixx0 = -1;
            $trackmarkcnt = 0;
            $lnno = 0;

            # if map extend is extended, redraw
            $needredraw = 0;

            while (1) {
                if ($ctrl->{'debug'} >= 3) {
                    l00httpd::dbp($config{'desc'}, "mapwd $mapwd mapht $mapht\n");
                    l00httpd::dbp($config{'desc'}, "scale : tl lat,lon: $maptllat, $maptllon\n");
                    l00httpd::dbp($config{'desc'}, "scale : br lat,lon: $mapbrlat, $mapbrlon\n");
                    l00httpd::dbp($config{'desc'}, "extent: tl lat,lon: $mapextend_tllat, $mapextend_tllon\n");
                    l00httpd::dbp($config{'desc'}, "extent: br lat,lon: $mapextend_brlat, $mapextend_brlon\n");
                }
                while ($_ = &l00httpd::l00freadLine($ctrl)) {
                    $lnno++;
                    s/\n//g;
                    s/\r//g;
                    #H LATITUDE LONGITUDE D 
                    #T N3349.55432 W11802.27042 16-Aug-10 07:11:57 -9
                    #my $pcx5mk = 'a';
                    if (/^H +LATITUDE +LONGITUDE /) {
                        $pcx5mk++;
                        $nogpstrks++;
                        if ($tracknpts ne '') {
                            $tracknpts .= sprintf("%4d track points: $firstptsintrack\n", $nowyptthistrack);
                        }
                        $tracknpts .= sprintf("Track %3d: ", $nogpstrks);;
                        $nowyptthistrack = 0;
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
                        # count track points in track
                        $nowyptthistrack++;
                        if ($nowyptthistrack == 1) {
                            $firstptsintrack = $_;
                        }

                        #print "$1 $2 $3 $4 $5 $6  ";
                        $plon = $5 + $6 / 60;
                        $plat = $2 + $3 / 60;
                        if ($4 eq 'W') {
                            $plon = -$plon;
                        }
                        if ($1 eq 'S') {
                            $plat = -$plat;
                        }
                        if ($fitmapphase > 0) {
                            if ($fitmapphase == 1) {
                                $fitmapmaxlon = $plon;
                                $fitmapminlon = $plon;
                                $fitmapmaxlat = $plat;
                                $fitmapminlat = $plat;
                                $fitmapphase = 2;
                            } else {
                                if ($fitmapmaxlon < $plon) {  $fitmapmaxlon = $plon; $needredraw = 1; }
                                if ($fitmapminlon > $plon) {  $fitmapminlon = $plon; $needredraw = 1; }
                                if ($fitmapmaxlat < $plat) {  $fitmapmaxlat = $plat; $needredraw = 1; }
                                if ($fitmapminlat > $plat) {  $fitmapminlat = $plat; $needredraw = 1; }
                            }
                        }
                        ($pixx, $pixy, $notclip) = &ll2xysvg ($plon, $plat);
                        if ($ctrl->{'debug'} >= 5) {
                            l00httpd::dbp($config{'desc'}, "(pixx $pixx, pixy $pixy, notclip $notclip) = &ll2xysvg (plon $plon, plat $plat)\n");
                        }
                        if ($notclip) {
                            $displaypt = 0; # default to not displaying
                            if ($nogpstrks == $starttrack) {
                                # starting track
                                if ($nowyptthistrack >= $startpoint) {
                                    if ($nowyptthistrack == ($startpoint + 1)) {
                                        $rawstartstop = sprintf("Start track %3d point %4d: %s\n", $nogpstrks, $nowyptthistrack, $_);
                                    }
                                    # yes
                                    $displaypt = 1;
                                }
                            } elsif ($nogpstrks > $starttrack) {
                                # beyond starting track
                                $displaypt = 1;
                            }
                            # check ending
                            if ($nogpstrks == $stoptrack) {
                                # ending track
                                if ($nowyptthistrack >= $stoppoint) {
                                    if ($nowyptthistrack == $stoppoint) {
                                        $rawstartstop .= sprintf("Stop  track %3d point %4d: %s\n", $nogpstrks, $nowyptthistrack, $_);
                                    }
                                    # yes
                                    $displaypt = 0;
                                }
                            } elsif ($nogpstrks > $stoptrack) {
                                # beyond ending track
                                $displaypt = 0;
                            }
                            if (defined ($form->{'markpointdo'})) {
                                if (($nogpstrks == $marktrack) &&
                                    ($nowyptthistrack == $markpoint)) {
                                    $lon = $plon;
                                    $lat = $plat;
                                }
                                if (($nogpstrks == $marktrack) &&
                                    ($nowyptthistrack >= $markpoint) &&
                                    $notclip) {
                                    # have we moved enough?
                                    if (($pixx0 < 0) ||
                                        (sqrt(($pixx0 - $pixx) ** 2 + ($pixy0 - $pixy) ** 2) > 20)) {
                                        # first time or moved more than 20 pixels
                                        print $sock "<div style=\"position: absolute; left:$pixx"."px; top:$pixy"."px;\">\n";
                                        $trackmark = chr($trackmarkcnt + 0x30);
                                        $trackmarkcnt++;
                                        print $sock "<font color=\"magenta\">$trackmark</font></div>\n";
                                        $rawstartstop .= sprintf("   <a href=\"/view.htm?path=$waypts&hiliteln=$lnno&lineno=on#line%d\">%s:</a> track %3d point %4d: %s\n", $lnno - 5, $trackmark, $nogpstrks, $nowyptthistrack, $_);
                                        # last position
                                        $pixx0 = $pixx;
                                        $pixy0 = $pixy;
                                    }
                                }
                            }


                            if ($displaypt) {
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
                    if (($plon, $plat) = /^([0-9.\-]+),([0-9.\-]+)[ ,]+([^ ].*)$/) {
                        ##long,lat,name
                        #121.386309,31.171295,Huana
                        if ($fitmapphase > 0) {
                            if ($fitmapphase == 1) {
                                $fitmapmaxlon = $plon;
                                $fitmapminlon = $plon;
                                $fitmapmaxlat = $plat;
                                $fitmapminlat = $plat;
                                $fitmapphase = 2;
                            } else {
                                if ($fitmapmaxlon < $plon) {  $fitmapmaxlon = $plon; $needredraw = 1; }
                                if ($fitmapminlon > $plon) {  $fitmapminlon = $plon; $needredraw = 1; }
                                if ($fitmapmaxlat < $plat) {  $fitmapmaxlat = $plat; $needredraw = 1; }
                                if ($fitmapminlat > $plat) {  $fitmapminlat = $plat; $needredraw = 1; }
                            }
                        }
                        ($pixx, $pixy, $notclip) = &ll2xysvg ($plon, $plat);
                        if ($notclip) {
                            print $sock "<div style=\"position: absolute; left:$pixx"."px; top:$pixy"."px;\">\n";
                            print $sock "<font color=\"$waycolor\">$3</font></div>\n";
                        }
                    }
                }

                if ($fitmapphase == 2) {
                    $maptllon = $fitmapminlon;
                    $maptllat = $fitmapmaxlat;
                    $mapbrlon = $fitmapmaxlon;
                    $mapbrlat = $fitmapminlat;

                    $maptllon -= ($fitmapmaxlon - $fitmapminlon) / 10;
                    $maptllat += ($fitmapmaxlat - $fitmapminlat) / 10;
                    $mapbrlon += ($fitmapmaxlon - $fitmapminlon) / 10;
                    $mapbrlat -= ($fitmapmaxlat - $fitmapminlat) / 10;

                    $mapextend_tllon = $maptllon - ($maptlx)              / ($mapbrx - $maptlx) * ($mapbrlon - $maptllon);
                    $mapextend_tllat = $maptllat + ($maptly)              / ($mapbry - $maptly) * ($maptllat - $mapbrlat);
                    $mapextend_brlon = $mapbrlon + ($mapwd - 1 - $mapbrx) / ($mapbrx - $maptlx) * ($mapbrlon - $maptllon);
                    $mapextend_brlat = $mapbrlat - ($mapht - 1 - $mapbry) / ($mapbry - $maptly) * ($maptllat - $mapbrlat);
                }

                if ($needredraw) {
                    l00httpd::dbp($config{'desc'}, "'Force map to fit track' causes map extend to change so must regenerate\n");

                    &l00httpd::l00freadOpen($ctrl, $waypts);
                    $pcx5mk = 'a';
                    $nogpstrks = 0;
                    $tracknpts = '';
                    $nowyptthistrack = 0;
                    $rawstartstop = '';
                    $firstptsintrack = 0;
                    $pixx0 = -1;
                    $trackmarkcnt = 0;
                    $lnno = 0;

                    # if map extend is extended, redraw
                    $needredraw = 0;
                } else {
                    last;
                }
            }


            if ($fitmapphase == 2) {
                $fitmapphase = -1;
            }

            if ($tracknpts ne '') {
                $tracknpts .= sprintf("%4d track points: $firstptsintrack\n", $nowyptthistrack);
            }

            if ($ctrl->{'debug'} >= 3) {
                l00httpd::dbp($config{'desc'}, "Create svg of track(s) from x,y/long,lat above: <a href=\"/svg.htm?view=&graph=$fname\">$fname</a>\n");
            }
            &l00svg::plotsvgmapoverlay ($fname, $svg, $mapwd, $mapht, $path, $waycolor);
            $svgout = '';
            $svgout .= "<svg  x=\"0\" y=\"0\" width=\"$mapwd\" height=\"$mapht\"xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" xml:space=\"preserve\" viewBox=\"0 0 $mapwd $mapht\" preserveAspectRatio=\"xMidYMid meet\">";
            $svgout .= "<g id=\"bitmap\" style=\"display:online\"> ";
            $svgout .= "<image x=\"0\" y=\"0\" width=\"$mapwd\" height=\"$mapht\" xlink:href=\"/ls.htm$path?path=$path\" /> ";
            $svgout .= "</g> ";
            $svgout .= "<g id=\"$fname\" style=\"display:online\"> ";
            $svgout .= "    <g transform=\"translate(0 0)\"> ";
            $svgout .= "        <g transform=\"scale(1.0)\"> ";
            $svgout .= "            <image x=\"0\" y=\"0\" width=\"$mapwd\" height=\"$mapht\" xlink:href=\"/svg.htm?graph=$fname\"/> ";
            $svgout .= "        </g> ";
            $svgout .= "    </g> ";
            $svgout .= "</g>";
            $svgout .= "</svg>\n";
            print $sock "$svgout<br>\n";
            if ($ctrl->{'debug'} >= 3) {
                l00httpd::dbp($config{'desc'}, "Create svg of background map: <a href=\"/ls.htm$path?path=$path\">$path</a>\n");
                l00httpd::dbp($config{'desc'}, "and foreground track: <a href=\"/svg.htm?graph=$fname\">$fname</a>\n");
                $svgout =~ s/</&lt;/g;
                $svgout =~ s/>/&gt;/g;
                l00httpd::dbp($config{'desc'}, "\n$svgout\n");
            }
            # the following doesn't work (see l00svg.pm)
            #print $sock "<img src=\"/svg.htm/svg.svg?graph=${fname}.ovly.svg\"><br>\n";
        } else {
            # no overlaid track. .png will do
            print $sock "<img src=\"/ls.htm$path?path=$path".'&'."raw=on\"><br>\n";
        }

        print $sock "<hr>";
        print $sock "<a href=\"#ctrl\">Jump to control</a>.  \n";
        if ($waypts ne '') {
            print $sock "<a href=\"#tracklist\">Jump to list of tracks</a>.  \n";
        }
        print $sock "Click map below to move cursor:<br>\n";
        print $sock "<form action=\"/gpsmapsvg.htm\" method=\"get\">\n";
        print $sock "<input type=image width=$mapwd height=$mapht src=\"/ls.htm$path?path=$path".'&'."raw=on\">\n";
        # the following doesn't work (see l00svg.pm)
        #print $sock "<input type=image width=$mapwd height=$mapht src=\"/svg.htm/svg.svg?graph=singapore.png.ovly.svg\">\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
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
        print $sock "<form action=\"/gpsmapsvg.htm\" method=\"get\">\n";
        print $sock "Set $form->{'x'},$form->{'y'} as \n";
        print $sock "<input type=\"submit\" name=\"settl\" value=\"TL\">/";
        print $sock "<input type=\"submit\" name=\"setbr\" value=\"BR\">\n";
        print $sock "lat,lon: <input type=\"text\" size=\"10\" name=\"setlatlon\" value=\"$setlatlonvals\">\n";
        print $sock "<input type=\"submit\" name=\"cbpaste\" value=\"CB paste\">\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
        print $sock "<input type=\"hidden\" name=\"x\" value=\"$form->{'x'}\">\n";
        print $sock "<input type=\"hidden\" name=\"y\" value=\"$form->{'y'}\">\n";
        print $sock "</form>\n";
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
    print $sock "<a href=\"/gpsmapsvg.htm?path=$path\">Refresh</a> - \n";
    print $sock "<a href=\"/view.htm?path=$map\">$map</a>\n";
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
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"color\" value=\"$color\">0xrrggbb</td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Scale:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"scale\" value=\"$scale\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"set\" value=\"Set\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"movec\" value=\"Ctr\"> <input type=\"submit\" name=\"mark\" value=\"Mark\"> <input type=\"submit\" name=\"submit\" value=\"Read GPS\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
    print $sock "</form>\n";

    print $sock "<p>Waypoints:<br>\n";

    print $sock "<form action=\"/gpsmapsvg.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";
    print $sock "        <tr>\n";
    print $sock "            <td>Waypoint file:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"waypts\" value=\"$waypts\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Color:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"waycolor\" value=\"$waycolor\"></td>\n";
    print $sock "        </tr>\n";
                                                
    # start and stop gps track/point
    print $sock "        <tr>\n";
    print $sock "            <td>Start track #:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"starttrack\" value=\"$starttrack\"></td>\n";
    print $sock "        </tr>\n";
    print $sock "        <tr>\n";
    print $sock "            <td>and skip # point:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"startpoint\" value=\"$startpoint\"></td>\n";
    print $sock "        </tr>\n";
    print $sock "        <tr>\n";
    print $sock "            <td>Stop track #:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"stoptrack\" value=\"$stoptrack\"></td>\n";
    print $sock "        </tr>\n";
    print $sock "        <tr>\n";
    print $sock "            <td>and stop # point:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"stoppoint\" value=\"$stoppoint\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"dispwaypts\" value=\"Display waypoints\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"cb2wfile\" value=\"CB to filename\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td>Load again if no tracks</td>\n";
    if ($fitmapphase == 0) {
        $_ = '';
    } else {
        $_ = 'checked';
    }
    print $sock "        <td><input type=\"checkbox\" name=\"fittrack\" $_>Force map to fit track</td>\n";
    print $sock "    </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Mark track #:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"marktrack\" value=\"$marktrack\"></td>\n";
    print $sock "        </tr>\n";
    print $sock "        <tr>\n";
    print $sock "            <td>at # point:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"markpoint\" value=\"$markpoint\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"markpointdo\" value=\"Mark Track Pt\"></td>\n";
    print $sock "        <td>\n";
    print $sock "        <input type=\"submit\" name=\"markleftleft\" value=\"<<\">\n";
    print $sock "        <input type=\"submit\" name=\"markleft\" value=\"<\">\n";
    print $sock "        <input type=\"submit\" name=\"markright\" value=\">\">\n";
    print $sock "        <input type=\"submit\" name=\"markrightright\" value=\">>\">\n";
    print $sock "        </td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td>20 pixels interval</td>\n";
    print $sock "        <td>Move 1 point/100 points</td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
    print $sock "</form>\n";

    if ($waypts ne '') {
        print $sock "<a name=\"tracklist\"></a>There are $nogpstrks GPS tracks<br>\n";
        print $sock "<pre>\n$rawstartstop</pre>\n";
        print $sock "<pre>\n$tracknpts</pre>\n";
        print $sock "View waypoint/track file: <a href=\"/view.htm?path=$waypts\">$waypts</a>. \n";
        print $sock "Copy waypoint/track file to : <a href=\"/filemgt.htm?copy=Copy&path=$waypts&path2=l00%3A%2F%2Fwaypoints.trk\" target=\"newwin\">l00://waypoints.trk</a><p>\n";
    }

    if (&l00httpd::l00freadOpen($ctrl, $map)) {
        print $sock "Map file: $map<pre>\n";
        print $sock "maptlx $maptlx\n";
        print $sock "maptly $maptly\n";
        print $sock "maptllon $maptllon\n";
        print $sock "maptllat $maptllat\n";
        print $sock "mapbrx $mapbrx\n";
        print $sock "mapbry $mapbry\n";
        print $sock "mapbrlon $mapbrlon\n";
        print $sock "mapbrlat $mapbrlat\n";

        print $sock "(dumping $map)\n";

        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            print $sock "$_";
        }

        if ($fitmapphase != 0) {
            print $sock "\nOverwritten by fitmapphase $fitmapphase\n";
            print $sock "maptllon $maptllon = fitmapminlon $fitmapminlon;\n";
            print $sock "maptllat $maptllat = fitmapmaxlat $fitmapmaxlat;\n";
            print $sock "mapbrlon $mapbrlon = fitmapmaxlon $fitmapmaxlon;\n";
            print $sock "mapbrlat $mapbrlat = fitmapminlat $fitmapminlat;\n";
        }

        print $sock "</pre>\n";
    }

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
