# perl adb.pl adb.in

# synopsis:
# Autosync between PC and Android through adb.exe
# 
# 
# first command line argument is 'adb.in'
# 

$ifname = shift;
$idir = $ifname;
$idir =~ s/([\/\\])([^\/\\]+)$/$1/;

print "adb.in directory is $idir\n\n";

if (opendir (DIR, $idir)) {
    print "About to delete these files (review in explorer):\n\n";
    foreach $item (readdir (DIR)) {
        if (-f "$idir$item") {
            if ($item eq 'adb.in' || $item eq 'adb.pl') {
                next;
            }
            print "$idir$item\n";
        }
    }
    closedir (DIR);
    `explorer $idir`;
    print "\n^C now to terminate. <Enter> to continue.\n";
    <>;
    opendir (DIR, $idir);
    $cnt = 0;
    foreach $item (readdir (DIR)) {
        if (-f "$idir$item") {
            if ($item eq 'adb.in' || $item eq 'adb.pl') {
                next;
            }
            print "delete $idir$item\n";
            unlink ("$idir$item");
            $cnt++;
        }
    }
    closedir (DIR);
    print "\n$cnt files deleted. <Enter> to continue.\n";
    <>;
} else {
    print "Unable to opendir $idir\n";
}


# get date/time stamp of input file
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
        $whoami = '';
        if (open (IN, "<$ifname")) {
            undef %fstamp;
            undef %phpath;
            print "REREAD: $ifname\n";
            $fetch = 0;
            while (<IN>) {
                s/\n//;
                s/\r//;
                # save whoami command
                if (/(ssh .*\/\.whoami')/) {
                    $whoami = $1;
                    print "WHOAMI: $whoami\n";
                    print "WHOAMI: reply: ", `$whoami 2>&1`, "\n";
                }
                # save fetch command lines
                # rsync -v -e 'ssh -p 30339' --rsync-path='/data/data/com.spartacusrex.spartacuside/files/system/bin/rsync' 127.0.0.1:/sdcard/l00httpd/NtCompTw700.txt /cygdrive/D/x/ram/l00/NtCompTw700.txt
                # rsync -v -e 'ssh -p 30339' --rsync-path='/data/data/com.spartacusrex.spartacuside/files/system/bin/rsync' 127.0.0.1:/sdcard/l00httpd/NtCompTw700.txt 
                # /cygdrive/D/x/ram/l00/NtCompTw700.txt
                if (($cygpath) = /^rsync -v +-e .*(\/cygdrive\/\S+)$/) {
                    $pcpath = $cygpath;
                    $pcpath =~ s|^/cygdrive/(.)/|$1:\\|;
                    $pcpath =~ s/\//\\/g;
                    if (!(-f $pcpath)) {
                        print "FETCH: $pcpath\n";
                        print `$_` . "\n";
                        $fetch++;
                    }
                }
                # save push command lines
                # rsync -vv -e 'ssh -p 30339' --rsync-path='/data/data/com.spartacusrex.spartacuside/files/system/bin/rsync' /cygdrive/D/x/ram/l00/NtCompTw700.txt 127.0.0.1:/sdcard/l00httpd/NtCompTw700.txt
                # rsync -vv -e 'ssh -p 30339' --rsync-path='/data/data/com.spartacusrex.spartacuside/files/system/bin/rsync' 
                # /cygdrive/D/x/ram/l00/NtCompTw700.txt 
                # 127.0.0.1:/sdcard/l00httpd/NtCompTw700.txt
                if (($cygpath) = /^rsync -vv -e .*(\/cygdrive\/\S+) 127/) {
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
            if ($fetch) {
                print "\nFetch $fetch files. <Enter> to continue.\n";
                <>;
            }
        } else {
            die "Unable to read $ifname\n";
        }
    }

    foreach $pcpath (keys %rsynccmd) {
        $cmd = $rsynccmd{$pcpath};
        ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, 
            $atime, $mtime, $ctime, $blksize, $blocks) = stat($pcpath);
        print "#$cnt $mtime: $pcpath\n";
        if ($rsynctim{$pcpath} != $mtime) {
            print "\n$pcpath modified: $cmd\n";
            print `$cmd` . "\n";
            $rsynctim{$pcpath} = $mtime;
        }
    }
    # is connection still alive?
    if ($whoami ne '') {
        $_ = `$whoami 2>&1`;
        if (/refused/) {
            print "$whoami\n";
            print;
            print "whoami check failed. Exiting. <Enter>\n";
            <>;
            last;
        }
    }
    sleep(1);
    $cnt++;
}
