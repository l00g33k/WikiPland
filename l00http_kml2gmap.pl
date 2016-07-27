use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

my ($gmapscript0, $gmapscript1, $gmapscript2, $gmapscript2a, 
    $gmapscript3, $myCenters, $myMarkers, $mySetMap);
my ($width, $height, $apikey, $satellite);

$myCenters = '';
$myMarkers = '';
$mySetMap = '';

$width = 500;
$height = 380;
$satellite = 0;

$apikey = '';

$gmapscript0 = "<script\n";
#src="http://maps.googleapis.com/maps/api/js?key=$apikey">
$gmapscript1 = <<ENDOFSCRIPT1;
</script>

<script>
ENDOFSCRIPT1
#var  myCenter=new google.maps.LatLng(0,0);

#var myCenter =new google.maps.LatLng(45.4357487,12.3098395);
#var myCenter2=new google.maps.LatLng(46.4357487,13.3098395);
#$myCenters

$gmapscript2 = <<ENDOFSCRIPT2;

function initialize()
{
var mapProp = {
  center:myCenter,
ENDOFSCRIPT2
#  zoom:1,
#  mapTypeId:google.maps.MapTypeId.ROADMAP
$gmapscript2a = <<ENDOFSCRIPT2a;
  };

var map=new google.maps.Map(document.getElementById("googleMap"),mapProp);

ENDOFSCRIPT2a

#var marker =new google.maps.Marker({ position:myCenter , });
#var marker2=new google.maps.Marker({ position:myCenter2, });
#$myMarkers

#marker.setMap(map);
#marker2.setMap(map);
#$mySetMap

$gmapscript3 = <<ENDOFSCRIPT3;
}
google.maps.event.addDomListener(window, 'load', initialize);
</script>
ENDOFSCRIPT3


my %config = (proc => "l00http_kml2gmap_proc",
              desc => "l00http_kml2gmap_desc");

sub l00http_kml2gmap_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "kml2gmap: Create a link that send .kml to device Google Maps";
}


my ($htmlhead);
$htmlhead = "<!DOCTYPE html PUBLIC '-//WAPFORUM//DTD XHTML Mobile 1.0//EN' 'http://www.wapforum.org/DTD/xhtml-mobile10.dtd'>\x0D\x0A".
            "<html>\x0D\x0A".
            "<head>\x0D\x0A".
            "<meta name=\"generator\" content=\"WikiPland: https://github.com/l00g33k/WikiPland\">\x0D\x0A".
            "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\x0D\x0A";

sub l00http_kml2gmap_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($tmp, $lon, $lat, $buffer, $starname, $name, $nowypts, $labeltable);
    my ($lonmax, $lonmin, $latmax, $latmin, $zoom, $span, $ctrlon, $ctrlat);


    if (defined($ctrl->{'googleapikey'})) {
        $apikey = $ctrl->{'googleapikey'};
    }

    if (defined ($form->{'width'}) && ($form->{'width'} =~ /(\d+)/)) {
        $width = $form->{'width'};
    }
    if (defined ($form->{'height'}) && ($form->{'height'} =~ /(\d+)/)) {
        $height = $form->{'height'};
    }

    if (defined ($form->{'maptype'}) && ($form->{'maptype'} eq 'satellite')) {
        $satellite = 2;
    } elsif (defined ($form->{'maptype'}) && ($form->{'maptype'} eq 'hybrid')) {
        $satellite = 1;
    } else {
        $satellite = 0;
    }


    $labeltable = '';
    if (!defined ($form->{'path'})) {
        $form->{'path'} = '';
    } else {
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            $buffer = &l00httpd::l00freadAll($ctrl);
            $buffer =~ s/\r\n/\n/g;
            $buffer =~ s/\r/\n/g;
            $myCenters = '';
            $myMarkers = '';
            $mySetMap = '';
            $nowypts = 0;
            $lonmax = undef;
            foreach $_ (split ("\n", $buffer)) {
                s/\r//g;
                s/\n//g;
                #-118.0347581348814,33.80816583075773,Place1
                if (/^#/) {
                    next;
                }
                #https://www.google.com/maps/PVG@31.151045,121.8012844,15z
                #http://www.google.cn/maps/@31.3228158,120.6269192,502m/data=!3m1!1e3
                if (($name, $lat, $lon) = /\.google\..+?\/maps\/(.*)@([0-9.+-]+),([0-9.+-]+),/) {
                    # Parse coordinate from Google Maps URL
                    # https://www.google.com/maps/@31.1956864,121.3522793,15z
                    # https://www.google.com/maps/place/30%C2%B012'26.5%22N+115%C2%B002'06.5%22E/@30.206403,115.0352586,19z?hl=en
                    # match, falls thru
                    if ($starname ne '') {
                        # * name from line above over writes name from URL
                        $name = $starname;
                    }
                } elsif (($lat, $lon, $name) = /([0-9.+-]+?),([0-9.+-]+?)[, ]+([^ ]+)/) {
                    # match, falls thru
                    if ($starname ne '') {
                        # * name from line above over writes name from URL
                        $name = $starname;
                    }
                } elsif (/^\* +([^ ]+)/) {
                    # of the form:
                    # * name
                    # https://www.google.com/maps/@31.1956864,121.3522793,15z
                    $starname = $1;
                    next;
                } else {
                    $starname = '';
                    next;
                }

                # find max span
                if (!defined($lonmax)) {
                    $lonmax = $lon;
                    $lonmin = $lon;
                    $latmax = $lat;
                    $latmin = $lat;
                } else {
                    if ($lonmax < $lon) {
                        $lonmax = $lon;
                    }
                    if ($lonmin > $lon) {
                        $lonmin = $lon;
                    }
                    if ($latmax < $lat) {
                        $latmax = $lat;
                    }
                    if ($latmin > $lat) {
                        $latmin = $lat;
                    }
                }

                # var myCenter =new google.maps.LatLng(45.4357487,12.3098395);
                $myCenters .= "var myCenter$nowypts =new google.maps.LatLng($lat,$lon);\n";

                # var marker =new google.maps.Marker({ position:myCenter , });
                if ($nowypts < 26) {
                    $_ = chr(65 + $nowypts);
                } else {
                    $_ = chr(97 + $nowypts - 26);
                }
                $labeltable .= "$_: $name (lon/lat: $lon,$lat)\n";
                $myMarkers .= "var marker$nowypts =new google.maps.Marker({ ".
                    "  position:myCenter$nowypts , \n".
                    "  label: '$_' , \n".
                    "  title: '$name'});\n";

                # marker.setMap(map);
                $mySetMap .= "marker$nowypts.setMap(map);\n";
                $nowypts++;
            }
        }
    }


    if (defined ($form->{'path'})) {
        # Send HTTP and HTML headers
        if ($satellite == 1) {
            # http://www.w3schools.com/googleapi/google_maps_basic.asp
            $_ = 'HYBRID';
        } elsif ($satellite == 2) {
            # http://www.w3schools.com/googleapi/google_maps_basic.asp
            $_ = 'SATELLITE';
        } else {
            $_ = 'ROADMAP';
        }
        $ctrlon = ($lonmax + $lonmin) / 2;
        $ctrlat = ($latmax + $latmin) / 2;
        $span = sqrt (($lonmax - $lonmin) ** 2 + 
                      (($latmax - $latmin) * 
                      cos (($latmax + $latmin) / 2 / 180 
                        * 3.141592653589793)) ** 2);
        $zoom = 1;
        while () {
            if ($span * 2 ** $zoom > 180) {
                last;
            }
            $zoom++;
            if ($zoom >= 17) {
                last;
            }
        }

        print $sock $ctrl->{'httphead'} . $htmlhead . "<title>kml2gmap</title>\n" . 
            $gmapscript0 .
            "src=\"http://maps.googleapis.com/maps/api/js?key=$apikey\">\n" .
            $gmapscript1 .
            "var  myCenter=new google.maps.LatLng($ctrlat,$ctrlon);\n" .
            $myCenters .
            $gmapscript2 .
            "  zoom:$zoom,\n" .
            "  mapTypeId:google.maps.MapTypeId.$_\n" .
            $gmapscript2a .
            $myMarkers .
            $mySetMap .
            $gmapscript3 .
            $ctrl->{'htmlhead2'};

        print $sock "<div id=\"googleMap\" style=\"width:${width}px;height:${height}px;\"></div>\n";
    }


    print $sock "<p><pre>$labeltable</pre><p>\n";

    print $sock "<form action=\"/kml2gmap.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"makemap\" value=\"Update\"><p>\n";
    print $sock "Path: <input type=\"text\" name=\"path\" size=\"12\" value=\"$form->{'path'}\"><br>\n";
    print $sock "width: <input type=\"text\" name=\"width\" size=\"5\" value=\"$width\"><br>\n";
    print $sock "height: <input type=\"text\" name=\"height\" size=\"5\" value=\"$height\"><br>\n";
    if ($satellite == 0) {
        $_ = 'checked';
    } else {
        $_ = 'unchecked';
    }
    print $sock "<input type=\"radio\" name=\"maptype\" value=\"street\"    $_>Street<br>";
    if ($satellite == 1) {
        $_ = 'checked';
    } else {
        $_ = 'unchecked';
    }
    print $sock "<input type=\"radio\" name=\"maptype\" value=\"hybrid\" $_>Hybrid<br>";
    if ($satellite == 2) {
        $_ = 'checked';
    } else {
        $_ = 'unchecked';
    }
    print $sock "<input type=\"radio\" name=\"maptype\" value=\"satellite\" $_>Satellite<br>";
    print $sock "</form>\n";

    if (defined ($form->{'path'})) {
        print $sock "<p>View <a href=\"/view.htm?path=$form->{'path'}\">$form->{'path'}</a><p>\n";
    }

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
