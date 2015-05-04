use strict;
use warnings;
use l00backup;
use l00wikihtml;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Create reader push/pull copy/paste command lines

my %config = (proc => "l00http_reader_proc",
              desc => "l00http_reader_desc");
my ($hostpath, $zoom, $maxarts, $readln, $lastpath);
$hostpath = "c:\\x\\";
$zoom = 150;
$maxarts = 20;
$readln = 1;
$lastpath = '';

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
	my ($cachepath, $cachename, $cachelink, $url, $morepage, $tmp2, %duplicate, $cnt);
    my ($docaching);

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
        $zoom = $form->{'zoom'};
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
    print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\" target=\"newwin\">clipboard</a>\n";
    print $sock "<input type=\"submit\" name=\"markread\" value=\"Mark read\">\n";
    print $sock "<input type=\"hidden\" name=\"readln\" value=\"$readln\">\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</form>\n";

    print $sock "<p><a target=\"newwin\" href=\"/mobizoom.htm\">mobiz</a>\n";
    print $sock "<a href=\"#end\">end</a>\n";

    print $sock "<a href=\"#line\">Line $readln</a>:";
    if ($curr =~ /^(\d{8,8} \d{6,6}) /) {
		$cachename = $1;
		$cachename =~ s/ /_/;
		$cachepath = "$form->{'path'}.cached/";
        $cachename = "$cachepath$cachename.txt";
        $tmp2 = '';
		while (-e $cachename) {
            print $sock " <a target=\"newwin$tmp2\" href=\"/mobizoom.htm?url=$cachename&fetch=1&zoom=$zoom\">cached$tmp2</a> ";
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


    print $sock "<p>Listing of <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a>:\n";


    print $sock " <form action=\"/reader.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"download\" value=\"Download All\">\n";
    print $sock "max #:<input type=\"text\" size=\"3\" name=\"maxarts\" value=\"$maxarts\">\n";
    print $sock "zoom:<input type=\"text\" size=\"3\" name=\"zoom\" value=\"$zoom\">\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "<input type=\"submit\" name=\"mobizoomzoom\" value=\"Mobizoom %\">\n";
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
            while (<IN>) {
                if (/^---/) {
                    # --- ends attempt to cache
                    $docaching = 0;
                }
                if (-f "$ctrl->{'workdir'}SigReaderDownloadStop.txt") {
                    # Existence of file signal stop downloading
                    unlink ("$ctrl->{'workdir'}SigReaderDownloadStop.txt");
                    $docaching = 0;
                }
                if (/^(\d{8,8} \d{6,6}) /) {
					$cachename = $1;
					$cachename =~ s/ /_/;
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
                                                            print "off-line cache: $url\n";
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
					if (-e $cachename) {
                        my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
                        $size, $atime, $mtimea, $ctime, $blksize, $blocks)
                            = stat($cachename);
                        $cachelink = sprintf("<a href=\"/view.htm?path=$cachename\">(%6d)</a> ", $size);;
					} else {
					    $cachelink = '';
					}
				} else {
				    $cachelink = '';
				}
                if ($lnno == $readln) {
                    print $sock sprintf("<a name=\"line\"><font style=\"color:black;background-color:lime\">%04d</font>: ", $lnno) . $cachelink . $_;
                } else {
                    if (/^#/) {
                        # marked read
                    } else {
                        print $sock sprintf("<a href=\"/reader.htm?path=$form->{'path'}&readln=$lnno\">%04d</a>: ", $lnno) . $cachelink . $_;
                    }
                }
                $lnno++;
            }
            close(IN);
        }
        print $sock "<hr>\n";
        print $sock "<a name=\"end\"></a><a href=\"#top\">Jump to top</a>. Full file:\n";
        print $sock "<hr>\n";
        if (open(IN, "<$form->{'path'}")) {
            $lnno = 1;
            while (<IN>) {
                print $sock sprintf("%04d: ", $lnno) . $_;
                $lnno++;
            }
            close(IN);
        }
    }
    print $sock "</pre>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
