use strict;
use warnings;
use l00wikihtml;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# (Non automatic) slide show

my %config = (proc => "l00http_album_proc",
              desc => "l00http_album_desc");
my ($width, $height, $llspath, $picsperpage);
$width = '100%';
$height = '';
$picsperpage = 6;


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
    my ($path, $file, @allpics, $last, $next, $phase, $outbuf, $ii, $tmp);
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $file, $target, 
        %pics, %notes,
        $size, $atime, $mtimea, $mtimeb, $ctime, $blksize, $blocks);
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>l00httpd</title>" . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"#end\">end</a>\n";

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
    }


    if (defined ($form->{'path'})) {
        ($path) = $form->{'path'} =~ /^(.+\/)[^\/]+$/;

        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            print $sock "<pre>\n";
            undef %pics;
            undef %notes;
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                s/\n//;
                s/\r//;
                if (($file) = /^\* (.+)/) {
                    $target = "not found $file";
                    if (-f $file) {
                        $target = $file;
                    } elsif (-f "$path$file") {
                        $target = "$path$file";
                    }
                    $pics{$file} = $target;
                    $pics{$file} = 'notes';
                    print $sock "$target\n";
                }
            }
            print $sock "</pre>\n";
        }

        $outbuf = '';
        if (($path) = $form->{'path'} =~ /^(.+\/)[^\/]+$/) {
            if (opendir (DIR, $path)) {
                undef @allpics;
                foreach $file (readdir (DIR)) {
                    if ($file =~ /\.jpg$/i) {
                        push (@allpics, $file);
                    } elsif ($file =~ /\.png$/i) {
                        push (@allpics, $file);
                    }
                }
                closedir (DIR);

                # sort by reverse time, so 'next' come first
                $llspath = $path;

                $last = '';
                $next = '';
                $phase = 0; # search for 1 pic match
                for ($ii = 0; $ii <= $#allpics; $ii++) {
                    $file = $allpics[$ii];
                    if ($path . $file eq $form->{'path'}) {
                        # found 'this', don't update $last
                        $phase = 1;
                    }
                    if ($phase == 0) {
                        # remember the one that comes before 'this'. Because
                        # we are in reverse order, what's before 'this' is next
                        $tmp = $ii - $picsperpage + 1;
                        if ($tmp < 0) {
                            $tmp = 0;
                        }
                        $next = $path . $allpics[$tmp];
                    }
                    if ($phase == ($picsperpage + 1)) {
                        # we have found the number of pictures to display
                        $tmp = $ii + $picsperpage;
                        if ($tmp > $#allpics) {
                            $tmp = $#allpics;
                        }
                        $last = $path . $allpics[$tmp];

                        last;   # done searching
                    }
                    if ($phase) {
                        ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
                            $size, $atime, $mtimea, $ctime, $blksize, $blocks)
                            = stat($path . $file);
                        ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
                            = localtime($ctime);
                        $outbuf .= "<br>\n";
                        $outbuf .= sprintf ("%d: %4d/%02d/%02d %02d:%02d:%02d:<br>\n", $#allpics - $ii + 1, 1900+$year, 1+$mon, $mday, $hour, $min, $sec);

                        $outbuf .= "<a href=\"/ls.htm/$file?path=$path$file\"><img src=\"$path$file\" width=\"$width\" height=\"$height\"><a/>\n";
                        $phase++;
                    }
                }
                if ($last eq '') {
                    # if we never found $last, use given path=
                    $last = $form->{'path'};
                }
                if ($next eq '') {
                    # if we never found $next, use given path=
                    $next = $form->{'path'};
                }
            }
        }
        print $sock "<a href=\"/album.htm?path=$last\">Older</a> \n";
        print $sock "<a href=\"/album.htm?path=$next\">Newer</a> \n";

        print $sock $outbuf;
        print $sock "<a href=\"/album.htm?path=$last\">Older</a> \n";
        print $sock "<a href=\"/album.htm?path=$next\">Newer</a> \n";
    }

    print $sock "<p>\n";
    for ($ii = 1; $ii < $#allpics; $ii++) {
        $file = $allpics[$#allpics - $ii + 1];
        print $sock "<a href=\"/album.htm?path=$path$file\">$ii</a>\n";
    }
    print $sock "<p>\n";

    print $sock "<a name=\"end\"><a/>";
    print $sock "<a/><form action=\"/album.htm\" method=\"get\">\n";
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
    print $sock "</table>\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</form>\n";

    print $sock "<p>Jump to <a href=\"#top\">top</a>. clip: <a href=\"/clip.htm?update=Copy+to+clipboard&clip=$form->{'path'}\">$form->{'path'}</a><br>\n";
    print $sock "<a href=\"/ls.htm?path=$path\">$path</a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;