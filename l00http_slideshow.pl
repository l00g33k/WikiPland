use strict;
use warnings;
use l00wikihtml;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# (Non automatic) slide show

my %config = (proc => "l00http_slideshow_proc",
              desc => "l00http_slideshow_desc");
my ($width, $height, $llspath, $picsperpage, $nonewline, $gpstrk, $gpstrk0, %locs);
my ($showname);
$width = '100%';
$height = '';
$picsperpage = 6;
$nonewline = '';
$showname = '';;
$gpstrk0 = '.';
$gpstrk = '';

sub l00http_slideshow_j2date {
    my ($datetimestr) = @_;
    my ($se,$mi,$hr,$da,$mo,$yr,$tmp);

    ($se,$mi,$hr,$da,$mo,$yr,$tmp,$tmp,$tmp) = gmtime ($datetimestr);

    sprintf ("%04d%02d%02d %02d%02d%02d", 
        $yr + 1900, $mo + 1, $da, $hr, $mi, $se);
}

sub l00http_slideshow_date2j {
# convert from date to seconds
    my $temp = pop;
    my $secs = 0;
    my ($yr, $mo, $da, $hr, $mi, $se);

    $temp =~ s/ //g;
    $temp =~ s/_//g;
    if (($yr, $mo, $da, $hr, $mi, $se) = ($temp =~ /(....)(..)(..)(..)(..)(..)/)) {
        $yr -= 1900;
        $mo--;
        $secs = &l00mktime::mktime ($yr, $mo, $da, $hr, $mi, $se);
    }
    
    $secs;
}

sub llsfn2 {
    my ($rst);
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtimea, $mtimeb, $ctime, $blksize, $blocks);
    
    if ((-d $llspath.$a) && (-d $llspath.$b)) {
        # both dir
        $rst = $b cmp $a;
    } elsif (!(-d $llspath.$a) && !(-d $llspath.$b)) {
        # both file
        # it's not a directory, print a link to a file
        ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtimea, $ctime, $blksize, $blocks)
        = stat($llspath.$a);
        ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtimeb, $ctime, $blksize, $blocks)
        = stat($llspath.$b);
        $rst = $mtimeb <=> $mtimea;
    } elsif (-d $llspath.$a) {
        $rst = 1;
    } else {
        $rst = -1;
    }
    $rst;
}

sub llsfn3 {
    my ($rst);
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtimea, $mtimeb, $ctime, $blksize, $blocks);
    
    if ((-d $llspath.$a) && (-d $llspath.$b)) {
        # both dir
        $rst = $b cmp $a;
    } elsif (!(-d $llspath.$a) && !(-d $llspath.$b)) {
        # both file
#       # it's not a directory, print a link to a file
#       ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
#       $size, $atime, $mtimea, $ctime, $blksize, $blocks)
#       = stat($llspath.$a);
#       ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
#       $size, $atime, $mtimeb, $ctime, $blksize, $blocks)
#       = stat($llspath.$b);
        $rst = $b cmp $a;
    } elsif (-d $llspath.$a) {
        $rst = 1;
    } else {
        $rst = -1;
    }
    $rst;
}

sub l00http_slideshow_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "slideshow: Non-automatic slide show";
}

sub l00http_slideshow_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($path, $file, @allpics, $phase, $outbuf, $ii, $tmp);
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $older, $newer, 
        $size, $atime, $mtimea, $mtimeb, $ctime, $blksize, $blocks, $urlname);
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst, $newline);
    my ($idx0, $idx1, $plon, $plat, $datetime, $datetime0, $waypts, $mkridx);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>l00httpd</title>" . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"#end\">end</a> -- \n";

    if (defined ($form->{'set'})) {
        if (defined ($form->{'width'})) {
            $width = $form->{'width'};
        }
        if (defined ($form->{'height'})) {
            $height = $form->{'height'};
        }
        if (defined ($form->{'picsperpage'})) {
            $picsperpage = $form->{'picsperpage'};
        }
        if ((defined ($form->{'nonewline'})) && ($form->{'nonewline'} eq 'on')) {
            $nonewline = 'checked';
        } else {
            $nonewline = '';
        }
        if ((defined ($form->{'showname'})) && ($form->{'showname'} eq 'on')) {
            $showname = 'checked';
        } else {
            $showname = '';
        }
        if (defined ($form->{'gpstrk'}) &&
            (length($form->{'gpstrk'}) > 0)) {
            $gpstrk = $form->{'gpstrk'};
        }
    }


    if (defined ($form->{'path'})) {
        $outbuf = '';
        if ($nonewline eq 'checked') {
            $newline = ' ';
        } else {
            $newline = '<br>';
        }
        $idx0 = 0;
        $idx1 = 0;
        $waypts = '';
        $mkridx = 0;
        if (($path) = $form->{'path'} =~ /^(.+\/)[^\/]+$/) {
            if (($gpstrk0 ne $gpstrk) ||
                ((defined ($form->{'reloadgps'})) && ($form->{'reloadgps'} eq 'on'))) {
                $gpstrk0 = $gpstrk;
                if (&l00httpd::l00freadOpen($ctrl, $gpstrk)) {
                    undef %locs;
                    while ($_ = &l00httpd::l00freadLine($ctrl)) {
                        s/[\r\n]//;
                        if (/^T +([NS])(\d\d)([0-9.\-]+) +([EW])(\d\d\d)([0-9.\-]+).* ; gps (\d{8,8} \d{6,6})/) {
                            #print "$1 $2 $3 $4 $5 $6  ";
                            $plon = $5 + $6 / 60;
                            $plat = $2 + $3 / 60;
                            if ($4 eq 'W') {
                                $plon = -$plon;
                            }
                            if ($1 eq 'S') {
                                $plat = -$plat;
                            }
                            $datetime = &l00http_slideshow_date2j($7);
                            $locs{$datetime} = "$plat,$plon";
                        }
#    if(/20170811/) {
#    print "$datetime $locs{$datetime}\n";
#    }
                    }
                }
            }

            if (opendir (DIR, $path)) {
                undef @allpics;
                foreach $file (readdir (DIR)) {
                    if ($file =~ /\.jpg$/i) {
                        push (@allpics, $file);
                    } elsif ($file =~ /\.png$/i) {
                        push (@allpics, $file);
                    } elsif ($file =~ /\.wmf$/i) {
                        push (@allpics, $file);
                    }
                }
                closedir (DIR);

                # sort by reverse time, so 'next' come first
                $llspath = $path;
                if ($showname ne 'checked') {
                    @allpics = sort llsfn2 @allpics;
                } else {
                    @allpics = sort llsfn3 @allpics;
                }

                $phase = 0; # search for 1 pic match
                for ($ii = 0; $ii <= $#allpics; $ii++) {
                    $file = $allpics[$ii];
                    if ("$path$file" eq $form->{'path'}) {
                        $phase = 1;
                        $idx0 = $ii + 1;
                    }
                    if ($phase == ($picsperpage + 1)) {
                        # we have found the number of pictures to display
                        last;   # done searching
                    }
                    if ($phase) {
                        ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
                            $size, $atime, $mtimea, $ctime, $blksize, $blocks)
                            = stat($path . $file);
                        ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
                            = localtime($ctime);
                        if ($nonewline ne 'checked') {
                            $urlname = "$path$allpics[$ii]";
                            $urlname =~ s/\+/%2B/g;
#                           $outbuf .= sprintf ("<a href=\"/slideshow.htm?path=%s\">%d</a>: %4d/%02d/%02d %02d:%02d:%02d:", 
#                               $urlname,
#                               $ii + 1, 1900+$year, 1+$mon, $mday, $hour, $min, $sec);
                            if ($showname ne 'checked') {
                               $outbuf .= sprintf ("<a href=\"/slideshow.htm?path=%s\">%d</a>: <a href=\"/launcher.htm?path=%s\" target=\"_blank\">%4d/%02d/%02d %02d:%02d:%02d</a>:", 
                                    $urlname,
                                    $ii + 1, 
                                    $urlname,
                                    1900+$year, 1+$mon, $mday, $hour, $min, $sec);
                            } else {
                                $outbuf .= sprintf ("<a href=\"/slideshow.htm?path=%s\">%d</a>: <a href=\"/launcher.htm?path=%s\" target=\"_blank\">%s</a>:", 
                                    $urlname,
                                    $ii + 1, 
                                    $urlname,
                                    $allpics[$ii]);
                            }
                            if ($gpstrk ne '') {
                                #::now::#1
                                if ($file =~ /(\d{8,8}_\d{6,6})/) {
                                    $datetime0 = &l00http_slideshow_date2j($1);
                                    $tmp = &l00http_slideshow_j2date($datetime0);
                                    $waypts .= "* From filename: $file $datetime0($tmp)\n";
                                    foreach $datetime (sort {$a <=> $b} keys %locs) {
                                        if ($datetime >= $datetime0) {
                                            $tmp = &l00http_slideshow_j2date($datetime);
                                            $outbuf .= "<a href=\"/kml2gmap.htm?path=l00://slideshow_waypts.way&mkridx=$mkridx\">kml2gmap#$mkridx</a>";
                                            $mkridx++;
                                            $waypts .= "$locs{$datetime} XX\n";
                                            $waypts .= "** From GPS track: $datetime($tmp) $locs{$datetime}\n\n";
                                            last;
                                        }
                                    }
                                }
                            }
                        }
                        $outbuf .= "$newline\n";
                        $urlname = "$path$file";
                        $urlname =~ s/\+/%2B/g;
                        $outbuf .= "<a href=\"/ls.htm/$file?path=$urlname\" target=\"_blank\"><img src=\"/ls.htm/$file?path=$urlname\" alt=\"$file\" width=\"$width\" height=\"$height\"><a/>\n";
                        $outbuf .= "$newline\n";
                        $phase++;
                    }
                }
                $idx1 = $ii;
            }
        }

        print $sock "<a href=\"/slideshow.htm?path=$path$allpics[0]\">Newest</a> \n";
        $tmp = $#allpics - $picsperpage + 1;
        if ($tmp < 0) {
            $tmp = 0;
        }
        print $sock "<a href=\"/slideshow.htm?path=$path$allpics[$tmp]\">Oldest</a> \n";

        if ($nonewline ne 'checked') {
            print $sock "<p>\n";
        }

        # find older and newer pages.
        $tmp = $idx0 - $picsperpage - 1;
        if ($tmp < 0) {
            $tmp = 0;
        }
        $newer = "$path$allpics[$tmp]";

        $tmp = $idx1;
        if ($tmp > $#allpics - $picsperpage + 1) {
            $tmp = $#allpics - $picsperpage + 1;
        }
        $older = "$path$allpics[$tmp]";

        print $sock "<a href=\"/slideshow.htm?path=$newer\">Newer</a> \n";
        print $sock "<a href=\"/slideshow.htm?path=$older\">Older</a> \n";
        print $sock "$idx0..$idx1 of ", $#allpics + 1, ".\n";
        print $sock "<p>\n";

        print $sock $outbuf;

        if ($nonewline ne 'checked') {
            print $sock "<p>\n";
        }

        print $sock "<a href=\"/slideshow.htm?path=$newer\">Newer</a> \n";
        print $sock "<a href=\"/slideshow.htm?path=$older\">Older</a> \n";
        print $sock "$idx0..$idx1 of ", $#allpics + 1, "\n";

        if ($nonewline ne 'checked') {
#::now::#2
            if ($gpstrk ne '') {
                # create l00://slideshow_waypts.way consist of waypoints.
$waypts .= <<aassdd;
=Rendering waypoints=
* Using Gogole Maps API on Google Map
** [[/kml2gmap.htm?path=\$&width=400&height=500|400 x 500]]
** [[/kml2gmap.htm?path=\$&width=600&height=300|600 x 300]]
** [[/kml2gmap.htm?path=\$&width=700&height=400|700 x 400]]
** [[/kml2gmap.htm?path=\$&width=800&height=600|800 x 600]]
** [[/kml2gmap.htm?path=\$&width=900&height=500|900 x 500]]
** [[/kml2gmap.htm?path=\$&width=1200&height=600|1200 x 600]]
** [[/kml2gmap.htm?path=\$&width=1400&height=700|1400 x 700]]
** [[/kml2gmap.htm?path=\$&width=1600&height=800|1600 x 800]]
* Download [[/kml2gmap.htm?path=\$|kml]] file
aassdd

                &l00httpd::l00fwriteOpen($ctrl, "l00://slideshow_waypts.way");
                &l00httpd::l00fwriteBuf($ctrl, $waypts);
                &l00httpd::l00fwriteClose($ctrl);

                print $sock "<p>kml2gmap: <a href=\"/kml2gmap.htm?path=l00://slideshow_waypts.way\">l00://slideshow_waypts.way</a> \n";
            }
        }
    }

    print $sock "<p>\n";
    if ($showname ne 'checked') {
        for ($ii = 1; $ii < $#allpics; $ii++) {
            $file = $allpics[$#allpics - $ii + 1];
            print $sock "<a href=\"/slideshow.htm?path=$path$file\">$ii</a>\n";
        }
    } else {
        for ($ii = 1; $ii < $#allpics; $ii++) {
            $file = $allpics[$ii - 1];
            print $sock "<a href=\"/slideshow.htm?path=$path$file\">$ii</a>\n";
        }
    }
    print $sock "<p>\n";

    print $sock "<a name=\"end\"><a/>";
    print $sock "<a/><form action=\"/slideshow.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"set\" value=\"Set\"><br>Image size, e.g.: 1024 or 100%\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Width: <input type=\"text\" size=\"4\" name=\"width\" value=\"$width\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Height: <input type=\"text\" size=\"4\" name=\"height\" value=\"$height\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Pic per page: <input type=\"text\" size=\"3\" name=\"picsperpage\" value=\"$picsperpage\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"checkbox\" name=\"nonewline\" $nonewline>No newline\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"checkbox\" name=\"showname\" $showname>Show filename\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "GPS trk: <input type=\"text\" size=\"6\" name=\"gpstrk\" value=\"$gpstrk\">\n";
    print $sock "<input type=\"checkbox\" name=\"reloadgps\">Reload\n";
    print $sock "</td></tr>\n";
    print $sock "</table>\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</form>\n";

    print $sock "<p>Jump to <a href=\"#top\">top</a>. clip: <a href=\"/clip.htm?update=Copy+to+clipboard&clip=$form->{'path'}\">$form->{'path'}</a><br>\n";
    print $sock "<a href=\"/ls.htm?path=$path\">$path</a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
