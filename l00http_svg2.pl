
use strict;
use warnings;
use l00wikihtml;
use l00svg;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# SVG graph


my %config = (proc => "l00http_svg2_proc",
              desc => "l00http_svg2_desc");
my ($lastx, $lasty, $lastoff, $svgwd, $svght, $extractor, $extractororg);
$svgwd = 500;
$svght = 300;
$extractororg = '([0-9.\-+fe]+)[, :]+([0-9.\-+fe]+)';
$extractor = $extractororg;

sub l00http_svg2_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "svg: Plotting svg graphs";
}

sub l00http_svg2_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($ii, $data, $svg, $size, $graphname, $x, $xpix, $y, $ypix, $off);
    my ($se,$mi,$hr,$da,$mo,$yr,$dummy, $date, $httphdr, $lnno, $cnt);


    if (defined ($form->{'view'})) {
        # Send HTTP and HTML headers
        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>svg2</title>" . $ctrl->{'htmlhead2'};
        $graphname = 'demo';
        if (defined ($form->{'graph'})) {
            $graphname = $form->{'graph'};
        }

        print $sock "<form action=\"/svg2.htm\" method=\"get\">\n";
        print $sock "<input type=image style=\"float:none\" src=\"/svg2.htm?graph=$graphname\"><br>\n";

        if (defined ($form->{'x'})) {
            $off = 0;
            while (1) {
                ($x, $y) = &l00svg::svg2_getCurveXY (
                    $graphname, 0, $off);
                if (!defined($x)) {
                    $x = 0;
                    $y = 0;
                    last;
                }
                ($xpix, $ypix) = &l00svg::svg2_curveXY2screenXY (
                    $graphname, 0, $x, $y);
                if ($xpix >= $form->{'x'}) {
                    last;
                }
                $off++;    
            }
            $xpix += 3;
            $ypix += 0;
            print $sock "<div style=\"position: absolute; left:$xpix"."px; top:$ypix"."px;\">\n";
            print $sock "<font color=\"red\">+</font></div>\n";
        }

        print $sock "<input type=\"hidden\" name=\"graph\" value=\"$graphname\">\n";
        print $sock "<input type=\"hidden\" name=\"view\">\n";
        print $sock "</form>\n";

        print $sock "$ctrl->{'home'} $ctrl->{'HOME'}\n";
        print $sock "Click graph above.\n";
        if (defined ($form->{'x'})) {
            print $sock "You clicked: ($form->{'x'},$form->{'y'})<br>\n";
            if (($x > 946713600) && ($x < 1577865600)) {
                # 946713600 is 2000/1/1 00:00:00, must be a date
                # $dummy = &l00mktime::mktime (120, 0, 1, 0, 0, 0);
                # print "sec $dummy\n";
                # 1577865600 is 2020/1/1 00:00:00, must be a date
                ($se,$mi,$hr,$da,$mo,$yr,$dummy,$dummy,$dummy) = gmtime ($x);
                $date = sprintf ("%02d%02d%02d:%02d%02d%02d", $yr - 100, $mo + 1, $da, $hr, $mi, $se);
                print $sock "Values: ($date, $y) [#$off]<br>\n";
            } else {
                print $sock "Values: ($x, $y) [#$off]<br>\n";
            }
            my ($rnghi, $rnglo);
            # get base graph name
            $rnghi = 0;
            $rnglo = 0;
            if ($graphname =~ /^(.+?):(.+?):(.+?):$/) {
                ($graphname, $rnghi, $rnglo) = ($1, $2, $3);
            }
            if (defined($lastx)) {
                if (($x > 946713600) && ($x < 1577865600)) {
                    print $sock "Delta: (", ($x - $lastx) / 3600, " hr, ", $y - $lasty, " ) [#", $off - $lastoff, "]<br>\n";
                } else {
                    print $sock "Delta: (", $x - $lastx, ", ", $y - $lasty, " ) [#", $off - $lastoff, "]<br>\n";
                }
                if ($off > $lastoff) {
                    $_ = "$graphname:$off:$lastoff:";
                } else {
                    $_ = "$graphname:$lastoff:$off:";
                }
                print $sock "Zoom <a href=\"/svg2.htm?graph=$_&view=\">selection</a>";
                if (($rnghi != 0) && ($rnglo != 0)) {
                    $_ = "$graphname:".
                        ($rnghi + int(($rnghi-$rnglo)/2))
                        .":".
                        ($rnglo - int(($rnghi-$rnglo)/2))
                        .":";
                    print $sock ", <a href=\"/svg2.htm?graph=$_&view=\">zoom out</a>";
                }
                print $sock ", <a href=\"/svg2.htm?graph=$graphname&view=\">reset</a><br>\n";
            } else {
                if (($rnghi != 0) && ($rnglo != 0)) {
                    print $sock "Zoom ";
                    if (($rnghi != 0) && ($rnglo != 0)) {
                        $_ = "$graphname:".
                            ($rnghi + int(($rnghi-$rnglo)/2))
                            .":".
                            ($rnglo - int(($rnghi-$rnglo)/2))
                            .":";
                        print $sock ", <a href=\"/svg2.htm?graph=$_&view=\">zoom out</a>";
                    }
                    print $sock ", <a href=\"/svg2.htm?graph=$graphname&view=\">reset</a><br>\n";
                }
            }

            $lastx = $x;
            $lasty = $y;
            $lastoff = $off;
        }
        print $sock "<p><a href=\"/svg2.htm\">List of all graphs</a><br>\n";

        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
    } elsif (defined ($form->{'graph'})) {
        # return pre-created graph
        $svg = &l00svg::getsvg2($form->{'graph'});
        $size = length($svg);
        print $sock "HTTP/1.1 200 OK\r\n".
                    "Content-Type: image/svg+xml\r\n".
                    "Content-Length: $size\r\n".
                    "Connection: close\r\n".
                    "Server: l00httpd\r\n".
                    "\r\n";
        syswrite ($sock, $svg, $size);
        $sock->close;
    } elsif (defined ($form->{'path'})) {
        $httphdr = "$ctrl->{'httphead'}$ctrl->{'htmlhead'}$ctrl->{'htmlttl'}$ctrl->{'htmlhead2'}";
        $httphdr .= "<a name=\"top\"></a>$ctrl->{'home'} $ctrl->{'HOME'}<a href=\"#end\">end</a> -\n";
        if (defined ($form->{'path'})) {
            $httphdr .= "Path: <a href=\"/view.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";
        }
        print $sock "$httphdr<br>\n";

        if (defined($form->{'plot'})) {
            if (defined($form->{'svgwd'}) && ($form->{'svgwd'} =~ /(\d+)/)) {
                $svgwd = $1;
            }
            if (defined($form->{'svght'}) && ($form->{'svght'} =~ /(\d+)/)) {
                $svght = $1;
            }
            if (defined($form->{'extractor'}) && (length($form->{'extractor'}) > 3)) {
                $extractor = $form->{'extractor'};
            } else {
                $extractor = $extractororg;
            }
        }

        print $sock "<form action=\"/svg2.htm\" method=\"get\">\n";
        print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

        print $sock "        <tr>\n";
        print $sock "            <td><input type=\"submit\" name=\"plot\" value=\"Plot\"></td>\n";
        print $sock "            <td><input type=\"text\" size=\"16\" name=\"path\" value=\"$form->{'path'}\"></td>\n";
        print $sock "        </tr>\n";
        print $sock "        <tr>\n";
        print $sock "            <td>Extrator regex</td>\n";
        print $sock "            <td><input type=\"text\" size=\"16\" name=\"extractor\" value=\"$extractor\"></td>\n";
        print $sock "        </tr>\n";
        print $sock "        <tr>\n";
        print $sock "            <td>width</td>\n";
        print $sock "            <td><input type=\"text\" size=\"6\" name=\"svgwd\" value=\"$svgwd\"></td>\n";
        print $sock "        </tr>\n";
        print $sock "        <tr>\n";
        print $sock "            <td>height</td>\n";
        print $sock "            <td><input type=\"text\" size=\"6\" name=\"svght\" value=\"$svght\"></td>\n";
        print $sock "        </tr>\n";

        print $sock "</table>\n";
        print $sock "</form><p>\n";
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            print $sock "View: <a href=\"/view.htm?path=l00://concat.txt\">l00://concat.txt</a><p>Processing $form->{'path'}:<br>\n";
            $data = "<pre>\n";
            $lnno = 0;
            $svg = '';
            $cnt = 0;
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                $lnno++;
                s/[\r\n]//g;
                if (($x, $y) = /$extractor/) {
                    $cnt++;
                    if (defined($y)) {
                        $svg .= " $x,$y";
                    } else {
                        $svg .= " $cnt,$x";
                    }
                }
                if ($lnno < 1000) {
                    $data .= "$_\n";
                }
            }
            $data .= "</pre>\n";
            &l00svg::plotsvg2 ($form->{'path'}, $svg, $svgwd, $svght);
            print $sock "<a href=\"/svg.pl?graph=$form->{'path'}&view=\"><img src=\"/svg.pl?graph=$form->{'path'}\" alt=\"alt\"></a>\n";

            print $sock "$data";
        }

        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
    } else {
        # wrong usage, demo feature
        # create the demo
        &l00svg::getsvg2('demo');

        # Send HTTP and HTML headers
        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>svg2 demo</title>" . $ctrl->{'htmlhead2'};
        print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<br>\n";

        print $sock "<a href=\"/svg2.htm?graph=demo&view=\">Viewer demo</a><br>\n";
        print $sock "SVG plotting demo:<p>\n";
        print $sock "<a href=\"/svg2.htm?graph=demo&view=\">".
        "<img src=\"/svg2.htm?graph=demo\">".
        "</a>\n";

        print $sock "<p>List of graphs in memory:<br>\n";
        foreach $_ (&l00svg::svg_graphlist()) {
            print $sock "<a href=\"/svg2.htm?graph=$_&view=\">$_</a><br>\n";
		}

        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
    }


}


\%config;
