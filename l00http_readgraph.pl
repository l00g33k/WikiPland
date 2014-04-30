use strict;
use warnings;
use l00wikihtml;
use l00svg;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# read graph


my %config = (proc => "l00http_readgraph_proc",
              desc => "l00http_readgraph_desc");
my ($lastx, $lasty, $lastoff);

sub l00http_readgraph_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "readgraph: Read readings off graph";
}

sub l00http_readgraph_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($ii, $data, $svg, $size, $graphname, $x, $xpix, $y, $ypix, $off);
    my ($se,$mi,$hr,$da,$mo,$yr,$dummy, $date, $graph, $grx, $gry, $bkgnd, $ovly);


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>l00httpd</title>" . $ctrl->{'htmlhead2'};

    $graphname = 'demo';

    print $sock "<form action=\"/readgraph.htm\" method=\"get\">\n";
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
            if ($xpix >= $form->{'x'}) {
                last;
            }
            $off++;    
        }
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
            print $sock "Values: ($date, $y) [#$off]<br>\n";
        } else {
            print $sock "Values: ($x, $y) [#$off]<br>\n";
        }
        if (defined($lastx)) {
            if (($x > 946713600) && ($x < 1577865600)) {
                print $sock "Delta: (", ($x - $lastx) / 3600, " hr, ", $y - $lasty, " ) [#", $off - $lastoff, "]<br>\n";
            } else {
                print $sock "Delta: (", $x - $lastx, ", ", $y - $lasty, " ) [#", $off - $lastoff, "]<br>\n";
            }
        }
        $lastx = $x;
        $lasty = $y;
        $lastoff = $off;
    }
    print $sock "<p><a href=\"/svg.htm\">List of all graphs</a><br>\n";

# <svg  x="0" y="0" width="875" height="532"xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xml:space="preserve" viewBox="0 0 875 532" preserveAspectRatio="xMidYMid meet"> <g id="bitmap" style="display:online"> <image x="0" y="0" width="875" height="532" xlink:href="/ls.htm/singapore.png?path=/sdcard/l00httpd/maps/cy.png" /> </g> <g id="PajekSVG" style="display:online"> <g transform="translate(0 0)"> <g transform="scale(1.0)"> <image x="0" y="0" width="875" height="532" xlink:href="/svg.htm?graph=battvolt"/> </g> </g> </g> </svg>

#<svg  x="0" y="0" width="875" height="532" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" xml:space="preserve" viewBox="0 0 875 532" preserveAspectRatio="xMidYMid meet">
# <g id="bitmap" style="display:online">
#   <image x="0" y="0" width="875" height="532" xlink:href="/ls.htm/singapore.png?path=/sdcard/l00httpd/maps/cy.png" />
# </g>
# <g id="PajekSVG" style="display:online">
#   <g transform="translate(0 0)">
#     <g transform="scale(1.0)">
#       <image x="0" y="0" width="875" height="532" xlink:href="/svg.htm?graph=battvolt"/>
#     </g>
#   </g>
# </g>
#</svg>

#           &l00svg::plotsvg ('battvolt', $svgvolt, $graphwd, $graphht);
$bkgnd = '/ls.htm?path=/sdcard/l00httpd/maps/cy.png';
$ovly = '/svg.htm?graph=battvolt';
$ovly = '/svg.htm?graph=readgraph';
$grx = 875;
$gry = 532;
            &l00svg::plotsvg ('readgraph', '0,3 1,6 2,3 3,5', $grx, $gry);
$graph = '';
$graph .= "<svg  x=\"0\" y=\"0\" width=\"$grx\" height=\"$gry\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" xml:space=\"preserve\" viewBox=\"0 0 $grx $gry\" preserveAspectRatio=\"xMidYMid meet\">";
$graph .= " <g id=\"bitmap\" style=\"display:online\">";
$graph .= "   <image x=\"0\" y=\"0\" width=\"$grx\" height=\"$gry\" xlink:href=\"$bkgnd\" />";
$graph .= " </g>";
$graph .= " <g id=\"PajekSVG\" style=\"display:online\">";
$graph .= "   <g transform=\"translate(0 0)\">";
$graph .= "     <g transform=\"scale(1.0)\">";
$graph .= "       <image x=\"0\" y=\"0\" width=\"$grx\" height=\"$gry\" xlink:href=\"$ovly\"/>";
$graph .= "     </g>";
$graph .= "   </g>";
$graph .= " </g>";
$graph .= "</svg>";
#	$graph =~ s/</&lt;/g;
#	$graph =~ s/>/&gt;/g;
print $sock $graph;

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};


}


\%config;
