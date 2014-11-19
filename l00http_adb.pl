use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Create adb push/pull copy/paste command lines

my %config = (proc => "l00http_adb_proc",
              desc => "l00http_adb_desc");


sub l00http_adb_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "adb: Create adb push/pull copy/paste command lines";
}

sub l00http_adb_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($buf);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>adb</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<br>\n";


    if (defined ($form->{'hostpath'})) {
        $ctrl->{'adbpath'} = $form->{'hostpath'}
    }

    if (defined ($form->{'path'})) {
        print $sock "<form action=\"/adb.htm\" method=\"get\">\n";
        print $sock "<input type=\"submit\" name=\"backup\" value=\"Make backup\">\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
        print $sock "</form>\n";

        if ($form->{'path'} =~ /^(.+\/)([^\/]+)$/) {
            if (defined ($form->{'backup'})) {
                # make backup
                &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 5);
            }
            $_ = "$form->{'path'}";
            s / /%20/g;
            print $sock "<br><a href=\"/clip.htm?update=Copy+to+clipboard&clip=$_\">Copy path</a><p>\n";

            $buf = &l00httpd::pcSyncCmdline($ctrl, $form->{'path'});
            print $sock $buf;
        }
    }

    print $sock "Go to ls.pl, set \"'Size' send to'\" to 'adb', then click the file you want to exchange with the desktop\n";

    print $sock "<form action=\"/adb.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";
    print $sock "        <tr>\n";
    print $sock "            <td>Host path:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"hostpath\" value=\"$ctrl->{'adbpath'}\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Set host path\"></td>\n";
    print $sock "        <td>&nbsp;</td>\n";
    print $sock "    </tr>\n";
    print $sock "</table>\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</form><p>\n";

    print $sock "<p>Listing of adb.pl (click <a href=\"/view.htm?path=$ctrl->{'plpath'}l00http_adb.pl&hidelnno=on\">here</a> and copy from screen)\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;

__DATA__
Content of 'adb.pl'. Copy and paste to host file:
# perl adb.pl adb.in

$ifname = shift;
($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, 
    $atime, $mtime, $ctime, $blksize, $blocks) = stat($ifname);
$adbintime = $mtime - 1;    # so it always load at first run

$cnt = 0;
while (1) {
    # check adb.in spec file timestamp change
    ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, 
        $atime, $mtime, $ctime, $blksize, $blocks) = stat($ifname);
    if ($adbintime != $mtime) {
        # adb.in spec file was modified by user, rescan
        $adbintime = $mtime;
        if (open (IN, "<$ifname")) {
            undef %fstamp;
            undef %phpath;
            print "REREAD: $ifname\n";
            while (<IN>) {
                # save command lines
                if (($cygpath) = /^rsync -vv -e .*(\/cygdrive\/\S+) 127/) {
                    s/\n//;
                    s/\r//;
                    $pcpath = $cygpath;
                    $pcpath =~ s|^/cygdrive/(.)/|$1:\\|;
                    $pcpath =~ s/\//\\/g;
                    ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, 
                        $atime, $mtime, $ctime, $blksize, $blocks) = stat($pcpath);
                    $rsynccmd{$pcpath} = $_;
                    $rsynctim{$pcpath} = $mtime;
                    print "TARGET: $rsynctim{$pcpath} : $pcpath\n";
                }

            }
            close (IN);
        } else {
            die "Unable to read $ifname\n";
        }
    }

    print "loop $cnt:\n";
    foreach $pcpath (keys %rsynccmd) {
        $cmd = $rsynccmd{$pcpath};
        print "CANDIDATE: $pcpath\n";
        ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, 
            $atime, $mtime, $ctime, $blksize, $blocks) = stat($pcpath);
        if ($rsynctim{$pcpath} != $mtime) {
            print "\n$pcpath modified: $cmd\n";
            print `$cmd` . "\n";
            $rsynctim{$pcpath} = $mtime;
        }
    }
    sleep(1);
    $cnt++;
}
