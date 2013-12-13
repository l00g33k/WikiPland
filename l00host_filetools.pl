use warnings;
use strict;

my ($arg, $getphonepath, $nofiles, $nodirs);
$nofiles = 0;
$nodirs = 0;

$getphonepath = '';
while ($arg = shift) {
    if ($arg =~ /getphonepath=(.+)/) {
        $getphonepath = $1;
        print "getphonepath=$getphonepath\n";
    } elsif ($arg =~ /help/) {
        print "getphonepath=#\n";
        exit;
    }
}


sub procdir {
    my ($dname) = @_;
    my ($buf, $ret, $rst, $line, $dname2, $fname);

    print "Scanning $dname\n";
    $nodirs++;

    # get directory listing
    $ret = `"adb shell ls -l $getphonepath$dname"`;
    foreach $line (split ("\n", $ret)) {
        $line =~ s/\n//g;
        $line =~ s/\r//g;
        if (substr ($line, 54, 1) ne ' ') {
            print "UNEXPECTED non space at [54] $line\n";
        } elsif ($line =~ /^d/) {
            $dname2 = substr ($line, 55, 1000);
            &procdir ("$dname$dname2/");
        } else {
            $nofiles++;
            $fname = substr ($line, 55, 1000);
            $buf = "adb pull \"$getphonepath$dname$fname\" \"$dname$fname\"";
            print STDERR "$buf              ";
            $rst = `$buf`;
            #print "$rst    ";
            #print "$buf\n";
        }
    }

    1;
}


if ($getphonepath ne '') {
    &procdir ('');
    print "Copied $nofiles files in $nodirs directories\n";
}



#while (0) {
#    if (/^-/) {
#        s/\n//g;
#        s/\r//g;
##----rw-rw- system   system       2608 2010-05-11 00:02 NtSsh.txt.bak
#        if (substr ($_, 54, 1) ne ' ') {
#            print STDERR "UNEXPECTED non space at [54] $_\n";
#        } else {
#            $fname = substr ($_, 55, 1000);
#            #$buf = "adb shell ls $getphonepath$fname";
#            #$buf = "dir $fname";
#            $buf = "adb pull $getphonepath$fname $fname";
#            $rst = `$buf`;
#            print "$fname $rst";
#        }
#    }
#}
