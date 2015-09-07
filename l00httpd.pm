# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14
use warnings;
use strict;



package l00httpd;

#use l00httpd;      # used for findInBuf

my ($readName, $readBuf, @readAllLines, $readIdx, $writeName, $writeBuf);
my ($debuglog, $debuglogstate, %poorwhois);

$debuglog = '';
$debuglogstate = 0;

#debugprint("calling $cnt\n");

sub dbp {
    my ($desc, $msg) = @_;
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst);

    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (time);
    if ($debuglogstate == 0) {
        # get name
        if ($desc =~ /l00http_(.+?)_desc/) {
            $desc = $1;
        }
        # last line was completed, print date/time
        $debuglog .= sprintf ("%4d%02d%02d %02d%02d%02d: $desc: ", $year + 1900, $mon+1, $mday, $hour, $min, $sec);
        $debuglog .= $msg;
        if (!($msg =~ "\n")) {
            # not a complete line, remember
            $debuglogstate = 1;
        }
    } else {
        # last line was not completed, just append
        $debuglog .= $msg;
        if ($msg =~ "\n") {
            # complete line, reset
            $debuglogstate = 0;
        }
    }

    if (length($debuglog) > 1000000) {
        $debuglog = substr($debuglog, length($debuglog) - 1000000, 1000000);
    }

    1;
}
sub dbphash {
    my ($desc, $name, $hash) = @_;
    my ($buf);

    $buf = &dumphashbuf ($name, $hash);
    &dbp($desc, "Dumping hash $name:\n$buf\n");
}
sub dbpget {
    $debuglog;
}
sub dbpclr {
    $debuglog = '';
}




#$buf = &l00httpd::urlencode ($buf);
sub urlencode {
    my ($buf) = @_;

    # http://search.cpan.org/~mithun/URI-Encode-0.09/lib/URI/Encode.pm
    # reserved char:
    #  ! * ' ( ) ; : @ & = + $ , / ? # [ ]
    if (defined($buf)) {
        $buf =~  s/!/%21/g;
        $buf =~ s/\*/%2A/g;
        $buf =~  s/'/%27/g;
        $buf =~ s/\(/%28/g;
        $buf =~ s/\)/%29/g;
        $buf =~  s/;/%3B/g;
        $buf =~  s/:/%3A/g;
        $buf =~ s/\@/%40/g;
        $buf =~  s/&/%26/g;
        $buf =~  s/=/%3D/g;
        $buf =~ s/\+/%2B/g;
        $buf =~ s/\$/%24/g;
        $buf =~  s/,/%2C/g;
        $buf =~ s/\//%2F/g;
        $buf =~ s/\?/%3F/g;
        $buf =~  s/#/%23/g;
        $buf =~ s/\[/%5B/g;
        $buf =~ s/\]/%5D/g;

        $buf =~    s/ /+/g;

        $buf =~  s/"/%22/g;
        $buf =~ s/\|/%7C/g;
        $buf =~ s/\r/%0D/g;
        $buf =~ s/\n/%0A/g;
    } else {
        $buf = '';
    }

    $buf;
}

#$buf = &l00httpd::dumphashbuf ("gps", $buf);
sub dumphashbuf {
    my ($name, $hash) = @_;
    my ($tmp, $key, $buf);
    $buf = '';
    for $key (keys %$hash) {
        $tmp = $hash->{$key};
        if (defined ($tmp)) {
            $buf .= "$name->$key => $tmp\n";
            if (ref $tmp eq 'HASH') {
                $buf .= &dumphashbuf ("$name->$key", $tmp);
            } elsif (ref $tmp eq 'ARRAY') {
                $buf .= "$name->$key => ";
                $buf .= 'last index: ' . $#$tmp . "; content:\n";
                $buf .= join ("\n", @$tmp);
                $buf .= "\n";
            } elsif ($key eq 'result') {
#               $buf .= &dumphashbuf ("$name->$key", $tmp);
            }
        } else {
            $buf .= "$name->$key => (undef)\n";
        }
    }
    $buf;
}

#$buf = $ctrl->{'droid'}->readLocation();
#&l00httpd::dumphash ("gps", $buf);
sub dumphash {
    my ($name, $hash) = @_;
    my ($tmp, $key);
    #print "$name is $hash\n";
    for $key (keys %$hash) {
        $tmp = $hash->{$key};
        if (defined ($tmp)) {
            print "$name->$key => $tmp\n";
            if (ref $tmp eq 'HASH') {
                &dumphash ("$name->$key", $tmp);
            } elsif (ref $tmp eq 'ARRAY') {
                print "$name->$key => ";
                print 'last index: ' . $#$tmp . "; content:\n";
                print join ("\n", @$tmp);
                print "\n";
            } elsif ($key eq 'result') {
#               &dumphash ("$name->$key", $tmp);
            }
        } else {
            print "$name->$key => (undef)\n";
        }
    }
}

#$found .= &l00httpd::findInBuf ($findtext, $block, $buf);
sub findInBuf  {
    # $findtext : string to find
    # $block    : text block marker
    # $buf      : find string in $buf
    my ($findtext, $block, $buf) = @_;
    my ($hit, $found, $blocktext, $line, $pattern, $lnno, $llnno);

 
    # find them
    $hit = 0;
    $found = '';
    $blocktext = '';
    $llnno = 1;
    foreach $line (split ("\n", $buf)) {
        # remove %l00httpd:lnno:$lnno% metadata
        # extract $lnno line number or count locally if not available
		if (($lnno) = $line =~ /^%l00httpd:lnno:(\d+)%/) {
            $lnno = sprintf("%04d: ", $lnno);
#           $lnno = sprintf("<a href=\"/view.htm?path=$\">%04d</a>: ", $lnno);
		    $line =~ s/^%l00httpd:lnno:\d+%//;
        } else {
            $lnno = sprintf("%04d: ", $llnno);
#           $lnno = sprintf("<a href=\"/view.htm?path=$\">%04d</a>: ", $llnno);
            $llnno++;
        }
        if ($line =~ /$block/i) {
            # found new block
            if ($hit) {
                # if single line mode, $block eq '.', make single line
                if ($block eq '.') {
                    $blocktext =~ s/\n//g;
                    $blocktext =~ s/\r//g;
                    $blocktext .= "\n";
                }
                # report if found
                $found .= "$blocktext";
            }
            $hit = 0;
            $blocktext = '';
        }
        # $findtext could be multiple pattern separated by |||
        foreach $pattern (split ('\|\|\|', $findtext)) {
            if ($line =~ /$pattern/i) {
                $hit = 1;
            }
        }
        # insert a leading space to prevent special meaning for ^::
        $line =~ s/^::/ ::/;
        if (($blocktext eq '') && ($block ne '.')) {
            # block header and not line mode
            $blocktext .= "<font style=\"color:black;background-color:silver\">\n";
            $blocktext .= "$lnno$line\n";
            $blocktext .= "</font>\n";
#        } elsif ($block ne '.') {
#            # not line mode, highlight hits
#            foreach $pattern (split ('\|\|\|', $findtext)) {
#                $line =~ s/($pattern)/<font style=\"color:black;background-color:yellow\">$1<\/font>/gi;
#            }
#            $blocktext .= "$line\n";
        } else {
            # highlight hits
            foreach $pattern (split ('\|\|\|', $findtext)) {
                $line =~ s/($pattern)/<font style=\"color:black;background-color:yellow\">$1<\/font>/gi;
            }
            $blocktext .= "$lnno$line\n";
        }
    }
    if ($hit) {
        # if single line mode, $block eq '.', make single line
        if ($block eq '.') {
            $blocktext =~ s/\n//g;
            $blocktext =~ s/\r//g;
            $blocktext .= "\n";
        }
        $found .= "$blocktext";
    }
    $found;
}

#&l00httpd::l00fstat($ctrl, $fname);
sub l00fstat {
    my ($ctrl, $fname) = @_;
    my ($ret);

    $ret = undef;
	
    if ($fname =~ /^l00:\/\/./) {
        # ram file
        if (defined($ctrl->{'l00file'}->{$fname})) {
		    # ram file exist
            $ret = length($ctrl->{'l00file'}->{$fname});
		}
    } else {
        my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
            $size, $atime, $mtimea, $ctime, $blksize, $blocks)
                = stat($fname);
        $ret = $size;
    }
    $ret;
}

#&l00httpd::l00freadOpen($ctrl, $fname);
sub l00freadOpen {
    my ($ctrl, $fname) = @_;
    my ($ret);

    $readName = $fname;
    $readIdx = -1;
	
    if ($fname =~ /^l00:\/\/./) {
        # ram file
        if (defined($ctrl->{'l00file'}->{$fname})) {
		    # ram file exist
            $readBuf = $ctrl->{'l00file'}->{$fname};
            $ret = 1;
		} else {
		    # ram file doesn't exist
            $readBuf = undef;
            $ret = 0;
		}
    } else {
	    if (open(IN, "<$fname")) {
		    # disk file exist
            local $/ = undef;
            $readBuf = <IN>;
			close (IN);
            $ret = 1;
		} else {
		    # disk file doesn't exist
            $readBuf = undef;
            $ret = 0;
		}
    }
    $ret;
}

#$buf = &l00httpd::l00freadAll($ctrl);
sub l00freadAll {
    my ($ctrl) = @_;

    $readBuf;
}

#$buf = &l00httpd::l00freadLine($ctrl);
sub l00freadLine {
    my ($ctrl) = @_;
    my ($buf);

    if (defined($readBuf)) {
        if ($readIdx < 0) {
	        # split monolithic buffer into array
            @readAllLines = split("\n", $readBuf);
		    # reset index
            $readIdx = 0;
        }

        if ($readIdx <= $#readAllLines) {
	        # index in range of array
            $buf = "$readAllLines[$readIdx]\n";
            $readIdx++;
	    } else {
	        # EOF
            $buf = undef;
	    }
    } else {
        $buf = undef;
    }

    $buf;
}


#my ($readName, $readBuf, @readAllLines, $writeName, $writeBuf);
#
#&l00httpd::l00fwriteOpen($ctrl, $fname);
sub l00fwriteOpen {
    my ($ctrl, $fname) = @_;

    $writeName = $fname;
    $writeBuf = '';

    1;
}

#&l00httpd::l00fwriteBuf($ctrl, $buf);
sub l00fwriteBuf {
    my ($ctrl, $buf) = @_;

    $writeBuf .= $buf;

    1;
}

#&l00httpd::l00fwriteClose($ctrl);
sub l00fwriteClose {
    my ($ctrl) = @_;
    my ($ret);

    $ret = 0;   # non zero error

    if ($writeName =~ /^l00:\/\/./) {
        # ram file
        if ($writeBuf eq '') {
            $ctrl->{'l00file'}->{$writeName} = undef;
        } else {
            $ctrl->{'l00file'}->{$writeName} = $writeBuf;
        }
    } else {
        if ($writeBuf eq '') {
            # write 0 bytes file is delete file.
            unlink ($writeName);
        } else {
	        if (open(OU, ">$writeName")) {
                print OU $writeBuf;
			    close (OU);
		    } else {
                $ret = 1;
            }
        }
    }
    $ret;
}



#&l00httpd::l00npoormanrdns($ctrl, $myname, $fullpath);
sub l00npoormanrdns {
    my ($ctrl, $myname, $fullpath) = @_;
    my ($ret, $patt, $name);
    my ($leading, $st, $en, $trailing);

    $ret = '';

    &dbp($myname.'l00httpd.pm', "reading '$fullpath'\n");
    if (open(IN, "<$fullpath")) {
        undef %poorwhois;
        while (<IN>) {
            if (/^#/) {
                next;
            }
            s/\r//;
            s/\n//;
            if (($patt, $name) = /(.*)=>(.*)/) {
                $ret .= "$patt is $name\n";
                &dbp($myname.'l00httpd.pm', "$patt is $name\n");
                #46.51.248-254.*=>AMAZON_AWS
                if (($leading, $st, $en, $trailing) = ($patt =~ /(.+?)\.(\d+)-(\d+)\.(.*)/)) {
                    &dbp($myname.'l00httpd.pm', "range: $patt ($st, $en) is $name\n");
                    for ($st..$en) {
                        $patt = "$leading.$_.$trailing";
                        &dbp($myname.'l00httpd.pm', "expanded: $patt is $name\n");
                        $patt =~ s/\./\\./g;
                        $patt =~ s/\*/\\d+/g;
                        $poorwhois{$patt} = $name;
                    }
                } else {
                    &dbp($myname.'l00httpd.pm', "full octet: $patt is $name\n");
                    $patt =~ s/\./\\./g;
                    $patt =~ s/\*/\\d+/g;
                    $poorwhois{$patt} = $name;
                }
            }
        }
        close(IN);
    }


    $ret;
}

#&l00httpd::l00npoormanrdnshash($ctrl);
sub l00npoormanrdnshash {

    \%poorwhois
}

#&l00httpd::pcSyncCmdline($ctrl, $fullpath);
sub pcSyncCmdline {
    my ($ctrl, $fullpath) = @_;
    my ($buf, $clip, $rsyncpath, $path, $fname, $pcpath, $tmp);


    if (defined($ctrl->{'adbpath'})) {
        # use setting in l00httpd.cfg if defined
        $pcpath = $ctrl->{'adbpath'};
    } else {
        $pcpath = 'c:/x/';
    }

    $buf = '';
    $clip = '';

    if (($path, $fname) = $fullpath =~ /^(.+\/)([^\/]+)$/) {
        # Windows + cygwin
        $rsyncpath = $pcpath;
        $rsyncpath =~ s/^(\w):\\/\/cygdrive\/$1\//;
        $rsyncpath =~ s/\\/\//g;

        $buf .= "rsync -v  -e 'ssh -p 30339' --rsync-path='/data/data/com.spartacusrex.spartacuside/files/system/bin/rsync' 127.0.0.1:$path$fname $rsyncpath$fname<br>\n";
        $buf .= "rsync -vv -e 'ssh -p 30339' --rsync-path='/data/data/com.spartacusrex.spartacuside/files/system/bin/rsync' $rsyncpath$fname 127.0.0.1:$path$fname<br>\n";

        $buf .= "<pre>\n";
        $buf .= "adb pull \"$path$fname\" \"$pcpath$fname\"\n";
        $buf .= "adb push \"$pcpath$fname\" \"$path$fname\"\n";
        $buf .= "$pcpath$fname\n";

        $buf .= "ssh 127.0.0.1 -p 30339 'cat /sdcard/l00httpd/.whoami'\n";
        $buf .= "perl ${pcpath}adb.pl ${pcpath}adb.in\n";
        $buf .= "${pcpath}adb.in\n";
        $buf .= "</pre>\n";


        #$clip .= "Send the clipboard to the host through port <a href=\"/clipbrdxfer.htm?url=127.0.0.1%3A50337&name=p&pw=p&nofetch=on\">50337</a><br>\n";        

        $clip .= "rsync -v  -e 'ssh -p 30339' --rsync-path='/data/data/com.spartacusrex.spartacuside/files/system/bin/rsync' 127.0.0.1:$path$fname $rsyncpath$fname\n";
        $clip .= "rsync -vv -e 'ssh -p 30339' --rsync-path='/data/data/com.spartacusrex.spartacuside/files/system/bin/rsync' $rsyncpath$fname 127.0.0.1:$path$fname\n";

        $clip .= "adb pull \"$path$fname\" \"$pcpath$fname\"\n";
        $clip .= "adb push \"$pcpath$fname\" \"$path$fname\"\n";
        $clip .= "$pcpath$fname\n";

        $clip .= "ssh 127.0.0.1 -p 30339 'cat /sdcard/l00httpd/.whoami'\n";
        $clip .= "perl ${pcpath}adb.pl ${pcpath}adb.in\n";
        $clip .= "${pcpath}adb.in\n";

        # append in RAM
        &l00freadOpen($ctrl, 'l00://pcSyncCmdline');
        $tmp = &l00freadAll($ctrl);
        &l00fwriteOpen($ctrl, 'l00://pcSyncCmdline');
        &l00fwriteBuf($ctrl, "$tmp\n$clip\n");
        &l00fwriteClose($ctrl);

        $clip = urlencode ($clip);

        $buf = "View <a href=\"/view.htm?path=l00://pcSyncCmdline\">l00://pcSyncCmdline</a>. \n"
                . "Send the following lines to the <a href=\"/clip.htm?update=Copy+to+clipboard&clip=$clip\">clipboard</a>:<br>\n"
                . $buf;


    }

    $buf;
}


#use Win32::Clipboard;
#$clip = Win32::Clipboard();
#print "Type your name: ";
#$input = <>;
#chomp $input;
#$clip->Set("Hello, $input!");
#print "You may now paste!\n";
#print $clip->Get();
#

#&l00httpd::l00getCB($ctrl);
sub l00getCB {
    my ($ctrl) = @_;
    my ($buf);
    my ($clip);

#   $ctrl{'os'} = 'win';
#   $ctrl{'os'} = 'rhc';
#   $ctrl{'os'} = 'lin';

    if ($ctrl->{'os'} eq 'and') {
        $buf = $ctrl->{'droid'}->getClipboard();
        $buf = $buf->{'result'};
    } elsif ($ctrl->{'os'} eq 'win') {
        # Use Perl module
        eval 'use Win32::Clipboard';
        $clip = Win32::Clipboard();
        $buf = $clip->Get();
    } else {
        &l00freadOpen($ctrl, 'l00://clipboard.txt');
        $buf = &l00freadAll($ctrl);
    }
    if (!defined ($buf)) {
        $buf = ''; }

    $buf;
}

#&l00httpd::l00setCB($ctrl, $buf);
sub l00setCB {
    my ($ctrl, $buf) = @_;
    my ($clip);

    &l00fwriteOpen($ctrl, 'l00://clipboard.txt');
    &l00fwriteBuf($ctrl, $buf);
    &l00fwriteClose($ctrl);

    if ($ctrl->{'os'} eq 'and') {
        $ctrl->{'droid'}->setClipboard ($buf);
    } elsif ($ctrl->{'os'} eq 'cyg') {
        # ::todo:: add windows special character escape
        `echo $buf| clip`;
    } elsif ($ctrl->{'os'} eq 'win') {
        # Use Perl module
        eval 'use Win32::Clipboard';
        $clip = Win32::Clipboard();
        $clip->Set($buf);
    }
}


1;
