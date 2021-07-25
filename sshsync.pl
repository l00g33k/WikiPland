#while true; do echo -e "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ; perl sshsync.pl -dbg=5 --help | less -N ; echo ENTER ; read ; done
#while true; do echo -e "\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n" ; perl sshsync.pl -dbg=5 < sshsync.in ; echo ENTER ; read ; done


$dbg = 0;

$help = <<HELP;


Synopsis:

A no install method for bidirectional file sync using ssh and md5sum.
The md5sum of file1 and file2 are monitored.  If either sum has changed, 
it is fetched to replace the other file, in either direction.

On start up, if one file is missing, the other file is fetched so 
both side are the same.  And if both files already exist, and the 
sums are different, file1 is fetched to replace file2.

After start up the sums of all files are monitored and sync to the 
counterpart whenever the sum has changed.


How To Run:

Create a configuration file and make sure the CMDs work 
correctly and the paths are correct.

#Test configuration, set bash variables:
#CMD1='ssh t@localhost -p 30339'
#FILE1='/sdcard/z/zz'
#CMD2='bash -c'
#FILE2='zz'
#Make sure these bash expansions work:
#\$CMD1 "md5sum \$FILE1"
#\$CMD2 "md5sum \$FILE2"
#\$CMD1 "cat \$FILE1" | \$CMD2 "cat > \$FILE2"
#\$CMD2 "cat \$FILE2" | \$CMD1 "cat > \$FILE1"
#CMD1 ` FILE1 ` CMD2 ` FILE2
#` is delimiter. spaces before and after ` are trimmed
#leading <space> or # is comment line
ssh t@localhost -p 30339    `   /sdcard/z/zz    `   bash -c     `   zz

#Start it
perl sshsync.pl < sshsync.in


How It Works:

A configuration file is piped into the script to describe the files 
to be sync'ed using the following format.  There are 4 parts per line to 
describe a pair of files.  The bash expansions show how the md5sum 
are computed and how the files are copied.

These 3 CMD patterns work:

ssh:                ssh ID@HOST -p PORT
ssh with password:  sshpass -p PASSWORD ssh ID@HOST -p PORT
local:              bash -c


Theory Of Script Operation:



HELP

$filespecfname = '';

#TOO0: Scan CMD line options
while ($_ = shift) {
    if (/-dbg=(\d)/) {
        $dbg = $1;
        print "OPTION: -dbg=$dbg\n";
    } elsif (/--help/) {
        print $help;
        exit 0;
    } elsif (-f $_) {
        # it's a file, assume filespec
        $filespecfname = $_;
        print "File spec: >$filespecfname<\n";
    } else {
        print "IGNORE UNKNOWN OPTION: >$_<\n";
    }
}


@filespecin = ();
$filespecinsig = '';
if (open(IN, "<$filespecfname")) {
    print "Filespec from file >$filespecfname<\n";
    while (<IN>) {
        push(@filespecin, $_);
    }
    close(IN);

    $cmd = "bash -c 'ls --full-time $filespecfname | tr \"\\n\" \" \" ; md5sum $filespecfname | tr \"\\n\" \" \"'";
    $filespecinsig = `$cmd`;
    print "filespec sig: $filespecinsig\n";
} else {
    print "Filespec from file STDIN\n";
    while (<>) {
        push(@filespecin, $_);
    }
}


sub scanSpecFileSig {
    print "Reading file specifications (make sure bash command FILE1/FILE2 can execute):\n";

    @filespec = ();
    $lnno = 0;
    $fcnt = 0;
    foreach $_ (@filespecin) {
        $lnno++;
        if (/^[ #]/) {
            # ' ' or '#' is comment
            next;
        }
        s/[\n\r]//g;
        print "$lnno: >$_<\n", if ($dbg >= 5);
        # delimited by `, trim leading/trailing spaces
        if (($cmd1, $file1, $cmd2, $file2) = /^([^ #].+?) *` *(.+?) *` *(.+?) *` *(.+?) *$/) {
            print "Found: ($cmd1, $file1, $cmd2, $file2)\n", if ($dbg >= 3);
            push(@filespec, "$cmd1`$file1`$cmd2`$file2");
        }
    }
    print "\n", if ($dbg >= 5);


    print "File specifications and md5sum:\n";
    for ($cnt = 0; $cnt <= $#filespec; $cnt++) {
        ($CMD1, $FILE1, $CMD2, $FILE2) = split ('`', $filespec[$cnt]);
        print "$cnt: $CMD1 ` $FILE1 ` $CMD2 ` $FILE2\n";

        $cmd = "$CMD1 'ls --full-time $FILE1 | tr \"\\n\" \" \" ; md5sum $FILE1 | tr \"\\n\" \" \"'";
        # ffe51486284a93a4c6769e8b95056c9a
        $_ = `$cmd`;
        if (/([0-9a-f]{32,32})/) {
            # looks like md5sum
            print "   FILE1: $cmd\n    => $_\n";
            $file1sum{$FILE1} = $1;
        } else {
            print "   FILE1: $cmd\n    => FILE MISSING\n";
            $file1sum{$FILE1} = '';
        }

        $cmd = "$CMD2 'ls --full-time $FILE2 | tr \"\\n\" \" \" ; md5sum $FILE2 | tr \"\\n\" \" \"'";
        # ffe51486284a93a4c6769e8b95056c9a
        $_ = `$cmd`;
        if (/([0-9a-f]{32,32})/) {
            # looks like md5sum
            print "   FILE2: $cmd\n    => $_\n";
            $file2sum{$FILE2} = $1;
        } else {
            print "   FILE2: $cmd\n    => FILE MISSING\n";
            $file2sum{$FILE2} = '';
        }

        # if both missing, ignore
        if (($file1sum{$FILE1} eq '') && ($file2sum{$FILE2} eq '')) {
            print "   BOTH MISSING, IGNORE\n";
        } elsif (($file1sum{$FILE1} ne '') && ($file2sum{$FILE2} ne '')) {
            print "   BOTH EXIST, COPY FROM FILE1 $FILE1 to FILE2 $FILE2\n";
            $cmd = "$CMD1 'cat $FILE1' | $CMD2 'cat > $FILE2'";
            $_ = `$cmd`;
        } elsif ($file1sum{$FILE1} ne '') {
            print "   $FILE1 EXIST, COPY to FILE2 $FILE2\n";
            $cmd = "$CMD1 'cat $FILE1' | $CMD2 'cat > $FILE2'";
            $_ = `$cmd`;
        } elsif ($file2sum{$FILE2} ne '') {
            print "   $FILE2 EXIST, COPY to FILE1 $FILE1\n";
            $cmd = "$CMD2 'cat $FILE2' | $CMD1 'cat > $FILE1'";
            $_ = `$cmd`;
        }
    }
}


scanSpecFileSig();

$loop = 0;
while (1) {
    $loop++;
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
    $t = sprintf ("%05d: %4d%02d%02d %02d%02d%02d", $loop, $year + 1900, $mon+1, $mday, $hour, $min, $sec);
    if ($dbg >= 1) {
        print "$t\n";
    } else {
        printf STDERR "$t   \r";
    }

    for ($cnt = 0; $cnt <= $#filespec; $cnt++) {
        ($CMD1, $FILE1, $CMD2, $FILE2) = split ('`', $filespec[$cnt]);
        if ($dbg >= 1) {
            print "  $cnt: $CMD1 ` $FILE1 ` $CMD2 ` $FILE2\n";
        } else {
            print "$t: $cnt: $CMD1 ` $FILE1 ` $CMD2 ` $FILE2   \r";
        }

        $cmd = "$CMD1 'ls --full-time $FILE1 | tr \"\\n\" \" \" ; md5sum $FILE1 | tr \"\\n\" \" \"'";
        # ffe51486284a93a4c6769e8b95056c9a
        $_ = `$cmd`;
        print "   FILE1: $cmd\n    => $_\n", if ($dbg >= 5);
        if (/([0-9a-f]{32,32})/) {
            # looks like md5sum
            print "    md5sum: old: $file1sum{$FILE1} cmp new: $1\n", if ($dbg >= 5);
            if ($file1sum{$FILE1} ne $1) {
                # save it
                $file1sum{$FILE1} = $1;
                print "$t\n", if ($dbg < 1);
                print "    Push to FILE2 as FILE1 changed: $_\n";

                $cmd = "$CMD1 'cat $FILE1' | $CMD2 'cat > $FILE2'";
                $_ = `$cmd`;
                print "     => FILE2: $cmd\n", if ($dbg >= 3);

                $cmd = "$CMD2 'ls --full-time $FILE2 | tr \"\\n\" \" \" ; md5sum $FILE2 | tr \"\\n\" \" \"'";
                $_ = `$cmd`;
                print "      new sum: $cmd\n       => $_\n", if ($dbg >= 5);
                if (/([0-9a-f]{32,32})/) {
                    # looks like md5sum
                    $file2sum{$FILE2} = $1;
                }
            }
        }

        $cmd = "$CMD2 'ls --full-time $FILE2 | tr \"\\n\" \" \" ; md5sum $FILE2 | tr \"\\n\" \" \"'";
        # ffe51486284a93a4c6769e8b95056c9a
        $_ = `$cmd`;
        print "   FILE2: $cmd\n    => $_\n", if ($dbg >= 5);
        if (/([0-9a-f]{32,32})/) {
            # looks like md5sum
            print "    md5sum: old: $file2sum{$FILE2} cmp new: $1\n", if ($dbg >= 5);
            if ($file2sum{$FILE2} ne $1) {
                # save it
                $file2sum{$FILE2} = $1;
                print "$t\n", if ($dbg < 1);
                print "    Push to FILE1 as FILE2 changed: $_\n";

                $cmd = "$CMD2 'cat $FILE2' | $CMD1 'cat > $FILE1'";
                $_ = `$cmd`;
                print "     => FILE1: $cmd\n", if ($dbg >= 3);

                $cmd = "$CMD1 'ls --full-time $FILE1 | tr \"\\n\" \" \" ; md5sum $FILE1 | tr \"\\n\" \" \"'";
                $_ = `$cmd`;
                print "      new sum: $cmd\n       => $_\n", if ($dbg >= 5);
                if (/([0-9a-f]{32,32})/) {
                    # looks like md5sum
                    $file1sum{$FILE1} = $1;
                }
            }
        }
    }

    if (-f $filespecfname) {
        $cmd = "bash -c 'ls --full-time $filespecfname | tr \"\\n\" \" \" ; md5sum $filespecfname | tr \"\\n\" \" \"'";
        $_ = `$cmd`;
        if ($filespecinsig ne $_) {
            $filespecinsig = $_;
            print "filespec sig changed, new: $filespecinsig\n";


            @filespecin = ();
            if (open(IN, "<$filespecfname")) {
                print "Filespec from file >$filespecfname<\n";
                while (<IN>) {
                    push(@filespecin, $_);
                }
                close(IN);

                $cmd = "bash -c 'ls --full-time $filespecfname | tr \"\\n\" \" \" ; md5sum $filespecfname | tr \"\\n\" \" \"'";
                $filespecinsig = `$cmd`;
                print "filespec sig: $filespecinsig\n";
            }

            scanSpecFileSig();
        }
    }

    sleep(1);
}
