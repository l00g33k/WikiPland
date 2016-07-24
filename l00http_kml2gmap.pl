use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

my ($gmapscript);

$gmapscript = <<ENDOFSCRIPT;
<script
src="http://maps.googleapis.com/maps/api/js">
</script>

<script>
var myCenter=new google.maps.LatLng(45.4357487,12.3098395);
var myCenter2=new google.maps.LatLng(46.4357487,13.3098395);

function initialize()
{
var mapProp = {
  center:myCenter,
  zoom:7,
  mapTypeId:google.maps.MapTypeId.ROADMAP
  };

var map=new google.maps.Map(document.getElementById("googleMap"),mapProp);

var marker=new google.maps.Marker({
  position:myCenter,
  });
var marker2=new google.maps.Marker({
  position:myCenter2,
  });

marker.setMap(map);
marker2.setMap(map);
}

google.maps.event.addDomListener(window, 'load', initialize);
</script>
ENDOFSCRIPT


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
    my ($mypath, $host, $tmp);

    $mypath = '';
    if (defined ($form->{'path'})) {
        $mypath = $form->{'path'};
    }

    if (defined ($ctrl->{'kml2gmap'})) {
        $host = $ctrl->{'kml2gmap'};
    } else {
        $host = 'http://127.0.0.1:20337';
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $htmlhead . "<title>kml2gmap</title>\n" . 
        $gmapscript .
        $ctrl->{'htmlhead2'};

    if (defined ($form->{'generate'})) {
        print $sock "<div id=\"googleMap\" style=\"width:500px;height:380px;\"></div>\n";
    } else {
        print $sock "View or download <a href=\"/kml2gmap.htm?path=$mypath&generate=gen\">Google Maps HTML file</a>.\n";
    }


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
