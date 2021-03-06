use strict;
use warnings;
use l00backup;
use l00wikihtml;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Create reader push/pull copy/paste command lines

my %config = (proc => "l00http_reader_proc",
              desc => "l00http_reader_desc");
my ($hostpath, $zoom, $maxarts, $readln, $lastpath, $maxlines);
$hostpath = "c:\\x\\";
$zoom = 150;
$maxarts = 20;
$readln = 1;
$lastpath = '';
$maxlines = 100;

sub l00http_reader_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "reader: reader";
}

sub l00http_reader_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($path, $fname, $lnno, $lnno2, $tmp, $curr, $buf, $font0, $font1);
	my ($cachepath, $cachename, $cachenameonly, $cachelink, $url, $morepage, $tmp2, %duplicate, $cnt);
    my ($docaching, $noart, $nodownload);
    my ($diskunread, $diskreaded, $diskcached, $diskcachedbytes, %disklinked);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>reader</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<a name=\"top\"></a><br>\n";


    if (defined ($form->{'readln'})) {
        $readln = $form->{'readln'};
#   } else {
#       $readln = 1;
    }
    if (defined ($form->{'next'})) {
        $readln++;
    }
    if (defined ($form->{'last'})) {
        $readln--;
    }
    if (defined ($form->{'mobizoomzoom'})) {
        if (defined ($form->{'zoomradio'})) {
            $zoom = $form->{'zoomradio'};
        } else {
            $zoom = $form->{'zoom'};
        }
    }
    if (defined ($form->{'setmaxlines'}) && defined ($form->{'maxlines'})) {
        # parse max number of lines to display
        if ($form->{'maxlines'} =~ /(\d+)/) {
            $maxlines = $1;
        }
    }

    $curr = '';
    $lnno = 0;
    $lnno2 = 0;
    if (defined ($form->{'path'})) {
        if ($lastpath ne $form->{'path'}) {
            # reset readln when switching to different file
            $lastpath = $form->{'path'};
            $readln = 1;
        }
        if (open(IN, "<$form->{'path'}")) {
            $buf = '';
            while (<IN>) {
                $lnno++;
                # mark read
                if ((defined ($form->{'markread'})) && ($lnno == $readln) && (/^[^#]/)) {
                    $buf .= "#$_";
                } else {
                    $buf .= $_;
                }
                # find line
                if (/^#/) {
                    next;
                }
                if (/^[0-9 ]/) {
                    $lnno2++;
                    if (defined ($form->{'markread'})) {
                        if ($lnno == ($readln + 1)) {
                            $curr = $_;
                        }
                    } else {
                        if ($lnno == $readln) {
                            $curr = $_;
                        }
                    }
                } else {
                   #last;
                }
            }
            close(IN);
        }
    }

    # mark read
    if (defined ($form->{'markread'})) {
        &l00backup::backupfile ($ctrl, $form->{'path'}, 0, 0);
        if (open(OUT, ">$form->{'path'}")) {
            print OUT $buf;
            close(OUT);
        }
        $readln++;
    }

    print $sock "<p>\n";


    print $sock "<p><form action=\"/reader.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"last\" value=\"Last\">\n";
    print $sock "<input type=\"submit\" name=\"refresh\" value=\"Refresh\">\n";
    print $sock "<input type=\"submit\" name=\"next\" value=\"Next\">\n";
#   $tmp = $curr;
#   $tmp =~ s/ /+/g;
#   $tmp =~ s/:/%3A/g;
#   $tmp =~ s/&/%26/g;
#   $tmp =~ s/=/%3D/g;
#   $tmp =~ s/"/%22/g;
#   $tmp =~ s/\//%2F/g;
#   $tmp =~ s/\|/%7C/g;
    $tmp = &l00httpd::urlencode ($curr);
    if (defined($ctrl->{'readerjumpurl'})) {
        $tmp .= "&url=$ctrl->{'readerjumpurl'}";
    }
    print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&jumpurl=yes&clip=$tmp\" target=\"_blank\">clipboard</a>\n";
    print $sock "<input type=\"submit\" name=\"markread\" value=\"Mark read\">\n";
    print $sock "<input type=\"hidden\" name=\"readln\" value=\"$readln\">\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</form>\n";

    print $sock "<p><a target=\"_blank\" href=\"/mobizoom.htm\">mobiz</a>\n";
    print $sock "<a href=\"#end\">end</a>\n";

    print $sock "<a href=\"#line\">Line $readln</a>:";
    if ($curr =~ /^(\d{8,8} \d{6,6}) /) {
		$cachename = $1;
		$cachename =~ s/ /_/;
		$cachepath = "$form->{'path'}.cached/";
        $cachename = "$cachepath$cachename.txt";
        $tmp2 = '';
		while (-e $cachename) {
            print $sock " <a target=\"_blank\" href=\"/mobizoom.htm?url=$cachename&fetch=1&zoom=$zoom\">cached$tmp2</a> ";
            $cachename =~ s/\.txt$/_.txt/;   # grow _.txt :)
            if ($tmp2 eq '') {
                $tmp2 = '-1';
            } else {
                $tmp2 = '-' . (substr($tmp2, 1, 1) + 1);
            }
		}
    }
    $curr = &l00wikihtml::wikihtml ($ctrl, "", $curr, 0);
    print $sock "<p>$curr";


    print $sock "<p>Listing of <a href=\"/view.htm?path=$form->{'path'}\">$form->{'path'}</a>:\n";

    print $sock "<form action=\"/reader.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"setmaxlines\" value=\"Max Lines\">\n";
    print $sock "<input type=\"text\" size=\"3\" name=\"maxlines\" value=\"$maxlines\">\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</form>\n";

    print $sock "<form action=\"/reader.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"download\" value=\"Download All\">\n";
    print $sock "max #:<input type=\"text\" size=\"3\" name=\"maxarts\" value=\"$maxarts\">\n";
    print $sock "zoom:<input type=\"text\" size=\"3\" name=\"zoom\" value=\"$zoom\">\n";
    print $sock "<input type=\"radio\" name=\"zoomradio\" value=\"121\"><a href=\"/reader.pl?path=$form->{'path'}&zoomradio=121&mobizoomzoom=Mobizoom\">121</a> ";
    print $sock "<input type=\"radio\" name=\"zoomradio\" value=\"146\"><a href=\"/reader.pl?path=$form->{'path'}&zoomradio=146&mobizoomzoom=Mobizoom\">146</a> ";
    print $sock "<input type=\"radio\" name=\"zoomradio\" value=\"187\"><a href=\"/reader.pl?path=$form->{'path'}&zoomradio=187&mobizoomzoom=Mobizoom\">187</a> ";
    print $sock "<input type=\"radio\" name=\"zoomradio\" value=\"240\"><a href=\"/reader.pl?path=$form->{'path'}&zoomradio=240&mobizoomzoom=Mobizoom\">240</a> ";
    print $sock "<input type=\"submit\" name=\"mobizoomzoom\" value=\"Mobizoom %\">\n";
    print $sock "<input type=\"submit\" name=\"diskusage\" value=\"Disk Usage\">\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    if (defined ($form->{'diskusage'})) {
        $diskunread = 0;
        $diskreaded = 0;
        $diskcached = 0;
        $diskcachedbytes = 0;
        undef %disklinked;
        print $sock "<a href=\"#diskusage\">Jump usage report</a>\n";
    }
    print $sock "</form>\n";

    if ((defined ($form->{'path'})) && (defined ($form->{'download'}))) {
        print $sock "<br>Downloading. $lnno2 lines to check.\n";
        print $sock "Start 20347 server and click <a href=\"http://127.0.0.1:20347/sleep.htm?path=$ctrl->{'workdir'}SigReaderDownloadStop.txt&save=y&buffer=Existence+of+file+signal+stop\">here</a> to stop downloading.\n";
        print $sock "<br>\n";
    }

    print $sock "<pre>\n";

    if (defined ($form->{'path'})) {
        if (open(IN, "<$form->{'path'}")) {
            if (defined ($form->{'download'}) && defined ($form->{'maxarts'})) {
                $maxarts = $form->{'maxarts'};
            }

            $lnno = 1;
            $cnt = 0;
            $docaching = 1;
            $noart = 0;
            $nodownload = 0;
            while (<IN>) {
                if (/^---/) {
                    # --- ends attempt to cache
                    # change to
                    # --- ends readmarks
                    $docaching = 0;
                    last;
                }
                # % is %TOC or %TXTDOPL and must not be present between 
                # article entries. We stop here
                if (/^%/) {
                    last;
                }
                if (-f "$ctrl->{'workdir'}SigReaderDownloadStop.txt") {
                    # Existence of file signal stop downloading
                    unlink ("$ctrl->{'workdir'}SigReaderDownloadStop.txt");
                    $docaching = 0;
                }
				$cachelink = '';
                if (/^ *$/) {
                    # skip blank lines
                    next;
                }
                if (/^(\d{8,8} \d{6,6}) /) {
                    # date stamp (20170313 133301) in column 0 signifies
                    # uncached entry
                    $noart++;
                    if (($noart <= $maxlines) ||
                        (defined ($form->{'diskusage'}))) {
                        # process up to $maxlines only
                        # but do all if diskusage
					    $cachename = $1;
					    $cachename =~ s/ /_/;
                        $cachenameonly = "$cachename.txt";
					    $cachepath = "$form->{'path'}.cached/";
					    if (!-d $cachepath) {
                            # mkdir if not exist
                            mkdir ($cachepath);
					    }
                        $cachename = "$cachepath$cachename.txt";
                        if (defined ($form->{'download'}) && 
                            !(-e $cachename) &&
                            $docaching &&
                            ($lnno >= $readln) && # start from read
                            ($cnt < $maxarts)) {   # download at most 50 articles at once
                            # downloading and not yet cached. cache now
						    $tmp = $_;
                            $path = $form->{'path'};
                            $form->{'path'} = $cachename;

                            if (/(https*:\/\/[^ \n\r\t]+)/) {
                                $_ = $1;
                            }
                            if (!($_ =~ /https*:\/\//)) {
                                # Opera Mini does not include http://
                                $_ = "http://$_";
                            }
                            if ($_ =~ /google\.com\/url\?.*&q=(http.+)[^&]/) {
                                $_ = $1;
                            }
                            $form->{'url'} = $_;
                            $form->{'fetch'} = 1;
                            &l00http_mobizoom_proc($main, $ctrl);
                            $form->{'path'} = $path;

                            # special slashdot.org handling: download linked pages
                            # slashdot.org post often contains links. Let's cache those too.
                            if (&l00httpd::l00freadOpen($ctrl, $cachename)) {
                                while ($_ = &l00httpd::l00freadLine($ctrl)) {
                                    if (/href='\/mobizoom\.htm\?.+slashdot\.org/) {
                                        undef %duplicate;
                                        $morepage = $cachename;
                                        while ($_ = &l00httpd::l00freadLine($ctrl)) {
                                            if (/Posted[\t ]+by/) {
                                                # skip first line, may have link to poster
                                                &l00httpd::l00freadLine($ctrl);
                                                while ($_ = &l00httpd::l00freadLine($ctrl)) {
                                                    if (/You may like to read/) {
                                                        # end of slashdot post/comment begins
                                                        last;
                                                    }
                                                    if (/Related Links/) {
                                                        # alternate end of slashdot post/comment begins
                                                        last;
                                                    }
                                                    # look for URL to download, e.g.
                                                    # <a href='/mobizoom.htm?zoom=144&url=http%3A%2F%2Fwww.monkey.org%2F~timothy%2F%26ei%3D-AikUrXeEISykgLev4DICw'>
                                                    if (/<a href='\/mobizoom\.htm\?.+?(http.+?)'>/) {
                                                        $url = $1;
                                                        $url =~ s/\%([a-fA-F0-9]{2})/pack("C", hex($1))/seg;
                                                        # chop off anything after &
                                                        $url =~ s/&.*$//;
                                                        # not link to previous
                                                        if (!($url =~ /sdsrc=prev/)) {
                                                            if (!defined($duplicate{$url})) {
                                                                # remember it
                                                                $duplicate{$url} = 1;
                                                                print "off-line cache: $url ($lnno/$lnno2)\n";
                                                                # fetch it
                                                                $path = $form->{'path'};
                                                                $morepage =~ s/\.txt$/_.txt/;   # grow _.txt :)
                                                                $form->{'path'} = $morepage;
                                                                $form->{'url'} = $url;
                                                                $form->{'fetch'} = 1;
                                                                &l00http_mobizoom_proc($main, $ctrl);
                                                                $form->{'path'} = $path;
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }

						    $_ = $tmp;
						    $cnt++;
                        }
                        if (defined ($form->{'diskusage'})) {
                            $diskunread++;
                        }
 					    if (-e $cachename) {
                            my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
                            $size, $atime, $mtimea, $ctime, $blksize, $blocks)
                                = stat($cachename);
                            $cachelink = sprintf("<a href=\"/view.htm?path=$cachename\">(%6d)</a> ", $size);;
                            $nodownload++;
                            if (defined ($form->{'diskusage'})) {
                                $disklinked{$cachenameonly} = 1;
                                $diskcached++;
                                $diskcachedbytes += $size;
                            }
					    }
                    }
				}
                if ($lnno == $readln) {
                    # current line
                    print $sock sprintf("<a name=\"line\"><font style=\"color:black;background-color:lime\">%04d</font>: ", $lnno) . $cachelink . $_;
                } else {
                    if (/^#\d{8,8} \d{6,6} /) {
                        # this entry already marked read
                        if (defined ($form->{'diskusage'})) {
                            $diskreaded++;
                        }
                    } else {
                        print $sock sprintf("<a href=\"/reader.htm?path=$form->{'path'}&readln=$lnno\">%04d</a>: ", $lnno) . $cachelink . $_;
                    }
                }
                $lnno++;
                if (($noart > $maxlines) &&
                    (!defined ($form->{'diskusage'}))) {
                    # stops at limit
                    print $sock "\nListed maximum number of $maxlines articles. There may be more articles not listed.\n\n";
                    last;
                }
            }
            close(IN);
        }
        print $sock "<hr>\n";

        # disk usage report output
        if (defined ($form->{'diskusage'})) {
            print $sock "<a name=\"diskusage\"></a>Disk usage report:\n";
            printf $sock ("Total          articles:%10d\n", $lnno);
            printf $sock ("Read           articles:%10d\n", $diskreaded);
            printf $sock ("Unread         articles:%10d\n", $diskunread);
            printf $sock ("Cached unread  articles:%10d\n", $diskcached);
            printf $sock ("Cached    size in bytes:%10d\n", $diskcachedbytes);

            if (opendir (DIR, $cachepath)) {
                my ($listed, $unlisted, $listedbytes, $unlistedbytes);
                $lnno = 0;
                $listed = 0;
                $unlisted = 0;
                $listedbytes = 0;
                $unlistedbytes = 0;
                foreach $_ (sort readdir (DIR)) {
                    $lnno++;
                    if (/\.txt$/) {
                        my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
                        $size, $atime, $mtimea, $ctime, $blksize, $blocks)
                            = stat("$cachepath$_");
                        if (defined($disklinked{$_})) {
                            #print $sock "listed $_\n";
                            $listed++;
                            $listedbytes += $size;
                        } else {
                            #print $sock "unlisted $_\n";
                            $unlisted++;
                            $unlistedbytes += $size;
                        }
                    }
                }
                &l00httpd::l00fwriteOpen($ctrl, 'l00://listed.txt');
                &l00httpd::l00fwriteBuf($ctrl, "l00://listed.txt");
                &l00httpd::l00fwriteClose($ctrl);
                &l00httpd::l00fwriteOpen($ctrl, 'l00://unlisted.txt');
                &l00httpd::l00fwriteBuf($ctrl, "l00://unlisted.txt");
                &l00httpd::l00fwriteClose($ctrl);
                print $sock "There are $lnno .txt in cached. $listed listed, unlisted $unlisted\n";
                printf $sock ("Listed   cache in bytes:%10d  <a href=\"/view.htm?path=l00://listed.txt\">l00://listed.txt</a>\n", $listedbytes);
                printf $sock ("Unlisted cache in bytes:%10d  <a href=\"/view.htm?path=l00://unlisted.txt\">l00://unlisted.txt</a>\n", $unlistedbytes);
                closedir (DIR);
            }

            print $sock "\n";
        }


        print $sock "<a name=\"end\"></a><a href=\"#top\">Jump to top</a>. Full file:\n";
        $_ = $noart - $nodownload;
        print $sock "There are $noart articles, $nodownload cached, $_ uncached (but only $maxlines lines are processed)\n";
    }
    print $sock "</pre>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
