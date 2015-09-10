use strict;
use warnings;
use l00backup;
use l00crc32;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_fstat_proc",
              desc => "l00http_fstat_desc");


sub l00http_fstat_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "fstat: Compute file statistics";
}



sub l00http_fstat_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>File statistics</title>" .$ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}\n";
    # clip.pl with \ on Windows
    $_ = $form->{'path'};
    if ($ctrl->{'os'} eq 'win') {
        s/\//\\/g;
    }
    print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$_\">Path</a>:\n";
    print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";

    if ((defined ($form->{'path'})) && (-f $form->{'path'})) {
        my ($buf, $crc32, $crc);
        local $/ = undef;
        if(open(IN, "<$form->{'path'}")) {
            binmode (IN);
            $buf = <IN>;
            close(IN);
        } else {
            $buf = '';
        }
        my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
            $size, $atime, $mtime, $ctime, $blksize, $blocks)
            = stat($form->{'path'});
        print $sock "<p>File statistics:<p>\n";
        print $sock "<pre>\n";
        print $sock "$form->{'path'}\n";
        my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
            = localtime($ctime);
        print $sock sprintf ("Creation    : %4d/%02d/%02d %02d:%02d:%02d\n", 1900+$year, 1+$mon, $mday, $hour, $min, $sec);
        ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
            = localtime($mtime);
        print $sock sprintf ("Modification: %4d/%02d/%02d %02d:%02d:%02d\n", 1900+$year, 1+$mon, $mday, $hour, $min, $sec);
        ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
            = localtime($atime);
        print $sock sprintf ("Access      : %4d/%02d/%02d %02d:%02d:%02d\n", 1900+$year, 1+$mon, $mday, $hour, $min, $sec);
        print $sock "CRC32 is computed using pure Perl and will be very slow...\n";
        $crc32 = &l00crc32::crc32($buf);
        $crc = 0;
#       $crc = &cksum($buf);
        print $sock sprintf ("CRC32       : 0x%08x\n", $crc32);
        print $sock          "Size        : $size bytes\n";
        print $sock "<pre>\n";
    }
}

\%config;
