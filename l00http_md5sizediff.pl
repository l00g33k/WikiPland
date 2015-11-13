use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my %config = (proc => "l00http_md5sizediff_proc",
              desc => "l00http_md5sizediff_desc");
my ($thispath, $thatpath);
$thispath = '';
$thatpath = '';

sub l00http_md5sizediff_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "md5sizediff: diff directory trees using externally computed md5sum";
}

sub l00http_md5sizediff_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($jumper, %bymd5sum, %byname, %sizebymd5sum, $side, $sname, $files, $file, $cnt);
    my ($dummy, $size, $md5sum, $pfname, $pname, $fname);
    my (%cnt, $oname, %out, $idx, $md5sum1st);
    my (@lmd5sum, @rmd5sum, $common);

    if (defined ($form->{'compare'})) {
        # compare defined, i.e. clicked. Get from form
        if (defined ($form->{'path'})) {
            $thispath = $form->{'path'};
        }
        if (defined ($form->{'path2'})) {
            $thatpath = $form->{'path2'};
        }
    } else {
        # compare not defined, i.e. not click, push 
        $thatpath = $thispath;
        if (defined ($form->{'path'})) {
            $thispath = $form->{'path'};
        }
    }



    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    if ((defined ($thispath) && 
        (length ($thispath) > 0))) {
        $thispath =~ s/\r//g;
        $thispath =~ s/\n//g;
        $_ = $thispath;
        # keep path only
        s/\/[^\/]+$/\//;
        print $sock " Path: <a href=\"/ls.htm?path=$_\">$_</a>";
        $_ = $thispath;
        # keep name only
        s/^.+\/([^\/]+)$/$1/;
        print $sock "<a href=\"/ls.htm?path=$thispath\">$_</a>\n";
    }
    print $sock "<p>\n";


    # copy paste target
    if (defined ($form->{'paste4'})) {
        $thispath = &l00httpd::l00getCB($ctrl);
    }
    if (defined ($form->{'paste2'})) {
        $thatpath = &l00httpd::l00getCB($ctrl);
    }

    # compare
    if ((defined ($form->{'compare'})) &&
        (defined ($thispath) && 
        (length ($thispath) > 0)) &&
        (defined ($thatpath) && 
        (length ($thatpath) > 0))) {

        $jumper = "    ".
             "<a href=\"#top\">top</a> ".
             "<a href=\"#dup_THIS\">(dupe this</a> ".
             "<a href=\"#dup_THAT\">that)</a> ".
             "<a href=\"#this_only\">(only this</a> ".
             "<a href=\"#that_only\">that)</a> ".
             "<a href=\"#changed\">changed</a> ".
             "<a href=\"#same\">same</a> ".
             "<a href=\"#end\">end</a> ".
             "\n";

        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} = '';
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<pre>\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper\n";
        print $sock "<pre>\n";
        print $sock "$jumper\n";

        # read in this and that files
        # ----------------------------------------------------------------
        undef %bymd5sum;
        undef %byname;
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "Read input files:\n\n";
        print $sock "Read input files:\n\n";
        foreach $side (($thispath, $thatpath)) {
            if ($side eq $thispath) {
                $sname = 'THIS';
            } else {
                $sname = 'THAT';
            }
            $files = 0;
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$sname side: $side\n";
            print $sock "$sname side: $side\n";
            # split combined input files for each side
            foreach $file (split('\|\|', $side)) {
                $cnt = 0;
                if (&l00httpd::l00freadOpen($ctrl, $file)) {
                    while ($_ = &l00httpd::l00freadLine($ctrl)) {
                        s/ <dir>//g;
                        if (/^\|\|/) {
                            ($dummy, $size, $md5sum, $pfname) = split('\|\|', $_);
                            $size   =~ s/^ *//;
                            $md5sum =~ s/^ *//;
                            $pfname =~ s/^ *//;
                            $size   =~ s/ *$//;
                            $md5sum =~ s/ *$//;
                            $pfname =~ s/ *$//;
                            ($pname, $fname) = $pfname =~ /^(.+[\\\/])([^\\\/]+)$/;
                            $fname = lc($fname);
                            $bymd5sum{$sname}{$md5sum}{$pfname} = $fname;
                            $byname{$sname}{$fname}{$md5sum} = $pfname;
                            $sizebymd5sum{$md5sum} = $size;
                            $cnt++;
                        }
                    }
                }
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "Read $sname $cnt: $files:$file\n";
                print $sock "Read $sname $cnt: $files:$file\n";
                $files++;
            }
        }

        # files duplicated within each side
        # ----------------------------------------------------------------
        $cnt{'THIS'} = 0;
        $cnt{'THAT'} = 0;
        foreach $sname (('THIS', 'THAT')) {
            # for each side
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<a name=\"dup_$sname\"></a>";
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper";
            print $sock "<a name=\"dup_$sname\"></a>";
            print $sock "----------------------------------------------------------\n";
            print $sock "$jumper";
            if ($sname eq 'THIS') {
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "    $sname duplicated md5sum: $thispath\n\n";
                print $sock "    $sname duplicated md5sum: $thispath\n\n";
            } else {
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "    $sname duplicated md5sum: $thatpath\n\n";
                print $sock "    $sname duplicated md5sum: $thatpath\n\n";
            }

            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} = '';
            foreach $md5sum (sort keys %{$bymd5sum{$sname}}) {
                # for each md5sum
                if ($md5sum ne '00000000000000000000000000000000') {
                    # not a directory
                    @_ = (keys %{$bymd5sum{$sname}{$md5sum}});
                    # is there more than one file name recorded?
                    if ($#_ > 0) {
                        $_ = $#_ + 1;
                        $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= 
                            sprintf ("   %03d: dup: $_ files $sizebymd5sum{$md5sum} $md5sum --- $_[0]\n        ", $cnt{$sname}).
                            join("\n        ", @_)."\n";
                        #print $sock "md5sum $sname: $#_ md5sum $md5sum:\n   ".join("\n   ", @_)."\n";
                        $cnt{$sname}++;
                    }
                }
            }
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$sname self duplicated: $cnt{$sname} files\n\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "%INCLUDE<l00://md5sizediff.$sname.self_dup.htm>%\n";
            print $sock "$sname self duplicated: $cnt{$sname} files\n";
        }


        # Files unique to each side
        # ----------------------------------------------------------------
        foreach $sname (('THIS', 'THAT')) {
            # for each side
            if ($sname eq 'THIS') {
                $oname = 'THAT';
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<a name=\"this_only\"></a>";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "    This only md5sum: $thispath\n\n";
                print $sock "<a name=\"this_only\"></a>";
                print $sock "----------------------------------------------------------\n";
                print $sock "$jumper";
                print $sock "    This only by md5sum: $thispath\n\n";
            } else {
                $oname = 'THIS';
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<a name=\"that_only\"></a>";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "    That only md5sum: $thatpath\n\n";
                print $sock "<a name=\"that_only\"></a>";
                print $sock "----------------------------------------------------------\n";
                print $sock "$jumper";
                print $sock "    That only by md5sum: $thatpath\n\n";
            }
            undef %out;
            $common = 0;
            foreach $md5sum (sort keys %{$bymd5sum{$sname}}) {
                # for each md5sum here
                if ($md5sum ne '00000000000000000000000000000000') {
                    $common++;
                }
                if (($md5sum ne '00000000000000000000000000000000') && !defined($bymd5sum{$oname}{$md5sum})) {
                    # not a directory and not there
                    @_ = (keys %{$bymd5sum{$sname}{$md5sum}});
                    $out{$_[0]} = $md5sum;
                }
            }
            $cnt = 0;
            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.only.htm"} = '';
            foreach $pfname (sort keys %out) {
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.only.htm"} .= sprintf ("   %03d: $pfname $sizebymd5sum{$out{$pfname}} $out{$pfname}\n", $cnt);
                #printf $sock ("   %03d: $pfname $out{$pfname}\n", $cnt);
                $cnt++;
            }
            #print $sock "\n";
            if ($sname eq 'THIS') {
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "This only: $cnt files (out of $common md5sum)\n\n";
                print $sock "This only: $cnt files (out of $common same md5sum)\n";
            } else {
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "That only: $cnt files (out of $common md5sum)\n\n";
                print $sock "That only: $cnt files (out of $common same md5sum)\n";
            }
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "%INCLUDE<l00://md5sizediff.$sname.only.htm>%\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "\n";
        }

        # files with different md5sum on both side
        # ----------------------------------------------------------------
        $sname = 'THIS';
        $oname = 'THAT';
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<a name=\"changed\"></a>";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "    Same name different md5sum\n\n";
        print $sock "<a name=\"changed\"></a>";
        print $sock "----------------------------------------------------------\n";
        print $sock "$jumper";
        print $sock "    Same name different md5sum\n\n";

        undef %out;
        $cnt = 0;
        $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} = '';
        $common = 0;
        foreach $fname (sort keys %{$byname{$sname}}) {
            # for each file name in this
            if (defined(${$byname{$oname}}{$fname})) {
                $common++;
                # that also exist in that
                # our databases
                # $byname{$sname}{$fname}{$md5sum} = $pfname;
                # $bymd5sum{$sname}{$md5sum}{$pfname} = $fname;
                # list a md5sum in this
                @lmd5sum = keys %{$byname{$sname}{$fname}};
                # list a md5sum in that
                @rmd5sum = keys %{$byname{$oname}{$fname}};
                if (($#lmd5sum > 0) ||             # more than one md5sum in this, or
                    ($#rmd5sum > 0) ||             # more than one md5sum in that, or
                    ($lmd5sum[0] ne $rmd5sum[0])) {# they are not equal
                    $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= sprintf ("   %03d: diff: $fname --- ", $cnt);
                    for ($idx = 0; $idx <= $#lmd5sum; $idx++) {
                        ($pfname) = keys %{$bymd5sum{$sname}{$lmd5sum[$idx]}};
                        if ($idx == 0) {
                            $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= "$pfname\n";
                        }
                        $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= "        THIS $idx: $sizebymd5sum{$lmd5sum[$idx]} $lmd5sum[$idx] $pfname\n";
                    }
                    for ($idx = 0; $idx <= $#rmd5sum; $idx++) {
                        ($pfname) = keys %{$bymd5sum{$oname}{$rmd5sum[$idx]}};
                        $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= "        THAT $idx: $sizebymd5sum{$rmd5sum[$idx]} $rmd5sum[$idx] $pfname\n";
                    }
                    $cnt++;
                }
            }
        }
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "Same name different md5sum: $cnt files (out of $common same name)\n\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "%INCLUDE<l00://md5sizediff.diff.htm>%\n";
        print $sock "Same name different md5sum: $cnt files (out of $common same name)\n";

        # files with same md5sum on both side
        # ----------------------------------------------------------------
        $sname = 'THIS';
        $oname = 'THAT';
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<a name=\"same\"></a>";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "    Same md5sum\n\n";
        print $sock "<a name=\"same\"></a>";
        print $sock "----------------------------------------------------------\n";
        print $sock "$jumper";
        print $sock "    Same md5sum\n\n";

        undef %out;
        $cnt = 0;
        $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} = '';
        $common = 0;
        foreach $md5sum (sort keys %{$bymd5sum{$sname}}) {
            if (($md5sum ne '00000000000000000000000000000000') && defined($bymd5sum{$oname}{$md5sum})) {
                # not a directory and is there
                @_ = (keys %{$bymd5sum{$sname}{$md5sum}});
                $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= 
                sprintf ("   %03d: same: $_ files $sizebymd5sum{$md5sum} $md5sum --- $_[0]\n", $cnt).
                "        $_[0]\n";
                @_ = (keys %{$bymd5sum{$oname}{$md5sum}});
                $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= 
                "        $_[0]\n";
                $cnt++;
            }
        }
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "Same md5sum: $cnt files\n\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "%INCLUDE<l00://md5sizediff.same.htm>%\n";
        print $sock "Same md5sum: $cnt files\n";


        # ----------------------------------------------------------------

        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<a name=\"end\"></a>";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "</pre>\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "Links to results in RAM<br>\n";
        print $sock "<a name=\"end\"></a>";
        print $sock "----------------------------------------------------------\n";
        print $sock "$jumper";
        print $sock "----------------------------------------------------------\n";
        print $sock "</pre>\n";
        print $sock "Links to results in RAM<br>\n";

        print $sock "<a href=\"/ls.htm?path=l00://md5sizediff.all.htm\">l00://md5sizediff.all.htm</a> - ", length($ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"}), " bytes<br>";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.THIS.self_dup.htm\">l00://md5sizediff.THIS.self_dup.htm</a> - ", length($ctrl->{'l00file'}->{"l00://md5sizediff.THIS.self_dup.htm"}), " bytes<br>";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.THAT.self_dup.htm\">l00://md5sizediff.THAT.self_dup.htm</a> - ", length($ctrl->{'l00file'}->{"l00://md5sizediff.THAT.self_dup.htm"}), " bytes<br>";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.THIS.only.htm\">l00://md5sizediff.THIS.only.htm</a> - ", length($ctrl->{'l00file'}->{"l00://md5sizediff.THIS.only.htm"}), " bytes<br>";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.THAT.only.htm\">l00://md5sizediff.THAT.only.htm</a> - ", length($ctrl->{'l00file'}->{"l00://md5sizediff.THAT.only.htm"}), " bytes<br>";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.diff.htm\">l00://md5sizediff.diff.htm</a> - ", length($ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"}), " bytes<br>";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.same.htm\">l00://md5sizediff.same.htm</a> - ", length($ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"}), " bytes<br>";
    }

    print $sock "<form action=\"/md5sizediff.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"compare\" value=\"Compare\"> Use || to combine inputs\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "This:<br><textarea name=\"path\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$thispath</textarea>\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "That:<br><textarea name=\"path2\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$thatpath</textarea>\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    if ($ctrl->{'os'} eq 'and') {
        print $sock "<tr><td>\n";
        print $sock "Paste CB to ";
        print $sock "<input type=\"submit\" name=\"paste4\" value=\"'This:'\"> ";
        print $sock "<input type=\"submit\" name=\"paste2\" value=\"'That:'\">\n";
        print $sock "</td></tr>\n";
    }
    print $sock "</table><br>\n";
    print $sock "</form>\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
