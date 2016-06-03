use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my %config = (proc => "l00http_md5sizediff_proc",
              desc => "l00http_md5sizediff_desc");
my ($thispath, $thatpath, $mode, $unixhdr, $unixhdr2, $unixftr);
my ($unixhdrdup, $unixhdronly, $unixhdrdiff, $unixhdrsame, $progressstep);
$thispath = '';
$thatpath = '';
$mode = 'text';
$progressstep = 1000;

$unixhdr = <<markunixhdr;
#!/bin/sh
#set -x

# This file is:
markunixhdr

$unixhdr2 = <<markunixhdr2;

# This is a recursive script. The initial invocation is without 
# arguments. It falls to the else clause which invokes itself 
# with partial path to the duplicated target files.
# The default implementation keeps the first file as the reference
# and verifies that the second and onwards are identical to 
# the first and then delete them.

# Save this file as 'm5script.sh' or change this variable:
SCRIPT=./m5script.sh

COPYDIR=/copy/to/

if [ \$# != 0 ]; then
    # Sample invocation: \$0 dir1/file1 dir2/file2 dir3/file3

    if [ \$# -eq 1 ]; then
        ONLYFILE=\$1
        # just one file, must be this only or that only
        # or same in both
        echo ONLY/SAME "\$ONLYFILE"
        if [ -f "\$BASEDIR\$ONLYFILE" ]; then
            echo will cp "\$BASEDIR\$ONLYFILE" "\$COPYDIR\$ONLYFILE"
            echo will rm "\$BASEDIR\$ONLYFILE"
        fi
    else
        FILE2KEEP=\$1
        # while there are two or more arguments
        while [ \$# -gt 1 ]; do
            FILE2RM=\$2
            diff "\$BASEDIR\$FILE2KEEP" "\$BASEDIR\$FILE2RM"
            if [ \$? == 0 ]; then
                echo SAME "\$BASEDIR\$FILE2KEEP" "\$BASEDIR\$FILE2RM"
                # uncomment one of these
                echo will rm "\$BASEDIR\$FILE2KEEP"
                echo will rm "\$BASEDIR\$FILE2RM"
            else
                echo DIFF "\$BASEDIR\$FILE2KEEP" "\$BASEDIR\$FILE2RM"
            fi
            # pop deleted file
            shift
        done
    fi

else
markunixhdr2


$unixhdrdup = <<markunixhdrdup;
#!/bin/sh
#set -x

# This is a recursive script. The initial invocation is without 
# arguments. It falls to the else clause which invokes itself 
# with partial path to the duplicated target files.
# The default implementation keeps the first file as the reference
# and verifies that the md5sum is as expected. It then deletes all 
# other files with matching md5sum. Files with unmatched md5sum 
# are kept.

# You need to delete 'CMD4DUP=echo' below so 'CMD4DUP=rm' takes effect


if [ \$# != 0 ]; then
    # Sample invocation: \$0 dir1/file1 dir2/file2 dir3/file3

    if [ \$# -lt 2 ]; then
        printf "Incorrect usage\\n"
    else
        MD5SUM=\$1
        shift
        FILE2KEEP=\$1
        shift

        let UNIQUEFIL+=1

        # verify md5sum match
        printf "### \$MD5SUM (# \$UNIQUEFIL)\\n" >> \$SCRIPT.log
        printf "    " >> \$SCRIPT.log
        md5sum "\$BASEDIR\$FILE2KEEP" | grep \$MD5SUM >> \$SCRIPT.log
        if [ \$? -ne 0 ]; then
            printf "!!!     keep file md5sum UNEXPECTED\\n" >> \$SCRIPT.log
            let FILEBADM5+=1
        else
            while [ \$# -ge 1 ]; do
                FILE2DEL=\$1
                printf "    " >> \$SCRIPT.log
                md5sum "\$BASEDIR\$FILE2DEL" | grep \$MD5SUM >> \$SCRIPT.log
                if [ \$? -eq 0 ]; then
                    printf "        md5sum match: \$CMD4DUP \\\"\$BASEDIR\$FILE2DEL\\\"\\n" >> \$SCRIPT.log
                    \$CMD4DUP "\$BASEDIR\$FILE2DEL" >> \$SCRIPT.log
                    let FILEDELET+=1
                else
                    printf "!!!       md5sum UNEXPECTED: \\\"\$BASEDIR\$FILE2DEL\\\"\\n" >> \$SCRIPT.log
                    let FILEBADM5+=1
                fi
                # pop deleted file
                shift
            done
        fi
    fi
    # pause per set. Comment out for non stop run
    #read

else
#fi
# To make a shorter script file for faster run, uncomment fi above 
# and delete everything below this line

    UNIQUEFIL=0
    FILEDELET=0
    FILEBADM5=0

    CMD4DUP=rm
    CMD4DUP='echo WILL RM '

markunixhdrdup


$unixhdronly = <<markunixhdronly;

# This is a recursive script. The initial invocation is without 
# arguments. It falls to the else clause which invokes itself 
# with partial path to the duplicated target files.
# The default implementation keeps the first file as the reference
# and verifies that the second and onwards are identical to 
# the first and then delete them.

# Save this file as 'm5script.sh' or change this variable:
SCRIPT=./m5script.sh

COPYDIR=/copy/to/

if [ \$# != 0 ]; then
    # Sample invocation: \$0 dir1/file1 dir2/file2 dir3/file3

    if [ \$# -eq 1 ]; then
        ONLYFILE=\$1
        # just one file, must be this only or that only
        # or same in both
        echo ONLY/SAME "\$ONLYFILE"
        if [ -f "\$BASEDIR\$ONLYFILE" ]; then
            echo will cp "\$BASEDIR\$ONLYFILE" "\$COPYDIR\$ONLYFILE"
            echo will rm "\$BASEDIR\$ONLYFILE"
        fi
    else
        FILE2KEEP=\$1
        # while there are two or more arguments
        while [ \$# -gt 1 ]; do
            FILE2RM=\$2
            diff "\$BASEDIR\$FILE2KEEP" "\$BASEDIR\$FILE2RM"
            if [ \$? == 0 ]; then
                echo SAME "\$BASEDIR\$FILE2KEEP" "\$BASEDIR\$FILE2RM"
                # uncomment one of these
                echo will rm "\$BASEDIR\$FILE2KEEP"
                echo will rm "\$BASEDIR\$FILE2RM"
            else
                echo DIFF "\$BASEDIR\$FILE2KEEP" "\$BASEDIR\$FILE2RM"
            fi
            # pop deleted file
            shift
        done
    fi

else
markunixhdronly


$unixhdrdiff = <<markunixhdrdiff;

# This is a recursive script. The initial invocation is without 
# arguments. It falls to the else clause which invokes itself 
# with partial path to the duplicated target files.
# The default implementation keeps the first file as the reference
# and verifies that the second and onwards are identical to 
# the first and then delete them.

# Save this file as 'm5script.sh' or change this variable:
SCRIPT=./m5script.sh

COPYDIR=/copy/to/

if [ \$# != 0 ]; then
    # Sample invocation: \$0 dir1/file1 dir2/file2 dir3/file3

    if [ \$# -eq 1 ]; then
        ONLYFILE=\$1
        # just one file, must be this only or that only
        # or same in both
        echo ONLY/SAME "\$ONLYFILE"
        if [ -f "\$BASEDIR\$ONLYFILE" ]; then
            echo will cp "\$BASEDIR\$ONLYFILE" "\$COPYDIR\$ONLYFILE"
            echo will rm "\$BASEDIR\$ONLYFILE"
        fi
    else
        FILE2KEEP=\$1
        # while there are two or more arguments
        while [ \$# -gt 1 ]; do
            FILE2RM=\$2
            diff "\$BASEDIR\$FILE2KEEP" "\$BASEDIR\$FILE2RM"
            if [ \$? == 0 ]; then
                echo SAME "\$BASEDIR\$FILE2KEEP" "\$BASEDIR\$FILE2RM"
                # uncomment one of these
                echo will rm "\$BASEDIR\$FILE2KEEP"
                echo will rm "\$BASEDIR\$FILE2RM"
            else
                echo DIFF "\$BASEDIR\$FILE2KEEP" "\$BASEDIR\$FILE2RM"
            fi
            # pop deleted file
            shift
        done
    fi

else
markunixhdrdiff


$unixhdrsame = <<markunixhdrsame;
#!/bin/sh
#set -x

# TBD...
# This is a recursive script. The initial invocation is without 
# arguments. It falls to the else clause which invokes itself 
# with partial path to the duplicated target files.
# The default implementation keeps the first file as the reference
# and verifies that the md5sum is as expected. It then deletes all 
# other files with matching md5sum. Files with unmatched md5sum 
# are kept.
# It uses 'source' because invoking another instance of itself 
# does not work with Android TerminalIDE and I need it to work
# on unrooted Android

# You need to delete 'CMD4DUP=echo' below so 'CMD4DUP=rm' takes effect


if [ \$# != 0 ]; then
    # Sample invocation: \$0 dir1/file1 dir2/file2 dir3/file3

    if [ \$# -ne 3 ]; then
        printf "!!!     Wrong number of arguments\\n"
    else
        MD5SUM=\$1
        #DELFILE=\$2
        DELFILE=\$3

        #CMDSAME=rm
        CMDSAME=echo

        let UNIQUEFIL+=1

        # verify md5sum match
        printf "### \$MD5SUM\\n" >> \$SCRIPT.log
        printf "    " >> \$SCRIPT.log
        md5sum "\$BASEDIR\$DELFILE" | grep \$MD5SUM >> \$SCRIPT.log
        if [ \$? -eq 0 ]; then
            printf "        md5sum match: \$CMDSAME '\$BASEDIR\$DELFILE'\\n" >> \$SCRIPT.log
            \$CMDSAME "\$BASEDIR\$DELFILE" >> \$SCRIPT.log
            let FILEDELET+=1
        else
            printf "!!!     md5sum UNEXPECTED: \$BASEDIR\$DELFILE\\n" >> \$SCRIPT.log
            let FILEBADM5+=1
        fi
    fi

else
    printf "Starting \$SCRIPT\\n" > \$SCRIPT.log

    UNIQUEFIL=0
    FILEDELET=0
    FILEBADM5=0


markunixhdrsame


$unixftr = <<markunixftr;
fi
markunixftr

sub l00http_md5sizediff_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "md5sizediff: diff directory trees using externally computed md5sum";
}

sub l00http_md5sizediff_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($jumper, %bymd5sum, %byname, %sizebymd5sum, $side, $sname, $files, $file, $cnt);
    my ($dummy, $size, $md5sum, $pfname, $pname, $fname);
    my (%cnt, $oname, %out, $idx, $md5sum1st, $ii);
    my ($match, $matchcnt, $matchnone, $matchone, $matchmulti, $matchlist);
    my (@lmd5sum, @rmd5sum, $common, $orgpath, %orgdir, $thisname, $thatname, $orgname);
    my ($thisonly, $thatonly, $diffmd5sum, $samemd5sum);

    if (defined ($form->{'mode'})) {
        if ($form->{'mode'} eq 'dos') {
            $mode = 'dos';
        } elsif ($form->{'mode'} eq 'unix') {
            $mode = 'unix';
        } else {
            $mode = 'text';
        }
    }
    if (defined ($form->{'compare'})) {
        # compare defined, i.e. clicked. Get from form
        if (defined ($form->{'path'})) {
            $thispath = $form->{'path'};
        }
        if (defined ($form->{'path2'})) {
            $thatpath = $form->{'path2'};
        }
    } else {
        # compare not defined, i.e. not click, push 
        $thatpath = $thispath;
        if (defined ($form->{'path'})) {
            $thispath = $form->{'path'};
        }
    }
    if (defined ($form->{'match'})) {
        $match = $form->{'match'};
    } else {
        $match = '';
    }



    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    if ((defined ($thispath) && 
        (length ($thispath) > 0))) {
        $thispath =~ s/\r//g;
        $thispath =~ s/\n//g;
        $_ = $thispath;
        # keep path only
        s/\/[^\/]+$/\//;
        print $sock " Path: <a href=\"/ls.htm?path=$_\">$_</a>";
        $_ = $thispath;
        # keep name only
        s/^.+\/([^\/]+)$/$1/;
        print $sock "<a href=\"/view.htm?path=$thispath\">$_</a>\n";
    }
    print $sock "<p>\n";


    # copy paste target
    if (defined ($form->{'paste4'})) {
        $thispath = &l00httpd::l00getCB($ctrl);
    }
    if (defined ($form->{'paste2'})) {
        $thatpath = &l00httpd::l00getCB($ctrl);
    }

    # compare
    if (!defined ($thatpath)) {
        $thatpath = '';
    }
    if ((defined ($form->{'compare'})) &&
        (defined ($thispath) && 
        (length ($thispath) > 0))) {

        $jumper = "    ".
             "<a href=\"#top\">top</a> ".
             "<a href=\"#dup_THIS\">(dupe this</a> ".
             "<a href=\"#dup_THAT\">that)</a> ".
             "<a href=\"#this_only\">(only this</a> ".
             "<a href=\"#that_only\">that)</a> ".
             "<a href=\"#changed\">changed</a> ".
             "<a href=\"#same\">same</a> ".
             "<a href=\"#end\">end</a> ".
             "\n";

        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} = '';
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<pre>\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper\n";
        print $sock "<pre>\n";
        print $sock "$jumper\n";

        # read in this and that files
        # ----------------------------------------------------------------
        undef %bymd5sum;
        undef %byname;
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "Read input files:\n\n";
        print $sock "Read input files:\n\n";
        # file names only of input files
        $thisname = '';
        $thatname = '';
        foreach $side (($thispath, $thatpath)) {
            if ($side eq $thispath) {
                $sname = 'THIS';
            } else {
                $sname = 'THAT';
            }
            $files = 0;
            $orgdir{$sname} = '';
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$sname side: $side\n";
            print $sock "$sname side: $side\n";
            # split combined input files for each side
            foreach $file (split('\|\|', $side)) {
                $cnt = 0;
                if ((length($file) > 0) && 
                    &l00httpd::l00freadOpen($ctrl, $file)) {
                    if ($sname eq 'THIS') {
                        if ($thisname eq '') {
                            $thisname = $file;
                            $thisname =~ s/^.+\/([^\/]+)$/$1/;
                        }
                    } else {
                        if ($thatname eq '') {
                            $thatname = $file;
                            $thatname =~ s/^.+\/([^\/]+)$/$1/;
                        }
                    }
                    while ($_ = &l00httpd::l00freadLine($ctrl)) {
                        s/ <dir>//g;
                        s/\r//;
                        s/\n//;
                        if (/^\|\|/) {
                            ($dummy, $size, $md5sum, $pfname) = split('\|\|', $_);
                            $size   =~ s/^ *//;
                            $md5sum =~ s/^ *//;
                            $pfname =~ s/^ *//;
                            $size   =~ s/ *$//;
                            $md5sum =~ s/ *$//;
                            $pfname =~ s/ *$//;
                            ($pname, $fname) = $pfname =~ /^(.+[\\\/])([^\\\/]+)$/;
                            $fname = lc($fname);
                            $bymd5sum{$sname}{$md5sum}{$pfname} = $fname;
                            $byname{$sname}{$fname}{$md5sum} = $pfname;
                            $sizebymd5sum{$md5sum} = $size;
                            $cnt++;
                        } elsif (/^\* (.+)/) {
                            if ($orgdir{$sname} ne '') {
                                $orgdir{$sname} .= '||';
                            }
                            $orgdir{$sname} .= $1;
                        }
                    }
                }
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "Read $sname $cnt: $files:$file\n";
                print $sock "Read $sname $cnt: $files:$file\n";
                $files++;
            }
        }



        # files duplicated within each side
        # ----------------------------------------------------------------
        $cnt{'THIS'} = 0;
        $cnt{'THAT'} = 0;
        foreach $sname (('THIS', 'THAT')) {
            # for each side
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<a name=\"dup_$sname\"></a>";
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper";
            print $sock "<a name=\"dup_$sname\"></a>";
            print $sock "----------------------------------------------------------\n";
            print $sock "$jumper";
            if ($sname eq 'THIS') {
                $orgpath = $thispath;
                $orgname = $thisname;
            } else {
                $orgpath = $thatpath;
                $orgname = $thatname;
            }
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "    $sname duplicated md5sum: $orgpath\n\n";
            print $sock "    $sname duplicated md5sum: $orgpath\n\n";

            if ($mode eq 'unix') {
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} = 
                    "$unixhdrdup".
                    "    # '$sname.self_dup' from $orgpath\n".
                    "    # org dir: $orgdir{$sname}\n\n".
                    "    BASEDIR=$orgdir{$sname}\n".
                    "    # Save this file as '$orgname.THIS.self_dup.sh' or change this variable:\n".
                    "    SCRIPT=\${BASEDIR}../$orgname.THIS.self_dup.sh\n\n".
                    "    if [ -f \$SCRIPT ]; then\n".
                    "        printf \"Starting \$SCRIPT\\n\" > \$SCRIPT.log\n";
            } elsif ($mode eq 'dos') {
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} = "\@echo off\n";
            } else {
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} = '';
            }
            # count $match
            $matchnone = 0;
            $matchone = 0;
            $matchmulti = 0;
            foreach $md5sum (sort keys %{$bymd5sum{$sname}}) {
                # for each md5sum
                if ($md5sum ne '00000000000000000000000000000000') {
                    # not a directory
                    @_ = (sort keys %{$bymd5sum{$sname}{$md5sum}});
                    # is there more than one file name recorded?
                    if ($#_ > 0) {
                        $matchlist = '';
                        if ($match ne '') {
                            # count match
                            $matchcnt = 0;
                            # find match
                            for ($ii = 0; $ii <= $#_; $ii++) {
                                if ($_[$ii] =~ /$match/) {
                                    $matchcnt++;
                                    if ($mode eq 'unix') {
                                        $matchlist .= "  \"$_[$ii]\"";
                                    } else {
                                        $matchlist .= "         \"$_[$ii]\"\n";
                                    }
                                }
                            }
                            if ($matchcnt == 0) {
                                $matchnone++;
                            } elsif ($matchcnt == 1) {
                                $matchone++;
                            } else {
                                $matchmulti++;
                            }
                            # find not match
                            for ($ii = 0; $ii <= $#_; $ii++) {
                                if (!($_[$ii] =~ /$match/)) {
                                    if ($mode eq 'unix') {
                                        $matchlist .= "  \"$_[$ii]\"";
                                    } else {
                                        $matchlist .= "         \"$_[$ii]\"\n";
                                    }
                                }
                            }
                        } else {
                            # no match regex, list all
                            for ($ii = 0; $ii <= $#_; $ii++) {
                                if ($mode eq 'unix') {
                                    $matchlist .= "  \"$_[$ii]\"";
                                } else {
                                    $matchlist .= "         \"$_[$ii]\"\n";
                                }
                            }
                        }

                        # $_ is number of dups
                        $_ = $#_ + 1;
                        if ($mode eq 'unix') {
                            for ($ii = 0; $ii <= $#_; $ii++) {
                                $_[$ii] =~ s/^\.[\\\/]//;
                            }
                            if ($matchcnt != 1) {
                                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= 
                                    "        # matchcnt: $matchcnt\n";
                            }
                            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= 
                                sprintf ("        #   %03d: dup: $_ files $sizebymd5sum{$md5sum} $md5sum --- $_[0]\n",   $cnt{$sname}).
                                "        source \$SCRIPT  $md5sum $matchlist\n";
                            if (($cnt{$sname} > 0) && ($cnt{$sname} % $progressstep) == 0) {
                                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= 
                                    "        echo $cnt{$sname} files\n";
                            }
                        } elsif ($mode eq 'dos') {
                            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= 
                                sprintf ("rem %03d: dup: $_ files $sizebymd5sum{$md5sum} $md5sum --- $_[0]\n", $cnt{$sname}).
                                "$matchlist\n";
                        } else {
                            if ($matchcnt != 1) {
                                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= 
                                         "    # matchcnt: $matchcnt\n";
                            }
                            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= 
                                sprintf ("    %03d: dup: $_ files $sizebymd5sum{$md5sum} $md5sum --- $_[0]\n", $cnt{$sname}).
                                "$matchlist\n";
                        }
                        #print $sock "md5sum $sname: $#_ md5sum $md5sum:\n   ".join("\n   ", @_)."\n";
                        $cnt{$sname}++;
                    }
                }
            }
            # create $match output
            if ($match ne '') {
                $_ = "Unique files: $cnt{$sname}; matched: none: $matchnone, one: $matchone, more: $matchmulti (find '# matchcnt:')";
            } else {
                $_ = "Match regex not specified, not counting match";
            }
            if ($mode eq 'unix') {
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "        printf \"Processed \$UNIQUEFIL unique files\\n\"\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "        printf \"Processed \$UNIQUEFIL unique files\\n\" >> \$SCRIPT.log\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "        printf \"Deleted \$FILEDELET duplicated files\\n\"\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "        printf \"Deleted \$FILEDELET duplicated files\\n\" >> \$SCRIPT.log\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "        printf \"\$FILEBADM5 files have unexpected md5sum !!!\\n\"\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "        printf \"\$FILEBADM5 files have unexpected md5sum !!!\\n\" >> \$SCRIPT.log\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "        \n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "        printf \"*** About to launch less to review \$SCRIPT.log. ^C to cancel\\n\"\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "        read\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "        less -N \$SCRIPT.log\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "    else\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "        printf \"MISSING \$SCRIPT\\n\"\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "    fi\n\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "fi\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "\n# Match = >$match<\n# $_\n";
            } elsif ($mode eq 'dos') {
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "\nrem Match = >$match<\nrem $_\n";
            } else {
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "\nMatch = >$match<\n$_\n";
            }
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$sname self duplicated: $cnt{$sname} files\n\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "%INCLUDE<l00://md5sizediff.$sname.self_dup.htm>%\n";
            print $sock "$sname self duplicated: $cnt{$sname} files\n";
        }


        # Files unique to each side
        # ----------------------------------------------------------------
        if ($thatpath ne '') {
            # generate this only and that only if only both files are provided
            foreach $sname (('THIS', 'THAT')) {
                # for each side
                if ($sname eq 'THIS') {
                    $oname = 'THAT';
                    $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<a name=\"this_only\"></a>";
                    $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
                    $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper";
                    $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "    This only md5sum: $thispath\n\n";
                    print $sock "<a name=\"this_only\"></a>";
                    print $sock "----------------------------------------------------------\n";
                    print $sock "$jumper";
                    print $sock "    This only by md5sum: $thispath\n\n";
                } else {
                    $oname = 'THIS';
                    $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<a name=\"that_only\"></a>";
                    $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
                    $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper";
                    $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "    That only md5sum: $thatpath\n\n";
                    print $sock "<a name=\"that_only\"></a>";
                    print $sock "----------------------------------------------------------\n";
                    print $sock "$jumper";
                    print $sock "    That only by md5sum: $thatpath\n\n";
                }
                undef %out;
                $common = 0;
                foreach $md5sum (sort keys %{$bymd5sum{$sname}}) {
                    # for each md5sum here
                    if ($md5sum ne '00000000000000000000000000000000') {
                        $common++;
                    }
                    if (($md5sum ne '00000000000000000000000000000000') && !defined($bymd5sum{$oname}{$md5sum})) {
                        # not a directory and not there
                        @_ = (keys %{$bymd5sum{$sname}{$md5sum}});
                        $out{$_[0]} = $md5sum;
                    }
                }
                $cnt = 0;
                if ($mode eq 'unix') {
                    $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.only.htm"} = 
                        "$unixhdr".
                        "# '$sname.only' from $orgpath\n".
                        "# org dir: $orgdir{$sname}\n\n".
                        "BASEDIR=$orgdir{$sname}\n".
                        "BASEDIR=$orgdir{$sname}\n".
                        "$unixhdr2";
                } elsif ($mode eq 'dos') {
                    $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.only.htm"} = '';
                } else {
                    $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.only.htm"} = '';
                }
                foreach $pfname (sort keys %out) {
                    if ($mode eq 'unix') {
                        $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.only.htm"} .= 
                            sprintf ("    #   %03d: ${sname}.only: $pfname $sizebymd5sum{$out{$pfname}} $out{$pfname}\n", $cnt);
                        $pfname =~ s/^\.[\\\/]//;
                        $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.only.htm"} .= 
                            "    source \$SCRIPT  \"$pfname\"\n";
                        #printf $sock ("   %03d: $pfname $out{$pfname}\n", $cnt);
                        $cnt++;
                    } elsif ($mode eq 'dos') {
                        $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.only.htm"} .= sprintf ("   %03d: $pfname $sizebymd5sum{$out{$pfname}} $out{$pfname}\n", $cnt);
                        #printf $sock ("   %03d: $pfname $out{$pfname}\n", $cnt);
                        $cnt++;
                    } else {
                        $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.only.htm"} .= sprintf ("   %03d: $pfname $sizebymd5sum{$out{$pfname}} $out{$pfname}\n", $cnt);
                        #printf $sock ("   %03d: $pfname $out{$pfname}\n", $cnt);
                        $cnt++;
                    }
                }
                #print $sock "\n";
                if ($sname eq 'THIS') {
                    $thisonly = $cnt;
                    $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "This only: $cnt files (out of $common md5sum)\n\n";
                    print $sock "This only: $cnt files (out of $common same md5sum)\n";
                } else {
                    $thatonly = $cnt;
                    $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "That only: $cnt files (out of $common md5sum)\n\n";
                    print $sock "That only: $cnt files (out of $common same md5sum)\n";
                }
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "%INCLUDE<l00://md5sizediff.$sname.only.htm>%\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "\n";
            }
        } else {
            $ctrl->{'l00file'}->{"l00://md5sizediff.THAT.only.htm"} = '';
        }

        # files with different md5sum on both side
        # ----------------------------------------------------------------
        $sname = 'THIS';
        $oname = 'THAT';
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<a name=\"changed\"></a>";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "    Same name different md5sum\n\n";
        print $sock "<a name=\"changed\"></a>";
        print $sock "----------------------------------------------------------\n";
        print $sock "$jumper";
        print $sock "    Same name different md5sum\n\n";

        undef %out;
        $cnt = 0;
        if ($mode eq 'unix') {
            $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} = 
                "$unixhdr".
                "# 'diff'\n".
                "# org dir: $orgdir{$sname} $orgdir{$oname}\n\n".
                "BASEDIR=$orgdir{$sname}\n".
                "$unixhdr2";
        } elsif ($mode eq 'dos') {
            $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} = '';
        } else {
            $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} = '';
        }
        $common = 0;
        foreach $fname (sort keys %{$byname{$sname}}) {
            # for each file name in this
            if (defined(${$byname{$oname}}{$fname})) {
                $common++;
                # that also exist in that
                # our databases
                # $byname{$sname}{$fname}{$md5sum} = $pfname;
                # $bymd5sum{$sname}{$md5sum}{$pfname} = $fname;
                # list a md5sum in this
                @lmd5sum = keys %{$byname{$sname}{$fname}};
                # list a md5sum in that
                @rmd5sum = keys %{$byname{$oname}{$fname}};
                if (($#lmd5sum > 0) ||             # more than one md5sum in this, or
                    ($#rmd5sum > 0) ||             # more than one md5sum in that, or
                    ($lmd5sum[0] ne $rmd5sum[0])) {# they are not equal
                    if ($mode eq 'unix') {
                        $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= sprintf ("   %03d: diff: $fname --- ", $cnt);
                        for ($idx = 0; $idx <= $#lmd5sum; $idx++) {
                            ($pfname) = keys %{$bymd5sum{$sname}{$lmd5sum[$idx]}};
                            if ($idx == 0) {
                                $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= "$pfname\n";
                            }
                            $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= "        THIS $idx: $sizebymd5sum{$lmd5sum[$idx]} $lmd5sum[$idx] $pfname\n";
                        }
                        for ($idx = 0; $idx <= $#rmd5sum; $idx++) {
                            ($pfname) = keys %{$bymd5sum{$oname}{$rmd5sum[$idx]}};
                            $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= "        THAT $idx: $sizebymd5sum{$rmd5sum[$idx]} $rmd5sum[$idx] $pfname\n";
                        }
                    } elsif ($mode eq 'dos') {
                        $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= sprintf ("   %03d: diff: $fname --- ", $cnt);
                        for ($idx = 0; $idx <= $#lmd5sum; $idx++) {
                            ($pfname) = keys %{$bymd5sum{$sname}{$lmd5sum[$idx]}};
                            if ($idx == 0) {
                                $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= "$pfname\n";
                            }
                            $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= "        THIS $idx: $sizebymd5sum{$lmd5sum[$idx]} $lmd5sum[$idx] $pfname\n";
                        }
                        for ($idx = 0; $idx <= $#rmd5sum; $idx++) {
                            ($pfname) = keys %{$bymd5sum{$oname}{$rmd5sum[$idx]}};
                            $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= "        THAT $idx: $sizebymd5sum{$rmd5sum[$idx]} $rmd5sum[$idx] $pfname\n";
                        }
                    } else {
                        $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= sprintf ("   %03d: diff: $fname --- ", $cnt);
                        for ($idx = 0; $idx <= $#lmd5sum; $idx++) {
                            ($pfname) = keys %{$bymd5sum{$sname}{$lmd5sum[$idx]}};
                            if ($idx == 0) {
                                $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= "$pfname\n";
                            }
                            $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= "        THIS $idx: $sizebymd5sum{$lmd5sum[$idx]} $lmd5sum[$idx] $pfname\n";
                        }
                        for ($idx = 0; $idx <= $#rmd5sum; $idx++) {
                            ($pfname) = keys %{$bymd5sum{$oname}{$rmd5sum[$idx]}};
                            $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= "        THAT $idx: $sizebymd5sum{$rmd5sum[$idx]} $rmd5sum[$idx] $pfname\n";
                        }
                    }
                    $cnt++;
                }
            }
        }
        $diffmd5sum = $cnt;
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "Same name different md5sum: $cnt files (out of $common same name)\n\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "%INCLUDE<l00://md5sizediff.diff.htm>%\n";
        print $sock "Same name different md5sum: $cnt files (out of $common same name)\n";



        # files with same md5sum on both side
        # ----------------------------------------------------------------
        $sname = 'THIS';
        $oname = 'THAT';
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<a name=\"same\"></a>";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "    Same md5sum\n\n";
        print $sock "<a name=\"same\"></a>";
        print $sock "----------------------------------------------------------\n";
        print $sock "$jumper";
        print $sock "    Same md5sum\n\n";

        undef %out;
        $cnt = 0;
        if ($mode eq 'unix') {
            $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} = 
                "$unixhdrsame".
                "    # 'same'\n".
                "    # org dir: $orgdir{$sname} $orgdir{'THAT'}\n\n".
                "    BASEDIR=$orgdir{'THAT'}\n".
                "    # Save this file as '\$BASEDIR../$thatname.same.sh' or change this variable:\n".
                "    SCRIPT=\$BASEDIR../$thatname.same.sh\n\n".
                "    if [ -f \$SCRIPT ]; then\n";
        } elsif ($mode eq 'dos') {
            $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} = '';
        } else {
            $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} = '';
        }
        $common = 0;
        foreach $md5sum (sort keys %{$bymd5sum{$sname}}) {
            if (($md5sum ne '00000000000000000000000000000000') && defined($bymd5sum{$oname}{$md5sum})) {
                # not a directory and is there
                if ($mode eq 'unix') {
                    $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= 
                        sprintf ("        #   %03d: same: $_ files $sizebymd5sum{$md5sum} $md5sum --- $_[0]\n", $cnt);
                    @_ = (sort keys %{$bymd5sum{$sname}{$md5sum}});
                    $_[0] =~ s/^\.[\\\/]//;
                    $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= 
                        "        source \$SCRIPT  $md5sum  \"$_[0]\" ";
                    @_ = (sort keys %{$bymd5sum{$oname}{$md5sum}});
                    $_[0] =~ s/^\.[\\\/]//;
                    $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= 
                        "\"$_[0]\"\n";
                } elsif ($mode eq 'dos') {
                    @_ = (sort keys %{$bymd5sum{$sname}{$md5sum}});
                    $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= 
                        sprintf ("   %03d: same: $_ files $sizebymd5sum{$md5sum} $md5sum --- $_[0]\n", $cnt).
                        "        $_[0]\n";
                    @_ = (sort keys %{$bymd5sum{$oname}{$md5sum}});
                    $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= 
                        "        $_[0]\n";
                } else {
                    @_ = (sort keys %{$bymd5sum{$sname}{$md5sum}});
                    $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= 
                        sprintf ("   %03d: same: $_ files $sizebymd5sum{$md5sum} $md5sum --- $_[0]\n", $cnt).
                        "        $_[0]\n";
                    @_ = (sort keys %{$bymd5sum{$oname}{$md5sum}});
                    $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= 
                        "        $_[0]\n";
                }
                $cnt++;
            }
        }
        if ($mode eq 'unix') {
            $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= "\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= "        printf \"Processed \$UNIQUEFIL unique files\\n\"\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= "        printf \"Processed \$UNIQUEFIL unique files\\n\" >> \$SCRIPT.log\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= "        printf \"Deleted \$FILEDELET duplicated files\\n\"\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= "        printf \"Deleted \$FILEDELET duplicated files\\n\" >> \$SCRIPT.log\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= "        printf \"\$FILEBADM5 files have unexpected md5sum !!!\\n\"\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= "        printf \"\$FILEBADM5 files have unexpected md5sum !!!\\n\" >> \$SCRIPT.log\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= "    else\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= "        printf \"MISSING \$SCRIPT\\n\"\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= "    fi\n\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= "fi\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= "\n# Match = >$match<\n# $_\n";
        } elsif ($mode eq 'dos') {
        } else {
        }
        $samemd5sum = $cnt;
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "Same md5sum: $cnt files\n\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "%INCLUDE<l00://md5sizediff.same.htm>%\n";
        print $sock "Same md5sum: $cnt files\n";


        # ----------------------------------------------------------------

        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "<a name=\"end\"></a>";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$jumper";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "----------------------------------------------------------\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "</pre>\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "Links to results in RAM<br>\n";
        print $sock "<a name=\"end\"></a>";
        print $sock "----------------------------------------------------------\n";
        print $sock "$jumper";
        print $sock "----------------------------------------------------------\n";
        print $sock "</pre>\n";

        print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
        print $sock "<tr><td>\n";
        print $sock "RAM file</td><td align=\"right\">bytes\n";
        print $sock "</td><td align=\"right\">files\n";
        if ($mode eq 'unix') {
            print $sock "</td><td>copy script\n";
        }
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/ls.htm?path=l00://md5sizediff.all.htm\">l00://md5sizediff.all.htm</a> </td><td align=\"right\"> &nbsp;";
        print $sock "</td><td align=\"right\">&nbsp;\n";
        if ($mode eq 'unix') {
            print $sock "</td><td>&nbsp;\n";
        }
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.THIS.self_dup.htm\">l00://md5sizediff.THIS.self_dup.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.THIS.self_dup.htm"});
        print $sock "</td><td align=\"right\">$cnt{'THIS'}\n";
        if ($mode eq 'unix') {
            print $sock "</td><td><a href=\"/filemgt.htm?path=l00://md5sizediff.THIS.self_dup.htm&path2=$thispath.THIS.self_dup.sh\">THIS.self_dup.sh</a>\n";
        }
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.THAT.self_dup.htm\">l00://md5sizediff.THAT.self_dup.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.THAT.self_dup.htm"});
        print $sock "</td><td align=\"right\">$cnt{'THAT'}\n";
        if ($mode eq 'unix') {
            if ($thatpath ne '') {
                print $sock "</td><td><a href=\"/filemgt.htm?path=l00://md5sizediff.THAT.self_dup.htm&path2=$thispath.THAT.self_dup.sh\">THAT.self_dup.sh</a>\n";
            } else {
                print $sock "</td><td>&nbsp;\n";
            }
        }
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.THIS.only.htm\">l00://md5sizediff.THIS.only.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.THIS.only.htm"});
        print $sock "</td><td align=\"right\">$thisonly\n";
        if ($mode eq 'unix') {
            print $sock "</td><td>&nbsp;\n";
        }
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.THAT.only.htm\">l00://md5sizediff.THAT.only.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.THAT.only.htm"});
        print $sock "</td><td align=\"right\">$thatonly\n";
        if ($mode eq 'unix') {
            print $sock "</td><td>&nbsp;\n";
        }
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.diff.htm\">l00://md5sizediff.diff.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"});
        print $sock "</td><td align=\"right\">$diffmd5sum\n";
        if ($mode eq 'unix') {
            print $sock "</td><td>&nbsp;\n";
        }
        print $sock "</td></tr>\n";
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.same.htm\">l00://md5sizediff.same.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"});
        print $sock "</td><td align=\"right\">$samemd5sum\n";
        if ($mode eq 'unix') {
            print $sock "</td><td><a href=\"/filemgt.htm?path=l00://md5sizediff.same.htm&path2=$thatpath.same.sh\">same.sh</a>\n";
        }
        print $sock "</td></tr>\n";
        print $sock "</table>\n";
    }

    print $sock "<form action=\"/md5sizediff.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"compare\" value=\"Compare\"> Use || to combine inputs\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    if ($mode eq 'text') { $_ = "checked"; } else { $_ = "unchecked"; }
    print $sock "<input type=\"radio\" name=\"mode\" value=\"text\" $_>Text ";
    if ($mode eq 'dos' ) { $_ = "checked"; } else { $_ = "unchecked"; }
    print $sock "<input type=\"radio\" name=\"mode\" value=\"dos\"  $_>.bat ";
    if ($mode eq 'unix') { $_ = "checked"; } else { $_ = "unchecked"; }
    print $sock "<input type=\"radio\" name=\"mode\" value=\"unix\"  $_>.sh ";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "Match: <input type=\"text\" size=\"16\" name=\"match\" value=\"$match\">\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "This:<br><textarea name=\"path\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$thispath</textarea>\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "That:<br><textarea name=\"path2\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$thatpath</textarea>\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    if ($ctrl->{'os'} eq 'and') {
        print $sock "<tr><td>\n";
        print $sock "Paste CB to ";
        print $sock "<input type=\"submit\" name=\"paste4\" value=\"'This:'\"> ";
        print $sock "<input type=\"submit\" name=\"paste2\" value=\"'That:'\">\n";
        print $sock "</td></tr>\n";
    }
    print $sock "</table><br>\n";
    print $sock "</form>\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
