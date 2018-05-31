use strict;
use warnings;
use l00wikihtml;
use l00mktime;
use POSIX;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# (Non automatic) slide show

my %config = (proc => "l00http_album_proc",
              desc => "l00http_album_desc");
my ($width, $height, $llspath, %album_mon2nm);
my (%gpsbydate, %gpsfilebydate, @gpsbydateidx, %picbystamp, $picbystampcnt, $noGps, $oldestpicstamp, $newestpicstamp);
my (@srcdir, $srcdirsig, @gpsdir, $gpsdirsig, $warnings, $posixoffset);
$width = '67%';
$height = '';
$noGps = 2;
undef %gpsbydate;
@gpsbydateidx = ();
undef %picbystamp;
$srcdirsig = '';
$gpsdirsig = '';
$oldestpicstamp = 0;
$newestpicstamp = 0;

%album_mon2nm = (
    Jan => 0,
    Feb => 1,
    Mar => 2,
    Apr => 3,
    May => 4,
    Jun => 5,
    Jul => 6,
    Aug => 7,
    Sep => 8,
    Oct => 9,
    Nov => 10,
    Dec => 11
);


sub album_web {
    my ($ctrl, $sock, %album) = @_;
    my ($matchdate, $anchor, $tmp, $utc, $path, @gpsdates);
    my ($gpsdate, $lat, $lon, $sh, $bat, $caption);

    $anchor = 0;
    $sh = '';
    $bat = '';

    print $sock "<a name=\"pictop\"></a>\n";
    print $sock "<a name=\"pic$anchor\"></a>\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\" style=\"width: 100%;\">\n";


    foreach $utc (sort keys %album) {
        ($matchdate, $caption) = $album{$utc} =~ /^(.+?)\|(.+)$/;
        print $sock "<tr><td style=\"width: 100%;\">\n";

        $anchor++;
        print $sock "<a name=\"pic$anchor\"></a> ";
        print $sock "<a href=\"#pictop\">top</a> - ";
        $tmp = $anchor - 1;
        print $sock "<a href=\"#pic$tmp\">last #$tmp</a> - ";
        print $sock "<a href=\"#pic$anchor\">#$anchor</a> - ";
        $tmp = $anchor + 1;
        print $sock "<a href=\"#pic$tmp\">next #$tmp</a> - \n";
        print $sock "<a href=\"#picbot\">bottom</a> \n";

        ($utc, $path) = split('\|', $picbystamp{$matchdate});
        if ($ctrl->{'debug'} >= 4) {
            $tmp = &l00httpd::time2now_string ($matchdate);
            print $sock "<br>(dbg: file stamp $matchdate $tmp utc of file stamp $utc) ";
        }
        $tmp = &l00httpd::time2now_string ($utc);
        print $sock " - <a href=\"/ls.htm?path=$path\" target=\"_blank\">Picture</a> UTC: $tmp\n";


        $tmp = $path;
        $tmp =~ s/\\/\//g;
        $sh  .= "cp \"$tmp\" .\n";
        $tmp = $path;
        $tmp =~ s/\//\\/g;
        $bat .= "copy \"$tmp\" .\n";

        $tmp = &l00httpd::time2now_string ($matchdate);

        @gpsdates = &album_findgps($ctrl, $utc);

        if ($#gpsdates == 0) {
            $tmp = &l00httpd::time2now_string ($gpsdates[0]);
            print $sock "<a href=\"/view.htm?path=$gpsfilebydate{$gpsdates[0]}\" target=\"_blank\">GPS</a> ";
        } else {
            $tmp = &l00httpd::time2now_string ($gpsdates[$noGps]);
            print $sock "<a href=\"/view.htm?path=$gpsfilebydate{$gpsdates[$noGps]}\" target=\"_blank\">GPS</a> ";
        }

        &l00httpd::l00fwriteOpen($ctrl, "l00://album_$anchor.txt");
        foreach $gpsdate (@gpsdates) {
            ($lat, $lon) = split(",", $gpsbydate{$gpsdate});
            $gpsdate = &l00httpd::time2now_string ($gpsdate);
            &l00httpd::l00fwriteBuf($ctrl, "* $gpsdate\n$lat,$lon $gpsdate\n");
        }
        &l00httpd::l00fwriteClose($ctrl);

        print $sock "<a href=\"/kml2gmap.htm?path=l00://album_$anchor.txt\" target=\"_blank\">$tmp</a><br>\n";
        if ($caption ne '') {
           #print $sock "$caption<br>\n";
            print $sock &l00wikihtml::wikihtml ($ctrl, "", "$caption<br>\n", 0);;
        }

        print $sock "<a href=\"/activity.htm?start=Start&path=$path\" target=\"_blank\">".
                    "<img src=\"/ls.htm?path=$path\" ".
                    "alt=\"$path\" ".
                    "width=\"$width\" height=\"$height\">".
                    "</a>\n";

        print $sock "</td></tr>\n";

    }
    print $sock "</table>\n";


    &l00httpd::l00fwriteOpen($ctrl, "l00://album_sh.txt");
    &l00httpd::l00fwriteBuf($ctrl, $sh);
    &l00httpd::l00fwriteClose($ctrl);
    &l00httpd::l00fwriteOpen($ctrl, "l00://album_bat.txt");
    &l00httpd::l00fwriteBuf($ctrl, $bat);
    &l00httpd::l00fwriteClose($ctrl);

    print $sock "<br><a name=\"picbot\"></a>Jump to picture: \n";
    for $_ (1..$anchor) {
        if ($_ > 1) {
            print $sock " - ";
        }
        print $sock "<a href=\"#pic$_\">#$_</a>";
    }
    print $sock "<br>\n";
}


sub album_findgps {
    my ($ctrl, $picdate) = @_;
    my (@gpsdates, $ii);


    @gpsdates = ();

    for ($ii = 0; $ii <= $#gpsbydateidx; $ii++) {
        if ($picdate < $gpsbydateidx[$ii]) {
            if ($ctrl->{'debug'} >= 4) {
                my ($buf, $tmp);
                $tmp = &l00httpd::time2now_string ($picdate);
                $buf = "album_findgps: file date $picdate $tmp; closest GPS $gpsbydateidx[$ii] ";
                $tmp = &l00httpd::time2now_string ($gpsbydateidx[$ii]);
                $buf .= "$tmp\n";
                l00httpd::dbp($config{'desc'}, $buf);
            }
            if (($ii > $noGps) && ($ii < ($#gpsbydateidx - $noGps))) {
                @gpsdates = @gpsbydateidx[$ii-$noGps .. $ii+$noGps];
            } else {
                @gpsdates = ($gpsbydateidx[$ii]);
            }
            last;
        }
    }

    @gpsdates;
}


# album_scanjpg: search the array of directories for .jpg and .off2utc
# filenames of .jpg is expected to have the date/time stamp of the picture as a prefix
# _+#.off2utc: # is the value to be added to picture time to arrive at UTC time

sub album_scanjpg {
    my ($ctrl, @srcdir) = @_;
    my ($path, $file, $tmp, $ii);
    my ($nopics, $nodirs, $stamp);
    my ($year, $mon, $mday, $hour, $min, $sec);
    my (@subdirs, $off2utc, $newday);

    $nopics = 0;
    $nodirs = 0;
    $off2utc = 0;
    $newday = '';
    @subdirs = ();
    foreach $path (@srcdir) {
        print "Scan JPG in $path ";
        if (opendir (JPG, $path)) {
            $nodirs++;
            if ($ctrl->{'debug'} >= 4) {
                l00httpd::dbp($config{'desc'}, "DIR : $path\n");
            }
            foreach $file (sort readdir (JPG)) {
                print ".", if (($nopics % 1000) == 0);
                $stamp = 0;
                if (-d "$path$file") {
                    if ($file !~ /^\.+$/) {
                        push(@subdirs, "$path$file/");
                    }
                } elsif (($year, $mon, $mday, $hour, $min, $sec) =
                    # 2018_03_11 20_21_31_IMG_0539.jpg
                    $file =~ /^(\d\d\d\d)_(\d\d)_(\d\d) (\d\d)_(\d\d)_(\d\d)(.+\.jpg)$/i) {
                    $nopics++;
                    $mon--;
                    $year -= 1900;
                    #$stamp = &l00mktime::mktime ($year, $mon, $mday, $hour, $min, $sec);
                    $stamp = mktime($sec, $min, $hour, $mday, $mon, $year, 0, 0, -1) + $posixoffset;
                } elsif (($year, $mon, $mday, $hour, $min, $sec) =
                    # IMG_20180310_180333.jpg
                    $file =~ /^IMG_(\d\d\d\d)(\d\d)(\d\d)_(\d\d)(\d\d)(\d\d)(.*\.jpg)$/i) {
                    $nopics++;
                    $mon--;
                    $year -= 1900;
                    #$stamp = &l00mktime::mktime ($year, $mon, $mday, $hour, $min, $sec);
                    $stamp = mktime($sec, $min, $hour, $mday, $mon, $year, 0, 0, -1) + $posixoffset;
                } elsif (($year, $mon, $mday, $hour, $min, $sec) =
                    # 20171115_232451.jpg    
                    $file =~ /^(\d\d\d\d)(\d\d)(\d\d)_(\d\d)(\d\d)(\d\d)(.*\.jpg)$/i) {
                    $nopics++;
                    $mon--;
                    $year -= 1900;
                    #$stamp = &l00mktime::mktime ($year, $mon, $mday, $hour, $min, $sec);
                    $stamp = mktime($sec, $min, $hour, $mday, $mon, $year, 0, 0, -1) + $posixoffset;
                } elsif ($file =~ /_([+\-]\d+)\.off2utc$/i) {
                    $off2utc = $1;
                    $ctrl->{'l00file'}->{"l00://album_pics.txt"} .= "off2utc $off2utc $stamp $file $path\n";
                }

                if ($stamp) {
                    if ($newday ne "$year:$mon$mday") {
                        $newday =  "$year:$mon$mday";
                        $tmp = &l00httpd::time2now_string ($stamp - 1);
                        if (($year, $mon, $mday, $hour, $min, $sec) = $tmp =~ /(\d\d\d\d)(\d\d)(\d\d) (\d\d)(\d\d)(\d\d)/) {
                            $tmp = "${year}_${mon}_${mday} ${hour}_${min}_${sec}_x_-0.off2utc";
                            $ctrl->{'l00file'}->{"l00://album_off2utc.txt"} .= "* Edit <a href=\"/edit.htm?path=$path$tmp\">$path$tmp<a/>???\n/n";
                        }
                    }
                    $tmp = $stamp + ($off2utc * 3600);
                    $picbystamp{$stamp} = "$tmp|$path$file";
                    $ctrl->{'l00file'}->{"l00://album_pics.txt"} .= "$stamp $tmp $off2utc $file $path\n";
                }
            }
        }
        print "\n";
    }        

    if ($#subdirs >= 0) {
        ($_, $tmp) = &album_scanjpg($ctrl, @subdirs);
        $nodirs += $_;
        $nopics += $tmp;
    }

    ($nodirs, $nopics);
}


sub album_readgps {
    my (@gpsdir) = @_;
    my ($ns, $lat_d, $lad_m, $ew, $lon_d, $lon_m, $gpsstamp, $l00stamp);
    my ($nofiles, $nopoints, $time0, $lon, $lat);
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);
    my ($path, $file, $tmp, $ii, $stamp);

    $nofiles = 0;
    $nopoints = 0;
    foreach $path (@gpsdir) {
        print "Scan GPS records in $path ";
        if (opendir (GPS, $path)) {
            foreach $file (sort readdir (GPS)) {
                # gps_20141225.trk
                if (($year, $mon, $mday) =
                    $file =~ /gps_(\d\d\d\d)(\d\d)(\d\d)\.trk$/) {
                    $mon--;
                    $year -= 1900;
                    #$stamp = &l00mktime::mktime ($year, $mon, $mday, 0, 0, 0);
                    $stamp = mktime(0, 0, 0, $mday, $mon, $year, 0, 0, -1) + $posixoffset;

                    # only scan for GPS records withing 1 day of oldest and newest
                    if (($stamp > ($oldestpicstamp - 86400)) && 
                        ($stamp < ($newestpicstamp + 86400)) &&
                        open(TRK, "<$path$file")) {
                        print ".";
                        $nofiles++;
                        $tmp = 0;
                        #T  N4315.84286 W00255.66779 12-Mar-18 11:14:45   73 ; gps 20180312 121552
                        #                            GPS time in UTC           log time in localtime
                        while (<TRK>) {
                            if (($ns, $lat_d, $lad_m, $ew, $lon_d, $lon_m, $gpsstamp, $l00stamp) 
                                = /T +([NS])(\d\d)([\d.]+) ([WE])(\d\d\d)([\d.]+) (\d\d-...-\d\d \d\d:\d\d:\d\d) *-*\d+ ; gps ([ 0-9]+)/) {
                                $lat = $lat_d + $lad_m / 60.0;
                                if ($ns eq 'S') {
                                    $lat = -$lat;
                                }
                                $lon = $lon_d + $lon_m / 60.0;
                                if ($ew eq 'W') {
                                    $lon = -$lon;
                                }
                                # convert GPS UTC time
                                if (($mday, $mon, $year, $hour, $min, $sec) =
                                    $gpsstamp =~ /(\d\d)-(...)-(\d\d) (\d\d):(\d\d):(\d\d)/) {
                                    #print "($mday, $mon, $year, $hour, $min, $sec) ", if(($nofiles ==1)&&($tmp<5));
                                    $mon = $album_mon2nm{$mon};
                                    $year += 100;
                                    #print "$mon ", if(($nofiles ==1)&&($tmp<5));
                                    #$gpsstamp = &l00mktime::mktime ($year, $mon, $mday, $hour, $min, $sec);
                                    $gpsstamp = mktime($sec, $min, $hour, $mday, $mon, $year, 0, 0, -1) + $posixoffset;
                                    #print "$gpsstamp ", if(($nofiles ==1)&&($tmp<5));
                                    #$_ = &l00httpd::time2now_string ($gpsstamp);
                                    #print "$_ ", if(($nofiles ==1)&&($tmp<5));

                                    # convert local log time
                                    if (($year, $mon, $mday, $hour, $min, $sec) =
                                        $l00stamp =~ /(\d\d\d\d)(\d\d)(\d\d) (\d\d)(\d\d)(\d\d)/) {
                                        #print "($mday, $mon, $year, $hour, $min, $sec) ", if(($nofiles ==1)&&($tmp<5));
                                        $mon--;
                                        $year -= 1900;
                                        #print "$mon ", if(($nofiles ==1)&&($tmp<5));
                                        #$l00stamp = &l00mktime::mktime ($year, $mon, $mday, $hour, $min, $sec);
                                        $l00stamp = mktime($sec, $min, $hour, $mday, $mon, $year, 0, 0, -1) + $posixoffset;
                                        #print "$l00stamp ", if(($nofiles ==1)&&($tmp<5));
                                        #$_ = &l00httpd::time2now_string ($l00stamp);
                                        #print "$_ ", if(($nofiles ==1)&&($tmp<5));

                                        if (!defined($gpsbydate{$gpsstamp})) {
                                            $nopoints++;
                                            $gpsbydate{$gpsstamp} = "$lat,$lon,$l00stamp";
                                            $gpsfilebydate{$gpsstamp} = "$path$file";
                                        }
                                    }
                                }
                                #print "$lat $lon ($ns, $lat_d, $lad_m, $ew, $lon_d, $lon_m, $gpsstamp, $l00stamp)\n", if(($nofiles ==1)&&($tmp<5));
                            }
                        }
                        close(TRK);
                    }
                }
            }
        }
        print "\n";
    }

    ($nofiles, $nopoints);
}


sub l00http_album_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "album: A photo album with describtion";
}

sub l00http_album_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($path, $file, $last, $next, $phase, $outbuf, $ii, $tmp);
    my ($srcfile, $dir, $regex, $output, $time0, $stamp, $utc, $date, $match, $anchor,
        $size, $atime, $mtimea, $mtimeb, $ctime, $blksize, $blocks, $caption);
    my ($year, $mon, $mday, $hour, $min, $sec);
    my ($matchdate, $stats, $unmatched, $gpsdate, @gpsdates, $lat, $lon);
    my (%album);



    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>album</title>" . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"#end\">end</a>\n";
    print $sock " - <a href=\"/album.htm?path=$form->{'path'}\">Refresh</a>\n";
    if (defined ($form->{'path'})) {
        print $sock " - <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a>\n";
    }
    print $sock "<p>\n";

    if (defined ($form->{'set'})) {
        if (defined ($form->{'width'})) {
            $width = $form->{'width'};
        }
        if (defined ($form->{'height'})) {
            $height = $form->{'height'};
        }
    }

    if (defined ($form->{'clearcache'})) {
        $srcdirsig = '';
        $gpsdirsig = '';
        undef %picbystamp;
        undef %gpsbydate;
    }

    if (defined ($form->{'path'})) {
        ($path) = $form->{'path'} =~ /^(.+\/)[^\/]+$/;
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            undef @srcdir;
            undef @gpsdir;
            $time0 = time;
            $stats = '';
            $warnings = '';

            $ctrl->{'l00file'}->{"l00://album_warnings.txt"} = '';
            $ctrl->{'l00file'}->{"l00://album_pics.txt"}  = "%TOC%\n";
            $ctrl->{'l00file'}->{"l00://album_pics.txt"} .= "filestamp UTC off2utc name path\nSearch off2utc for UTC offset\n";
            $ctrl->{'l00file'}->{"l00://album_pics.txt"} .= "* Note: current implementation will only present one of many pictures with the same timestamp\n";
            $ctrl->{'l00file'}->{"l00://album_off2utc.txt"}  = "* To create .off2utc files\n\n";
            $ctrl->{'l00file'}->{"l00://album_gps.txt"} = "UTC lat lon\n";


            $warnings .= "See <a href=\"/view.htm?path=l00://album_warnings.txt\" target=\"_blank\">".
                "l00://album_warnings.txt</a> for full list of warnings\n";
            $warnings .= "See <a href=\"/view.htm?path=l00://album_pics.txt\" target=\"_blank\">".
                "l00://album_pics.txt</a> for list of all pictures\n";
            $warnings .= "See <a href=\"/ls.htm?path=l00://album_off2utc.txt\" target=\"_blank\">".
                "l00://album_pics.txt</a> to create .off2utc for UTC time conversion\n";
            $warnings .= "See <a href=\"/view.htm?path=l00://album_gps.txt\" target=\"_blank\">".
                "l00://album_gps.txt</a> for list of all GPS positions\n";

            # my mktime
            $stamp = &l00mktime::mktime (110, 0, 1, 0, 0, 0);
            # POSIX
            $tmp = mktime(0, 0, 0, 1, 0, 110, 0, 0, -1);
            $posixoffset = $stamp - $tmp;
            $stats .= "Add $posixoffset secs to POSIX::mktime() for time\n";

            # scan album source
            $srcfile = &l00httpd::l00freadAll($ctrl);
            foreach $_ (split("\n", $srcfile)) {
                s/\n//;
                s/\r//;
                if (/^DIR:(.+)/) {
                    push(@srcdir, $1);
                }
                if (/^GPS:(.+)/) {
                    push(@gpsdir, $1);
                }
            }

            $_ = join('::', @srcdir);
            if ($srcdirsig ne $_) {
                $srcdirsig = $_;
                print $sock "Scanning JPG pictures...<br>\n";
                $time0 = time;
                ($_, $tmp) = &album_scanjpg($ctrl, @srcdir);
                $stats .= "Read $tmp pictures from $_ directories in ";
                $stats .= sprintf("%.1f secs", time - $time0);
                $stats .= "\n";
            } else {
                $stats .= "Using cached picture list of $picbystampcnt pictures: $srcdirsig\n";
            }

            $oldestpicstamp = 0;
            $picbystampcnt = 0;
            foreach $_ (sort keys %picbystamp) {
                $picbystampcnt++;
                if ($oldestpicstamp == 0) {
                    $oldestpicstamp = $_;
                }
                $newestpicstamp = $_;
            }
            if ($oldestpicstamp > 0) {
                $tmp = &l00httpd::time2now_string ($oldestpicstamp);
                $stats .= "    Oldest picture date stamp is $tmp ($oldestpicstamp)\n";
                $tmp = &l00httpd::time2now_string ($newestpicstamp);
                $stats .= "    Newest picture date stamp is $tmp ($newestpicstamp)\n";
            } else {
                $stats .= "    no pictures found\n";
            }

            $_ = join('::', @gpsdir);
            if ($gpsdirsig ne $_) {
                $gpsdirsig = $_;
                print $sock "Scanning GPS records...<br>\n";
                $time0 = time;
                ($_, $tmp) = &album_readgps(@gpsdir);

                foreach $_ (sort keys %gpsbydate) {
                    $ctrl->{'l00file'}->{"l00://album_gps.txt"} .= "$_ $gpsbydate{$_}\n";
                    push(@gpsbydateidx, $_);
                }

                $stats .= "Read $tmp GPS locations from $_ files in ";
                $stats .= sprintf("%.1f secs", time - $time0);
                $stats .= "\n";
            } else {
                $tmp = $#gpsbydateidx + 1;
                $stats .= "Using cached GPS list of $tmp locations: $gpsdirsig\n";
            }
            if ($#gpsbydateidx >= 0) {
                $tmp = &l00httpd::time2now_string ($gpsbydateidx[0]);
                $stats .= "    oldest GPS: $tmp ($gpsbydateidx[0])\n";
                $tmp = &l00httpd::time2now_string ($gpsbydateidx[$#gpsbydateidx]);
                $stats .= "    newest GPS: $tmp ($gpsbydateidx[$#gpsbydateidx])\n";
            } else {
                $stats .= "    no GPS records found\n";
            }
            $stats .= "Note: 2017_11_15 23_00_00_+8.off2utc adds 8 hours to picture time stamp for UTC for time after the time in filename\n";



            # generate web view
            $unmatched = 0;
            $anchor = 0;
            $output = '';
            $caption = '';
            undef %album;

            foreach $_ (split("\n", $srcfile)) {
                s/\n//;
                s/\r//;
                if (($tmp) = /^\* (.+)$/) {
                    $caption = $1;
                } elsif (($tmp) = /^\*\* (.+)$/) {
                    if (($path, $file) = $tmp =~ /^(.*[\\\/])([^\\\/]+)$/) {
                        # now we have ($path, $file)
                    } else {
                        $path = '';
                        $file = $tmp;
                    }

                    $match = 0;
                    foreach $date (sort keys %picbystamp) {
                        if ($picbystamp{$date} =~ /$file/) {
                            $match++;
                            $matchdate = $date;
                        }
                    }
                    if ($match != 1) {
                        $unmatched++;
                        if ($unmatched <= 3) {
                            $warnings .= "There are $match matches for $file\n";
                            if ($unmatched == 3) {
                                $warnings .= "See <a href=\"/view.htm?path=l00://album_warnings.txt\" target=\"_blank\">".
                                "l00://album_warnings.txt</a> for additional possible mismatch\n";
                            }
                        }
                        $ctrl->{'l00file'}->{"l00://album_warnings.txt"} .= 
                            "$match matches for $file\n";
                        $output .= "$_\n";
                        next;
                    }
                    $output .= "$_\n";

                    ($utc, $path) = split('\|', $picbystamp{$matchdate});
                    $album{$utc} = "$matchdate|$caption";


                    
                    $anchor++;
                    $tmp = $anchor - 1;
                    $tmp = $anchor + 1;

                    $tmp = &l00httpd::time2now_string ($utc);

                    $tmp = &l00httpd::time2now_string ($matchdate);
                    $output .= "    pic date is $matchdate aka $tmp\n";

                    @gpsdates = &album_findgps($ctrl, $utc);
                    $output .= "    gps date is " . join(' ', @gpsdates);

                    if ($#gpsdates == 0) {
                        $tmp = &l00httpd::time2now_string ($gpsdates[0]);
                    } else {
                        $tmp = &l00httpd::time2now_string ($gpsdates[$noGps]);
                    }
                    $output .= " aka $tmp\n";

                    $caption = '';
                } else {
                    $output .= "$_\n";
                }
            }

            &album_web($ctrl, $sock, %album);

            $stats .= "View generated shell script to copy to .: <a href=\"/view.htm?path=l00://album_sh.txt\" target=\"_blank\">l00://album_sh.txt</a>\n";
            $stats .= "View generated batch file to copy to .: <a href=\"/view.htm?path=l00://album_bat.txt\" target=\"_blank\">l00://album_bat.txt</a>\n";

           #print $sock &l00wikihtml::wikihtml ($ctrl, "", "$warnings\n$stats\n$output", 0);;
            print $sock &l00wikihtml::wikihtml ($ctrl, "", "$warnings\n$stats", 0);;
        }
    }


    print $sock "<p>\n";

    print $sock "<a name=\"end\"><a/>";
    print $sock "<a/><form action=\"/album.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"set\" value=\"Set\"> Image size, e.g.: 1024 or 100%\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Width: <input type=\"text\" size=\"4\" name=\"width\" value=\"$width\">\n";
    print $sock "<a href=\"/album.htm?set=Set&width=100%25&path=$form->{'path'}\">100</a>\n";
    print $sock "<a href=\"/album.htm?set=Set&width=67%25&path=$form->{'path'}\">67</a>\n";
    print $sock "<a href=\"/album.htm?set=Set&width=50%25&path=$form->{'path'}\">50</a>\n";
    print $sock "<a href=\"/album.htm?set=Set&width=33%25&path=$form->{'path'}\">33</a>\n";
    print $sock "<a href=\"/album.htm?set=Set&width=25%25&path=$form->{'path'}\">25</a>\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Height: <input type=\"text\" size=\"4\" name=\"height\" value=\"$height\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"clearcache\" value=\"Clear cache\">\n";
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
