use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Create adb push/pull copy/paste command lines

my %config = (proc => "l00http_adb_proc",
              desc => "l00http_adb_desc");
my ($hostpath);
$hostpath = "c:\\x\\";


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
    my ($path, $fname);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>adb</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<br>\n";


    if (defined ($form->{'hostpath'})) {
        $hostpath = $form->{'hostpath'}
    }

    if (defined ($form->{'path'})) {
        if ($form->{'path'} =~ /^(.+\/)([^\/]+)$/) {
            $path = $1;
            $fname = $2;
            $_ = "$form->{'path'}";
            s / /%20/g;
            print $sock "<br><a href=\"/clip.htm?update=Copy+to+clipboard&clip=$_\">Copy path</a><br>\n";
            print $sock "<pre>\n";
            print $sock "adb shell ls -l $path$fname\n";
            print $sock "adb pull \"$path$fname\" \"$hostpath$fname\"\n";
            print $sock "$hostpath$fname\n";
            print $sock "adb push \"$hostpath$fname\" \"$path$fname\"\n";
            print $sock "perl c:\\x\\adb.pl c:\\x\\adb.in\n";
            print $sock "</pre>\n";
            print $sock "busybox vi $path$fname<p>Copied to clipboard<p>\n";
            if ($ctrl->{'os'} eq 'and') {
                $ctrl->{'droid'}->setClipboard ("busybox vi $path$fname"); 
            }
        }
    }

    print $sock "Go to ls.pl, set \"'Size' send to'\" to 'adb', then click the file you want to exchange with the desktop\n";

    print $sock "<form action=\"/adb.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";
    print $sock "        <tr>\n";
    print $sock "            <td>Host path:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"hostpath\" value=\"$hostpath\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Set host path\"></td>\n";
    print $sock "        <td>&nbsp;</td>\n";
    print $sock "    </tr>\n";
    print $sock "</table>\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</form>\n";

    print $sock "Listing of adb.pl:<pre>\n";
    print $sock <<eop
#adb push "pcfile" "devicefile"

# perl c:\\x\\adb.pl c:\\x\\adb.in

print "adb push \"pc\" \"device\"\\n";

\$ifname = shift;

(\$dev, \$ino, \$mode, \$nlink, \$uid, \$gid, \$rdev, 
    \$size, \$atime, \$mtime, \$ctime, \$blksize, \$blocks)
= stat(\$ifname);
\$adbintime = \$mtime;

if (open (IN, "<\$ifname")) {
    undef %fstamp;
    undef %phpath;
    while (<IN>) {
        # save command lines
        if ((\$pcpath, \$phpath) = /adb push "(.+?)" "(.+?)"/) {
            (\$dev, \$ino, \$mode, \$nlink, \$uid, \$gid, \$rdev, 
                \$size, \$atime, \$mtime, \$ctime, \$blksize, \$blocks)
            = stat(\$pcpath);
            \$fstamp{\$pcpath} = \$mtime;
            \$phpath{\$pcpath} = \$phpath;
            print "TARGET: \$fstamp{\$pcpath} : \$pcpath\\n";
        }
    }
    close (IN);
}

\$cnt = 0;
while (1) {
    (\$dev, \$ino, \$mode, \$nlink, \$uid, \$gid, \$rdev, 
        \$size, \$atime, \$mtime, \$ctime, \$blksize, \$blocks)
    = stat(\$ifname);
    if (\$adbintime != \$mtime) {
        # spec file changed
        \$adbintime = \$mtime;
        if (open (IN, "<\$ifname")) {
            undef %fstamp;
            undef %phpath;
            print "REREAD: \$ifname\\n";
            while (<IN>) {
                # save command lines
                if ((\$pcpath, \$phpath) = /adb push "(.+?)" "(.+?)"/) {
                    (\$dev, \$ino, \$mode, \$nlink, \$uid, \$gid, \$rdev, 
                        \$size, \$atime, \$mtime, \$ctime, \$blksize, \$blocks)
                    = stat(\$pcpath);
                    \$fstamp{\$pcpath} = \$mtime;
                    \$phpath{\$pcpath} = \$phpath;
                    print "TARGET: \$fstamp{\$pcpath} : \$pcpath\\n";
                }
            }
            close (IN);
        } else {
            print "Unable to read \$ifname\\n";
            next;
        }
    }

    print "loop \$cnt:\\n";
    foreach \$pcpath (keys %phpath) {
        \$cmd = "adb push \"\$pcpath\" \"\$phpath{\$pcpath}\"";
        print "CANDIDATE: \$cmd\\n";
        (\$dev, \$ino, \$mode, \$nlink, \$uid, \$gid, \$rdev, 
            \$size, \$atime, \$mtime, \$ctime, \$blksize, \$blocks)
        = stat(\$pcpath);
        if (\$fstamp{\$pcpath} != \$mtime) {
            print "\\n\$pcpath modified: \$cmd\\n";
            print `\$cmd` . "\\n";
            \$fstamp{\$pcpath} = \$mtime;
        }
    }
    sleep(1);
    \$cnt++;
}
eop
;

    print $sock "</pre>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
