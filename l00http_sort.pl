use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# sort block selected in edit.pl

#l00httpd::dbp($config{'desc'}, "2 contextln $contextln\n");
my %config = (proc => "l00http_sort_proc",
              desc => "l00http_sort_desc");
my ($linessorted, @sortbuf, $sortkey, $sortdir);
$linessorted = 0;
$sortkey = '';

sub sortfn {
    my ($cmp, $akey, $bkey);

    if ($a =~ /$sortkey/) {
        $akey = $1;
    } else {
        $akey = $a;
    }
    if ($b =~ /$sortkey/) {
        $bkey = $1;
    } else {
        $bkey = $b;
    }
    l00httpd::dbp('l00http_sort_desc', "akey $akey       bkey $bkey\n");

    if ($sortdir) {
        $cmp = $akey cmp $bkey;
    } else {
        $cmp = $bkey cmp $akey;
    }


    $cmp;
}

sub l00http_sort_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "sort: sort file";
}

sub l00http_sort_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($lineno, $outbuf, @inbuf, $ii, $last, $pname, $fname);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#end\">Jump to end</a>\n";

    if ($form->{'path'} =~ /^l00:\/\//) {
        $pname = '';
        $fname = $form->{'path'};
    } else {
        ($pname, $fname) = $form->{'path'} =~ /^(.+[\\\/])([^\\\/]+)$/;
    }
    print $sock " - <a href=\"/clip.htm?update=Copy+to+clipboard&clip=$form->{'path'}%0D\">Path</a>: ";
    print $sock " <a href=\"/ls.htm?path=$pname\">$pname</a>";
    print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$fname</a> - \n";
    print $sock "<a href=\"/view.htm/$fname.htm?path=$pname$fname\">view</a>\n";
    
    print $sock "<br>\n";


    if (!defined ($form->{'sorting'})) {
        $linessorted = 0;
        if (&l00httpd::l00freadOpen($ctrl, "$pname$fname")) {
            $outbuf = &l00httpd::l00freadAll($ctrl);
            &l00httpd::l00fwriteOpen($ctrl, 'l00://editblock.txt');
            &l00httpd::l00fwriteBuf($ctrl, $outbuf);
            &l00httpd::l00fwriteClose($ctrl);
        }
    }

    if (defined ($form->{'save'})) {
        if (&l00httpd::l00freadOpen($ctrl, 'l00://editblock.txt')) {
            $outbuf = &l00httpd::l00freadAll($ctrl);
            &l00httpd::l00fwriteOpen($ctrl, "$pname$fname");
            &l00httpd::l00fwriteBuf($ctrl, $outbuf);
            &l00httpd::l00fwriteClose($ctrl);
        }
    }


    if (defined ($form->{'pick'})) {
        undef @inbuf;
        if (&l00httpd::l00freadOpen($ctrl, 'l00://editblock.txt')) {
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                push (@inbuf, $_);
            }
            $outbuf = '';
            # skip first $linessorted line already sorted
            for ($ii = 0; $ii < $linessorted; $ii++) {
                $outbuf .= $inbuf[$ii];
            }
            # insert picked line
            $outbuf .= $inbuf[$form->{'pick'} - 1];
            for ($ii = $linessorted; $ii <= $#inbuf; $ii++) {
                if ($ii != ($form->{'pick'} - 1)) {
                    $outbuf .= $inbuf[$ii];
                }
            }
            &l00httpd::l00fwriteOpen($ctrl, 'l00://editblock.txt');
            &l00httpd::l00fwriteBuf($ctrl, $outbuf);
            &l00httpd::l00fwriteClose($ctrl);
            $linessorted++;
        }
    }

    if (defined ($form->{'ascend'})) {
        undef @inbuf;
        if (&l00httpd::l00freadOpen($ctrl, 'l00://editblock.txt')) {
            $sortdir = 1;
            $sortkey = '(.+)';
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                push (@inbuf, $_);
                if (/%EDITSORTKEY:(.+)%/) {
                    $sortkey = $1;
                    l00httpd::dbp('l00http_sort_desc', "Ascending sortkey $sortkey\n");
                }
            }
            $outbuf = join("", sort sortfn (@inbuf));
            &l00httpd::l00fwriteOpen($ctrl, 'l00://editblock.txt');
            &l00httpd::l00fwriteBuf($ctrl, $outbuf);
            &l00httpd::l00fwriteClose($ctrl);
        }
    }
    if (defined ($form->{'descend'})) {
        undef @inbuf;
        if (&l00httpd::l00freadOpen($ctrl, 'l00://editblock.txt')) {
            $sortdir = 0;
            $sortkey = '(.+)';
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                push (@inbuf, $_);
                if (/%EDITSORTKEY:(.+)%/) {
                    $sortkey = $1;
                    l00httpd::dbp('l00http_sort_desc', "Dscending sortkey $sortkey\n");
                }
            }
            $outbuf = join("", sort sortfn (@inbuf));
            &l00httpd::l00fwriteOpen($ctrl, 'l00://editblock.txt');
            &l00httpd::l00fwriteBuf($ctrl, $outbuf);
            &l00httpd::l00fwriteClose($ctrl);
        }
    }
    if (defined ($form->{'dedup'})) {
        undef @inbuf;
        undef $last;
        if (&l00httpd::l00freadOpen($ctrl, 'l00://editblock.txt')) {
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                if (defined($last) && ($last eq $_)) {
                    # same as last line, dedup by skipping
                    next;
                }
                push (@inbuf, $_);
                $last = $_;
            }
            $outbuf = join("", sort sortfn (@inbuf));
            &l00httpd::l00fwriteOpen($ctrl, 'l00://editblock.txt');
            &l00httpd::l00fwriteBuf($ctrl, $outbuf);
            &l00httpd::l00fwriteClose($ctrl);
        }
    }

    # display sort in progress
    if (&l00httpd::l00freadOpen($ctrl, 'l00://editblock.txt')) {
        print $sock "<p><pre>\n";
        $lineno = 1;
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            $outbuf .= $_;
            s/\r//g;
            s/\n//g;
            s/</&lt;/g;
            s/>/&gt;/g;
            if (($lineno - 1) < $linessorted) {
                # highlight sorted line
                print $sock sprintf ("<font style=\"color:black;background-color:lime\">".
                                     "%04d</font>: ", $lineno) . "$_\n";
            } else {
                print $sock sprintf ("<a href=\"/sort.htm?path=$pname$fname&sorting=sorting&pick=$lineno\">%04d</a>: ", $lineno) . "$_\n";
            }
            $lineno++;
        }
        print $sock "</pre>\n";
    }


    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";

    print $sock "<tr><td>\n";
    print $sock "<form action=\"/sort.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"save\" value=\"S&#818;ave\" accesskey=\"s\">\n";
    print $sock "<input type=\"hidden\" name=\"sorting\" value=\"sorting\">\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$pname$fname\">\n";
    print $sock "</form>\n";
    print $sock "</td>\n";

    print $sock "<td>\n";
    print $sock "<form action=\"/sort.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"reset\" value=\"R&#818;eset\" accesskey=\"r\">\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$pname$fname\">\n";
    print $sock "</form>\n";
    print $sock "</td></tr>\n";

    print $sock "<form action=\"/sort.htm\" method=\"get\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"ascend\" value=\"All A&#818;scend\" accesskey=\"a\">\n";
    print $sock "</td>\n";
    print $sock "<td>\n";
    print $sock "<input type=\"submit\" name=\"descend\" value=\"D&#818;escend\" accesskey=\"d\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"dedup\" value=\"De-du&#818;p\" accesskey=\"u\">\n";
    print $sock "</td>\n";
    print $sock "<td>\n";
    print $sock "&nbsp;\n";
    print $sock "</td></tr>\n";
    print $sock "<input type=\"hidden\" name=\"sorting\" value=\"sorting\">\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$pname$fname\">\n";
    print $sock "</form>\n";

    print $sock "</table><br>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
