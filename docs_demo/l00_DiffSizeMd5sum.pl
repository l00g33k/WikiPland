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
                        $bymd5sum{$sname}{$md5sum}{$pfname} = $fname;
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
    print $sock "\n";

    print $sock "<a name=\"dup\"></a>Duplicates:\n";
    print $sock "$jumper\n";
    foreach $sname (('LEFT ', 'RIGHT')) {
        print $sock "  $sname:\n";
        foreach $md5sum (sort keys %{$bymd5sum{$sname}}) {
            if ($md5sum != 0) {
                @_ = (keys %{$bymd5sum{$sname}{$md5sum}});
                if ($#_ > 0) {
                    print $sock "md5sum $sname: $#_ md5sum $md5sum:\n   ".join("\n   ", @_)."\n";
                }
            }
        }
    }
    print $sock "\n";

    print $sock "<a name=\"left\"></a>Left only: $left\n";
    print $sock "$jumper\n";
    foreach $md5sum (sort keys %{$bymd5sum{'LEFT '}}) {
        if (($md5sum != 0) && !defined($bymd5sum{'RIGHT'}{$md5sum})) {
            @_ = (keys %{$bymd5sum{'LEFT '}{$md5sum}});
            print $sock "md5sum $sname: $#_ md5sum $md5sum:\n   ".join("\n   ", @_)."\n";
        }
    }
    print $sock "\n";

    print $sock "<a name=\"right\"></a>Right only: $right\n";
    print $sock "$jumper\n";
    foreach $md5sum (sort keys %{$bymd5sum{'RIGHT'}}) {
        if (($md5sum != 0) && !defined($bymd5sum{'LEFT '}{$md5sum})) {
            @_ = (keys %{$bymd5sum{'RIGHT'}{$md5sum}});
            print $sock "md5sum $sname: $#_ md5sum $md5sum:\n   ".join("\n   ", @_)."\n";
        }
    }
    print $sock "\n";


    print $sock "$jumper\n";

    print $sock "</pre>\n";
}

