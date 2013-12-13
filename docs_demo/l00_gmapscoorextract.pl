
use l00wikihtml;


my $form, $gmaplink, $lon, $lat;
$form = $ctrl->{'FORM'};

if (defined ($form->{'arg1'})) {
    $gmaplink = $form->{'arg1'};
}


if (defined ($gmaplink) && (length($gmaplink) > 4)) {
    print $sock "Google Maps link entered:<br>\n";
    print $sock "$gmaplink<br>\n";
 
    if (($lat,$lon) = $gmaplink =~ /&*ll=([0-9.+\-]+),([0-9.+\-]+)&*/) {
        print $sock "<form>\n";
        print $sock "Lon,Lat: <input type=\"text\" value=\"$lon,$lat,?\"><p>\n";
        print $sock "Send to clipboard: <a href=\"/clip.htm?update=Copy+to+clipboard&clip=$lon%2C$lat%2C%3F\">$lon,$lat,?</a>\n";
        print $sock "</form>\n";
    } else {
        print $sock "Did not find coordinate between &amp;=36.223438,-119.333835&amp;\n";
    }
} else {
    print $sock "Enter Google Maps link in 'Arg1' below\n";
}

print $sock "<p>Extract Google Maps link coordinate<br>\n";
