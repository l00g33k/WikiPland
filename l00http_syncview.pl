use strict;
use warnings;
use l00backup;
use l00httpd;


# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# deletes files for now, rename, move and copy possible

my %config = (proc => "l00http_syncview_proc",
              desc => "l00http_syncview_desc");


# Theory of operation
# 1) Scan left file for first apperance of markers matching regex 
# and record start line and length of block and save in array
# 2) Scan right file for first apperance of markers matching regex 
# and record start line and length of block in associative array
# 3) Find first marker in left beyond specified number of lines 
# to skip, display the block on the left
# 4) Using associative array to look for the matching marker in 
# the right file and display matching block. Handle missing 
# associative array index



my ($width, $rightfile, $leftfile, $skip, $highlight);
my ($maxline, @RIGHT, @LEFT, $leftregex, $rightregex);
$width = 20;
$rightfile = '';
$leftfile = '';
$maxline = 1000;
$leftregex = '';
$rightregex = '';
$skip = 0;
$highlight = '';

sub l00http_syncview_make_outline {
    my ($oii, $nii, $width, $leftfile, $rightfile) = @_;
    my ($oout, $nout, $ospc, $tmp, $clip, $view, $lineno0, $lineno);


    if (($oii >= 0) && ($oii <= $#LEFT)) {
        $tmp = sprintf ("%-${width}s", substr($LEFT[$oii],0,$width));
        $ospc = sprintf ("%5d: %-${width}s", $oii + 1, ' ');
        $ospc =~ s/./ /g;
        $tmp =~ s/</&lt;/g;
        $tmp =~ s/>/&gt;/g;
        #$clip = &l00httpd::urlencode ($LEFT[$oii]);
        #$clip = "/clip.htm?update=Copy+to+clipboard&clip=$clip";

        $lineno = $oii + 1;
        $lineno0 = $lineno - 3;
        if ($lineno0 < 1) {
            $lineno0 = 1;
        }
        $view = "/view.htm?path=$leftfile&hiliteln=$lineno&lineno=on#line$lineno0";
        $oout = sprintf ("%5d<a href=\"%s\">:</a> %s", $oii + 1, $view, $tmp);
    } else {
        # make a string of space of same length
        $ospc = sprintf ("%5d: %-${width}s", 0, ' ');
        $ospc =~ s/./ /g;
        $oout = $ospc;
    }
    if (($nii >= 0) && ($nii <= $#RIGHT)) {
        $tmp = sprintf ("%-${width}s", substr($RIGHT[$nii],0,$width));
        $tmp =~ s/</&lt;/g;
        $tmp =~ s/>/&gt;/g;
        #$clip = &l00httpd::urlencode ($RIGHT[$nii]);
        #$clip = "/clip.htm?update=Copy+to+clipboard&clip=$clip";

        $lineno = $nii + 1;
        $lineno0 = $lineno - 3;
        if ($lineno0 < 1) {
            $lineno0 = 1;
        }
        $view = "/view.htm?path=$rightfile&hiliteln=$lineno&lineno=on#line$lineno0";
        $nout = sprintf ("%5d<a href=\"%s\">:</a> %s", $nii + 1, $view, $tmp);
    } else {
        $nout = '';
    }

    ($oout, $nout, $ospc);
}

sub l00http_syncview_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "syncview: synchronized view of two files";
}

sub l00http_syncview_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($htmlout, $cnt, $ln, $ii);
    my (@leftblkat, @leftmarkers, @leftblksz, $leftblkcnt, $rightblkcnt, $lastblksz);
    my (%rightmarkerat, %rightblksz, $lastrightmkr, $lnsoutput, $blkidx);
    my ($oout, $nout, $ospc, $dupmarkercnt, %dummymarker);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"_top_\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    if ((defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0))) {
        $form->{'path'} =~ s/\r//g;
        $form->{'path'} =~ s/\n//g;
        $_ = $form->{'path'};
        # keep path only
        s/\/[^\/]+$/\//;
        print $sock " Path: <a href=\"/ls.htm?path=$_\">$_</a>";
        $_ = $form->{'path'};
        # keep name only
        s/^.+\/([^\/]+)$/$1/;
        print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$_</a>\n";
    }
    print $sock "- <a href=\"#form\">Jump to end</a>\n";
    print $sock "<p>\n";


    if (defined ($form->{'width'})) {
        if ($form->{'width'} =~ /(\d+)/) {
            $width = $1;
        }
    }
    if (defined ($form->{'maxline'})) {
        if ($form->{'maxline'} =~ /(\d+)/) {
            $maxline = $1;
        }
    }
    if (defined ($form->{'skip'})) {
        if ($form->{'skip'} =~ /(\d+)/) {
            $skip = $1;
        }
    }
    if (defined ($form->{'leftregex'})) {
        $leftregex = $form->{'leftregex'};
    }
    if (defined ($form->{'rightregex'})) {
        $rightregex = $form->{'rightregex'};
    }
    if (defined ($form->{'highlight'})) {
        $highlight = $form->{'highlight'};
    }

    # copy paste target
    if (defined ($form->{'swap'})) {
        $_ = $leftfile;
        $leftfile = $rightfile;
        $rightfile = $_;

        $_ = $leftregex;
        $leftregex = $rightregex;
        $rightregex = $_;
    } elsif (defined ($form->{'pasteright'})) {
        # if pasting right file
        # this takes precedence over 'path'
        $rightfile = &l00httpd::l00getCB($ctrl);
    } elsif (defined ($form->{'pasteleft'})) {
        # if pasting left file
        # this takes precedence over 'path'
        $leftfile = &l00httpd::l00getCB($ctrl);
    } elsif (defined ($form->{'path'})) {
        # could be 'view' or from launcher.htm
        if (defined ($form->{'pathright'})) {
            # 'view' clicked, right file from rightfile field
            $rightfile = $form->{'pathright'};
        } else {
            # from ls.htm, push first file to be rightfile
            $rightfile = $leftfile;
        }
        # left file always from 'path' (field or from ls.htm)
        $leftfile = $form->{'path'};
    }

    if (defined ($form->{'view'})) {
        # 'view' clicked
        if ((defined ($form->{'pathright'})) && (length($form->{'pathright'}) > 2)) {
            $rightfile = $form->{'pathright'};
        }
        if ((defined ($form->{'pathleft'})) && (length($form->{'pathleft'}) > 2)) {
            $leftfile = $form->{'pathleft'};
        }

        $htmlout = "<pre>\n";

        # 1) Scan left file for first apperance of markers matching regex 
        # and record start line and length of block and save in array
        if (&l00httpd::l00freadOpen($ctrl, "$leftfile")) {
            $htmlout .= "Left file: <a href=\"/view.htm?path=$leftfile\">$leftfile</a>\n";
            undef @LEFT;
            $cnt = 0;
            undef @leftblkat;
            undef @leftmarkers;
            undef @leftblksz;
            $leftblkcnt = 0;
            $lastblksz = 0;
            $dupmarkercnt = 0;
            undef %dummymarker;
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                s/\r//;
                s/\n//;
                $lastblksz++;
                if (/$leftregex/) {
                    if (defined($dummymarker{$1})) {
                        # ignore duplicated marker
                        $dupmarkercnt++;
                    } else {
                        $dummymarker{$1} = 1;
                        $leftblkat[$leftblkcnt] = $cnt;
                        $leftmarkers[$leftblkcnt] = $1;
                        if ($leftblkcnt > 0) {
                            $leftblksz[$leftblkcnt - 1] = $lastblksz;
                        }
                        $leftblkcnt++;
                        $lastblksz = 1;
                    }
                }
                push (@LEFT, $_);
                $cnt++;
            }
            if ($leftblkcnt > 0) {
                $leftblksz[$leftblkcnt - 1] = $lastblksz;
            }
            $htmlout .= "    read $cnt lines and found $leftblkcnt markers, $dupmarkercnt duplicates\n";
        } else {
            $htmlout .= "$leftfile open failed\n";
        }


        # 2) Scan right file for first apperance of markers matching regex 
        # and record start line and length of block in associative array
        if (&l00httpd::l00freadOpen($ctrl, "$rightfile")) {
            $htmlout .= "Right file: <a href=\"/view.htm?path=$rightfile\">$rightfile</a>\n";
            undef @RIGHT;
            $cnt = 0;
            undef %rightmarkerat;
            undef %rightblksz;
            $lastrightmkr = '';
            $rightblkcnt = 0;
            $lastblksz = 0;
            $dupmarkercnt = 0;
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                s/\r//;
                s/\n//;
                $lastblksz++;
                if (/$rightregex/) {
                    if (defined($rightmarkerat{$1})) {
                        # ignore duplicated marker
                        $dupmarkercnt++;
                    } else {
                        $rightmarkerat{$1} = $cnt;
                        if ($lastrightmkr ne '') {
                            $rightblksz{$lastrightmkr} = $lastblksz;
                        }
                        $lastblksz = 1;
                        $lastrightmkr = $1;
                        $rightblkcnt++;
                    }
                }
                push (@RIGHT, $_);
                $cnt++;
            }
            $rightblksz{$lastrightmkr} = $lastblksz;
            $htmlout .= "    read $cnt lines and found $rightblkcnt markers, $dupmarkercnt duplicates\n\n";
        } else {
            $htmlout .= "$rightfile open failed\n\n";
        }


        $lnsoutput = 0;
        $blkidx = 0;
        while ($lnsoutput++ < $maxline) {
            for ($blkidx = 0; $blkidx < $leftblkcnt; $blkidx++) {
                if ($leftblkat[$blkidx] < $skip) {
                    next;
                }
                # 3) Find first marker in left beyond specified number of lines 
                # to skip, display the block on the left
                # 4) Using associative array to look for the matching marker in 
                # the right file and display matching block. Handle missing 
                # associative array index
                if (!defined($rightblksz{$leftmarkers[$blkidx]}) ||
                    ($leftblksz[$blkidx] >= $rightblksz{$leftmarkers[$blkidx]})) {
                    # left block larger
                    # print both
                    $ii = 0;
                    if (defined($rightblksz{$leftmarkers[$blkidx]})) {
                        for (; $ii < $rightblksz{$leftmarkers[$blkidx]}; $ii++) {
                            ($oout, $nout, $ospc) = &l00http_syncview_make_outline(
                                $leftblkat[$blkidx] + $ii, 
                                $rightmarkerat{$leftmarkers[$blkidx]} + $ii, 
                                $width, $leftfile, $rightfile);
                            if ($ii == 0) {
                                $oout =~ s/($leftmarkers[$blkidx])/<font style="color:black;background-color:silver">$1<\/font>/;
                                $nout =~ s/($leftmarkers[$blkidx])/<font style="color:black;background-color:silver">$1<\/font>/;
                            }
                            $htmlout .= " $oout |$nout\n";
                            if ($lnsoutput++ >= $maxline) {
                                last;
                            }
                        }
                        if ($lnsoutput >= $maxline) {
                            last;
                        }
                    }
                    # and remaining left
                    for (; $ii < $leftblksz[$blkidx]; $ii++) {
                        ($oout, $nout, $ospc) = &l00http_syncview_make_outline(
                            $leftblkat[$blkidx] + $ii, 
                            -1, 
                            $width, $leftfile, $rightfile);
                        $htmlout .= " $oout |$nout\n";
                        if ($lnsoutput++ >= $maxline) {
                            last;
                        }
                    }
                } else {
                    # right block larger
                    # print both
                    $ii = 0;
                    if (defined($rightmarkerat{$leftmarkers[$blkidx]})) {
                        for (; $ii < $leftblksz[$blkidx]; $ii++) {
                            ($oout, $nout, $ospc) = &l00http_syncview_make_outline(
                                $leftblkat[$blkidx] + $ii, 
                                $rightmarkerat{$leftmarkers[$blkidx]} + $ii, 
                                $width, $leftfile, $rightfile);
                            if ($ii == 0) {
                                $oout =~ s/($leftmarkers[$blkidx])/<font style="color:black;background-color:silver">$1<\/font>/;
                                $nout =~ s/($leftmarkers[$blkidx])/<font style="color:black;background-color:silver">$1<\/font>/;
                            }
                            $htmlout .= " $oout |$nout\n";
                            if ($lnsoutput++ >= $maxline) {
                                last;
                            }
                        }
                        if ($lnsoutput >= $maxline) {
                            last;
                        }
                    }
                    # and remaining left
                    for (; $ii < $rightblksz{$leftmarkers[$blkidx]}; $ii++) {
                        ($oout, $nout, $ospc) = &l00http_syncview_make_outline(
                            -1, 
                            $rightmarkerat{$leftmarkers[$blkidx]} + $ii, 
                            $width, $leftfile, $rightfile);
                        $htmlout .= " $oout |$nout\n";
                        if ($lnsoutput++ >= $maxline) {
                            last;
                        }
                    }
                }
                if ($lnsoutput >= $maxline) {
                    last;
                }
            }
            last;
        }
        $htmlout .= "</pre>\n";

        # global highlight
        if (($highlight ne '') && (length($highlight) > 1)) {
            $htmlout =~ s/($highlight)/<font style="color:black;background-color:yellow">$1<\/font>/gsm;
        }

        print $sock $htmlout;
    }

    print $sock "<a href=\"#_top_\">Jump to top</a><br>\n";
    print $sock "<a name=\"form\"></a>\n";
    print $sock "<form action=\"/syncview.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"view\" value=\"View\">\n";
    print $sock "Width: <input type=\"text\" size=\"4\" name=\"width\" value=\"$width\">\n";
    print $sock "Highlight: <input type=\"text\" size=\"8\" name=\"highlight\" value=\"$highlight\">\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"pasteleft\" value=\"CB>Left:\">";
    print $sock " Marker regex: <input type=\"text\" size=\"8\" name=\"leftregex\" value=\"$leftregex\">\n";
    print $sock "<br><textarea name=\"pathleft\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$leftfile</textarea>\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"pasteright\" value=\"CB>Right:\">";
    print $sock " Marker regex: <input type=\"text\" size=\"8\" name=\"rightregex\" value=\"$rightregex\">\n";
    print $sock "<br><textarea name=\"pathright\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$rightfile</textarea>\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "&nbsp;";
    print $sock "<input type=\"submit\" name=\"swap\" value=\"Swap\">; ";
    print $sock "Skip <input type=\"text\" size=\"4\" name=\"skip\" value=\"$skip\"> lines, view\n";
    print $sock "<input type=\"text\" size=\"4\" name=\"maxline\" value=\"$maxline\"> lines max.\n";
    print $sock "</td></tr>\n";
    print $sock "</table><br>\n";
    print $sock "</form>\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
