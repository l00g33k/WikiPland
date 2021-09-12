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
            printf "!!!     keep file md5sum VERIFIED OK\\n" >> \$SCRIPT.log
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
    my ($dummy, $size, $md5sum, $pfname, $pname, $fname, %treesize, $tmp, %uniquefiles);
    my (%cnt, $oname, %out, $idx, $md5sum1st, $ii, @sorting, $filterthis, $filterthat, $filterthis0, $filterthat0, $filterthisexclu, $filterthatexclu);
    my ($match, $matchcnt, $matchnone, $matchone, $matchmulti, $matchlist, $phase);
    my (@lmd5sum, @rmd5sum, $common, $orgpath, %orgdir, $thisname, $thatname, $orgname);
    my ($thisonly, $thatonly, $diffmd5sum, $uniquemd5sum, $samemd5sum, %dupdirs, %listdirs, %alldirs, $alldirs);
    my (%thisext, %thatext, %filtercnt);

    $uniquemd5sum = 0;

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
    if (defined ($form->{'match'}) &&
        (length($form->{'match'}) > 0)) {
        $match = $form->{'match'};
    } else {
        $match = '';
    }

    if (defined ($form->{'filterthis'}) &&
        (length($form->{'filterthis'}) > 0)) {
        $filterthis = $form->{'filterthis'};
        $filterthis0 = $filterthis;
        $filterthisexclu = 0;
        if ($filterthis =~ /^!!/) {
            $filterthisexclu = 1;
            $filterthis0 = substr($filterthis, 2, 9999);
        }
    } else {
        $filterthis = '';
        $filterthis0 = $filterthis;
        $filterthisexclu = 0;
    }
    if (defined ($form->{'filterthat'}) &&
        (length($form->{'filterthat'}) > 0)) {
        $filterthat = $form->{'filterthat'};
        $filterthat0 = $filterthat;
        $filterthatexclu = 0;
        if ($filterthat =~ /^!!/) {
            $filterthatexclu = 1;
            $filterthat0 = substr($filterthat, 2, 9999);
        }
    } else {
        $filterthat = '';
        $filterthat0 = $filterthat;
        $filterthatexclu = 0;
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

        undef %thisext;
        undef %thatext;

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
        $phase = 0;
        foreach $side (($thispath, $thatpath)) {
            if ($phase == 0) {
                $sname = 'THIS';
            } else {
                $sname = 'THAT';
            }
            $phase++;
            $files = 0;
            $orgdir{$sname} = '';
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$sname side: $side\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.all.htm"} = '';
            # split combined input files for each side
            $filtercnt{$sname} = 0;
            foreach $file (split('\|\|', $side)) {
                print $sock "$sname side: <a href=\"/view.htm?path=$file\" target=\"_blank\">$file</a>\n";
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
                            if ($sname eq 'THIS') {
                                if ($filterthis0 ne '') {
                                    if ($filterthisexclu) {
                                        # we are filtering input. Skip if matched
                                        if ($pfname =~ /$filterthis0/i) {
                                            next;
                                        }
                                    } else {
                                        # we are filtering input. Skip if not matched
                                        if ($pfname !~ /$filterthis0/i) {
                                            next;
                                        }
                                    }
                                }
                                # count extensions
                                if ($pfname =~ /[\\\/][^\\\/]*\.([^.\\\/]+)$/i) {
                                    $thisext{$1}++;
                                } else {
                                    $thisext{'(no ext)'}++;
                                }
                            } else {
                                if ($filterthat0 ne '') {
                                    if ($filterthatexclu) {
                                        # we are filtering input. Skip if matched
                                        if ($pfname =~ /$filterthat0/i) {
                                            next;
                                        }
                                    } else {
                                        # we are filtering input. Skip if not matched
                                        if ($pfname !~ /$filterthat0/i) {
                                            next;
                                        }
                                    }
                                }
                                # count extensions
                                if ($pfname =~ /[\\\/][^\\\/]*\.([^.\\\/]+)$/i) {
                                    $thatext{$1}++;
                                } else {
                                    $thatext{'(no ext)'}++;
                                }
                            }
                            $filtercnt{$sname}++;
                            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.all.htm"} .= "$_\n";
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
            # self dup dir count
            undef $dupdirs{"self_dup_$sname"};
            undef $listdirs{"self_dup_$sname"};
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
                    # count match
                    if ($#_ > 0) {
                        $matchlist = '';
                        # count match
                        $matchcnt = 0;
                        if ($match ne '') {
                            # find match
                            for ($ii = 0; $ii <= $#_; $ii++) {
                                if ($_[$ii] =~ /$match/) {
                                    $matchcnt++;
                                    if ($mode eq 'unix') {
                                        $matchlist .= "  \"$_[$ii]\"";
                                    } elsif ($mode eq 'dos') {
                                        $_ = $_[$ii];
                                        tr/\//\\/;
                                        $matchlist .= "     del \"$_\"\n";
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
                                    } elsif ($mode eq 'dos') {
                                        $_ = $_[$ii];
                                        tr/\//\\/;
                                        $matchlist .= "     rem \"$_\"\n";
                                    } else {
                                        $matchlist .= "         \"$_[$ii]\"\n";
                                    }
                                }
                            }
                        } else {
                            # no match regex, list all
                            undef %alldirs;
                            for ($ii = 0; $ii <= $#_; $ii++) {
                                if ($mode eq 'unix') {
                                    $matchlist .= "  \"$_[$ii]\"";
                                } else {
                                    $matchlist .= "         \"$_[$ii]\"\n";
                                }
                                # count listdirs
                                ($pname, $fname) = $_[$ii] =~ /^(.+[\\\/])([^\\\/]+)$/;
                                if (defined($listdirs{"self_dup_$sname"}{$pname})) {
                                    $listdirs{"self_dup_$sname"}{$pname}++;
                                } else {
                                    $listdirs{"self_dup_$sname"}{$pname} = 1;
                                }
                                $alldirs{$pname} = 1;
                            }
                            # remember dup dirs
                            $_ = join("::", sort(keys %alldirs));
                            if (/::/) {
                                # remember only if there are dups
                                if (defined($dupdirs{"self_dup_$sname"}{$_})) {
                                    $dupdirs{"self_dup_$sname"}{$_}++;
                                } else {
                                    $dupdirs{"self_dup_$sname"}{$_} = 1;
                                }
                            }
                        }

                        # $_ is number of dups
                        $_ = $#_ + 1;
                        if ($mode eq 'unix') {
                            for ($ii = 0; $ii <= $#_; $ii++) {
                                $_[$ii] =~ s/^\.[\\\/]//;
                            }
                            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= 
                                "        # matchcnt: $matchcnt\n";
                            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= 
                                sprintf ("        #   %03d: dup: $_ files $sizebymd5sum{$md5sum} $md5sum --- %s\n",   
                                    $cnt{$sname}, $_[0]).
                                "        source \$SCRIPT  $md5sum $matchlist\n";
                            if (($cnt{$sname} > 0) && ($cnt{$sname} % $progressstep) == 0) {
                                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= 
                                    "        echo $cnt{$sname} files\n";
                            }
                        } elsif ($mode eq 'dos') {
                            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= 
                                sprintf ("rem %03d: dup: $_ files $sizebymd5sum{$md5sum} $md5sum --- %s\n",   
                                    $cnt{$sname}, $_[0]).
                                "$matchlist";
                            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= 
                                     "     rem matchcnt: $matchcnt\n\n";
                        } else {
                            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= 
                                sprintf ("    %03d: dup: $_ files $sizebymd5sum{$md5sum} $md5sum --- %s\n",   
                                    $cnt{$sname}, $_[0]).
                                "$matchlist";
                            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= 
                                     "    # matchcnt: $matchcnt\n\n";
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
#               $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "\nrem Match = >$match<\nrem $_\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} = "rem Match = >$match<\nrem $_\n\n" . 
                                                                                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"};
            } else {
#               $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} .= "\nMatch = >$match<\n$_\n";
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"} = "Match = >$match<\n$_\n\n" . 
                                                                                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup.htm"};
            }
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "$sname self duplicated: $cnt{$sname} files\n\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "%INCLUDE<l00://md5sizediff.$sname.self_dup.htm>%\n";
            print $sock "$sname self duplicated: $cnt{$sname} files\n";

            # list dupdirs count
            $cnt = 0;
            foreach $_ (sort keys %{$listdirs{"self_dup_$sname"}}) {
                $cnt++;
            }
            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup_dirs.htm"} = "::toc:: List of dirs ($cnt) (list appears below)\n";
            $cnt = 0;
            foreach $_ (sort keys %{$dupdirs{"self_dup_$sname"}}) {
                $cnt++;
            }
            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup_dirs.htm"} .= "::toc:: List of duplicated dirs sets ($cnt)\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup_dirs.htm"} .= "A: B (C D E ...)\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup_dirs.htm"} .= "    A: sequence number\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup_dirs.htm"} .= "    B: common files in these directories\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup_dirs.htm"} .= "    C,D,E...: total files in each of these directories\n";
            undef @sorting;
            foreach $alldirs (sort keys %{$dupdirs{"self_dup_$sname"}}) {
                push (@sorting, sprintf("%9d %s", $dupdirs{"self_dup_$sname"}{$alldirs}, $alldirs));
            }
            # list sets of duplicated directory sorted by number of files in the directory
            $cnt = 0;
            foreach $alldirs (sort {$b cmp $a} @sorting) {
                $cnt++;
                ($size, $alldirs) = $alldirs =~ /^ *(\d+) (.+)$/;
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup_dirs.htm"} .= "$cnt: $size (";
                foreach $pname (split("::", $alldirs)) {
                    $tmp = "self_dup_$sname";
                    $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup_dirs.htm"} .= " $listdirs{$tmp}{$pname}";
                }
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup_dirs.htm"} .= ") $alldirs\n";
                foreach $_ (split("::", $alldirs)) {
                    $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup_dirs.htm"} .= "                    $_\n";
                }
            }
            # list all directories with number of files in the directory
            $cnt = 0;
            foreach $_ (sort keys %{$listdirs{"self_dup_$sname"}}) {
                $cnt++;
            }
            $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup_dirs.htm"} .= "\n::toc:: List of dirs ($cnt)\n";
            # count sub tree size
            undef %treesize;
            # foreach path
            foreach $pname (sort keys %{$listdirs{"self_dup_$sname"}}) {
                # size of this dir
                $size = $listdirs{"self_dup_$sname"}{$pname};
                while ($pname =~ /[\\\/]/) {
                    # while still have \ or / in path name
                    if (defined($treesize{$pname})) {
                        $treesize{$pname} += $size;
                    } else {
                        $treesize{$pname} = $size;
                    }
                    # trim off lowest level of directory
                    $pname =~ s/[^\\\/]+[\\\/]$//;
                }
                if (defined($treesize{$pname})) {
                    $treesize{$pname} += $size;
                } else {
                    $treesize{$pname} = $size;
                }
            }
            # list each directory
            $cnt = 0;
            foreach $_ (sort keys %{$listdirs{"self_dup_$sname"}}) {
                # count files in subtree
                $cnt++;
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.self_dup_dirs.htm"} .= 
                    sprintf ("%5d: %5d %7d %s\n", $cnt, $listdirs{"self_dup_$sname"}{$_}, $treesize{$_}, $_);
            }
        }


        # Files unique to each side
        # ----------------------------------------------------------------
        $thisonly = 0;
        $thatonly = 0;
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

                # self only dir count
                undef $dupdirs{"only_$sname"};
                undef $listdirs{"only_$sname"};
                foreach $pfname (sort keys %out) {
                    if ($mode eq 'unix') {
                        $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.only.htm"} .= 
                            sprintf ("    #   %03d: ${sname}.only: %s %d %s\n", $pfname, $sizebymd5sum{$out{$pfname}}, $out{$pfname}, $cnt);
                        $pfname =~ s/^\.[\\\/]//;
                        $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.only.htm"} .= 
                            "    source \$SCRIPT  \"$pfname\"\n";
                        #printf $sock ("   %03d: $pfname $out{$pfname}\n", $cnt);
                        $cnt++;
                    } elsif ($mode eq 'dos') {
                        $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.only.htm"} .= 
                            sprintf ("   %03d: %s %d %s\n", $cnt, $pfname, $sizebymd5sum{$out{$pfname}}, $out{$pfname});
                        #printf $sock ("   %03d: $pfname $out{$pfname}\n", $cnt);
                        $cnt++;
                    } else {
                        $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.only.htm"} .= 
                            sprintf ("   %03d: %s %d %s\n", $cnt, $pfname, $sizebymd5sum{$out{$pfname}}, $out{$pfname});
                        #printf $sock ("   %03d: $pfname $out{$pfname}\n", $cnt);
                        $cnt++;
                    }
                    # count listdirs
                    ($pname, $fname) = $pfname =~ /^(.+[\\\/])([^\\\/]+)$/;
                    if (defined($listdirs{"only_$sname"}{$pname})) {
                        $listdirs{"only_$sname"}{$pname}++;
                    } else {
                        $listdirs{"only_$sname"}{$pname} = 1;
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


                # list dupdirs count
                # list all directories with number of files in the directory
                $cnt = 0;
                foreach $_ (sort keys %{$listdirs{"only_$sname"}}) {
                    $cnt++;
                }
                # count sub tree size
                undef %treesize;
                # foreach path
                foreach $pname (sort keys %{$listdirs{"only_$sname"}}) {
                    # count duplicated dirs?
                    if (defined($dupdirs{"only_$sname"}{$pname})) {
                        $dupdirs{"only_$sname"}{$pname}++;
                    } else {
                        $dupdirs{"only_$sname"}{$pname} = 1;
                    }
                    # size of this dir
                    $size = $listdirs{"only_$sname"}{$pname};
                    while ($pname =~ /[\\\/]/) {
                        # while still have \ or / in path name
                        if (defined($treesize{$pname})) {
                            $treesize{$pname} += $size;
                        } else {
                            $treesize{$pname} = $size;
                        }
                        # trim off lowest level of directory
                        $pname =~ s/[^\\\/]+[\\\/]$//;
                    }
                    if (defined($treesize{$pname})) {
                        $treesize{$pname} += $size;
                    } else {
                        $treesize{$pname} = $size;
                    }
                }
                $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.only_dirs.htm"} = "::toc:: List of dirs ($cnt) (number of only file, files in tree)\n";
                # list each directory
                $cnt = 0;
                foreach $_ (sort keys %{$listdirs{"only_$sname"}}) {
                    # count files in subtree
                    $cnt++;
                    $ctrl->{'l00file'}->{"l00://md5sizediff.$sname.only_dirs.htm"} .= 
                        sprintf ("%5d: %5d %7d %s\n", $cnt, $listdirs{"only_$sname"}{$_}, $treesize{$_}, $_);
                }
            }
        } else {
            $ctrl->{'l00file'}->{"l00://md5sizediff.THIS.only.htm"} = '';
            $ctrl->{'l00file'}->{"l00://md5sizediff.THAT.only.htm"} = '';

            $ctrl->{'l00file'}->{"l00://md5sizediff.THIS.only_dirs.htm"} = "(empty)\n";
            $ctrl->{'l00file'}->{"l00://md5sizediff.THAT.only_dirs.htm"} = "(empty)\n";
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
        $ctrl->{'l00file'}->{"l00://md5sizediff.uniquemd5sum.htm"} = '';

        $common = 0;
        # diff dir count
        undef $dupdirs{"diff"};
        undef $listdirs{"diff"};
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
                        $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= sprintf ("   %03d: diff: %s --- ", $cnt, $fname);
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
                        $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= sprintf ("   %03d: diff: %s --- ", $cnt, $fname);
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
                        $ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"} .= sprintf ("   %03d: diff: %s --- ", $cnt, $fname);
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
                    # count listdirs
                    ($pname, $fname) = $pfname =~ /^(.+[\\\/])([^\\\/]+)$/;
                    if (defined($listdirs{"diff"}{$pname})) {
                        $listdirs{"diff"}{$pname}++;
                    } else {
                        $listdirs{"diff"}{$pname} = 1;
                    }
                }
            }
        }
        $diffmd5sum = $cnt;
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "Same name different md5sum: $cnt files (out of $common same name)\n\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.all.htm"} .= "%INCLUDE<l00://md5sizediff.diff.htm>%\n";
        print $sock "Same name different md5sum: $cnt files (out of $common same name)\n";

        # list diff count
        $cnt = 0;
        foreach $_ (sort keys %{$listdirs{"diff"}}) {
            $cnt++;
        }
        $ctrl->{'l00file'}->{"l00://md5sizediff.diff_dirs.htm"} = "::toc:: List of dirs ($cnt) (number of diff file, files in tree)\n";
        # count sub tree size
        undef %treesize;
        # foreach path
        foreach $pname (sort keys %{$listdirs{"diff"}}) {
            # count duplicated dirs?
            if (defined($dupdirs{"diff"}{$pname})) {
                $dupdirs{"diff"}{$pname}++;
            } else {
                $dupdirs{"diff"}{$pname} = 1;
            }
            # size of this dir
            $size = $listdirs{"diff"}{$pname};
            while ($pname =~ /[\\\/]/) {
                # while still have \ or / in path name
                if (defined($treesize{$pname})) {
                    $treesize{$pname} += $size;
                } else {
                    $treesize{$pname} = $size;
                }
                # trim off lowest level of directory
                $pname =~ s/[^\\\/]+[\\\/]$//;
            }
            if (defined($treesize{$pname})) {
                $treesize{$pname} += $size;
            } else {
                $treesize{$pname} = $size;
            }
        }
        # list each directory
        $cnt = 0;
        foreach $_ (sort keys %{$listdirs{"diff"}}) {
            # count files in subtree
            $cnt++;
            $ctrl->{'l00file'}->{"l00://md5sizediff.diff_dirs.htm"} .= 
                sprintf ("%5d: %5d %7d %s\n", $cnt, $listdirs{"diff"}{$_}, $treesize{$_}, $_);
        }


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
                        sprintf ("        #   %03d: same: $_ files $sizebymd5sum{$md5sum} $md5sum --- %s\n", $cnt, $_[0]);
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
                        sprintf ("   %03d: same: $_ files $sizebymd5sum{$md5sum} $md5sum --- %s\n", $cnt, $_[0]).
                        "        $_[0]\n";
                    @_ = (sort keys %{$bymd5sum{$oname}{$md5sum}});
                    $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= 
                        "        $_[0]\n";
                } else {
                    @_ = (sort keys %{$bymd5sum{$sname}{$md5sum}});
                    $ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"} .= 
                        sprintf ("   %03d: same: $_ files $sizebymd5sum{$md5sum} $md5sum --- %s\n", $cnt, $_[0]).
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


        # list same count
        $cnt = 0;
        foreach $_ (sort keys %{$listdirs{"same"}}) {
            $cnt++;
        }
        $ctrl->{'l00file'}->{"l00://md5sizediff.same_dirs.htm"} = "::toc:: List of dirs ($cnt) (number of same file, files in tree)\n";
        # count sub tree size
        undef %treesize;
        # foreach path
        foreach $pname (sort keys %{$listdirs{"same"}}) {
            # count duplicated dirs?
            if (defined($dupdirs{"same"}{$pname})) {
                $dupdirs{"same"}{$pname}++;
            } else {
                $dupdirs{"same"}{$pname} = 1;
            }
            # size of this dir
            $size = $listdirs{"same"}{$pname};
            while ($pname =~ /[\\\/]/) {
                # while still have \ or / in path name
                if (defined($treesize{$pname})) {
                    $treesize{$pname} += $size;
                } else {
                    $treesize{$pname} = $size;
                }
                # trim off lowest level of directory
                $pname =~ s/[^\\\/]+[\\\/]$//;
            }
            if (defined($treesize{$pname})) {
                $treesize{$pname} += $size;
            } else {
                $treesize{$pname} = $size;
            }
        }
        # list each directory
        $cnt = 0;
        foreach $_ (sort keys %{$listdirs{"same"}}) {
            # count files in subtree
            $cnt++;
            $ctrl->{'l00file'}->{"l00://md5sizediff.same_dirs.htm"} .= 
                sprintf ("%5d: %5d %7d %s\n", $cnt, $listdirs{"same"}{$_}, $treesize{$_}, $_);
        }


        # unique md5sum
        undef %uniquefiles;
        $ctrl->{'l00file'}->{"l00://md5sizediff.uniquemd5sum.htm"} = '';
        foreach $md5sum (sort keys %{$bymd5sum{'THIS'}}) {
            if ($md5sum ne '00000000000000000000000000000000') {
                if (!defined($bymd5sum{'THAT'}{$md5sum})) {
                    $uniquemd5sum++;
                    @_ = (sort keys %{$bymd5sum{'THIS'}{$md5sum}});
                    $uniquefiles{join(", ", @_).'notinthat'} = "<<<       : $md5sum - ".join(", ", @_)."\n";
                }
            }
        }
        foreach $md5sum (sort keys %{$bymd5sum{'THAT'}}) {
            if ($md5sum ne '00000000000000000000000000000000') {
                if (!defined($bymd5sum{'THIS'}{$md5sum})) {
                    $uniquemd5sum++;
                    @_ = (sort keys %{$bymd5sum{'THAT'}{$md5sum}});
                    $uniquefiles{join(", ", @_).'notinthis'} = "      >>> : $md5sum - ".join(", ", @_)."\n";
                }
            }
        }
        foreach $_ (sort keys %uniquefiles) {
            $ctrl->{'l00file'}->{"l00://md5sizediff.uniquemd5sum.htm"} .= $uniquefiles{$_};
        }
        $ctrl->{'l00file'}->{"l00://md5sizediff.uniquemd5sum.htm"} = 
            "<<<       : THIS ONLY\n".
            "      >>> : THAT ONLY\n".
            $ctrl->{'l00file'}->{"l00://md5sizediff.uniquemd5sum.htm"};





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


        # header
        # -------------------------------------
        print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
        print $sock "<tr><td>\n";
        print $sock "RAM file</td><td align=\"right\">bytes\n";
        print $sock "</td><td align=\"right\">files\n";
        if ($mode eq 'unix') {
            print $sock "</td><td>copy script\n";
        }
        print $sock "</td></tr>\n";

        # l00://md5sizediff.all.htm
        # -------------------------------------
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/ls.htm?path=l00://md5sizediff.all.htm\">l00://md5sizediff.all.htm</a> </td><td align=\"right\"> &nbsp;";
        print $sock "</td><td align=\"right\">&nbsp;\n";
        if ($mode eq 'unix') {
            print $sock "</td><td>&nbsp;\n";
        }
        print $sock "</td></tr>\n";

        # l00://md5sizediff.THIS.self_dup.htm
        # -------------------------------------
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.THIS.self_dup.htm\">l00://md5sizediff.THIS.self_dup.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.THIS.self_dup.htm"});
        print $sock "</td><td align=\"right\">$cnt{'THIS'}\n";
        if ($mode eq 'unix') {
            print $sock "</td><td><a href=\"/filemgt.htm?path=l00://md5sizediff.THIS.self_dup.htm&path2=$thispath.THIS.self_dup.sh\">THIS.self_dup.sh</a>\n";
        }
        print $sock "</td></tr>\n";

        # l00://md5sizediff.THIS.self_dup_dirs.htm
        # -------------------------------------
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.THIS.self_dup_dirs.htm\">l00://md5sizediff.THIS.self_dup_dirs.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.THIS.self_dup_dirs.htm"});
        @_ = keys %{$dupdirs{'self_dup_THIS'}};
        $_ = $#_ + 1;
        print $sock "</td><td align=\"right\">$_\n";
        print $sock "</td></tr>\n";

        # l00://md5sizediff.THAT.self_dup.htm
        # -------------------------------------
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

        # l00://md5sizediff.THAT.self_dup_dirs.htm
        # -------------------------------------
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.THAT.self_dup_dirs.htm\">l00://md5sizediff.THAT.self_dup_dirs.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.THAT.self_dup_dirs.htm"});
        @_ = keys %{$dupdirs{'self_dup_THAT'}};
        $_ = $#_ + 1;
        print $sock "</td><td align=\"right\">$_\n";
        print $sock "</td></tr>\n";

        # l00://md5sizediff.THIS.only.htm
        # -------------------------------------
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.THIS.only.htm\">l00://md5sizediff.THIS.only.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.THIS.only.htm"});
        print $sock "</td><td align=\"right\">$thisonly\n";
        if ($mode eq 'unix') {
            print $sock "</td><td>&nbsp;\n";
        }
        print $sock "</td></tr>\n";

        # l00://md5sizediff.THIS.only_dirs.htm
        # -------------------------------------
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.THIS.only_dirs.htm\">l00://md5sizediff.THIS.only_dirs.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.THIS.only_dirs.htm"});
        @_ = keys %{$dupdirs{'only_THIS'}};
        $_ = $#_ + 1;
#print join("\n", @_);
        print $sock "</td><td align=\"right\">$_\n";
        print $sock "</td></tr>\n";

        # l00://md5sizediff.THAT.only.htm
        # -------------------------------------
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.THAT.only.htm\">l00://md5sizediff.THAT.only.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.THAT.only.htm"});
        print $sock "</td><td align=\"right\">$thatonly\n";
        if ($mode eq 'unix') {
            print $sock "</td><td>&nbsp;\n";
        }
        print $sock "</td></tr>\n";

        # l00://md5sizediff.THAT.only_dirs.htm
        # -------------------------------------
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.THAT.only_dirs.htm\">l00://md5sizediff.THAT.only_dirs.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.THAT.only_dirs.htm"});
        @_ = keys %{$dupdirs{'only_THAT'}};
        $_ = $#_ + 1;
        print $sock "</td><td align=\"right\">$_\n";
        print $sock "</td></tr>\n";

        # l00://md5sizediff.diff.htm
        # -------------------------------------
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.diff.htm\">l00://md5sizediff.diff.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.diff.htm"});
        print $sock "</td><td align=\"right\">$diffmd5sum\n";
        if ($mode eq 'unix') {
            print $sock "</td><td>&nbsp;\n";
        }
        print $sock "</td></tr>\n";

        # l00://md5sizediff.uniquemd5sum.htm
        # -------------------------------------
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.uniquemd5sum.htm\">l00://md5sizediff.uniquemd5sum.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.uniquemd5sum.htm"});
        print $sock "</td><td align=\"right\">$uniquemd5sum\n";
        if ($mode eq 'unix') {
            print $sock "</td><td>&nbsp;\n";
        }
        print $sock "</td></tr>\n";

        # l00://md5sizediff.diff_dirs.htm
        # -------------------------------------
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.diff_dirs.htm\">l00://md5sizediff.diff_dirs.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.diff_dirs.htm"});
        @_ = keys %{$dupdirs{'diff'}};
        $_ = $#_ + 1;
        print $sock "</td><td align=\"right\">$_\n";
        print $sock "</td></tr>\n";

        # l00://md5sizediff.same.htm
        # -------------------------------------
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.same.htm\">l00://md5sizediff.same.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.same.htm"});
        print $sock "</td><td align=\"right\">$samemd5sum\n";
        if ($mode eq 'unix') {
            print $sock "</td><td><a href=\"/filemgt.htm?path=l00://md5sizediff.same.htm&path2=$thatpath.same.sh\">same.sh</a>\n";
        }
        print $sock "</td></tr>\n";

        # l00://md5sizediff.same_dirs.htm
        # -------------------------------------
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.same_dirs.htm\">l00://md5sizediff.same_dirs.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.same_dirs.htm"});
        @_ = keys %{$dupdirs{'same'}};
        $_ = $#_ + 1;
        print $sock "</td><td align=\"right\">$_\n";
        print $sock "</td></tr>\n";

        # l00://md5sizediff.THIS.all.htm
        # -------------------------------------
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.THIS.all.htm\">l00://md5sizediff.THIS.all.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.THIS.all.htm"});
        print $sock "</td><td align=\"right\">$filtercnt{'THIS'}\n";
        if ($mode eq 'unix') {
            print $sock "</td><td>&nbsp;\n";
        }
        print $sock "</td></tr>\n";

        # l00://md5sizediff.THAT.all.htm
        # -------------------------------------
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/view.htm?path=l00://md5sizediff.THAT.all.htm\">l00://md5sizediff.THAT.all.htm</a> </td><td align=\"right\"> ", length($ctrl->{'l00file'}->{"l00://md5sizediff.THAT.all.htm"});
        print $sock "</td><td align=\"right\">$filtercnt{'THAT'}\n";
        if ($mode eq 'unix') {
            print $sock "</td><td>&nbsp;\n";
        }
        print $sock "</td></tr>\n";

        print $sock "</table>\n";

        print $sock "<br>File extension reports:<br>\n";
        print $sock "<a href=\"/ls.htm?path=l00://md5sizediff.THIS.extensions.txt\">l00://md5sizediff.THIS.extensions.txt</a><br>\n";
        print $sock "<a href=\"/ls.htm?path=l00://md5sizediff.THAT.extensions.txt\">l00://md5sizediff.THAT.extensions.txt</a><br>\n";
        
        $ctrl->{'l00file'}->{"l00://md5sizediff.THIS.extensions.txt"}  = "* Extensions in $thispath\n\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.THIS.extensions.txt"} .= "|| # || ext || counts ||\n";
        $cnt = 0;
        foreach $_ (sort keys %thisext) {
            $cnt++;
            $ctrl->{'l00file'}->{"l00://md5sizediff.THIS.extensions.txt"} .= "|| $cnt || $_ || $thisext{$_} ||\n";
        }

        $ctrl->{'l00file'}->{"l00://md5sizediff.THAT.extensions.txt"}  = "* Extensions in $thatpath\n\n";
        $ctrl->{'l00file'}->{"l00://md5sizediff.THAT.extensions.txt"} .= "|| # || ext || counts ||\n";
        $cnt = 0;
        foreach $_ (sort keys %thatext) {
            $cnt++;
            $ctrl->{'l00file'}->{"l00://md5sizediff.THAT.extensions.txt"} .= "|| $cnt || $_ || $thatext{$_} ||\n";
        }
    }

    print $sock "<form action=\"/md5sizediff.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"compare\" value=\"C&#818;ompare\" accesskey=\"c\"> Use || to combine inputs\n";
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
    print $sock "Match: <input type=\"text\" size=\"16\" name=\"match\" value=\"$match\"> Count #dup of any full matching regex\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "This: (full pathname filter regex (!! inverte): <input type=\"text\" size=\"16\" name=\"filterthis\" value=\"$filterthis\"> )<br>";
    print $sock "<textarea name=\"path\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$thispath</textarea>\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "That: (full pathname filter regex (!! inverte): <input type=\"text\" size=\"16\" name=\"filterthat\" value=\"$filterthat\"> )<br>";
    print $sock "<textarea name=\"path2\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$thatpath</textarea>\n";
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
