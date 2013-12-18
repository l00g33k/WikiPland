# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14
use warnings;
use strict;

package l00httpd;

#use l00httpd;      # used for findInBuf

my ($readName, $readBuf, @readAllLines, $readIdx, $writeName, $writeBuf);
my ($debuglog, $debuglogstate);

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
        } else {
            $desc = '(???)';
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

    if (length($debuglog) > 200000) {
        $debuglog = substr($debuglog, length($debuglog) - 200000, 200000);
    }

    1;
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
    my ($hit, $found, $blocktext, $line, $pattern);

 
    # find them
    $hit = 0;
    $found = '';
    $blocktext = '';
    foreach $line (split ("\n", $buf)) {
        # remove %l00httpd:lnno:$lnno% metadata
		$line =~ s/^%l00httpd:lnno:\d+%//;
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
            $blocktext .= "$line\n";
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
            $blocktext .= "$line\n";
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

#&l00httpd::readOpen($ctrl, $fname);
sub readOpen {
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

#$buf = &l00httpd::readAll($ctrl);
sub readAll {
    my ($ctrl) = @_;

    $readBuf;
}

#$buf = &l00httpd::readLine($ctrl);
sub readLine {
    my ($ctrl) = @_;
    my ($buf);

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

    $buf;
}


#my ($readName, $readBuf, @readAllLines, $writeName, $writeBuf);
#
#&l00httpd::writeOpen($ctrl, $fname);
sub writeOpen {
    my ($ctrl, $fname) = @_;

    $writeName = $fname;
    $writeBuf = '';

    1;
}

#&l00httpd::writeBuf($ctrl, $buf);
sub writeBuf {
    my ($ctrl, $buf) = @_;

    $writeBuf .= $buf;

    1;
}

#&l00httpd::writeClose($ctrl);
sub writeClose {
    my ($ctrl) = @_;

    if ($writeName =~ /^l00:\/\/./) {
        # ram file
        $ctrl->{'l00file'}->{$writeName} = $writeBuf;
    } else {
	    if (open(OU, ">$writeName ")) {
            print OU $writeBuf;
			close (OU);
		}
    }
    1;
}

#
#&l00backup::backupfile ($ctrl, $form->{'path'}, 1, 5);
#



1;

