use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Copy to Android clipboard

my %config = (proc => "l00http_coorcalc_proc",
              desc => "l00http_coorcalc_desc");
my ($latlong, $distance, $bearing, $lat, $long);
$latlong = "0,0";
$distance = 0;
$bearing = 0;
$lat = 0;
$long = 0;


sub l00http_coorcalc_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "coorcalc: Coordinate calculator";
}

sub l00http_coorcalc_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data


    if (defined ($form->{'latlong'})) {
        $latlong = $form->{'latlong'};
        #N37 10.649 W118 33.805
        if (@_ = $latlong  =~ /([NS])(\d+) ([.0-9]+) ([EW])(\d+) ([.0-9]+)/) {
            if ($#_ == 5) {
                $lat = $_[1] + $_[2] / 60;
                if ($_[0] eq 'S') {
                    $lat = -$lat;
                }
                $long = $_[4] + $_[5] / 60;
                if ($_[3] eq 'W') {
                    $long = -$long;
                }
                $latlong = "$long, $lat";

            }
        }
        ($long, $lat) = $latlong =~ /(.+),(.+)/;
    }
    if (defined ($form->{'distance'})) {
		if ($form->{'distance'} =~ /(.+)mi/) {
			$distance = $1 * 5280 * 12 * 0.0254;
		} elsif ($form->{'distance'} =~ /(.+)ft/) {
			$distance = $1 * 12 * 0.0254;
		} elsif ($form->{'distance'} =~ /(.+)km/) {
			$distance = $1 * 1000;
		} elsif ($form->{'distance'} =~ /(.+)m/) {
			$distance = $1;
		}
    }
    if (defined ($form->{'bearing'})) {
		$bearing = $form->{'bearing'};
    }
    if (defined ($form->{'submit'})) {
		$lat  += ($distance * cos ($bearing / 180 * 3.141592653589793)) / 20000000 * 180;
		$long += ($distance * sin ($bearing / 180 * 3.141592653589793)) / 20000000 * 180;
		$latlong = "$long,$lat";
        if ($ctrl->{'os'} eq 'and') {
            $ctrl->{'droid'}->setClipboard ($latlong);
        }
    }


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>coorcalc</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a><br>\n";

    print $sock "<form action=\"/coorcalc.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Long,Lat:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"latlong\" value=\"$latlong\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Distance:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"distance\" value=\"$distance"."m\"> m, km, ft, mi</td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Bearing:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"bearing\" value=\"$bearing\"> degree</td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Calculate\"></td>\n";
    print $sock "        <td>Calculate new coordinate -&gt; clipboard</td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Latitude (readonly):</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"lat\" value=\"$lat\"></td>\n";
    print $sock "        </tr>\n";
                                                
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Longitude (readonly):</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"long\" value=\"$long\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>GMaps</td>\n";
    print $sock "            <td><a href=\"http://maps.google.com/maps?q=$lat,$long&z=20\">$lat,$long</a></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Clipboard</td>\n";
    print $sock "            <td><a href=\"/clip.htm?update=Copy+to+clipboard&clip=$lat%2C$long\">$lat,$long</a></td>\n";

    print $sock "        </tr>\n";
                                                
    print $sock "</table>\n";
    print $sock "</form>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};

}


\%config;
