use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

my ($gmapscript0, $gmapscript1, $gmapscript2, $gmapscript2a, 
    $gmapscript3, $myCenters, $myMarkers, $mySetMap);
my ($width, $height, $apikey, $satellite);
my ($new);

$new = 1;
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

#    var worldCoordinate = project(latLng);
#    var marker = new google.maps.Marker({
#      position: latLng,
#      map: map
#    });
$gmapscript2 = <<ENDOFSCRIPT2;

var lng0, lat0;
var latLngLast;
var cursor;
var map;

function getDistanceFromLatLonInKm(p1, p2) {
    var R = 6371; // Radius of the earth in km
    var dLat = deg2rad(p2.lat()-p1.lat());  // deg2rad below
    var dLon = deg2rad(p2.lng()-p1.lng()); 
    var a = 
        Math.sin(dLat/2) * Math.sin(dLat/2) +
        Math.cos(deg2rad(p1.lat())) * Math.cos(deg2rad(p2.lat())) * 
        Math.sin(dLon/2) * Math.sin(dLon/2)
    ; 
    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a)); 
    var d = R * c; // Distance in km
    return d;
}

function deg2rad(deg) {
    return deg * (Math.PI/180)
}

function placeMarkerAndPanTo(latLng, map) {
    var zoom = map.getZoom();
    var scale = 1 << zoom;


    cursor.setPosition(latLng);
    cursor.setVisible(true);
    cursor.setMap(map);

    document.getElementById("zoom").firstChild.nodeValue = "Zoom level: " + zoom;
    document.getElementById("coor").firstChild.nodeValue = 
        "Coor (lat, lng): " + latLng;
    if (typeof latLngLast !== 'undefined') {
        // the latLngLast is defined
        document.getElementById("distance").firstChild.nodeValue = 
            "Distance: " + 
            getDistanceFromLatLonInKm(latLng, latLngLast) + " km";
    }
    document.getElementById("long").value = latLng.lng();
    document.getElementById("lat").value = latLng.lat();
    lng0 = latLng.lng();
    lat0 = latLng.lat();

    latLngLast = latLng;
}
      
function initialize()
{
var mapProp = {
  center:myCenter,
ENDOFSCRIPT2
#  zoom:1,
#  mapTypeId:google.maps.MapTypeId.ROADMAP
$gmapscript2a = <<ENDOFSCRIPT2a;
  };

map=new google.maps.Map(document.getElementById("googleMap"),mapProp);

map.addListener('click', function(e) {
    placeMarkerAndPanTo(e.latLng, map);
});

// Create the search box and link it to the UI element.
var input = document.getElementById('pac-input');
var searchBox = new google.maps.places.SearchBox(input);
map.controls[google.maps.ControlPosition.TOP_LEFT].push(input);

// Bias the SearchBox results towards current map's viewport.
map.addListener('bounds_changed', function() {
  searchBox.setBounds(map.getBounds());
});



// search map

var markers = [];
// Listen for the event fired when the user selects a prediction and retrieve
// more details for that place.
searchBox.addListener('places_changed', function() {
  var places = searchBox.getPlaces();

  if (places.length == 0) {
    return;
  }

  // Clear out the old markers.
  markers.forEach(function(marker) {
    marker.setMap(null);
  });
  markers = [];

  // For each place, get the icon, name and location.
  var bounds = new google.maps.LatLngBounds();
  places.forEach(function(place) {
    if (!place.geometry) {
      console.log("Returned place contains no geometry");
      return;
    }
    var icon = {
      url: place.icon,
      size: new google.maps.Size(71, 71),
      origin: new google.maps.Point(0, 0),
      anchor: new google.maps.Point(17, 34),
      scaledSize: new google.maps.Size(25, 25)
    };

    // Create a marker for each place.
    markers.push(new google.maps.Marker({
      map: map,
      icon: icon,
      title: place.name,
      position: place.geometry.location
    }));

    if (place.geometry.viewport) {
      // Only geocodes have viewport.
      bounds.union(place.geometry.viewport);
    } else {
      bounds.extend(place.geometry.location);
    }
  });
  map.fitBounds(bounds);
});


ENDOFSCRIPT2a

#var marker =new google.maps.Marker({ position:myCenter , });
#var marker2=new google.maps.Marker({ position:myCenter2, });
#$myMarkers


#marker.setMap(map);
#marker2.setMap(map);
#$mySetMap

$gmapscript3 = <<ENDOFSCRIPT3;

var myCenterCursor =new google.maps.LatLng(0,0);
cursor=new google.maps.Marker({ position:myCenterCursor});

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
    my ($nomarkers, $lnno);


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


    # delete waypoint
    if (defined ($form->{'path'}) && 
        defined ($form->{'delln'})) {
        $buffer = '';
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            # back up
            &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 5);
            $lnno = 0;
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                $lnno++;
                if ($lnno == $form->{'delln'}) {
                    $_ = "#$_";
                }
                $buffer .= $_;
            }

            # update file
            &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
            &l00httpd::l00fwriteBuf($ctrl, $buffer);
            &l00httpd::l00fwriteClose($ctrl);
        }
    }


    # add new waypoint
    if (defined ($form->{'path'}) && 
        defined ($form->{'addway'}) &&
        defined ($form->{'desc'}) &&
        defined ($form->{'long'}) &&
        defined ($form->{'lat'})) {
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            $buffer = &l00httpd::l00freadAll($ctrl);
            $buffer = "* $form->{'desc'}\n$form->{'lat'},$form->{'long'} $form->{'desc'}\n\n$buffer";
            if ($form->{'desc'} =~ /^new\d/) {
                $new++;
            }

            # back up
            &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 5);
            # update file
            &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
            &l00httpd::l00fwriteBuf($ctrl, $buffer);
            &l00httpd::l00fwriteClose($ctrl);
        }
    }


    $labeltable = '';
    if (!defined ($form->{'path'})) {
        $form->{'path'} = 'l00://waypoint.txt';
        &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
        &l00httpd::l00fwriteBuf($ctrl, "# sample waypoint\n40.7488798,-73.9701978 United Nations HQ\n");
        &l00httpd::l00fwriteClose($ctrl);
    }
    if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
        $buffer = &l00httpd::l00freadAll($ctrl);
        $buffer =~ s/\r\n/\n/g;
        $buffer =~ s/\r/\n/g;
        $myCenters = '';
        $myMarkers = '';
        $mySetMap = '';
        $nowypts = 0;
        $lonmax = undef;
        $starname = '';
        $nomarkers = 0;
        $lnno = 0;
        foreach $_ (split ("\n", $buffer)) {
            $lnno++;
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
                    $starname = '';
                }
            } elsif (($lat, $lon, $name) = /([0-9.+-]+?),([0-9.+-]+?)[, ]+([^ ]+)/) {
                # match, falls thru
                if ($starname ne '') {
                    # * name from line above over writes name from URL
                    $name = $starname;
                    $starname = '';
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

            # count markers
            $nomarkers++;

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
#           $labeltable .= "$_: $name (lat, lng): $lat, $lon\n";
            $labeltable .= "<a href=\"/kml2gmap.htm?delln=$lnno&path=$form->{'path'}\">del</a>: ";
            $labeltable .= "$_: $name (lat, lng): $lat, $lon\n";
            $myMarkers .= "var marker$nowypts =new google.maps.Marker({ ".
                "  position:myCenter$nowypts , \n".
                "  label: '$_' , \n".
                "  title: '$name'});\n";

            # marker.setMap(map);
            $mySetMap .= "marker$nowypts.setMap(map);\n";
            $nowypts++;
        }
    }


    $span = 0;
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
        if ($nomarkers == 1) {
            $zoom = 11;
        } else {
            $zoom = 1;
            if ($span > 1e-9) {
                while (1) {
                    if ($span * 2 ** $zoom > 180) {
                        last;
                    }
                    $zoom++;
                    if ($zoom >= 17) {
                        last;
                    }
                }
            }
        }

        print $sock $ctrl->{'httphead'} . $htmlhead . "<title>kml2gmap</title>\n" . 
            $gmapscript0 .
            "src=\"http://maps.googleapis.com/maps/api/js?key=$apikey&libraries=places\">\n" .
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

        print $sock "<input id=\"pac-input\" class=\"controls\" type=\"text\" placeholder=\"Search Box\">\n";
        print $sock "<div id=\"googleMap\" style=\"width:${width}px;height:${height}px;\"></div>\n";
    }


    print $sock "<p><pre>$labeltable</pre>\n";
    print $sock "<span id=\"zoom\">&nbsp;</span><br>";
    print $sock "<span id=\"coor\">&nbsp;</span><br>";
    print $sock "<span id=\"distance\">&nbsp;</span><p>";


    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - \n";
    print $sock "View: <a href=\"/view.htm?path=$form->{'path'}\">$form->{'path'}</a><p>\n";


    print $sock "<form action=\"/kml2gmap.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"makemap\" value=\"Update\"></td><td>\n";
    print $sock "&nbsp;\n";
#    if ($satellite == 0) {
#        $_ = 'checked';
#    } else {
#        $_ = 'unchecked';
#    }
#    print $sock "<input type=\"radio\" name=\"maptype\" value=\"street\"    $_>Street<br>";
#    if ($satellite == 1) {
#        $_ = 'checked';
#    } else {
#        $_ = 'unchecked';
#    }
#    print $sock "<input type=\"radio\" name=\"maptype\" value=\"hybrid\" $_>Hybrid<br>";
#    if ($satellite == 2) {
#        $_ = 'checked';
#    } else {
#        $_ = 'unchecked';
#    }
#    print $sock "<input type=\"radio\" name=\"maptype\" value=\"satellite\" $_>Satellite<br>";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Path:</td><td><input type=\"text\" name=\"path\" size=\"12\" value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "width:</td><td><input type=\"text\" name=\"width\" size=\"5\" value=\"$width\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "height:</td><td><input type=\"text\" name=\"height\" size=\"5\" value=\"$height\">\n";
    print $sock "</td></tr>\n";
    print $sock "</table>\n";
    print $sock "</form>\n";

    if (defined ($form->{'path'})) {
        print $sock "<p><form action=\"/kml2gmap.htm\" method=\"post\">\n";
        print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
        print $sock "<tr><td>\n";
        print $sock "<input type=\"submit\" name=\"addway\" value=\"Add waypoint\"></td><td>Click on map for coor\n";
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "Description:</td><td><input type=\"text\" name=\"desc\" size=\"12\" value=\"new$new\">\n";
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "Path:</td><td><input type=\"text\" name=\"path\" size=\"12\" value=\"$form->{'path'}\">\n";
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "Longitude:</td><td><input type=\"text\" name=\"long\" id=\"long\" size=\"12\">\n";
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "Latitude:</td><td><input type=\"text\" name=\"lat\"  id=\"lat\"  size=\"12\">\n";
        print $sock "</td></tr>\n";
        print $sock "</table><br>\n";
        print $sock "</form>\n";
    }

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
