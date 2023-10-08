use strict;
use warnings;
use l00svg;
use l00base64;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# GPS map without data connection

my $lon = 0;
my $lat = 0;
my $path = '';
my $currannofile = '';
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

$allannos_base = '';

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
    my ($ctrl, $allin1annofile) = @_;
    my ($ret, $fname, $annos);

    $ret = 0;
    $fname = '';

    if (&l00httpd::l00freadOpen($ctrl, $allin1annofile)) {
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
            # read annotations as multi lines
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
    my ($coor, $tmp, $svg, %annosxy2txt, $xy, $oneannofile, $overlaymap, $mapurl);
    my ($allin1annofile, $picname, $ii, $nextpic, $nexturl, $finestep, $stepsize);
    my ($graphdatafile, $graphxoff, $graphyoff, $graphwidth, $graphheight, $svggraph);

    undef %annosxy2txt;
    undef %allannos;


    # process all annotations
    if (defined ($form->{'allin1annofile'})) {
        $allin1annofile = $form->{'allin1annofile'};
        if (-f $allin1annofile) {
            if (&picanno_allanno ($ctrl, $allin1annofile)) {
#never gets here
                $allin1annofile = '';
            }
        }
    } else {
        $allin1annofile = '';
    }


    $bare = '';
    if (defined ($form->{'bare'}) && ($form->{'bare'} eq 'on')) {
        $bare = 'checked';
    }

    $finestep = '';
    $stepsize = 10;
    if (defined ($form->{'finestep'}) && ($form->{'finestep'} eq 'on')) {
        $finestep = 'checked';
        $stepsize = 1;
    }

    if ($allin1annofile ne '') {
        # if all in one annotations, collect annotations for current image
        # and make next image URL
        if (defined ($form->{'path'})) {
            $path = $form->{'path'};
            $picname = $path;
            $picname =~ s/.+[\\\/]//;

            undef %annosxy2txt;
            # read current annotation into hash by xy
            foreach $_ (split("\n", $allannos{$picname})) {
                if (/^(\d+),(\d+): +(.+)$/) {
                    $annosxy2txt{"$1,$2"} = $3;
                }
            }

            # make next image URL
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
        # get annotation file path
        if (defined ($form->{'oneannofile'})) {
            $oneannofile = $form->{'oneannofile'};
        } else {
            $oneannofile = '';
        }
        # supplied or RAM?
        if (defined ($form->{'path'})) {
            $path = $form->{'path'};
            if ($oneannofile ne '') {
                # use supplied oneannofile
                $currannofile = $oneannofile;
            } elsif (-f "$path.txt") {
                $currannofile = "$path.txt";
            } else {
                # otherwise use RAM file
                $picname = $path;
                $picname =~ s/.+[\\\/]//;

                $currannofile = "l00://$picname.anno";
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


    $graphxoff = 0;
    if (defined ($form->{'graphxoff'}) && ($form->{'graphxoff'} =~ /^(\d+)$/)) {
        $graphxoff = $1;
        if (defined ($form->{'graphxdec'})) {
            $graphxoff -= $stepsize;
        }
        if (defined ($form->{'graphxinc'})) {
            $graphxoff += $stepsize;
        }
    }
    $graphyoff = 0;
    if (defined ($form->{'graphyoff'}) && ($form->{'graphyoff'} =~ /^(\d+)$/)) {
        $graphyoff = $1;
        if (defined ($form->{'graphydec'})) {
            $graphyoff -= $stepsize;
        }
        if (defined ($form->{'graphyinc'})) {
            $graphyoff += $stepsize;
        }
    }
    $graphwidth = 100;
    if (defined ($form->{'graphwidth'}) && ($form->{'graphwidth'} =~ /^(\d+)$/)) {
        $graphwidth = $1;
        if (defined ($form->{'graphwdec'})) {
            $graphwidth -= $stepsize;
        }
        if (defined ($form->{'graphwinc'})) {
            $graphwidth += $stepsize;
        }
    }
    $graphheight = 100;
    if (defined ($form->{'graphheight'}) && ($form->{'graphheight'} =~ /^(\d+)$/)) {
        $graphheight = $1;
        if (defined ($form->{'graphhdec'})) {
            $graphheight -= $stepsize;
        }
        if (defined ($form->{'graphhinc'})) {
            $graphheight += $stepsize;
        }
    }
    $graphdatafile = '';
    $svggraph = '';
    if (defined ($form->{'graphdatafile'}) && (length($form->{'graphdatafile'}) > 1)) {
        $graphdatafile = $form->{'graphdatafile'};
        # read and make svg graph
        if (&l00httpd::l00freadOpen($ctrl, $graphdatafile)) {
            $tmp = '';
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                s/[\r\n]//g;
                $tmp .= "$_ ";
            }
            &l00svg::plotsvg2 ('picannograph', $tmp, $graphwidth, $graphheight);

            ($pixx, $pixy) = &annoll2xysvg ($graphxoff, $graphyoff);
            $svggraph = "<div style=\"position: absolute; left:$pixx"."px; top:$pixy"."px;\">\n";
            $svggraph .= "<img src=\"/svg.pl?graph=picannograph\"></div>\n";
        }
    }



    if ($allin1annofile ne '') {
        # Set next refresh URL and send HTTP and HTML headers
        $nexturl = "/picannosvg.htm?refresh=y&scale=$scale&allin1annofile=$allin1annofile&path=$allannos_base$nextpic";
        #if ($bare eq 'checked') {
            $nexturl .= "&bare=on";
        #}
        #<meta http-equiv=\"refresh\" content=\"2; url=$nexturl\">
        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>picannosvg</title>" . "<meta http-equiv=\"refresh\" content=\"3; url=$nexturl\">" . $ctrl->{'htmlhead2'};
    } else {
        # Send HTTP and HTML headers
        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>picannosvg</title>" . $ctrl->{'htmlhead2'};
        # parse annotation file
        if (&l00httpd::l00freadOpen($ctrl, $currannofile)) {
            # parse oneannofile
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
                # read annotation into hash by xy
                if (/^(\d+),(\d+): +(.+)$/) {
                    $annosxy2txt{"$1,$2"} = $3;
                }
            }
            # update annotation if setting annotation
            if (defined($form->{'set'}) &&
                defined($form->{'anno'}) && 
                (length($form->{'anno'}) > 0)) {
                ($xx, $yy) = &annoxy2llsvg ($form->{'atx'}, $form->{'aty'});
                # set new annotation into hash by xy
                $annosxy2txt{"$xx,$yy"} = $form->{'anno'};
                $buf .= "$xx,$yy: $form->{'anno'}\n";
                if (&l00httpd::l00fwriteOpen($ctrl, $currannofile)) {
                    &l00httpd::l00fwriteBuf($ctrl, $buf);
                    &l00httpd::l00fwriteClose($ctrl);
                }
            }
        } elsif (&l00httpd::l00fwriteOpen($ctrl, $currannofile)) {
            # failed to read oneannofile, write a blank one
            &l00httpd::l00fwriteBuf($ctrl, "IMG_WD_HT=$mapwd,$mapht\n");
            &l00httpd::l00fwriteClose($ctrl);
            print $sock "Sample <a href=\"/view.htm?path=$currannofile\" target=\"_blank\">$currannofile</a> created as it was missing.  ".
                "<a href=\"/edit.htm?path=$currannofile\" target=\"_blank\">Edit</a> it for correct image size.<p>\n";
        }
    }


    # if picture exist, display picture and annotations
    if (-f "$path") {
        # show image to click in form
        # path to picture
        $mapurl = "/ls.htm$path?path=$path&raw=on";

        print $sock "<form action=\"/picannosvg.htm\" method=\"get\">\n";
        print $sock "<input type=\"image\" width=\"$mapwd\" height=\"$mapht\" src=\"$mapurl\">\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
        if (defined($oneannofile)) {
            print $sock "<input type=\"hidden\" name=\"oneannofile\" value=\"$oneannofile\">\n";
        }
        print $sock "<input type=\"hidden\" name=\"bare\" value=\"\">\n";
        print $sock "</form>\n";

        # show cursor if no all in 1 annotations
        ($pixx, $pixy) = &annoll2xysvg ($lon, $lat);
        if ($allin1annofile eq '') {
            if (defined($form->{'x'})) {
                # mark X if clicked
                print $sock "<div style=\"position: absolute; left:$pixx"."px; top:$pixy"."px;\">\n";
                print $sock "<font color=\"$color\">$marker</font></div>\n";
            }
        }
        # display annotations by hash of xy
        foreach $xy (keys %annosxy2txt) {
            ($pixx, $pixy) = &annoll2xysvg (split(',', $xy));
            print $sock "<div style=\"position: absolute; left:$pixx"."px; top:$pixy"."px;\">\n";
            print $sock "<font color=\"$color\">$annosxy2txt{$xy}</font></div>\n";
        }
        if ($svggraph ne '') {
            print $sock $svggraph;
        }
    }




    # report cursor x/y info if clicked and not bare
    if (defined ($form->{'x'})) {
        if ($bare eq '') {
            print $sock "Clicked pixel (x,y): $form->{'x'},$form->{'y'}\n";
            print $sock "Pic (x,y): ", $form->{'x'} * 100 / $scale,',',$form->{'y'} * 100 / $scale,"<br>\n";
        }
    }

    # display form if not bare
    if ($bare eq '') {
        print $sock "Max px (x,y): $mapwd,$mapht\n";
        print $sock "Max pic (x,y): ", $mapwd * 100 / $scale,',',$mapht * 100 / $scale,"<br>\n";

        print $sock "<p>$ctrl->{'home'} \n";
        print $sock "$ctrl->{'HOME'} \n";
        print $sock "Launch <a href=\"/launcher.htm?path=$path\" target=\"_blank\">$path</a> - ";
        if ($currannofile =~ /^l00:\/\//) {
            # is RAM anno file, make link to copy to disk file
            print $sock "View <a href=\"/view.htm?path=$currannofile\" target=\"_blank\">$currannofile</a> - ".
            "<a href=\"/filemgt.htm?path=$currannofile&path2=$path.txt\" target=\"_blank\">filemgt</a><p>\n";
        } else {
            print $sock "View <a href=\"/view.htm?path=$currannofile\" target=\"_blank\">$currannofile</a><p>\n";
        }

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
        if (!defined($oneannofile)) {
            $oneannofile = '';
        }
        print $sock "        <td>Annofile: <input type=\"text\" size=\"16\" name=\"oneannofile\" value=\"$oneannofile\"></td>\n";
        print $sock "    </tr>\n";

        print $sock "    <tr>\n";
        print $sock "        <td>All annos file:</td>\n";
        print $sock "        <td><input type=\"text\" size=\"16\" name=\"allin1annofile\" value=\"$allin1annofile\"></td>\n";
        print $sock "    </tr>\n";

        print $sock "    <tr>\n";
        print $sock "        <td>Graph data file:</td>\n";
        print $sock "        <td><input type=\"text\" size=\"16\" name=\"graphdatafile\" value=\"$graphdatafile\">".
                    "            <input type=\"checkbox\" name=\"finestep\" $finestep>fine +-</td>\n";
        print $sock "    </tr>\n";

        print $sock "    <tr>\n";
        print $sock "        <td>Graph offset x, y:</td>\n";
        print $sock "        <td><input type=\"text\" size=\"6\" name=\"graphxoff\" value=\"$graphxoff\">";
        if ($svggraph ne '') {
            print $sock "        <input type=\"submit\" name=\"graphxdec\" value=\"-\">";
            print $sock "        <input type=\"submit\" name=\"graphxinc\" value=\"+\">";
        }
        print $sock "            <input type=\"text\" size=\"6\" name=\"graphyoff\" value=\"$graphyoff\">";
        if ($svggraph ne '') {
            print $sock "        <input type=\"submit\" name=\"graphydec\" value=\"-\">";
            print $sock "        <input type=\"submit\" name=\"graphyinc\" value=\"+\">";
        }
        print $sock "    </td>\n";
        print $sock "    </tr>\n";

        print $sock "    <tr>\n";
        print $sock "        <td>Graph width, height:</td>\n";
        print $sock "        <td><input type=\"text\" size=\"6\" name=\"graphwidth\" value=\"$graphwidth\">";
        if ($svggraph ne '') {
            print $sock "        <input type=\"submit\" name=\"graphwdec\" value=\"-\">";
            print $sock "        <input type=\"submit\" name=\"graphwinc\" value=\"+\">";
        }
        print $sock "            <input type=\"text\" size=\"6\" name=\"graphheight\" value=\"$graphheight\">";
        if ($svggraph ne '') {
            print $sock "        <input type=\"submit\" name=\"graphhdec\" value=\"-\">";
            print $sock "        <input type=\"submit\" name=\"graphhinc\" value=\"+\">";
        }
        print $sock "    </td>\n";
        print $sock "    </tr>\n";

        print $sock "</table>\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
        print $sock "</form>\n";
    }

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
