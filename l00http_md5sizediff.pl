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
    if ((defined ($form->{'compare'})) &&
        (defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0)) &&
        (defined ($form->{'path2'}) && 
        (length ($form->{'path2'}) > 0))) {

        $jumper = "  ".
             "<a href=\"#top\">top</a> ".
             "<a href=\"#dup\">dup</a> ".
             "<a href=\"#left\">left</a> ".
             "<a href=\"#right\">right</a> ".
             "<a href=\"#end\">end</a> ".
             "\n";


        print $sock "<pre>\n";
        print $sock "$jumper\n\n";

        # read in left files undef %bysize;
        undef %bymd5sum;
        undef %byname;
        foreach $side (($form->{'path'}, $form->{'path2'})) {
            if ($side eq $form->{'path'}) {
                $sname = 'LEFT ';
            } else {
                $sname = 'RIGHT';
            }
            $files = 0;
            print $sock "$sname side: $side\n";
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
                print $sock "Read $sname $cnt: $files:$file\n";
                $files++;
            }
        }
        print $sock "\n"; 

        print $sock "<a name=\"dup\"></a>";
        print $sock "----------------------------------------------------------\n";
        print $sock "Duplicates by md5sum within each source:\n";
        print $sock "$jumper\n";
        $cnt{'LEFT '} = 0;
        $cnt{'RIGHT'} = 0;
        foreach $sname (('LEFT ', 'RIGHT')) {
            print $sock "  $sname:\n";
            foreach $md5sum (sort keys %{$bymd5sum{$sname}}) {
                if ($md5sum ne '00000000000000000000000000000000') {
                    @_ = (keys %{$bymd5sum{$sname}{$md5sum}});
                    if ($#_ > 0) {
                        print $sock "md5sum $sname: $#_ md5sum $md5sum:\n   ".join("\n   ", @_)."\n";
                        $cnt{$sname}++;
                    }
                }
            }
        }
        print $sock "\n";



        foreach $sname (('LEFT ', 'RIGHT')) {
            if ($sname eq 'LEFT ') {
                $oname = 'RIGHT';
                print $sock "<a name=\"left\"></a>";
                print $sock "----------------------------------------------------------\n";
                print $sock "Left only by md5sum: $form->{'path'}\n";
            } else {
                $oname = 'LEFT ';
                print $sock "<a name=\"right\"></a>";
                print $sock "----------------------------------------------------------\n";
                print $sock "Right only by md5sum: $form->{'path2'}\n";
            }
            print $sock "$jumper\n";
            undef %out;
            foreach $md5sum (sort keys %{$bymd5sum{$sname}}) {
                if (($md5sum ne '00000000000000000000000000000000') && !defined($bymd5sum{$oname}{$md5sum})) {
                    @_ = (keys %{$bymd5sum{$sname}{$md5sum}});
                    $out{$_[0]} = $md5sum;
                }
            }
            $cnt = 0;
            foreach $pfname (sort keys %out) {
                printf $sock ("   %03d: $pfname $out{$pfname}\n", $cnt);
                $cnt++;
            }
            print $sock "\n";
            if ($sname eq 'LEFT ') {
                print $sock "Left only: $cnt files\n";
            } else {
                print $sock "Right only: $cnt files\n";
            }
        }


        foreach $sname (('LEFT ', 'RIGHT')) {
            if ($sname eq 'LEFT ') {
                $oname = 'RIGHT';
                print $sock "<a name=\"left\"></a>";
                print $sock "----------------------------------------------------------\n";
                print $sock "Same name different md5sum: $form->{'path'}\n";
            } else {
                $oname = 'LEFT ';
                print $sock "<a name=\"right\"></a>";
                print $sock "----------------------------------------------------------\n";
                print $sock "Same name different md5sum: $form->{'path2'}\n";
            }
            print $sock "$jumper\n";
            undef %out;
            $cnt = 0;
            foreach $fname (sort keys %{$byname{$sname}}) {
                $idx = 0;
                foreach $md5sum (keys %{$byname{$sname}{$fname}}) {
                    if ($idx == 0) {
                        $md5sum1st = $md5sum;
                    } else {
                        if ($idx == 1) {
                            printf $sock ("   %03d: $sname: $byname{$sname}{$fname}{$md5sum1st} $md5sum1st\n", $cnt);
                            $cnt++;
                        }
                        printf $sock ("   %03d: $sname: $byname{$sname}{$fname}{$md5sum} $md5sum\n", $cnt);
                        $cnt++;
                    }
                    $idx++;
                }
                $idx = 0;
                foreach $md5sum (keys %{$byname{$oname}{$fname}}) {
                    if ($idx == 0) {
                        if ($md5sum1st ne $md5sum) {
                            printf $sock ("   %03d: $oname: $byname{$oname}{$fname}{$md5sum} $md5sum\n", $cnt);
                            $cnt++;
                        }
                    } else {
                        printf $sock ("   %03d: $oname: $byname{$oname}{$fname}{$md5sum} $md5sum\n", $cnt);
                        $cnt++;
                    }
                    $idx++;
                }
            }
            print $sock "\n";
            print $sock "Same name different md5sum $sname: $cnt files\n";
        }

        print $sock "<a name=\"end\"></a>";
        print $sock "$jumper\n";

        print $sock "</pre>\n";
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
