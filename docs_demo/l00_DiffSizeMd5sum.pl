if (!defined($ctrl->{'FORM'}->{'arg1'})) {
    print $sock "This do script compares two sets of size/md5sum files to identify duplicated/renamed/modified files<p>\n";
    print $sock "Enter 'Arg1'.<p>\n";
} else {
    print $sock "<pre>\n";
    print $sock "Arg1: $ctrl->{'FORM'}->{'arg1'}\n";
    ($left, $right) = split("::", $ctrl->{'FORM'}->{'arg1'});

    # read in left files undef %bysize;
    undef %bymd5sum;
    undef %bypath;
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
#print $sock "$size $md5sum $pname $fname\n";
                        $bymd5sum{$sname}{$md5sum}{$fname} = $pfname;
                        $bypath{$sname}{$pname} = $md5sum;
                        $byname{$sname}{$fname}{$pfname} = $md5sum;
                        $cnt++;
                    }
                }
                close (IN);
            }
            print $sock "Read $sname $cnt: $files:$file\n";
            $files++;
        }
    }

    # rename
    foreach $sname (('LEFT ', 'RIGHT')) {
        foreach $md5sum (sort keys %{$bymd5sum{$sname}}) {
            @_ = (keys %{$bymd5sum{$sname}{$md5sum}});
            if ($#_ > 0) {
                print $sock "md5sum rename $sname: $#_ $md5sum:\n   ".join("\n   ", @_)."\n";
            }
        }

    }

    print $sock "</pre>\n";

}

