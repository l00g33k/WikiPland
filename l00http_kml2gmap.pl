use strict;
use warnings;
use l00wikihtml;
use l00httpd;


# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

my ($gmapscript0, $gmapscript1, $gmapscript2, $gmapscript2a, $gmapscript2b, 
    $gmapscript3, $myCenters, $myMarkers, $mySetMap);
my ($width, $height, $apikey, $satellite, $initzoom);
my ($new, $selregex, $drawgrid, $matched, $exclude);

$new = 1;
$myCenters = '';
$myMarkers = '';
$mySetMap = '';
$selregex = '';
$drawgrid = '';
$initzoom = '';

$width = 500;
$height = 380;
$satellite = 0;

$apikey = '';
$matched = '';
$exclude = '';

$gmapscript0 = "<script\n";
#src="http://maps.googleapis.com/maps/api/js?key=$apikey">
$gmapscript1 = <<ENDOFSCRIPT1;
</script>

<script>
var grid;
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
        "Coor (lat,lng): " + latLng;
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

ENDOFSCRIPT2a
$gmapscript2b = <<ENDOFSCRIPT2b;

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


ENDOFSCRIPT2b

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
$htmlhead = "<!DOCTYPE html PUBLIC \"-//WAPFORUM//DTD XHTML Mobile 1.0//EN\" \"http://www.wapforum.org/DTD/xhtml-mobile10.dtd\">\x0D\x0A".
            "<html>\x0D\x0A".
            "<head>\x0D\x0A".
            "<meta name=\"generator\" content=\"WikiPland: https://github.com/l00g33k/WikiPland\">\x0D\x0A".
            "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\">\x0D\x0A";

sub l00http_kml2gmap_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($tmp, $lon, $lat, $gpslon, $gpslat, $buffer, $starname, $name, $nowypts, $labeltable, %labelsort);
    my ($lonmax, $lonmin, $latmax, $latmin, $zoom, $span, $ctrlon, $ctrlat, $desc);
    my ($nomarkers, $lnno, $jlabel, $jname, $htmlout, $selonly, $newbuf, $pathbase);
    my ($sortothers, %sortentires, $sortphase, $drawgriddo, $drawgriddo2);
    my (@polyline, $polyidx, $polybuf, $polypt);

    $gpslon = '';
    $gpslat = '';
    $desc = "new$new";

    $polyidx = 0;

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

    if (!defined ($form->{'path'})) {
        $form->{'path'} = 'l00://waypoint.txt';
        &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
        &l00httpd::l00fwriteBuf($ctrl, "# sample waypoint\n40.7488798,-73.9701978 United Nations HQ\n");
        &l00httpd::l00fwriteClose($ctrl);
    }
    if (!&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
        # target doesn't exist
        $form->{'path'} = 'l00://waypoint.txt';
        &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
        &l00httpd::l00fwriteBuf($ctrl, "# sample waypoint\n40.7488798,-73.9701978 United Nations HQ\n");
        &l00httpd::l00fwriteClose($ctrl);
    }


    if (defined ($form->{'update'})) {
        $matched = '';
        $exclude = '';
        if (defined($form->{'exclude'}) && ($form->{'exclude'} eq 'on')) {
            $exclude = 'checked';
        } elsif (defined($form->{'matched'}) && ($form->{'matched'} eq 'on')) {
            $matched = 'checked';
        }
        if (defined($form->{'drawgrid'}) && ($form->{'drawgrid'} eq 'on')) {
            $drawgrid = 'checked';
        } else {
            $drawgrid = '';
        }
        if (defined($form->{'initzoom'}) && ($form->{'initzoom'} =~ /(\d+)/)) {
            $initzoom = $1;
        } else {
            $initzoom = '';
        }
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


    # sort waypoint
    if (defined ($form->{'path'}) && 
        defined ($form->{'sort'})) {
        $buffer = '';
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            # back up
            &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 5);
            $lnno = 0;
            $sortphase = 0;
            $sortothers = '';
            undef %sortentires;
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                $lnno++;
                if (/^[%=]/) {
                    # stop at =chapter= or %TOC%
                    $sortphase = 1;
                }
                if ($sortphase > 0) {
                    $sortothers .= $_;
                } else {
                    if (/^\* +(.+)/) {
                        # of the form:
                        # * name
                        # https://www.google.com/maps/@31.1956864,121.3522793,15z
                        $starname = $1;
                        $sortentires{$starname} = $_;
                    } else {
                        $sortentires{$starname} .= $_;
                    }
                }
            }
            $buffer = '';
            foreach $_ (sort keys %sortentires) {
                $buffer .= $sortentires{$_};
            }
            $buffer .= $sortothers;

            # update file
            &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
            &l00httpd::l00fwriteBuf($ctrl, $buffer);
            &l00httpd::l00fwriteClose($ctrl);
        }
    }


    # add new waypoint
    if (defined ($form->{'path'}) && 
        (defined ($form->{'addway'}) || defined ($form->{'pasteadd'})) &&
        defined ($form->{'desc'}) &&
        defined ($form->{'long'}) &&
        defined ($form->{'lat'})) {
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            $buffer = &l00httpd::l00freadAll($ctrl);
            if (defined ($form->{'pasteadd'})) {
                # get name from clipboard
                $form->{'desc'} = &l00httpd::l00getCB($ctrl);
                if (length($form->{'desc'}) < 1) {
                    $form->{'desc'} = "new$new";
                    $new++;
                } else {
                    $form->{'desc'} =~ s/\r//g;
                    $form->{'desc'} =~ s/\n//g;
                }
            }
            $buffer = "* $form->{'desc'}\n$form->{'lat'},$form->{'long'} $form->{'desc'}\n\n$buffer";

            # back up
            &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 5);
            # update file
            &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
            &l00httpd::l00fwriteBuf($ctrl, $buffer);
            &l00httpd::l00fwriteClose($ctrl);
        }
    } 

    # paste GPS
    if (defined ($form->{'path'}) && 
        defined ($form->{'gpsmark'})) {
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            my ($out, $lastcoor, $lastgps, $lastres);
            ($out, $gpslat, $gpslon, $lastcoor, $lastgps, $lastres)
                = &l00httpd::android_get_gps ($ctrl, 1, 0);
            $desc = "GPS$new $ctrl->{'now_string'}";
            $new++;
        }
    } 

    undef %labelsort;
    if (defined($form->{'selregex'})) {
        if (length($form->{'selregex'}) > 0) {
            $selregex = $form->{'selregex'};
        } else {
            $selregex = '';
        }
    }
    if (defined ($form->{'mkridx'})) {
        if ($form->{'mkridx'} < 26) {
            $_ = chr(65 + $form->{'mkridx'});
        } else {
            $_ = chr(97 + $form->{'mkridx'} - 26);
        }
        $_ = " Centered on marker '$_'";
    } elsif (defined($selregex) && (length($selregex) > 0)) {
        $_ = " Centered by matching pattern '$selregex'";
    } else {
        $_ = "";
    }
    # matched and exclude options:
    $tmp = '';
    if ($matched eq 'checked') {
        $tmp .= '&matched=on';
    }
    if ($exclude eq 'checked') {
        $tmp .= '&exclude=on';
    }

    $labeltable = '';
    $labeltable .= "Markers from <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}<a>\n";
    $labeltable .= "Description: latitude,longitude ";
    $labeltable .= "(<a href=\"/kml2gmap.htm?path=$form->{'path'}&width=$width&height=$height$tmp\">reload</a>; ";
    $labeltable .= "<a href=\"/kml2gmap.htm?path=$form->{'path'}&width=$width&height=$height&update=yes&matched=&exclude=&selregex=\">all</a>. ";
    $labeltable .= "<a href=\"#___end___\">end</a>. ";
    $labeltable .= "<a href=\"#__form__\">form</a>)";
    $labeltable .= "$_\n<pre>";
    if ($ctrl->{'os'} eq 'and') {
        $labeltable .= "<form action=\"/kml2gmap.htm\" method=\"get\">";
        $labeltable .= "<input type=\"submit\" name=\"gpsmark\" value=\"Read GPS\">";
        $labeltable .= "<input type=\"hidden\" name=\"width\" value=\"$width\">";
        $labeltable .= "<input type=\"hidden\" name=\"height\" value=\"$height\">";
        $labeltable .= "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">";
        $labeltable .= "</form>";
        if (defined ($form->{'path'}) && 
            defined ($form->{'gpsmark'})) {
            $labeltable .= "<br><font style=\"color:red;background-color:yellow\">Enter Description below and click 'Add waypoint'</font>\n";
            $tmp = "path=l00://waypoint.txt&addway=add&desc=GPS$new+$ctrl->{'now_string'}&long=$gpslon&lat=$gpslat";
            $tmp =~ s/ /+/g;
            $labeltable .= "<a href=\"/kml2gmap.htm?$tmp\">Save to RAM file</a>\n";
            $new++;
        }
        $labeltable .= "<br>";
    }
    $htmlout = '';
    if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
        $buffer = &l00httpd::l00freadAll($ctrl);
        if (!($form->{'path'} =~ /l00:\/\//)) {
            $pathbase = $form->{'path'};
            $pathbase =~ s/([\\\/])[^\\\/]+$/$1/;
            $newbuf = '';
            foreach $_ (split ("\n", $buffer)) {
                #%INCLUDE<./london.way>%
                if (/^%INCLUDE<\.[\\\/](.+?)>%/) {
                    $newbuf .= "%INCLUDE&lt;$pathbase$1&gt;\n";
                    if (&l00httpd::l00freadOpen($ctrl, "$pathbase$1")) {
                        $newbuf .= &l00httpd::l00freadAll($ctrl);
                    }
                } else {
                    $newbuf .= "$_\n";
                }
            }
            $buffer = $newbuf;
        }
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
            $htmlout .= "$_\n";
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
            } elsif (/^poly:/) {
                if ($starname ne '') {
                    # * name from line above over writes name from URL
                    $name = $starname;
                    $starname = '';
                }

                s/^poly: *//;
                $polyidx++;
                @polyline = split(" ", $_);
                $polybuf = "var polycoor$polyidx = [\n";
                foreach $polypt (@polyline) {
                    ($lat, $lon) = split(',', $polypt);
                    $polybuf .= "    {lat: $lat, lng: $lon},\n";
                }
                $polybuf .= 
                "  ];\n".
                "  var polypath$polyidx = new google.maps.Polyline({\n".
                "    path: polycoor$polyidx,\n".
                "    geodesic: true,\n".
                "    strokeColor: '#FF0000',\n".
                "    strokeOpacity: 1.0,\n".
                "    strokeWeight: 1\n".
                "  });\n";

                $myMarkers .= $polybuf;
                $mySetMap .= "polypath$polyidx.setMap(map);\n";
            } elsif (($lat, $lon, $name) = /([0-9.+-]+?),([0-9.+-]+?)[, ]+(.+)/) {
                # match, falls thru
                if ($starname ne '') {
                    # * name from line above over writes name from URL
                    $name = $starname;
                    $starname = '';
                }
            } elsif (/^\* +(.+)/) {
                # of the form:
                # * name
                # https://www.google.com/maps/@31.1956864,121.3522793,15z
                $starname = $1;
                next;
            } elsif (/^T +([NS])(\d\d)([0-9.\-]+) +([EW])(\d\d\d)([0-9.\-]+)/) {
                # of the form:
                #T  N3349.55193 W11802.27050 04-Nov-17 07:35:18  -31 ; gps 20171104 005423
                $lon = $5 + $6 / 60;
                $lat = $2 + $3 / 60;
                if ($4 eq 'W') {
                    $lon = -$lon;
                }
                if ($1 eq 'S') {
                    $lat = -$lat;
                }
                $name = "L$lnno";
            } else {
                #$starname = '';
                next;
            }

            # select marker by regex
            if (defined($selregex) && (length($selregex) > 0)) {
                if ($matched eq 'checked') {
                    # select all matching
                    if (!($name =~ /$selregex/i)) {
                        # name not matching, skip
                        next;
                    }
                } elsif ($exclude eq 'checked') {
                    # exclude all matching
                    if ($name =~ /$selregex/i) {
                        # name matched, skip
                        next;
                    }
                } else {
                    # center one matched
                    if ($name =~ /$selregex/i) {
                        # fake mkridx corresponding to $nomarkers
                        $form->{'mkridx'} = $nomarkers;
                    }
                }
            }

            # find max span
            if (defined ($form->{'mkridx'})) {
                if (!defined($lonmax)) {
                    # so it is always defined
                    $lonmax = $lon;
                    $lonmin = $lon;
                    $latmax = $lat;
                    $latmin = $lat;
                }
                if ($form->{'mkridx'} == $nomarkers) {
                    # and we overwrite if selected
                    $lonmax = $lon;
                    $lonmin = $lon;
                    $latmax = $lat;
                    $latmin = $lat;
                }
            } elsif (!defined($lonmax)) {
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

            # count markers
            $nomarkers++;
            $jname = $name;
            $jname =~ s/'/\\'/g;

            # var myCenter =new google.maps.LatLng(45.4357487,12.3098395);
            $myCenters .= "var myCenter$nowypts =new google.maps.LatLng($lat,$lon);\n";

            # var marker =new google.maps.Marker({ position:myCenter , });
            if ($nowypts < 26) {
                $jlabel = chr(65 + $nowypts);
            } elsif ($nowypts < 52) {
                $jlabel = chr(97 + $nowypts - 26);
            } else {
                $jlabel = "P$nowypts";
            }
            $labelsort{"$name -- $jlabel"}  = "<a href=\"/kml2gmap.htm?delln=$lnno&path=$form->{'path'}\">del</a>: ";
            $labelsort{"$name -- $jlabel"} .= "<a href=\"/kml2gmap.htm?path=$form->{'path'}&width=$width&height=$height&mkridx=$nowypts\">$jlabel</a>: ";
            $labelsort{"$name -- $jlabel"} .= "$name <a href=\"/clip.htm?update=&clip=";
            $labelsort{"$name -- $jlabel"} .= &l00httpd::urlencode ($name);
            $labelsort{"$name -- $jlabel"} .= "\" target=\"_blank\">:</a> ";
            $labelsort{"$name -- $jlabel"} .= "<a href=\"/clip.htm?update=&clip=$lat,$lon\" target=\"_blank\">$lat,$lon</a>\n";

            $myMarkers .= "var marker$nowypts =new google.maps.Marker({ ".
                "  position:myCenter$nowypts , \n".
                "  label: '$jlabel' , \n".
                "  title: '$jname'});\n";

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
        if (defined($lonmax) && defined($lonmin) &&
            defined($latmax) && defined($latmin)) {
        $ctrlat = ($latmax + $latmin) / 2;
            $ctrlon = ($lonmax + $lonmin) / 2;
        $span = sqrt (($lonmax - $lonmin) ** 2 + 
                      (($latmax - $latmin) * 
                      cos (($latmax + $latmin) / 2 / 180 
                        * 3.141592653589793)) ** 2);
        } else {
            $ctrlat = 0;
            $ctrlon = 0;
            $span = 180;
        }

        if (defined ($form->{'gpsmark'})) {
            # selecting one
            $zoom = 18;
            # the selected marker
            $ctrlon = $gpslon;
            $ctrlat = $gpslat;

            # var myCenter =new google.maps.LatLng(45.4357487,12.3098395);
            $myCenters .= "var myCenterGPS =new google.maps.LatLng($gpslat,$gpslon);\n";

            $myMarkers .= "var markerGPS =new google.maps.Marker({ ".
                "  position:myCenterGPS , \n".
                "  label: 'gps' , \n".
                "  title: 'GPS'});\n";

            # marker.setMap(map);
            $mySetMap .= "markerGPS.setMap(map);\n";
        } elsif ($nomarkers == 1) {
            # if only one marker or
            $zoom = 11;
        } elsif (defined ($form->{'mkridx'})) {
            # selecting one
            $zoom = 13;
            # the selected marker
            $ctrlon = ($lonmax + $lonmin) / 2;
            $ctrlat = ($latmax + $latmin) / 2;
        } else {
            if ($initzoom ne '') {
                $zoom = $initzoom;
            } else {
                $zoom = 1;
                if ($span > 1e-9) {
                    while (1) {
                        if ($span * 2 ** $zoom > 200) {
                            last;
                        }
                        $zoom++;
                        if ($zoom >= 17) {
                            last;
                        }
                    }
                }
            }
        }

        if ($drawgrid eq 'checked') {
            $drawgriddo = "</script><script type=\"text/javascript\" src=\"ls.htm?raw=on&path=$ctrl->{'plpath'}v3_ll_grat.js\">\n";
            $drawgriddo2 = "grid = new Graticule(map, false);\n";
        } else {
            $drawgriddo = "\n";
            $drawgriddo2 = "\n";
        }

        print $sock $ctrl->{'httphead'} . $htmlhead . "<title>kml2gmap</title>\n" . 
            $gmapscript0 .
            "src=\"http://maps.googleapis.com/maps/api/js?key=$apikey&libraries=places\">\n" .
            $drawgriddo .
            $gmapscript1 .
            "var  myCenter=new google.maps.LatLng($ctrlat,$ctrlon);\n" .
            $myCenters .
            $gmapscript2 .
            "  zoom:$zoom,\n" .
            "  scaleControl: true,\n" .
            "  mapTypeId:google.maps.MapTypeId.$_\n" .
            $gmapscript2a .
            $drawgriddo2 .
            $gmapscript2b .
            $myMarkers .
            $mySetMap .
            $gmapscript3 .
            $ctrl->{'htmlhead2'};

        print $sock "<a name=\"___top___\"></a>\n";
        print $sock "<input id=\"pac-input\" class=\"controls\" type=\"text\" placeholder=\"Search Box\" accesskey=\"s\">\n";
        print $sock "<div id=\"googleMap\" style=\"width:${width}px;height:${height}px;\"></div>\n";
    } else {
        print $sock $ctrl->{'httphead'} . $htmlhead . "<title>kml2gmap</title>\n" . $ctrl->{'htmlhead2'};
        print $sock "<a name=\"___top___\"></a>\n";
    }

    # sort markers
    foreach $_ (sort keys %labelsort) {
        $labeltable .= $labelsort{$_};
    }
    $labeltable .= "displaying $nowypts waypoints\n";
    $labeltable .= "</pre>\n";

    print $sock "<span id=\"zoom\">&nbsp;</span><br>";
    print $sock "<span id=\"coor\">&nbsp;</span><br>";
    print $sock "<span id=\"distance\">&nbsp;</span><p>\n";

    print $sock "Last markers: \n";
    print $sock "<a href=\"/kml2gmap.htm?path=$form->{'path'}&mkridx=0\">A</a> - ";
    print $sock "<a href=\"/kml2gmap.htm?path=$form->{'path'}&mkridx=1\">B</a> - ";
    print $sock "<a href=\"/kml2gmap.htm?path=$form->{'path'}&mkridx=2\">C</a> - ";
    print $sock "<a href=\"/kml2gmap.htm?path=$form->{'path'}&mkridx=3\">D</a> - ";
    print $sock "<a href=\"/kml2gmap.htm?path=$form->{'path'}&mkridx=4\">E</a> - ";
    print $sock "<a href=\"/kml2gmap.htm?path=$form->{'path'}&mkridx=5\">F</a><br>\n";

    print $sock "$labeltable\n";


    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}\n";
    print $sock "<a href=\"#__toc__\">TOC</a> - \n";
    print $sock "<a href=\"#__form__\">form</a> - \n";
    print $sock "<a href=\"#___end___\">end</a> - \n";
    print $sock "Download: <a href=\"/kml.htm/$form->{'path'}.kml?path=$form->{'path'}\">.kml</a> - \n";
    print $sock "Read: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a> - \n";
    print $sock "<a href=\"/view.htm?path=$form->{'path'}\">View</a> - \n";
    print $sock "<a href=\"/launcher.htm?path=$form->{'path'}\">Launcher</a><p>\n";


    if (defined ($form->{'path'})) {
        print $sock "<a name=\"__form__\"></a>\n";
        print $sock "<p><form action=\"/kml2gmap.htm\" method=\"get\">\n";
        print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
        print $sock "<tr><td>\n";
        if (($ctrl->{'os'} eq 'and') ||
            ($ctrl->{'os'} eq 'cyg') ||
            ($ctrl->{'os'} eq 'win')) {
            print $sock "<input type=\"submit\" name=\"pasteadd\" value=\"Paste Add\">\n";
        } else {
            print $sock "No clipboard\n";
        }
        print $sock "</td><td>\n";
        print $sock "<input type=\"submit\" name=\"addway\" value=\"A&#818;dd waypoint\" accesskey=\"a\">\n";
        print $sock "Click on map for coor\n";
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "Description:</td><td><input type=\"text\" name=\"desc\" size=\"12\" value=\"$desc\" accesskey=\"e\">\n";
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "Path:</td><td><input type=\"text\" name=\"path\" size=\"12\" value=\"$form->{'path'}\">\n";
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "Longitude:</td><td><input type=\"text\" name=\"long\" id=\"long\" size=\"12\" value=\"$gpslon\">\n";
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "Latitude:</td><td><input type=\"text\" name=\"lat\"  id=\"lat\"  size=\"12\" value=\"$gpslat\">\n";
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "<input type=\"checkbox\" name=\"matched\" $matched>matched <br><input type=\"checkbox\" name=\"exclude\" $exclude>exclude</td><td>regex <input type=\"text\" name=\"selregex\" size=\"5\" value=\"$selregex\">\n";
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "<input type=\"checkbox\" name=\"drawgrid\" $drawgrid>Show grids</td><td><input type=\"submit\" name=\"update\" value=\"Update\">\n";
        print $sock "zoom <input type=\"text\" name=\"initzoom\" size=\"5\" value=\"$initzoom\"> (was $zoom)\n";
        print $sock "</td></tr>\n";
        print $sock "</table><br>\n";
        print $sock "<input type=\"hidden\" name=\"width\" value=\"$width\">\n";
        print $sock "<input type=\"hidden\" name=\"height\" value=\"$height\">\n";
        print $sock "</form>\n";

        if ($htmlout ne '') {
            my ($pname, $fname);
            if (($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/) {
                $htmlout =~ s/path=\.\//path=$pname/g;
                $htmlout =~ s/path=\$/path=$pname$fname/g;
                print $sock &l00wikihtml::wikihtml ($ctrl, $pname, $htmlout, '', $fname);
            }
        }
    }

    print $sock "<a name=\"___end___\"></a>\n";
    print $sock "<form action=\"/kml2gmap.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"makemap\" value=\"Update\"></td><td>\n";
    print $sock "<input type=\"submit\" name=\"sort\" value=\"Sort\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Path:</td><td><input type=\"text\" name=\"path\" size=\"12\" value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Width:</td><td><input type=\"text\" name=\"width\" size=\"5\" value=\"$width\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Height:</td><td><input type=\"text\" name=\"height\" size=\"5\" value=\"$height\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"checkbox\" name=\"matched\" $matched>matched <br><input type=\"checkbox\" name=\"exclude\" $exclude>exclude</td><td>regex <input type=\"text\" name=\"selregex\" size=\"5\" value=\"$selregex\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"checkbox\" name=\"drawgrid\" $drawgrid>Show grids</td><td>&nbsp;\n";
    print $sock "</td></tr>\n";

    # map size pre-sets (16:9)
    print $sock "<tr>";
    print $sock "<td>landscape</td>\n";
    print $sock "<td>portrait</td>\n";
    print $sock "</tr>\n";
    foreach $_ ((   
            "300,200,350,350",
            "400,200,350,400",
            "500,300,350,450",
            "600,300,350,500",
            "700,400,450,450",
            "800,400,450,600",
            "900,500,450,750",
            "1000,600,450,950",
            "1100,600,600,600",
            "1200,700,600,750",
            "1300,700,600,950",
            "1400,800,600,1200",
            "1500,800,900,900",
            "1600,900,900,1200",
            "1700,1000,900,1500",
            "1800,1000,900,1800")) {
        my ($w1, $h1, $w2, $h2) = split(',', $_);
        print $sock "<tr>";
        print $sock "<td><a href=\"/kml2gmap.htm?path=$form->{'path'}&makemap=Update&width=$w1&height=$h1\">${w1}x$h1</a></td>\n";
        print $sock "<td><a href=\"/kml2gmap.htm?path=$form->{'path'}&makemap=Update&width=$w2&height=$h2\">${w2}x$h2</a></td>\n";
        print $sock "</tr>\n";
    }

    print $sock "</table>\n";
    print $sock "</form>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
