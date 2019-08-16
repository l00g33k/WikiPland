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


my ($mapwd, $mapht);
$mapwd = 640;
$mapht = 480;


my %config = (proc => "l00http_picannosvg_proc",
              desc => "l00http_picannosvg_desc");


# converts lon/lat to screen x/y coordinate
sub ll2xysvg {
    my ($lonhtm, $lathtm) = @_;
    my ($pixx, $pixy, $notclip);
    $notclip = 1;

    $pixx = int ($lonhtm * $scale / 100);
    $pixy = int ($mapht * $scale / 100) - int ($lathtm * $scale / 100);

    ($pixx, $pixy, $notclip);
}

# converts screen x/y coordinate to lon/lat
sub xy2llsvg {
    my ($pixx, $pixy) = @_;
    my ($lonhtm, $lathtm);

    $lonhtm = $pixx * 100 / $scale;
    $lathtm = $mapht - $pixy * 100 / $scale;

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
    my ($notclip, $coor, $tmp, $svg, $anno);


    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        $map = "$path.txt";
    }
    # map clicked
    if (defined ($form->{'x'})) {
        ($lon, $lat) = &xy2llsvg ($form->{'x'}, $form->{'y'});
    }
    if (defined ($form->{'scale'})) {
        $scale = $form->{'scale'};
    }

    $anno = '';
    if (defined($form->{'anno'}) && (length($form->{'anno'}) > 0)) {
        $anno = $form->{'anno'};
    }


    if (&l00httpd::l00freadOpen($ctrl, $map)) {
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            s/\n//; s/\r//;
            if (/^IMG_WD_HT/) {
                ($mapwd, $mapht) = /^IMG_WD_HT=(\d+),(\d+)/;
                $mapwd = int ($mapwd * $scale / 100);
                $mapht = int ($mapht * $scale / 100);
		    }
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
    print $sock "            <td>A&#818;nnotation:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"anno\" value=\"\" accesskey=\"a\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"set\" value=\"S&#818;et\" accesskey=\"s\">".
                "            <input type=\"submit\" name=\"refresh\" value=\"R&#818;efresh\" accesskey=\"r\"></td>\n";
    print $sock "        <td>Sc&#818;ale <input type=\"text\" size=\"6\" name=\"scale\" value=\"$scale\" accesskey=\"c\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
    print $sock "</form>\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
