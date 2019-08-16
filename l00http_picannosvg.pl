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


my ($mapwd, $mapht);
$mapwd = 800;
$mapht = 600;


my %config = (proc => "l00http_picannosvg_proc",
              desc => "l00http_picannosvg_desc");


# converts lon/lat to screen x/y coordinate
sub annoll2xysvg {
    my ($lonhtm, $lathtm) = @_;
    my ($pixx, $pixy);

    $pixx = int ($lonhtm * $scale / 100);
    $pixy = int ($mapht * $scale / 100) - int ($lathtm * $scale / 100);

    ($pixx, $pixy);
}

# converts screen x/y coordinate to lon/lat
sub annoxy2llsvg {
    my ($pixx, $pixy) = @_;
    my ($lonhtm, $lathtm);

    $lonhtm = $pixx * 100 / $scale;
    $lathtm = $mapht - $pixy * 100 / $scale;

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
    my ($lond, $lonm, $lonc, $latd, $latm, $latc);
    my ($coor, $tmp, $svg, %annos, $xy);

    undef %annos;

    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        $map = "$path.txt";
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
            if (/^(\d+,\d+): +(.+)$/) {
                $annos{$1} = $2;
            }
        }
        # write annotation and scale file if missing
        if (defined($form->{'set'}) &&
            defined($form->{'anno'}) && 
            (length($form->{'anno'}) > 0)) {
            $annos{"$form->{'atx'},$form->{'aty'}"} = $form->{'anno'};
            $buf .= "$form->{'atx'},$form->{'aty'}: $form->{'anno'}\n";
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
            ($pixx, $pixy) = split(',', $xy);
            print $sock "<div style=\"position: absolute; left:$pixx"."px; top:$pixy"."px;\">\n";
            print $sock "<font color=\"$color\">$annos{$xy}</font></div>\n";
        }

        print $sock "<form action=\"/picannosvg.htm\" method=\"get\">\n";
        print $sock "<input type=image width=$mapwd height=$mapht src=\"/ls.htm$path?path=$path&raw=on\">\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
        print $sock "</form>\n";
    }


    if (defined ($form->{'x'})) {
        print $sock "Clicked pixel (x,y): $form->{'x'},$form->{'y'}\n";
        print $sock "Pic (x,y): ", $form->{'x'} * 100 / $scale,',',$form->{'y'} * 100 / $scale,"<br>\n";
    }
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

    print $sock "</table>\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
    print $sock "</form>\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
