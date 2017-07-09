# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14
use warnings;
use strict;

package l00svg;
my (%svggraphs, %svgparams);
my (@colors, $tmp);
my ($maxx, $maxy, $minx, $miny);
my ($mgl, $mgr, $mgt, $mgb, $txw, $txh, $txz);

$mgl = 70;
$mgr = 10;
$mgt = 10;
$mgb = 60;
$txh = 25;
$txw = 130;
$txz = 20;
$mgb = 10 + $txh;


#http://www.w3schools.com/tags/ref_colornames.asp
@colors = (
'Black', 
'Red',
'Blue', 
'DarkGreen', 
'Magenta', 
'BlueViolet', 
'MediumBlue',
'CadetBlue'
);


sub svg_graphlist {
    (sort keys %svggraphs);
}

sub svg_getCurveXY {
    my ($name, $idx, $off) = (@_);
    my ($cnt, $xx, $yy, @flds);

    undef $xx;
    undef $yy;
    $cnt = 0;
    if (defined ($svgparams{"$name"})) {
 
        foreach $_ (split (' ', $svgparams{"$name"})) {
 
            if ($cnt == $off) {
                if (@flds = split (',', $_)) {
                    $xx = $flds[0];
                    $yy = $flds[$idx + 1];
#                    # convert from data x,y to screen x,y
#                    ($xx, $yy) = &svg_curveXY2screenXY ($name, $idx, $xx, $yy);
                    last;
                }
            }
            $cnt++;
        }
    } else {
        $xx = 0;
		$yy = 0;
    }

    ($xx, $yy);
}

sub svg_curveXY2screenXY {
    my ($name, $idx, $xx, $yy) = (@_);

    # rescale
    if (defined ($svgparams{"$name"})) {
        if ($svgparams{"$name:maxx"} == $svgparams{"$name:minx"}) {
            # a constant x
            $xx = 0.5 *
                  ($svgparams{"$name:wd"} - $mgl - $mgr) + $mgl;
        } else {
            $xx = ($xx - $svgparams{"$name:minx"}) / 
                  ($svgparams{"$name:maxx"} - $svgparams{"$name:minx"}) *
                  ($svgparams{"$name:wd"} - $mgl - $mgr) + $mgl;
        }
        if ($svgparams{"$name:$idx:maxy"} == $svgparams{"$name:$idx:miny"}) {
            # a constant y
            $yy = ($svgparams{"$name:ht"} - $mgt - $mgb) - 
                  (0.5 * ($svgparams{"$name:ht"} - $mgt - $mgb)) + $mgt;
        } else {
            $yy = ($svgparams{"$name:ht"} - $mgt - $mgb) - 
                  (($yy - $svgparams{"$name:$idx:miny"}) /
                   ($svgparams{"$name:$idx:maxy"} - $svgparams{"$name:$idx:miny"}) *
                   ($svgparams{"$name:ht"} - $mgt - $mgb)) + $mgt;
        }
    } else {
        $xx = 0;
		$yy = 0;
    }

    ($xx, $yy);
}

# $svgxy is like: '0,1,2,4 1,4,4,1 2,2,5,8 3,19,11,3'
# $idx is index to y value
sub svg_convert_xy {
    my ($name, $svgxy, $idx, $wd, $ht) = (@_);
    my ($svg_xy2, $xx, $yy, $cnt);
    my (@flds);

    $cnt = 0;
    # scan whole curve for min/max
    $svgxy =~ s/^ *//;
    $svgxy =~ s/ *$//;
    foreach $_ (split (' ', $svgxy)) {
        # $_ is x,y0,y1, etc.
        # $idx is offset to curve, starting from 0
        if (@flds = split (',', $_)) {
            if (!defined($flds[$idx + 1])) {
                last;
            }
            if ($#flds < $idx + 1) {
                last;
            }
            #print ">$_<\n";
            $xx = $flds[0];
            $yy = $flds[$idx + 1];
            
            if ($cnt == 0) {
                $maxx = $xx;
                $minx = $xx;
                $maxy = $yy;
                $miny = $yy;
            } else {
                if ($xx > $maxx) { $maxx = $xx; }
                if ($xx < $minx) { $minx = $xx; }
                if ($yy > $maxy) { $maxy = $yy; }
                if ($yy < $miny) { $miny = $yy; }
            }
            $cnt++;
        }
    }

    # save data
    $svgparams{"$name"} = $svgxy;
    $svgparams{"$name:wd"} = $wd;
    $svgparams{"$name:ht"} = $ht;
    $svgparams{"$name:maxx"} = $maxx;
    $svgparams{"$name:minx"} = $minx;
    $svgparams{"$name:$idx:maxy"} = $maxy;
    $svgparams{"$name:$idx:miny"} = $miny;
    $svg_xy2 = '';
    if (defined($flds[$idx + 1])) {
        foreach $_ (split (' ', $svgxy)) {
            if (@flds = split (',', $_)) {
                $xx = $flds[0];
                $yy = $flds[$idx + 1];
                # $xx,$yy is curve x,y
                # rescale from curve x,y to screen x,y
                ($xx, $yy) = &svg_curveXY2screenXY ($name, $idx, $xx, $yy);
                # $xx,$yy has bene converted to screen x,y
                $svg_xy2 .= "$xx,$yy ";
            }
        }
    }

    $svg_xy2;
}

sub svg_convert_xy_mapoverlay {
    my ($name, $svgxy, $idx, $wd, $ht) = (@_);
    my ($svg_xy2, $xx, $yy, $cnt);
    my (@flds);


    # save data
    $svgparams{"$name"} = $svgxy;
    $svgparams{"$name:wd"} = $wd;
    $svgparams{"$name:ht"} = $ht;
    $svgparams{"$name:maxx"} = $wd;
    $svgparams{"$name:minx"} = 0;
    $svgparams{"$name:$idx:maxy"} = $ht;
    $svgparams{"$name:$idx:miny"} = 0;

    $svg_xy2 = '';
    foreach $_ (split (' ', $svgxy)) {
        if (($xx, $yy)  = split (',', $_)) {
            # $xx,$yy is curve x,y
            # rescale from curve x,y to screen x,y
            ($xx, $yy) = &svg_curveXY2screenXY ($name, $idx, $xx, $yy);
            # $xx,$yy has bene converted to screen x,y
            $svg_xy2 .= "$xx,$yy ";
        }
    }

    $svg_xy2;
}

# $data looks like '0,1 1,4 2,2 3,19'
# or '0,1,2,4 1,4,4,1 2,2,5,8 3,19,11,3'
# $wd, $ht is size of svg
sub plotsvg {
    my ($name, $data, $wd, $ht) = @_;
    my ($svg, $div, $ii, $svg_xy2, $color, $date, $x1, $x2, $y1, $y2);
    my ($se,$mi,$hr,$da,$mo,$yr,$dummy);


    $svg = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n";
    $svg .= "<svg width=\"$wd"."px\" height=\"$ht"."px\" viewBox=\"0 0 $wd $ht\" xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\"> ";

    for ($ii = 0; $ii < 999; $ii++) {
        # up to 999 curves
        $svg_xy2 = &svg_convert_xy ($name, $data, $ii, $wd, $ht);
        if ($svg_xy2 ne '') {
            $color = $colors[$ii & 7];
            $svg .= "<polyline fill=\"none\" stroke=\"$color\" stroke-width=\"2\" points=\"$svg_xy2\" />";
            $tmp = 2 + $txh + ($txh * $ii);
            $svg .= "<text x=\"2\" y=\"$tmp\" font-size=\"$txz\" fill=\"$color\">$maxy</text>";
            $tmp = $ht - 2 - $mgb - ($txh * $ii);
            $svg .= "<text x=\"2\" y=\"$tmp\" font-size=\"$txz\" fill=\"$color\">$miny</text>";
            if ($ii == 0) {
                $tmp = $ht - 5;
                if (($minx > 946713600) && ($minx < 1577865600)) {
                    # 946713600 is 2000/1/1 00:00:00, must be a date
                    # $dummy = &l00mktime::mktime (120, 0, 1, 0, 0, 0);
                    # print "sec $dummy\n";
                    # 1577865600 is 2020/1/1 00:00:00, must be a date
                    ($se,$mi,$hr,$da,$mo,$yr,$dummy,$dummy,$dummy) = gmtime ($minx);
                    $date = sprintf ("%02d%02d%02d:%02d%02d", $yr - 100, $mo + 1, $da, $hr, $mi);
                    $svg .= "<text x=\"$mgl\" y=\"$tmp\" font-size=\"$txz\" fill=\"black\">$date</text>";
                } else {
                    $svg .= "<text x=\"$mgl\" y=\"$tmp\" font-size=\"$txz\" fill=\"black\">$minx</text>";
                }
                if (($maxx > 946713600) && ($maxx < 1577865600)) {
                    # 946713600 is 2000/1/1 00:00:00, must be a date
                    # $dummy = &l00mktime::mktime (120, 0, 1, 0, 0, 0);
                    # print "sec $dummy\n";
                    # 1577865600 is 2020/1/1 00:00:00, must be a date
                    ($se,$mi,$hr,$da,$mo,$yr,$dummy,$dummy,$dummy) = gmtime ($maxx);
                    $date = sprintf ("%02d%02d%02d:%02d%02d", $yr - 100, $mo + 1, $da, $hr, $mi);
                    $svg .= "<text x=\"".int($wd-$txw-$mgr)."\" y=\"$tmp\" font-size=\"$txz\" fill=\"black\">$date</text>";
                } else {
                    $svg .= "<text x=\"".int($wd-$txw-$mgr)."\" y=\"$tmp\" font-size=\"$txz\" fill=\"black\">$maxx</text>";
                }
            }
        } else {
            last;
        }
    }
    $svg .= "<rect x=\"0\" y=\"0\" width=\"".int($wd-0) ."\" height=\"".int($ht-0) ."\" fill=\"none\" stroke=\"black\" stroke-width=\"1\" />";
    $svg .= "<rect x=\"$mgl\" y=\"$mgt\" width=\"".int($wd-$mgl-$mgr) ."\" height=\"".int($ht-$mgt-$mgb) ."\" fill=\"none\" stroke=\"black\" stroke-width=\"1\" />";
    $div = 8;
    for ($ii = 1; $ii < $div; $ii++) {
        # Y axis ticks
        $x1 = $mgl - 5;
        $y1 = int (($ht - $mgt - $mgb) * $ii / $div + $mgt);
        $x2 = $mgl;
        $y2 = int (($ht - $mgt - $mgb) * $ii / $div + $mgt);
        $svg .= "<line x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\" stroke=\"black\" stroke-width=\"1\" />";
        # X axis ticks
        $x1 = int (($wd - $mgl - $mgr) * $ii / $div + $mgl);
        $y1 = $ht - $mgb;
        $x2 = int (($wd - $mgl - $mgr) * $ii / $div + $mgl);
        $y2 = $ht - $mgb + 5;
        $svg .= "<line x1=\"$x1\" y1=\"$y1\" x2=\"$x2\" y2=\"$y2\" stroke=\"black\" stroke-width=\"1\" />";
    }


    $svg .= "</svg>";


    $svggraphs{$name} = $svg;
}

sub getsvg {
    my ($name) = @_;
    my ($ii, $data);

    if ($name eq 'demo') {
        $data = '';
        for ($ii = 0; $ii < 200; $ii++) {
            $data .= "$ii," . sin (2 * 3.1416 * $ii / 100) . ' ';
        }
        plotsvg ('demo', $data, 640, 480);
    }

    $svggraphs{$name};
}

sub plotsvgmapoverlay {
    my ($name, $data, $wd, $ht, $path, $waycolor) = @_;
    my ($svg, $div, $ii, $svg_xy2, $color, $date, $x1, $x2, $y1, $y2);
    my ($se,$mi,$hr,$da,$mo,$yr,$dummy);
    my (@tracks);

    # overwrite with no plot margin
    ($mgl, $mgr, $mgt, $mgb) = (0, 0, 0, 0);

    $svg = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n";
    $svg .= "<svg width=\"$wd"."px\" height=\"$ht"."px\" viewBox=\"0 0 $wd $ht\" xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\"> ";

    @tracks = split("::", $data);
    foreach $data (@tracks) {
        $svg_xy2 = &svg_convert_xy_mapoverlay ($name, $data, 0, $wd, $ht);
        if ($svg_xy2 ne '') {
            $svg .= "<polyline fill=\"none\" stroke=\"#$waycolor\" stroke-width=\"2\" points=\"$svg_xy2\" />";
        }
    }
    $svg .= "</svg>";
    $svggraphs{$name} = $svg;

    l00httpd::dbp(__FILE__, "Tracks.  <a href=\"/svg.htm?view=&graph=$name\">$name</a>\n");
    $svg =~ s/</&lt;/g;
    $svg =~ s/>/&gt;/g;
    l00httpd::dbp(__FILE__, "\n$svg\n");

    # restore plot margin
    ($mgl, $mgr, $mgt, $mgb) = (70, 10, 10, 60);

#    $svg = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n";
#    $svg .= "<svg  x=\"0\" y=\"0\" width=\"$wd\" height=\"$ht\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" xml:space=\"preserve\" viewBox=\"0 0 $wd $ht\" preserveAspectRatio=\"xMidYMid meet\">";
#    $svg .= "<g id=\"bitmap\" style=\"display:online\"> ";
#    $svg .= "<image x=\"0\" y=\"0\" width=\"$wd\" height=\"$ht\" xlink:href=\"/ls.htm/$name?path=$path\" /> ";
#    $svg .= "</g> ";
#    $svg .= "<g id=\"$name\" style=\"display:online\"> <g transform=\"translate(0 0)\"> <g transform=\"scale(1.0)\"> <image x=\"0\" y=\"0\" width=\"$wd\" height=\"$ht\" xlink:href=\"/svg.htm?graph=$name\"/> </g> </g> </g>";
#    $svg .= "</svg>";
#    $svggraphs{"${name}.ovly.svg"} = $svg;
#
#    l00httpd::dbp(__FILE__, "Overlay\n");
#    $svg =~ s/</&lt;/g;
#    $svg =~ s/>/&gt;/g;
#    l00httpd::dbp(__FILE__, "$svg\n");
}


1;
