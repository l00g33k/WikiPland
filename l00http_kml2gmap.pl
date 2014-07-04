#use strict;
#use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Copy to Android 

my %config = (proc => "l00http_kml2gmap_proc",
              desc => "l00http_kml2gmap_desc");

sub l00http_kml2gmap_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "kml2gmap: Create a link that send .kml to device Google Maps";
}


sub l00http_kml2gmap_proc {
    my ($main);
    ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    $sock = $ctrl->{'sock'};     # dereference network socket
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
    if (defined ($form->{'host'})) {
        $host = $form->{'host'};
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>kml2gmap</title>\n" . $refreshtag . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";

    if ((!($mypath =~ m|/|)) && (!($mypath =~ m|\\|))) {
        # try default path
        $mypath = $ctrl->{'plpath'} . $mypath;
    }

    print $sock "<form action=\"/kml2gmap.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"do\" value=\"Create link\"><p>\n";
    print $sock "Path: <input type=\"text\" name=\"path\" size=\"12\" value=\"$mypath\"><br>\n";
    print $sock "Host: <input type=\"text\" name=\"host\" size=\"12\" value=\"$host\"><br>\n";
    print $sock "</form>\n";

    print $sock "<p>\n";

    $tmp = &l00httpd::urlencode ("$host/kml.htm?path=$mypath");
    print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">Copy external URL to clipboard</a><p>\n";
    print $sock "<a href=\"$host/kml.htm?path=$mypath\">$host/kml.htm?path=$mypath</a><p>\n";
    print $sock "<a href=\"geo:0,0?q=$host/kml.htm?path=$mypath\">geo:0,0?q=$host/kml.htm?path=$mypath</a>\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
