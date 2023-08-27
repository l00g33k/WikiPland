# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14
use warnings;
use strict;

use l00mktime;


package l00httpd;

#use l00httpd;      # used for findInBuf

my ($readName, $readBuf, @readAllLines, $readIdx, $writeName, $writeBuf);
my ($debuglog, $debuglogstate, %poorwhois, $usewinclipboard, @colors);

$debuglog = '';
$debuglogstate = 0;
$usewinclipboard = 0;
@colors = (
    'aqua',
    'lime',
    'deepPink',
    'deepSkyBlue',
    'fuchsia',
    'yellow',
    'silver',
    'brown',
    'red',
    'gray',
    'olive',
    'lightGray',
    'teal'
);

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
        $debuglog = substr($debuglog, length($debuglog) - 700000, 700000);
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
        $buf =~  s/#/%23/g;
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
        $buf =~ s/\^/%5E/g;
        $buf =~ s/~/%7E/g;

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

#$found .= &l00httpd::findInBuf ($findtext, $block, $buf, [$literal], $lastfew, $nextfew, [$sort]);
sub findInBuf  {
    # $findtext : string to find
    # $block    : text block marker
    # $buf      : find string in $buf
    # $literal  : if true, convert <> to &lt; &gt;
    # $lastfew  : leading context
    # $nextfew  : tailing context
    # $sort     : if true, sort find results
    # $findstart: 
    # $findlen  :
    # $excludeinfound : exclude in found
    my ($findtext, $block, $buf, $literal, $lastfew, $nextfew, $sort, $findstart, $findlen, $excludeinfound) = @_;
    my ($hit, $found, $blocktext, $line, $lineorg, $pattern, $lnno, @founds, @findCount, $findidx, 
        $llnno, $invertfind, $ii, $color, @lastfewlns, $hitpast, $nextln, $dsplnno);

    $findidx = 0;
    foreach $pattern (split ('\|\|', $findtext)) {
        $findCount[$findidx] = 0;
        $findidx++;
    }

    if (!defined($literal)) {
        $literal = 0;
    }
    if (!defined($sort)) {
        $sort = 0;
    }
    if (!defined($findstart)) {
        $findstart = 0;
    }
    if (!defined($findlen)) {
        $findlen = 0;
    }

    if ($findtext =~ /^!!/) {
        # invert find logic
        substr($findtext, 0, 2) = '';
        $invertfind = 1;
    } else {
        $invertfind = 0;
    }

 
    # find them
    $hit = 0;
    $hitpast = 0;
    $found = '';
    undef @founds;
    $blocktext = '';
    $llnno = 1;
    if (!defined($lastfew)) {
        $lastfew = 0;
    }
    if (!defined($nextfew)) {
        $nextfew = 0;
    }
    undef @lastfewlns;
    foreach $line (split ("\n", $buf)) {
        $lineorg = $line;
        # remove %l00httpd:lnno:$lnno% metadata
        # extract $lnno line number or count locally if not available
		if (($lnno) = $line =~ /^%l00httpd:lnno:(\d+)%/) {
            $dsplnno = $lnno;
            $lnno = sprintf("%06d: ", $lnno);
#           $lnno = sprintf("<a href=\"/view.htm?path=$\">%06d</a>: ", $lnno);
		    $line =~ s/^%l00httpd:lnno:\d+%//;
        } else {
            $lnno = sprintf("%06d: ", $llnno);
#           $lnno = sprintf("<a href=\"/view.htm?path=$\">%06d</a>: ", $llnno);
            $llnno++;
            $dsplnno = $llnno;
        }
        # limit find range
        if ($findlen > 0) {
            if (($dsplnno < $findstart) || ($dsplnno > ($findstart + $findlen))) {
                next;
            }
        }
        if (($block eq '.') || ($line =~ /$block/i)) {
            # found new block, or line mode
            if ($hit) {
                # if single line mode, $block eq '.', make single line
                if ($block eq '.') {
                    $blocktext =~ s/\n//g;
                    $blocktext =~ s/\r//g;
                    $blocktext .= "\n";
                }
                # report if found
                if ($lastfew > 0) {
                    @_ = splice(@lastfewlns, 1, $#lastfewlns - 1);
                    $found .= join("", @_);
                }
                $found .= "$blocktext";
                if ($sort) {
                    push (@founds, "$blocktext");
                }
                # post context;
            } elsif ($hitpast) {
                $hitpast--;
                $found .= $nextln;
                if ($sort) {
                    # append to last found
                    $founds[$#founds] .= "$nextln";
                }
            }
            $hit = 0;
            $blocktext = '';
        }
        # $findtext could be multiple pattern separated by ||
        $findidx = 0;
        foreach $pattern (split ('\|\|', $findtext)) {
            if ($line =~ /$pattern/i) {
                # it's a hit
                $hit = 1;
                $hitpast = $nextfew;
                # but is it excluded?
                if ($excludeinfound ne '') {
                    # exclude in found specified
                    foreach $pattern (split ('\|\|', $excludeinfound)) {
                        if ($line =~ /$pattern/i) {
                            # clear hit flags
                            $hit = 0;
                            $hitpast = 0;
                            last;
                        }
                    }
                    $findCount[$findidx]++;
                } else {
                    $findCount[$findidx]++;
                    last;
                }
            }
            $findidx++;
        }
        if ($invertfind) {
            $hit = 1 - $hit;
            if ($hit) {
                $hitpast = $nextfew;
            } else {
                $hitpast = 0;
            }
        }

        # last few lines
        if ($lastfew > 0) {
            push (@lastfewlns, " $lnno$lineorg\n");
            if ($#lastfewlns >= $lastfew + 2) {
                shift (@lastfewlns);
            }
        }
        if ($nextfew > 0) {
            $nextln = " $lnno$lineorg\n";
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
#            foreach $pattern (split ('\|\|', $findtext)) {
#                $line =~ s/($pattern)/<font style=\"color:black;background-color:yellow\">$1<\/font>/gi;
#            }
#            $blocktext .= "$line\n";
        } else {
            # highlight hits
            $ii = 0;
            foreach $pattern (split ('\|\|', $findtext)) {
                if ($ii <= $#colors) {
                    $color = $colors[$ii];
                } else {
                    $color = $colors[$#colors];
                }
                if ($literal) {
                    $line =~ s/($pattern)/:~~123____==:$1:~~123____=#:/gi;
                } else {
                   $line =~ s/($pattern)/<font style=\"color:black;background-color:$color\">$1<\/font>/gi;
                }
                $ii++;
            }
            if ($literal) {
                $line =~ s/</&lt;/g;
                $line =~ s/>/&gt;/g;
                $line =~ s/:~~123____==:/<font style=\"color:black;background-color:$colors[0]\">/gi;
                $line =~ s/:~~123____=#:/<\/font>/gi;
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
        # append to last found
        if ($#founds >= 0) {
            $founds[$#founds] .= "$blocktext";
        }
    }
    if ($sort) {
        @founds = sort ({my($aa, $bb) = ($a, $b); $aa =~ s/\d+: +//; $bb =~ s/\d+: +//; $aa cmp $bb} @founds);
        $found = join ('', @founds);
    }
    ($found, @findCount);
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
    my ($ret, $numretry);

    $readName = $fname;
    $readIdx = -1;

    if (!defined($fname) || (length($fname) == 0)) {
    	$ret = 0;
    } elsif ($fname =~ /^l00:\/\/./) {
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
        if ($ctrl->{'os'} eq 'and') {
            # An Android device may be sleeping and file read 
            # may fail. Try a few more times
            $numretry = 5;
        } else {
            $numretry = 1;
        }
        while ($numretry > 0) {
	        if (open(IN, "<$fname")) {
		        # disk file exist
                binmode(IN);
                local $/ = undef;
                $readBuf = <IN>;
			    close (IN);
                $ret = 1;
                $numretry = 0;
		    } else {
		        # disk file doesn't exist
                $readBuf = undef;
                $ret = 0;
                $numretry--;
                if (($numretry > 0) &&
                    ($ctrl->{'os'} eq 'and')) {
                    # sleeps 10 msec before retry on Android
                    select (undef, undef, undef, 0.01);
                }
		    }
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

    if ($writeName =~ /^l00:\/\/./) {
        # initial time stamp
        $ctrl->{'l00filetime'}->{$writeName} = time;
    }

    1;
}

#&l00httpd::l00fwriteOpenAppend($ctrl, $fname);
sub l00fwriteOpenAppend {
    my ($ctrl, $fname) = @_;

    $writeName = $fname;
    $writeBuf = '';
	
    if ($fname =~ /^l00:\/\/./) {
        # ram file
        if (defined($ctrl->{'l00file'}->{$fname})) {
		    # ram file exist
            $writeBuf = $ctrl->{'l00file'}->{$fname};
		} else {
		    # ram file doesn't exist
            $writeBuf = undef;
		}
    } else {
	    if (open(IN, "<$fname")) {
		    # disk file exist
            binmode(IN);
            local $/ = undef;
            $writeBuf = <IN>;
			close (IN);
		} else {
		    # disk file doesn't exist
            $writeBuf = undef;
		}
    }
    1;
}

#&l00httpd::l00fwriteBuf($ctrl, $buf);
sub l00fwriteBuf {
    my ($ctrl, $buf) = @_;

    if (defined($buf)) {
        $writeBuf .= $buf;
    }

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
            # final time stamp
            $ctrl->{'l00filetime'}->{$writeName} = 0;
        } else {
            $ctrl->{'l00file'}->{$writeName} = $writeBuf;
            # final time stamp
            $ctrl->{'l00filetime'}->{$writeName} = time;
        }
    } else {
        if ($writeBuf eq '') {
            # write 0 bytes file is delete file.
            unlink ($writeName);
        } else {
	        if (open(OU, ">$writeName")) {
                binmode(OU);
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

    &dbp($myname.'l00httpd.pm', "reading '$fullpath'\n"), if ($ctrl->{'debug'} >= 5);
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
                &dbp($myname.'l00httpd.pm', "$patt is $name\n"), if ($ctrl->{'debug'} >= 5);
                #46.51.248-254.*=>AMAZON_AWS
                if (($leading, $st, $en, $trailing) = ($patt =~ /(.+?)\.(\d+)-(\d+)\.(.*)/)) {
                    &dbp($myname.'.l00httpd.pm', "range: $patt ($st, $en) is $name\n"), if ($ctrl->{'debug'} >= 5);
                    for ($st..$en) {
                        $patt = "$leading.$_.$trailing";
                        &dbp($myname.'l00httpd.pm', "expanded: $patt is $name\n"), if ($ctrl->{'debug'} >= 5);
                        $patt =~ s/\./\\./g;
                        $patt =~ s/\*/\\d+/g;
                        $poorwhois{$patt} = $name;
                    }
                } else {
                    &dbp($myname.'l00httpd.pm', "full octet: $patt is $name\n"), if ($ctrl->{'debug'} >= 5);
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

#       $buf .= "rsync -v  -e 'ssh -p 30339' --rsync-path='/data/data/com.spartacusrex.spartacuside/files/system/bin/rsync' 127.0.0.1:$path$fname $rsyncpath$fname<br>\n";
#       $buf .= "rsync -vv -e 'ssh -p 30339' --rsync-path='/data/data/com.spartacusrex.spartacuside/files/system/bin/rsync' $rsyncpath$fname 127.0.0.1:$path$fname<br>\n";
        # $ctrl->{'adbrsyncopt'} defaults to "-e 'ssh -p 30339'" and may be overwritte in l00httpd.cfg
        $buf .= "rsync -v  $ctrl->{'adbrsyncopt'} 127.0.0.1:$path$fname $rsyncpath$fname<br>\n";
        $buf .= "rsync -vv $ctrl->{'adbrsyncopt'} $rsyncpath$fname 127.0.0.1:$path$fname<br>\n";

        $buf .= "<pre>\n";
        $buf .= "adb pull \"$path$fname\" \"$pcpath$fname\"\n";
        $buf .= "adb push \"$pcpath$fname\" \"$path$fname\"\n";
        $buf .= "$pcpath$fname\n";

        $buf .= "ssh 127.0.0.1 -p 30339 'cat /sdcard/l00httpd/.whoami'\n";
        $buf .= "perl ${pcpath}adb.pl ${pcpath}adb.in\n";
        $buf .= "${pcpath}adb.in\n";
        $buf .= "</pre>\n";


        #$clip .= "Send the clipboard to the host through port <a href=\"/clipbrdxfer.htm?url=127.0.0.1%3A50337&name=p&pw=p&nofetch=on\">50337</a><br>\n";        

#       $clip .= "rsync -v  -e 'ssh -p 30339' --rsync-path='/data/data/com.spartacusrex.spartacuside/files/system/bin/rsync' 127.0.0.1:$path$fname $rsyncpath$fname\n";
#       $clip .= "rsync -vv -e 'ssh -p 30339' --rsync-path='/data/data/com.spartacusrex.spartacuside/files/system/bin/rsync' $rsyncpath$fname 127.0.0.1:$path$fname\n";
        $clip .= "rsync -v  $ctrl->{'adbrsyncopt'} 127.0.0.1:$path$fname $rsyncpath$fname\n";
        $clip .= "rsync -vv $ctrl->{'adbrsyncopt'} $rsyncpath$fname 127.0.0.1:$path$fname\n";

        $clip .= "adb pull \"$path$fname\" \"$pcpath$fname\"\n";
        $clip .= "adb push \"$pcpath$fname\" \"$path$fname\"\n";
        $clip .= "$pcpath$fname\n";

        $clip .= "ssh 127.0.0.1 -p 30339 'cat /sdcard/l00httpd/.whoami'\n";
        $clip .= "perl ${pcpath}adb.pl ${pcpath}adb.in\n";
        $clip .= "${pcpath}adb.in\n";

#       # append in RAM
#       &l00freadOpen($ctrl, 'l00://pcSyncCmdline');
#       $tmp = &l00freadAll($ctrl);
#       if (!defined($tmp)) {
#           $tmp = '';
#       }
        &l00fwriteOpen($ctrl, 'l00://pcSyncCmdline');
#       &l00fwriteBuf($ctrl, "$tmp\n$clip\n");
        &l00fwriteBuf($ctrl, "$clip\n");
        &l00fwriteClose($ctrl);

        $clip = urlencode ($clip);

        $buf = "View <a href=\"/view.htm?path=l00://pcSyncCmdline\">l00://pcSyncCmdline</a>. \n"
                . "Send the following lines to the <a href=\"/clip.htm?update=Copy+to+clipboard&clip=$clip\">clipboard</a>:<p>\n"
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
    my ($clip, $fhdl);

#   $ctrl{'os'} = 'win';
#   $ctrl{'os'} = 'rhc';
#   $ctrl{'os'} = 'lin';

    if ($ctrl->{'os'} eq 'and') {
        $buf = $ctrl->{'droid'}->getClipboard();
        $buf = $buf->{'result'};
    } elsif ($ctrl->{'os'} eq 'win') {
        # Use Perl module
        if ($usewinclipboard == 0) {
            $usewinclipboard =  1;
            eval 'use Win32::Clipboard';
        }
        $clip = Win32::Clipboard();
        $buf = $clip->Get();
    } elsif ($ctrl->{'os'} eq 'cyg') {
        local $/ = undef;
        if (open($fhdl,"</dev/clipboard")) {
            $buf = <$fhdl>;
            close($fhdl);
        }
    } elsif ($ctrl->{'os'} eq 'tmx') {
        $buf = `termux-clipboard-get`;
    } else {
        # Linux, using xclip
        $buf = `xclip -sel clip -o`;
    }
    if (!defined ($buf)) {
        $buf = ''; }

    $buf;
}

#&l00httpd::l00setCB($ctrl, $buf);
sub l00setCB {
    my ($ctrl, $buf) = @_;
    my ($clip, $fhdl);

    &l00fwriteOpen($ctrl, 'l00://clipboard.txt');
    &l00fwriteBuf($ctrl, $buf);
    &l00fwriteClose($ctrl);

    if ($ctrl->{'os'} eq 'and') {
        $ctrl->{'droid'}->setClipboard ($buf);
    } elsif ($ctrl->{'os'} eq 'cyg') {
        # ::todo:: add windows special character escape
#        $buf =~ s/\\/\\\\/g;
#        $buf =~ s/\n//g;
#        $buf =~ s/\r//g;

#        $buf =~ s/\\/\\\\/gm;
#        $buf =~ s/\//\\\//gm;
#        $buf =~ s/|/\|/gm;
#        $buf =~ s/\(/\\\(/gm;
#        $buf =~ s/\)/\\\)/gm;
#        $buf =~ s/'/\\'/gm;
        if (open($fhdl,">/dev/clipboard")) {
            print $fhdl $buf;
            close($fhdl);
        }
    } elsif ($ctrl->{'os'} eq 'win') {
        # Use Perl module
        if ($usewinclipboard == 0) {
            $usewinclipboard =  1;
            eval 'use Win32::Clipboard';
        }
        $clip = Win32::Clipboard();
        $clip->Set($buf);
    } elsif ($ctrl->{'os'} eq 'tmx') {
        $buf =~ s/\\/\\\\\\\\/gm;
        $buf =~ s/"/\\"/gm;
        `termux-clipboard-set "$buf"`;
    } else {
        # Linux, using xclip
        my ($pid);
        if ($pid = fork) {
        } else {
            # http://www.oreilly.com/openbook/cgi/ch10_10.html
            # child process
            system ("echo -n \"$buf\" | xclip -sel clip");
            exit (0);
        }
    }
if(0){
#           # launch editor
#           if (defined ($form->{'exteditor'})) {
#               if ($ctrl->{'os'} eq 'and') {
#                   $ctrl->{'droid'}->startActivity("android.intent.action.VIEW", "file://$path2", "text/plain");
#               } elsif (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
#                   my ($pid);
#                   if ($pid = fork) {
#                   } else {
#                       # http://www.oreilly.com/openbook/cgi/ch10_10.html
#                       # child process
#                       $_ = $path2;
#                       s/\//\\/g;
#                       system ("cmd /c \"start notepad ^\"$path2^\"\"");
#                       exit (0);
#                   }
#               }
#           }
}
}

#&l00httpd::l00PopMsg($ctrl, $buf);
sub l00PopMsg {
    my ($ctrl, $buf) = @_;

    if (defined($ctrl->{'toastapp'}) && 
        (-f $ctrl->{'toastapp'}) && 
        defined($ctrl->{'toastopt'})) {
print "TOAST : $ctrl->{'toastapp'} $ctrl->{'toastopt'}\n";
        `$ctrl->{'toastapp'} $ctrl->{'toastopt'} $buf`;
    } elsif ($ctrl->{'os'} eq 'and') {
        $ctrl->{'droid'}->makeToast($buf);
    } elsif ($ctrl->{'os'} eq 'win') {
        `msg %USERNAME% /TIME:1 $buf`;
    }

}


my @mname = ( "Jan", "Feb", "Mar", "Apr", "May", "Jun",
"Jul", "Aug", "Sep", "Oct", "Nov", "Dec");

#&l00httpd::android_get_gps($ctrl, $known0loc1, $lastgps);
sub android_get_gps {
    my ($ctrl, $known0loc1, $lastgps) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($tim, $out, $tmp, $lons, $lats);
    my ($gps, $coor, $src, $NS, $EW);
    my ($lat, $lon, $lastcoor, $lastres);


    $out = 'No GPS support';
    $lat = 0;
    $lon = 0;
    $lastcoor = '0,0';
    $lastres = '';

    if ($ctrl->{'os'} eq 'and') {
        if ($known0loc1 == 0) {
            $gps = $ctrl->{'droid'}->getLastKnownLocation();
        } else {
            $gps = $ctrl->{'droid'}->readLocation();
        }
        #&l00httpd::dumphash ("gps", $gps);

        if (ref $gps->{'result'}->{'network'} eq 'HASH') {
            $lastres = "        $lastgps";
            $coor = $gps->{'result'}->{'network'};
            $src = 'network';
        }
        # 'network' is always available whenever phone is on GSM network
        # put 'gps' second so as to always use gps even when network 
        # is available.
        if (ref $gps->{'result'}->{'gps'} eq 'HASH') {
            $lastres = "    $lastgps";
            $coor = $gps->{'result'}->{'gps'};
            $src = 'gps';
        }
        if (defined ($coor)) {
            $lastgps = time;
            $lastres .= " = $ctrl->{'now_string'}\n";

            $tmp = $lastgps - ($coor->{'time'} / 1000);
            $lastres .= "$coor->{'provider'}@"."$coor->{'time'} diff=$tmp s\n";

            $lon = $coor->{'longitude'};
            $lat = $coor->{'latitude'};
            $lastcoor = sprintf ("%15.10f,%14.10f", $lat, $lon);
            $tim = substr ($coor->{'time'}, 0, 10);
            my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($tim);
            if ($lon > 0) {
                $EW = "E";
                $lons = $lon;
            } else {
                $EW = "W";
                $lons = -$lon;
            }
            if ($lat > 0) {
                $NS = "N";
                $lats = $lat;
            } else {
                $NS = "S";
                $lats = -$lat;
            }
            #T  N2226.76139 E11354.35311 30-Dec-89 23:00:00 -9999
            $out = sprintf ("T  %s%02d%08.5f %s%03d%08.5f %02d-%s-%02d %02d:%02d:%02d % 4d ; $src $ctrl->{'now_string'}",
                $NS, int ($lats), ($lats - int ($lats)) * 60,
                $EW, int ($lons), ($lons - int ($lons)) * 60,
                $mday, $mname [$mon], $year % 100, $hour, $min, $sec, $coor->{'altitude'});
        }
    }

    ($out, $lat, $lon, $lastcoor, $lastgps, $lastres);
}


sub time2now_string {
    my ($time) = @_;
    my ($now_string);
    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime ($time);

    $now_string = sprintf ("%4d%02d%02d %02d%02d%02d", $year + 1900, $mon+1, $mday, $hour, $min, $sec);

    $now_string;
}


sub now_string2time {
    my ($now_string) = @_;
    my ($time, $year,$mon,$mday,$hour,$min,$sec);

    if (($year,$mon,$mday,$hour,$min,$sec) = $now_string =~ 
        /(\d\d\d\d)(\d\d)(\d\d) (\d\d)(\d\d)(\d\d)/) {
        $year -= 1900;
        $mon--;
        $time = &l00mktime::mktime ($year, $mon, $mday, $hour, $min, $sec);
    } else {
        $time = 0;
    }


    $time;
}



1;
