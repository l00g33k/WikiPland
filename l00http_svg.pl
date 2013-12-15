
use strict;
use warnings;
use l00wikihtml;
use l00svg;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# SVG graph


my %config = (proc => "l00http_svg_proc",
              desc => "l00http_svg_desc");

sub l00http_svg_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "svg: Plotting svg graphs";
}

sub l00http_svg_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($ii, $data, $svg, $size, $graphname, $x, $xpix, $y, $ypix, $off);
    my ($se,$mi,$hr,$da,$mo,$yr,$dummy, $date);


    if (defined ($form->{'view'})) {
        # Send HTTP and HTML headers
        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>l00httpd</title>" . $ctrl->{'htmlhead2'};
        $graphname = 'demo';
        if (defined ($form->{'graph'})) {
            $graphname = $form->{'graph'};
        }

        print $sock "<form action=\"/svg.htm\" method=\"get\">\n";
        print $sock "<input type=image style=\"float:none\" src=\"/svg.htm?graph=$graphname\"><br>\n";

        if (defined ($form->{'x'})) {
            $off = 0;
            while (1) {
                ($x, $y) = &l00svg::svg_getCurveXY (
                    $graphname, 0, $off);
                if (!defined($x)) {
                    $x = 0;
                    $y = 0;
                    last;
                }
                ($xpix, $ypix) = &l00svg::svg_curveXY2screenXY (
                    $graphname, 0, $x, $y);
#print "find #$off: ($x,$y) -> ($xpix, $ypix)\n";
                if ($xpix < $form->{'x'}) {
                    last;
                }
                $off++;    
            }
#           print $sock "<div style=\"position: absolute; left:$form->{'x'}px; top:$form->{'y'}px;\">\n";
            print $sock "<div style=\"position: absolute; left:$xpix"."px; top:$ypix"."px;\">\n";
            print $sock "<font color=\"red\">X</font></div>\n";
        }

        print $sock "<input type=\"hidden\" name=\"graph\" value=\"$graphname\">\n";
        print $sock "<input type=\"hidden\" name=\"view\">\n";
        print $sock "</form>\n";

        print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a>\n";
        print $sock "Click graph above.\n";
        if (defined ($form->{'x'})) {
            print $sock "You clicked: ($form->{'x'},$form->{'y'})<br>\n";
            if (($x > 946713600) && ($x < 1577865600)) {
                # 946713600 is 2000/1/1 00:00:00, must be a date
                # $dummy = &l00mktime::mktime (120, 0, 1, 0, 0, 0);
                # print "sec $dummy\n";
                # 1577865600 is 2020/1/1 00:00:00, must be a date
                ($se,$mi,$hr,$da,$mo,$yr,$dummy,$dummy,$dummy) = gmtime ($x);
                $date = sprintf ("%02d%02d%02d:%02d%02d", $yr - 100, $mo + 1, $da, $hr, $mi);
                print $sock "Values: ($date, $y)<br>\n";
            } else {
                print $sock "Values: ($x, $y)<br>\n";
            }
        }
        print $sock "<p><a href=\"/svg.htm\">List of all graphs</a><br>\n";

        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
    } elsif (defined ($form->{'graph'})) {
        # return pre-created graph
        $svg = &l00svg::getsvg($form->{'graph'});
        $size = length($svg);
        print $sock "HTTP/1.1 200 OK\r\n".
                    "Content-Type: image/svg+xml\r\n".
                    "Content-Length: $size\r\n".
                    "Connection: close\r\n".
                    "Server: l00httpd\r\n".
                    "\r\n";
        syswrite ($sock, $svg, $size);
        $sock->close;
    } else {
        # wrong usage, demo feature
        # create the demo
        &l00svg::getsvg('demo');

        # Send HTTP and HTML headers
        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>l00httpd</title>" . $ctrl->{'htmlhead2'};
        print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a><br>\n";

        print $sock "<a href=\"/svg.htm?graph=demo&view=\">Viewer demo</a><br>\n";
        print $sock "SVG plotting demo:<p>\n";
        print $sock "<a href=\"/svg.htm?graph=demo\">".
        "<img src=\"/svg.htm?graph=demo\">".
        "</a>\n";

        print $sock "<p>List of graphs in memory:<br>\n";
        foreach $_ (&l00svg::svg_graphlist()) {
            print $sock "<a href=\"/svg.htm?graph=$_&view=\">$_</a><br>\n";
		}

        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
    }


}


\%config;
