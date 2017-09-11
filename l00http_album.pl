use strict;
use warnings;
use l00wikihtml;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# (Non automatic) slide show

my %config = (proc => "l00http_album_proc",
              desc => "l00http_album_desc");
my ($width, $height, $llspath);
$width = '50%';
$height = '';


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
        %pics, %notes, @srcdir, $srcfile, %allpics, $dir, $regex, $output, 
        $size, $atime, $mtimea, $mtimeb, $ctime, $blksize, $blocks);
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);



    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>l00httpd</title>" . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"#end\">end</a>\n";
    if (defined ($form->{'path'})) {
        print $sock " - <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a><p>\n";
    }

    if (defined ($form->{'set'})) {
        if (defined ($form->{'width'})) {
            $width = $form->{'width'};
        }
        if (defined ($form->{'height'})) {
            $height = $form->{'height'};
        }
    }


    if (defined ($form->{'path'})) {
        ($path) = $form->{'path'} =~ /^(.+\/)[^\/]+$/;

        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            undef %pics;
            undef %notes;
            undef @srcdir;

            # read srcdir
            $srcfile = &l00httpd::l00freadAll($ctrl);
            foreach $_ (split("\n", $srcfile)) {
                s/\n//;
                s/\r//;
                if (/^DIR:(.+)/) {
                    push(@srcdir, $1);
                }
            }

            # scan for all pictures
            undef %allpics;
            foreach $dir (@srcdir) {
                if (opendir (DIR, $dir)) {
                    print $sock "Searching: <a href=\"/ls.htm?path=$dir\">$dir</a><br>\n";
                    foreach $file (readdir (DIR)) {
                        if (($file =~ /\.jpg/i)) {
                            $allpics{$file} = $dir;
                        }
                    }
                    closedir (DIR);
                }
            }

            # generate web view
            $output = '';
            foreach $_ (split("\n", $srcfile)) {
                s/\n//;
                s/\r//;
                if (/^DIR:(.+)/) {
                    next;
                }
                if (/^PIC:(.+)/) {
                    $regex = $1;
                    foreach $file (keys %allpics) {
                        if ($file =~ /$regex/i) {
                            $tmp = $allpics{"$file"}.$file;
                            $output .= "\n<a href=\"/ls.htm?path=$tmp\">".
                                "<img src=\"/ls.htm/$file?path=$tmp\" width=\"$width\" height=\"$height\"></a>".
                                "<br><small>$file</small>".
                                "\n";
                        }
                    }
                    next;
                }
                $output .= "$_\n";
            }
            print $sock &l00wikihtml::wikihtml ($ctrl, "", $output, 0);;

        }
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
    print $sock "</table>\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</form>\n";

    print $sock "<p>Jump to <a href=\"#top\">top</a>. clip: <a href=\"/clip.htm?update=Copy+to+clipboard&clip=$form->{'path'}\">$form->{'path'}</a><br>\n";
    print $sock "<a href=\"/ls.htm?path=$path\">$path</a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
