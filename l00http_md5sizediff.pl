use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my %config = (proc => "l00http_md5sizediff_proc",
              desc => "l00http_md5sizediff_desc");
my ($treeto, $treefilecnt, $treedircnt, $nodirmask, $nofilemask);
$treeto = '';
$nodirmask = '';
$nofilemask = '';


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
    my ($jumper, %bymd5sum, %byname, $side, $sname, $files, $file, $cnt);
    my ($dummy, $size, $md5sum, $pfname, $pname, $fname);
    my (%cnt, $oname, %out, $idx, $md5sum1st);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
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
    print $sock "<p>\n";


    # copy paste target
    if (defined ($form->{'paste4'})) {
        $form->{'path'} = &l00httpd::l00getCB($ctrl);
    }
    if (defined ($form->{'paste2'})) {
        $form->{'path2'} = &l00httpd::l00getCB($ctrl);
    }

    # compare
    if ((defined ($form->{'compare'})) &&
        (defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0)) &&
        (defined ($form->{'path2'}) && 
        (length ($form->{'path2'}) > 0))) {

        $jumper = "    ".
             "<a href=\"#top\">top</a> ".
             "<a href=\"#dup_LEFT_\">(dupe L</a> ".
             "<a href=\"#dup_RIGHT\">R)</a> ".
             "<a href=\"#left_only\">(only L</a> ".
             "<a href=\"#right_only\">R)</a> ".
             "<a href=\"#chg_LEFT_\">(changed L</a> ".
             "<a href=\"#chg_RIGHT\">R)</a> ".
             "<a href=\"#end\">end</a> ".
             "\n";

        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} = '';
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<pre>\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper\n";
        print $sock "<pre>\n";
        print $sock "$jumper\n";

        # read in left and right files
        # ----------------------------------------------------------------
        undef %bymd5sum;
        undef %byname;
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "Read input files:\n\n";
        print $sock "Read input files:\n\n";
        foreach $side (($form->{'path'}, $form->{'path2'})) {
            if ($side eq $form->{'path'}) {
                $sname = 'LEFT_';
            } else {
                $sname = 'RIGHT';
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
                            $bymd5sum{$sname}{$md5sum}{$pfname} = $fname;
                            $byname{$sname}{$fname}{$md5sum} = $pfname;
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
        $cnt{'LEFT_'} = 0;
        $cnt{'RIGHT'} = 0;
        foreach $sname (('LEFT_', 'RIGHT')) {
            # for each side
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<a name=\"dup_$sname\"></a>";
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper";
            print $sock "<a name=\"dup_$sname\"></a>";
            print $sock "----------------------------------------------------------\n";
            print $sock "$jumper";
            if ($sname eq 'LEFT_') {
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "    $sname duplicated md5sum: $form->{'path'}\n\n";
                print $sock "    $sname duplicated md5sum: $form->{'path'}\n\n";
            } else {
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "    $sname duplicated md5sum: $form->{'path2'}\n\n";
                print $sock "    $sname duplicated md5sum: $form->{'path2'}\n\n";
            }

            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} = '';
            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "  $sname:\n";
            #print $sock "  $sname:\n";
            foreach $md5sum (sort keys %{$bymd5sum{$sname}}) {
                # for each md5sum
                if ($md5sum ne '00000000000000000000000000000000') {
                    # not a directory
                    @_ = (keys %{$bymd5sum{$sname}{$md5sum}});
                    # is there more than one file name recorded?
                    if ($#_ > 0) {
                        $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "md5sum $sname: $#_ md5sum $md5sum:\n   ".join("\n   ", @_)."\n";
                        #print $sock "md5sum $sname: $#_ md5sum $md5sum:\n   ".join("\n   ", @_)."\n";
                        $cnt{$sname}++;
                    }
                }
            }
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "%INCLUDE<l00://md5sizediff.$sname.self_dup.htm>%\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$sname self duplicated: $cnt{$sname} files\n";
            print $sock "$sname self duplicated: $cnt{$sname} files\n";
        }


        # Files unique to each side
        # ----------------------------------------------------------------
        foreach $sname (('LEFT_', 'RIGHT')) {
            # for each side
            if ($sname eq 'LEFT_') {
                $oname = 'RIGHT';
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<a name=\"left_only\"></a>";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "    Left only md5sum: $form->{'path'}\n\n";
                print $sock "<a name=\"left_only\"></a>";
                print $sock "----------------------------------------------------------\n";
                print $sock "$jumper";
                print $sock "    Left only by md5sum: $form->{'path'}\n\n";
            } else {
                $oname = 'LEFT_';
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<a name=\"right_only\"></a>";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "    Right only md5sum: $form->{'path2'}\n\n";
                print $sock "<a name=\"right_only\"></a>";
                print $sock "----------------------------------------------------------\n";
                print $sock "$jumper";
                print $sock "    Right only by md5sum: $form->{'path2'}\n\n";
            }
            undef %out;
            foreach $md5sum (sort keys %{$bymd5sum{$sname}}) {
                # for each md5sum here
                if (($md5sum ne '00000000000000000000000000000000') && !defined($bymd5sum{$oname}{$md5sum})) {
                    # not a directory and not there
                    @_ = (keys %{$bymd5sum{$sname}{$md5sum}});
                    $out{$_[0]} = $md5sum;
                }
            }
            $cnt = 0;
            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.only.htm"} = '';
            foreach $pfname (sort keys %out) {
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.only.htm"} .= sprintf ("   %03d: $pfname $out{$pfname}\n", $cnt);
                #printf $sock ("   %03d: $pfname $out{$pfname}\n", $cnt);
                $cnt++;
            }
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "%INCLUDE<l00://md5sizediff.$sname.only.htm>%\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "\n";
            #print $sock "\n";
            if ($sname eq 'LEFT_') {
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "Left only: $cnt files\n";
                print $sock "Left only: $cnt files\n";
            } else {
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "Right only: $cnt files\n";
                print $sock "Right only: $cnt files\n";
            }
        }

        # files changed from each side
        # ----------------------------------------------------------------
        foreach $sname (('LEFT_', 'RIGHT')) {
            # for each side
            if ($sname eq 'LEFT_') {
                $oname = 'RIGHT';
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<a name=\"chg_LEFT_\"></a>";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "    Same name different md5sum: $form->{'path'}\n\n";
                print $sock "<a name=\"chg_LEFT_\"></a>";
                print $sock "----------------------------------------------------------\n";
                print $sock "$jumper";
                print $sock "    Same name different md5sum: $form->{'path'}\n\n";
            } else {
                $oname = 'LEFT_';
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<a name=\"chg_RIGHT\"></a>";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "    Same name different md5sum: $form->{'path2'}\n\n";
                print $sock "<a name=\"chg_RIGHT\"></a>";
                print $sock "----------------------------------------------------------\n";
                print $sock "$jumper";
                print $sock "    Same name different md5sum: $form->{'path2'}\n\n";
            }
            undef %out;
            $cnt = 0;
            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.changed.htm"} = '';
            foreach $fname (sort keys %{$byname{$sname}}) {
                # for each file name
                $idx = 0;
                # our database
                # $byname{$sname}{$fname}{$md5sum} = $pfname;
                # $bymd5sum{$sname}{$md5sum}{$pfname} = $fname;
                foreach $md5sum (keys %{$byname{$sname}{$fname}}) {
                    # 
                    if ($idx == 0) {
                        $md5sum1st = $md5sum;
                    } else {
                        if ($idx == 1) {
                            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.changed.htm"} .= 
                                  sprintf ("   %03d: $sname: $byname{$sname}{$fname}{$md5sum1st} $md5sum1st\n", $cnt);
                            #printf $sock ("   %03d: $sname: $byname{$sname}{$fname}{$md5sum1st} $md5sum1st\n", $cnt);
                            $cnt++;
                        }
                        $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.changed.htm"} .= 
                              sprintf ("   %03d: $sname: $byname{$sname}{$fname}{$md5sum} $md5sum\n", $cnt);
                        #printf $sock ("   %03d: $sname: $byname{$sname}{$fname}{$md5sum} $md5sum\n", $cnt);
                        $cnt++;
                    }
                    $idx++;
                }
                $idx = 0;
                foreach $md5sum (keys %{$byname{$oname}{$fname}}) {
                    if ($idx == 0) {
                        if ($md5sum1st ne $md5sum) {
                            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.changed.htm"} .= 
                                  sprintf ("   %03d: $oname: $byname{$oname}{$fname}{$md5sum} $md5sum\n", $cnt);
                            #printf $sock ("   %03d: $oname: $byname{$oname}{$fname}{$md5sum} $md5sum\n", $cnt);
                            $cnt++;
                        }
                    } else {
                            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.changed.htm"} .= 
                              sprintf ("   %03d: $oname: $byname{$oname}{$fname}{$md5sum} $md5sum\n", $cnt);
                        #printf $sock ("   %03d: $oname: $byname{$oname}{$fname}{$md5sum} $md5sum\n", $cnt);
                        $cnt++;
                    }
                    $idx++;
                }
            }
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "%INCLUDE<l00://md5sizediff.$sname.changed.htm>%\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "Same name different md5sum $sname: $cnt files\n";
            print $sock "Same name different md5sum $sname: $cnt files\n";
        }


        # ----------------------------------------------------------------

        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<a name=\"end\"></a>";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "</pre>\n";
        print $sock "<a name=\"end\"></a>";
        print $sock "$jumper\n";
        print $sock "</pre>\n";

        print $sock "<a href=\"/ls.htm?path=l00://md5sizediff.all.htm\">l00://md5sizediff.all.htm</a><br>";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.LEFT_.self_dup.htm\">l00://md5sizediff.LEFT_.self_dup.htm</a><br>";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.RIGHT.self_dup.htm\">l00://md5sizediff.RIGHT.self_dup.htm</a><br>";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.LEFT_.only.htm\">l00://md5sizediff.LEFT_.only.htm</a><br>";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.RIGHT.only.htm\">l00://md5sizediff.RIGHT.only.htm</a><br>";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.LEFT_.changed.htm\">l00://md5sizediff.LEFT_.changed.htm</a><br>";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.RIGHT.changed.htm\">l00://md5sizediff.RIGHT.changed.htm</a><br>";
    }

    print $sock "<form action=\"/md5sizediff.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"compare\" value=\"Compare\"> Use || to combine inputs\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Left:<br><textarea name=\"path\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$form->{'path'}</textarea>\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Right:<br><textarea name=\"path2\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$form->{'path2'}</textarea>\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    if ($ctrl->{'os'} eq 'and') {
        print $sock "<tr><td>\n";
        print $sock "Paste CB to ";
        print $sock "<input type=\"submit\" name=\"paste4\" value=\"'Left:'\"> ";
        print $sock "<input type=\"submit\" name=\"paste2\" value=\"'Right:'\">\n";
        print $sock "</td></tr>\n";
    }
    print $sock "</table><br>\n";
    print $sock "</form>\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
