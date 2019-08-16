use strict;
use warnings;
use l00svg;
use l00base64;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# GPS map without data connection

my $lon = 0;
my $lat = 0;
my $path = '';
my $map = '';
my $marker = 'X';
my $color = 'ff0000';
my $scale = 100;

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


my ($fname, $mapwd, $mapht);


my %config = (proc => "l00http_picannosvg_proc",
              desc => "l00http_picannosvg_desc");


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



sub l00http_picannosvg_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/

    "picannosvg: Annotate pictures";
}

sub l00http_picannosvg_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($pixx, $pixy, $pixx0, $pixy0, $buf, $lonhtm, $lathtm, $xx, $yy);
    my ($lond, $lonm, $lonc, $latd, $latm, $latc);
    my ($notclip, $coor, $tmp, $svg);


    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        ($fname) = $path =~ /\/([^\/]+)$/;
        $map = "$path.txt";
    }
    # map clicked
    if (defined ($form->{'x'})) {
        ($lon, $lat) = &xy2llsvg ($form->{'x'}, $form->{'y'});
    }
    if (defined ($form->{'scale'})) {
        $scale = $form->{'scale'};
    }

    if (defined ($form->{'anno'})) {
    }


    if (&l00httpd::l00freadOpen($ctrl, $map)) {
        $_ = &l00httpd::l00freadLine($ctrl); s/\n//; s/\r//; ($maptlx) = / *([^ ]+) */;
        $_ = &l00httpd::l00freadLine($ctrl); s/\n//; s/\r//; ($maptly) = / *([^ ]+) */;
        $_ = &l00httpd::l00freadLine($ctrl); s/\n//; s/\r//; ($maptllon) = / *([^ ]+) */;
        $_ = &l00httpd::l00freadLine($ctrl); s/\n//; s/\r//; ($maptllat) = / *([^ ]+) */;
        $_ = &l00httpd::l00freadLine($ctrl); s/\n//; s/\r//; ($mapbrx) = / *([^ ]+) */;
        $_ = &l00httpd::l00freadLine($ctrl); s/\n//; s/\r//; ($mapbry) = / *([^ ]+) */;
        $_ = &l00httpd::l00freadLine($ctrl); s/\n//; s/\r//; ($mapbrlon) = / *([^ ]+) */;
        $_ = &l00httpd::l00freadLine($ctrl); s/\n//; s/\r//; ($mapbrlat) = / *([^ ]+) */;

        # default
        $mapwd = int (($mapbrx + 1) * $scale / 100);
        $mapht = int (($mapbry + 1) * $scale / 100);
        $_ = &l00httpd::l00freadLine($ctrl); 
        if (defined($_)) {
            s/\n//; s/\r//;
            if (/^IMG_WD_HT/) {
                ($mapwd, $mapht) = /^IMG_WD_HT=(\d+),(\d+)/;
                $mapwd = int ($mapwd * $scale / 100);
                $mapht = int ($mapht * $scale / 100);
		    }
        }

        # compute map extends
        $mapextend_tllon = $maptllon - ($maptlx)              / ($mapbrx - $maptlx) * ($mapbrlon - $maptllon);
        $mapextend_tllat = $maptllat + ($maptly)              / ($mapbry - $maptly) * ($maptllat - $mapbrlat);
        $mapextend_brlon = $mapbrlon + ($mapwd - 1 - $mapbrx) / ($mapbrx - $maptlx) * ($mapbrlon - $maptllon);
        $mapextend_brlat = $mapbrlat - ($mapht - 1 - $mapbry) / ($mapbry - $maptly) * ($maptllat - $mapbrlat);
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


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>picannosvg</title>" . $ctrl->{'htmlhead2'};

    if (open (IN, "<$path")) {
        close (IN);
        ($pixx, $pixy, $notclip) = &ll2xysvg ($lon, $lat);
        if ($notclip) {
            print $sock "<div style=\"position: absolute; left:$pixx"."px; top:$pixy"."px;\">\n";
            print $sock "<font color=\"$color\">$marker</font></div>\n";
        }

        print $sock "<form action=\"/picannosvg.htm\" method=\"get\">\n";
        print $sock "<input type=image width=$mapwd height=$mapht src=\"/ls.htm$path?path=$path&raw=on\">\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
        print $sock "</form>\n";
    }


    if (defined ($form->{'x'})) {
        print $sock "<br>Clicked pixel (x,y): $form->{'x'},$form->{'y'}\n";
    }


    print $sock "<p>$ctrl->{'home'} \n";
    print $sock "$ctrl->{'HOME'} \n";
    print $sock "Launch <a href=\"/launcher.htm?path=$path\">$path</a> - ".
        "View <a href=\"/view.htm?path=$map\">$map</a><p>\n";


    print $sock "<form action=\"/picannosvg.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Annotation:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"anno\" value=\"\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"set\" value=\"Set\"></td>\n";
    print $sock "        <td>&nbsp;</td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
    print $sock "</form>\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
