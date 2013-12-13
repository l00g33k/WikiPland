use strict;
use warnings;
use l00wikihtml;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Converting tab delimited data (e.g. copied from Excel)
# and making constant width for easy viewing with fixed
# width font (e.g. vi of programmer's editor)

my %config = (proc => "l00http_dirnotes_proc",
              desc => "l00http_dirnotes_desc");
my ($buffer, $pre, $tblhdr, $tbl, $post, @width, @cols, $ii);
my (@modcmds, $modadd, $modcopy, $moddel, $modrow, $mod, $modtab);
my ($nocols, $norows, @rows, @keys, @order);
my (@allkeys, $sortdebug, @tblbdy);


sub l00http_dirnotes_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "dirnotes: Directory notes";
}



sub l00http_dirnotes_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno, $ii, $delnew);
    my ($dir, $file, $url, @flds, $noflds, %flindir, $fname, $fstamps);
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtime, $ctime, $blksize, $blocks);
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst, $find, $found);


    $url = '';

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} .$ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a> \n";
    if (defined ($form->{'path'})) {
        print $sock "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a> \n";
        # create shell script for vi
    }
    print $sock "<a href=\"#end\">Jump to end</a><hr>\n";

    if (defined ($form->{'find'})) {
        $find = $form->{'find'};
        if ($find =~ /^ *$/) {
            # form always defines it but may be blank
            $find = '';
        } elsif (!($find =~ /\(.+\)/)) {
            # must have ()
            $find = "($find)";
        }
    } else {
        $find = '';
    }

    $buffer = '';
    if ((defined ($form->{'path'})) && (length ($form->{'path'}) > 0)) {
        if (open (IN, "<$form->{'path'}")) {
            # http://www.perlmonks.org/?node_id=1952
            local $/ = undef;
            $buffer = <IN>;
            close (IN);
        }
        $url = "* [[/dirnotes.pl?path=$form->{'path'}|Run dirnotes]] [[/table.pl?path=$form->{'path'}|table edit dirnotes]]\n";
    }

    # scan directory
    $dir = '.';
    if ((defined ($form->{'path'})) && (length ($form->{'path'}) > 0)) {
        if ($form->{'path'} =~ m|^(.+)/[^/]+$|) {
            $dir = $1;
            if (opendir (DIR, $dir)) {
                foreach $file (sort readdir (DIR)) {
                    if (-f "$dir/$file") {
                        if (($file ne '.') && 
                            ($file ne '..') &&
                            !($file =~ /\.bak$/)) {
                            $flindir {$file} = 1;
                        }
                    }
                }
            }
        }
    }

    # extract texts before and after table 
    $pre = "";
    $tbl = "";
    $post = "";
    $buffer =~ s/\r//g;
    $noflds = 0;
    @alllines = split ("\n", $buffer);
    foreach $line (@alllines) {
        if ($line =~ /dirnotes\.pl/) {
            $url = '';
        }
        if ($line =~ /^\|\|[^|]/) {
            # seeing table
            ($fname, @flds) = split ('\|\|', $line);
            #why $fname is blank?
            ($fname, @flds) = @flds;
            $noflds = $#flds; # 1 less
            if ($fname =~ />(.+)</) {
                $fname = $1;
            }
            $fname =~ s/^ +//;
            $fname =~ s/ +$//;
            if (defined ($flindir {$fname})) {
                $flindir {$fname} = 0;
                # makes $delnew double duty to also report $find results
                if ($find ne '') {
                    $found = '';
                    if (open (IN, "<$dir/$fname")) {
                        while (<IN>) {
                            if (/$find/) {
                                $found = $1;
                            }
                        }
                    }
                    $delnew = "$found|| ";
                } else {
                    $delnew = ' ';
                }
                ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
                 $size, $atime, $mtime, $ctime, $blksize, $blocks)
                 = stat("$dir/$fname");
                ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
                 = localtime($mtime);
                $fstamps = sprintf ("%4d/%02d/%02d %02d:%02d:%02d", 1900+$year, 1+$mon, $mday, $hour, $min, $sec);
                $fname = "<a href=\"/ls.htm/$fname.htm?path=$dir/$fname\">$fname</a>";
            } else {
                $delnew = 'deleted';
                $fstamps = 'missing';
                if ($find ne '') {
                    $delnew = " ||deleted";
                }
            }
            $line = "||" . join('||', ($fname, $delnew, "\@$fstamps", @flds))."||";
            $tbl .= $line . "\n";
        } else {
            if ($tbl eq "") {
                $pre .= $line . "\n";
            } else {
                $post .= $line . "\n";
            }
        }
    }

    foreach $fname (sort keys %flindir) {
        if ($flindir {$fname} == 1) {
            ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
             $size, $atime, $mtime, $ctime, $blksize, $blocks)
             = stat("$dir/$fname");
            ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
             = localtime($mtime);
            $fstamps = sprintf ("%4d/%02d/%02d %02d:%02d:%02d", 1900+$year, 1+$mon, $mday, $hour, $min, $sec);
            # makes $delnew double duty to also report $find results
            if ($find ne '') {
                $found = '';
                if (open (IN, "<$dir/$fname")) {
print "$dir/$fname $find\n";
                    while (<IN>) {
                        if (/$find/) {
                            $found = $1;
                        }
                    }
                }
                $delnew = "$found|| ";
            } else {
                $delnew = 'new';
            }
            $line = "||$fname||$delnew||\@$fstamps||" . ("_||" x ($noflds + 1));
            $tbl .= $line . "\n";
        }
    }

    # glue it together
    $buffer = $pre . $url . $tbl . $post;

    # if save to file
    if ((defined ($form->{'save'}) &&
        (defined ($form->{'path'})) && 
        (length ($form->{'path'}) > 0))) {
        &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 5);
        if (open (OUT, ">$form->{'path'}")) {
            # http://www.perlmonks.org/?node_id=1952
            print OUT $buffer;
            close (OUT);
        } else {
            print $sock "Unable to write '$form->{'path'}'<p>\n";
        }
    }

    # generate HTML buttons, etc.

    # save
    print $sock "<form action=\"/dirnotes.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"save\" value=\"Save to file\">\n";
    print $sock "<input type=\"submit\" name=\"refresh\" value=\"Refresh\">\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "<p>Find: <td><input type=\"text\" size=\"12\" name=\"find\" value=\"$find\"> for .txt only</td>\n";
    print $sock "</form>\n";

    print $sock &l00wikihtml::wikihtml ($ctrl, $ctrl->{'plpath'}, $buffer, 0);
    print $sock "<hr><a name=\"end\"></a>\n";
 
    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
