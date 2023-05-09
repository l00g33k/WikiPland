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

my (%allannos, $allannos_base, @allannonames);

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


sub picanno_allanno {
    my ($ctrl, $allanno) = @_;
    my ($ret, $fname, $annos);

    $ret = 0;
    $fname = '';

    if (&l00httpd::l00freadOpen($ctrl, $allanno)) {
        #IMG_WORKDIR=c:\2\photo_europe2023\2n8\
        #IMG_WD_HT=800,600
        #
        #IMG_NAME=20230421_144637.jpg
        #254,466: anno 1
        #59,553: lower left coner
        #
        #IMG_NAME=20230421_164536.jpg
        #59,553: 20230421_164536
        #
        #IMG_NAME=20230421_164552.jpg
        #59,553: 20230421_164552
        #
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            s/[\r\n]//g;
            if (/^#/) {
                next;
            }
            if (/^IMG_WORKDIR=(.+)$/) {
                $allannos_base = $1;
            }
            if (/^IMG_WD_HT=/) {
                ($mapwd, $mapht) = /^IMG_WD_HT=(\d+),(\d+)/;
                $mapwd = int ($mapwd * $scale / 100);
                $mapht = int ($mapht * $scale / 100);
		    }
            if (/^IMG_NAME=(.+)$/) {
                $fname = $1;
                $annos = '';
            }
            if (/^ *$/) {
                if ($fname ne '') {
                    $allannos{$fname} = $annos;
                    $fname = '';
                }
            }
            # read annotations as hash
            if (/^(\d+),(\d+): +(.+)$/) {
                if ($annos ne '') {
                    $annos .= "\n";
                }
                $annos .= $_;
            }
        }
        @allannonames = keys %allannos;
    }

    $ret;
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
    my ($allanno, $picname, $ii, $nextpic, $nexturl);

    undef %annos;
    undef %allannos;


    # process all annotations
    if (defined ($form->{'allanno'})) {
        $allanno = $form->{'allanno'};
        if (-f $allanno) {
            if (&picanno_allanno ($ctrl, $allanno)) {
                $allanno = '';
            }
        }
    } else {
        $allanno = '';
    }


    if ($allanno ne '') {
        # save path to picture
        if (defined ($form->{'path'})) {
            $path = $form->{'path'};
            $picname = $path;
            $picname =~ s/.+[\\\/]//;

            $bare = '';
            if (defined ($form->{'bare'}) && ($form->{'bare'} eq 'on')) {
                $bare = 'checked';
            }

            undef %annos;
            foreach $_ (split("\n", $allannos{$picname})) {
                if (/^(\d+),(\d+): +(.+)$/) {
                    $annos{"$1,$2"} = $3;
                }
            }

            for ($ii = 0; $ii <= $#allannonames; $ii++) {
                if ($picname eq $allannonames[$ii]) {
                    $ii++;
                    last;
                }
            }
            if ($ii > $#allannonames) {
                $ii = 0;
            }
            $nextpic = $allannonames[$ii];
        }
    } else {
        # save annotation file path
        if (defined ($form->{'annofile'})) {
            $annofile = $form->{'annofile'};
        } else {
            $annofile = '';
        }
        # save bare (no form) flag
        $bare = '';
        if (defined ($form->{'bare'}) && ($form->{'bare'} eq 'on')) {
            $bare = 'checked';
        }

        # save path to picture
        if (defined ($form->{'path'})) {
            $path = $form->{'path'};
            if ($annofile ne '') {
                # use supplied annofile
                $map = $annofile;
            } else {
                # default to .jpg.txt
                $map = "$path.txt";
            }
        }

        # process map clicks
        if (defined ($form->{'x'})) {
            # convert to picture resolution
            ($lon, $lat) = &annoxy2llsvg ($form->{'x'}, $form->{'y'});
        }
        # save scale
        if (defined ($form->{'scale'})) {
            $scale = $form->{'scale'};
        }
    }


    if ($allanno ne '') {
        # Send HTTP and HTML headers
        $nexturl = "/picannosvg.htm?refresh=y&scale=$scale&allanno=$allanno&path=$allannos_base$nextpic";
#        if ($bare eq 'checked') {
            $nexturl .= "&bare=on";
#        }
        #<meta http-equiv=\"refresh\" content=\"2; url=$nexturl\">
        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>picannosvg</title>" . "<meta http-equiv=\"refresh\" content=\"3; url=$nexturl\">" . $ctrl->{'htmlhead2'};
    } else {
        # Send HTTP and HTML headers
        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>picannosvg</title>" . $ctrl->{'htmlhead2'};
        if (&l00httpd::l00freadOpen($ctrl, $map)) {
            # parse annofile
            $buf = '';
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                $buf .= $_;
                s/\n//; s/\r//;
                # parse image resolution
                if (/^IMG_WD_HT=/) {
                    ($mapwd, $mapht) = /^IMG_WD_HT=(\d+),(\d+)/;
                    $mapwd = int ($mapwd * $scale / 100);
                    $mapht = int ($mapht * $scale / 100);
		        }
                # read annotations as hash
                if (/^(\d+),(\d+): +(.+)$/) {
                    $annos{"$1,$2"} = $3;
                }
            }
            # update annotation if setting annotation
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
            # failed to read annofile, write a blank one
            &l00httpd::l00fwriteBuf($ctrl, "IMG_WD_HT=$mapwd,$mapht\n");
            &l00httpd::l00fwriteClose($ctrl);
            print $sock "Sample <a href=\"/view.htm?path=$map\" target=\"_blank\">$map</a> created as it was missing.  ".
                "<a href=\"/edit.htm?path=$map\" target=\"_blank\">Edit</a> it for correct image size.<p>\n";
        }
    }


    # if picture exist
    if (open (IN, "<$path")) {
        close (IN);
        ($pixx, $pixy) = &annoll2xysvg ($lon, $lat);
        if ($allanno eq '') {
            if (defined($form->{'x'})) {
                # mark X if clicked
                print $sock "<div style=\"position: absolute; left:$pixx"."px; top:$pixy"."px;\">\n";
                print $sock "<font color=\"$color\">$marker</font></div>\n";
            }
        }
        # display annotations
        foreach $xy (keys %annos) {
            ($pixx, $pixy) = &annoll2xysvg (split(',', $xy));
            print $sock "<div style=\"position: absolute; left:$pixx"."px; top:$pixy"."px;\">\n";
            print $sock "<font color=\"$color\">$annos{$xy}</font></div>\n";
        }

        # path to picture
        $mapurl = "/ls.htm$path?path=$path&raw=on";

        print $sock "<form action=\"/picannosvg.htm\" method=\"get\">\n";
        print $sock "<input type=image width=$mapwd height=$mapht src=\"$mapurl\">\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
        if (defined($annofile)) {
            print $sock "<input type=\"hidden\" name=\"annofile\" value=\"$annofile\">\n";
        }
        print $sock "<input type=\"hidden\" name=\"bare\" value=\"\">\n";
        print $sock "</form>\n";
    }


    if (defined ($form->{'x'})) {
        # report info if clicked and not bare
        if ($bare eq '') {
            print $sock "Clicked pixel (x,y): $form->{'x'},$form->{'y'}\n";
            print $sock "Pic (x,y): ", $form->{'x'} * 100 / $scale,',',$form->{'y'} * 100 / $scale,"<br>\n";
        }
    }

    # if not bare
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
        if (!defined($annofile)) {
            $annofile = '';
        }
        print $sock "        <td>Annofile: <input type=\"text\" size=\"16\" name=\"annofile\" value=\"$annofile\"></td>\n";
        print $sock "    </tr>\n";

        print $sock "    <tr>\n";
        print $sock "        <td>All annos:</td>\n";
        print $sock "        <td><input type=\"text\" size=\"16\" name=\"allanno\" value=\"$allanno\"></td>\n";
        print $sock "    </tr>\n";

        print $sock "</table>\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
        print $sock "</form>\n";
    }

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
