use strict;
use warnings;
use l00svg;
use l00base64;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# GPS map without data connection

my $lon = 0;
my $lat = 0;
my $path = '';
my $map = '';
my $marker = 'X';
my $color = 'ff0000';
my $scale = 100;
my $bare = '';

my ($mapwd, $mapht);
$mapwd = 800;
$mapht = 600;

my($base64fname, $base64data);
$base64fname = '';
$base64data = '';


my %config = (proc => "l00http_picannosvg_proc",
              desc => "l00http_picannosvg_desc");


# converts lon/lat to screen x/y coordinate
sub annoll2xysvg {
    my ($lonhtm, $lathtm) = @_;
    my ($pixx, $pixy);

    $pixx = int ($lonhtm * $scale / 100 + 0.5);
    $pixy = int ($lathtm * $scale / 100 + 0.5);

    ($pixx, $pixy);
}

# converts screen x/y coordinate to lon/lat
sub annoxy2llsvg {
    my ($pixx, $pixy) = @_;
    my ($lonhtm, $lathtm);

    $lonhtm = int ($pixx * 100 / $scale + 0.5);
    $lathtm = int ($pixy * 100 / $scale + 0.5);

    ($lonhtm, $lathtm);
}



sub l00http_picannosvg_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/

    "picannosvg: Annotate pictures";
}

sub l00http_picannosvg_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($pixx, $pixy, $pixx0, $pixy0, $buf, $lonhtm, $lathtm, $xx, $yy);
    my ($lond, $lonm, $lonc, $latd, $latm, $latc, $ext, $fname);
    my ($coor, $tmp, $svg, %annos, $xy, $annofile, $overlaymap, $mapurl);

    undef %annos;

    if (defined ($form->{'annofile'})) {
        $annofile = $form->{'annofile'};
    } else {
        $annofile = '';
    }
    $bare = '';
    if (defined ($form->{'bare'}) && ($form->{'bare'} eq 'on')) {
        $bare = 'checked';
    }

    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        if ($annofile ne '') {
            $map = $annofile;
        } else {
            $map = "$path.txt";
        }
    }

    # map clicked
    if (defined ($form->{'x'})) {
        ($lon, $lat) = &annoxy2llsvg ($form->{'x'}, $form->{'y'});
    }
    if (defined ($form->{'scale'})) {
        $scale = $form->{'scale'};
    }




    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>picannosvg</title>" . $ctrl->{'htmlhead2'};

    if (&l00httpd::l00freadOpen($ctrl, $map)) {
        $buf = '';
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            $buf .= $_;
            s/\n//; s/\r//;
            if (/^IMG_WD_HT=/) {
                ($mapwd, $mapht) = /^IMG_WD_HT=(\d+),(\d+)/;
                $mapwd = int ($mapwd * $scale / 100);
                $mapht = int ($mapht * $scale / 100);
		    }
            # read annotation
            if (/^(\d+),(\d+): +(.+)$/) {
                $annos{"$1,$2"} = $3;
            }
        }
        # write annotation and scale file if missing
        if (defined($form->{'set'}) &&
            defined($form->{'anno'}) && 
            (length($form->{'anno'}) > 0)) {
            ($xx, $yy) = &annoxy2llsvg ($form->{'atx'}, $form->{'aty'});
            $annos{"$xx,$yy"} = $form->{'anno'};
            $buf .= "$xx,$yy: $form->{'anno'}\n";
            if (&l00httpd::l00fwriteOpen($ctrl, $map)) {
                &l00httpd::l00fwriteBuf($ctrl, $buf);
                &l00httpd::l00fwriteClose($ctrl);
            }
        }
    } elsif (&l00httpd::l00fwriteOpen($ctrl, $map)) {
        &l00httpd::l00fwriteBuf($ctrl, "IMG_WD_HT=$mapwd,$mapht\n");
        &l00httpd::l00fwriteClose($ctrl);
        print $sock "Sample <a href=\"/view.htm?path=$map\" target=\"_blank\">$map</a> created as it was missing.  ".
            "<a href=\"/edit.htm?path=$map\" target=\"_blank\">Edit</a> it for correct image size.<p>\n";
    }



    if (open (IN, "<$path")) {
        close (IN);
        ($pixx, $pixy) = &annoll2xysvg ($lon, $lat);
        if (defined($form->{'x'})) {
            print $sock "<div style=\"position: absolute; left:$pixx"."px; top:$pixy"."px;\">\n";
            print $sock "<font color=\"$color\">$marker</font></div>\n";
        }
        # display annotations
        foreach $xy (keys %annos) {
            ($pixx, $pixy) = &annoll2xysvg (split(',', $xy));
            print $sock "<div style=\"position: absolute; left:$pixx"."px; top:$pixy"."px;\">\n";
            print $sock "<font color=\"$color\">$annos{$xy}</font></div>\n";
        }


# copied from l00http_gpsmapsvg.pl but not working
#        ($fname) = $path =~ /\/([^\/]+)$/;
#        $svg = "10,10 10,10 10,10 50,10 10,10";
#
#            $overlaymap  = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"no\"?>\n";
#            $overlaymap .= "<svg width=\"$mapwd"."px\" height=\"$mapht"."px\" viewBox=\"0 0 $mapwd $mapht\" xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\" xmlns:xlink=\"http://www.w3.org/1999/xlink\"> \n";
#            $overlaymap .= "<image x=\"0\" y=\"0\" width=\"$mapwd\" height=\"$mapht\" ";
#            if ($path ne $base64fname) {
#                $base64fname = $path;
#                $ext = '';
#                if (open(IN,"<$base64fname")){
#                    if ($base64fname =~ /\.(.+?$)/) {
#                        $ext = $1;
#                    }
#                    binmode(IN);
#                    local ($/);
#                    undef $/;
#                    $base64data = <IN>;
#                    close(IN);
#                    $base64data = l00base64::b64encode($base64data);
#                    $base64data = "data:image/$ext;base64,$base64data";
#                } else {
#                    # Can't open $base64fname
#                    $base64data = "/ls.htm?path=$path";
#                }
#            }
#            $overlaymap .= " xlink:href=\"$base64data\" />\n";
#            $overlaymap .= &l00svg::makesvgoverlaymap ($fname, $svg, $mapwd, $mapht, $path, '');
#            $overlaymap .= "\n";
#            $overlaymap .= "</svg>";
#            l00svg::setsvg("$fname.overlay", $overlaymap);
#
#            $mapurl = "/svg.htm?graph=$fname.overlay";

        $mapurl = "/ls.htm$path?path=$path&raw=on";

        print $sock "<form action=\"/picannosvg.htm\" method=\"get\">\n";
        print $sock "<input type=image width=$mapwd height=$mapht src=\"$mapurl\">\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
        print $sock "<input type=\"hidden\" name=\"annofile\" value=\"$annofile\">\n";
        print $sock "<input type=\"hidden\" name=\"annofile\" value=\"$annofile\">\n";
        print $sock "<input type=\"hidden\" name=\"bare\" value=\"\">\n";
        print $sock "</form>\n";
    }


    if (defined ($form->{'x'})) {
        if ($bare eq '') {
            print $sock "Clicked pixel (x,y): $form->{'x'},$form->{'y'}\n";
            print $sock "Pic (x,y): ", $form->{'x'} * 100 / $scale,',',$form->{'y'} * 100 / $scale,"<br>\n";
        }
    }
    if ($bare eq '') {
        print $sock "Max px (x,y): $mapwd,$mapht\n";
        print $sock "Max pic (x,y): ", $mapwd * 100 / $scale,',',$mapht * 100 / $scale,"<br>\n";

        print $sock "<p>$ctrl->{'home'} \n";
        print $sock "$ctrl->{'HOME'} \n";
        print $sock "Launch <a href=\"/launcher.htm?path=$path\" target=\"_blank\">$path</a> - ".
            "View <a href=\"/view.htm?path=$map\" target=\"_blank\">$map</a><p>\n";

        print $sock "<form action=\"/picannosvg.htm\" method=\"get\">\n";
        print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

        if (defined ($form->{'x'})) {
            print $sock "        <tr>\n";
            print $sock "            <td>A&#818;nnotation:</td>\n";
            print $sock "            <td><input type=\"text\" size=\"16\" name=\"anno\" value=\"\" accesskey=\"a\">".
                    "<input type=\"hidden\" name=\"atx\" value=\"$form->{'x'}\">\n".
                    "<input type=\"hidden\" name=\"aty\" value=\"$form->{'y'}\">\n".
                    "</td>\n";
            print $sock "        </tr>\n";
        }
                                                    
        print $sock "    <tr>\n";
        print $sock "        <td><input type=\"submit\" name=\"set\" value=\"S&#818;et\" accesskey=\"s\">".
                    "            <input type=\"submit\" name=\"refresh\" value=\"R&#818;efresh\" accesskey=\"r\"></td>\n";
        print $sock "        <td>Sc&#818;ale <input type=\"text\" size=\"6\" name=\"scale\" value=\"$scale\" accesskey=\"c\"></td>\n";
        print $sock "    </tr>\n";

        print $sock "    <tr>\n";
        print $sock "        <td><input type=\"checkbox\" name=\"bare\" $bare>Bare page</td>\n";
        print $sock "        <td>Notes: <input type=\"text\" size=\"16\" name=\"annofile\" value=\"$annofile\"></td>\n";
        print $sock "    </tr>\n";

        print $sock "</table>\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
        print $sock "</form>\n";
    }

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
