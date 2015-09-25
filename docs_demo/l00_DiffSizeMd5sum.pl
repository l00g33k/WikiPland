if (!defined($ctrl->{'FORM'}->{'arg1'})) {
    print $sock "This do script compares two sets of size/md5sum files to identify duplicated/renamed/modified files<p>\n";
    print $sock "Enter 'Arg1'.<p>\n";
} else {
    print $sock "<pre>\n";
    print $sock "Arg1: $ctrl->{'FORM'}->{'arg1'}\n";
    ($left, $right) = split("::", $ctrl->{'FORM'}->{'arg1'});

    $jumper = "  ".
         "<a href=\"#top\">top</a> ".
         "<a href=\"#dup\">dup</a> ".
         "<a href=\"#left\">left</a> ".
         "<a href=\"#right\">right</a> ".
         "<a href=\"#end\">end</a> ".
         "\n";

    print $sock "$jumper\n\n";

    # read in left files undef %bysize;
    undef %bymd5sum;
    undef %byname;
    foreach $side (($left, $right)) {
        if ($side eq $left) {
            $sname = 'LEFT ';
        } else {
            $sname = 'RIGHT';
        }
        $files = 0;
        print $sock "$sname side: $side\n";
        foreach $file (split('\|\|', $side)) {
            $cnt = 0;
            if (open(IN, "<$file")) {
                while (<IN>) {
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
                close (IN);
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
            if ($md5sum != 0) {
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
            print $sock "Left only by md5sum: $left\n";
        } else {
            $oname = 'LEFT ';
            print $sock "<a name=\"right\"></a>";
            print $sock "----------------------------------------------------------\n";
            print $sock "Right only by md5sum: $right\n";
        }
        print $sock "$jumper\n";
        undef %out;
        foreach $md5sum (sort keys %{$bymd5sum{$sname}}) {
            if (($md5sum != 0) && !defined($bymd5sum{$oname}{$md5sum})) {
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
            print $sock "Same name different md5sum: $left\n";
        } else {
            $oname = 'LEFT ';
            print $sock "<a name=\"right\"></a>";
            print $sock "----------------------------------------------------------\n";
            print $sock "Same name different md5sum: $right\n";
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
                    if ($md5sum1st != $md5sum) {
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



    print $sock "$jumper\n";

    print $sock "</pre>\n";
}

