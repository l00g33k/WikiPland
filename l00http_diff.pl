use strict;
use warnings;
use l00backup;
use l00httpd;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# deletes files for now, rename, move and copy possible

my %config = (proc => "l00http_diff_proc",
              desc => "l00http_diff_desc");
my ($treeto, $treefilecnt, $treedircnt, $width, $oldfile, $newfile, $hide);
$treeto = '';
$width = 20;
#$form->{'path'}
$oldfile = '';
$newfile = '';
$hide = '';

my (@OLD, @NEW, $OC, $NC, $OLNO, $NLNO, @OA, @NA, %SYMBOL);
my ($debug);

$debug = 0;

sub l00http_diff_make_outline {
    my ($oii, $nii) = @_;
    my ($oout, $nout, $ospc, $tmp, $clip);


    if (($oii >= 0) && ($oii <= $#OLD)) {
        $tmp = sprintf ("%-${width}s", substr($OLD[$oii],0,$width));
        $ospc = sprintf ("%3d: %-${width}s", $oii + 1, ' ');
        $ospc =~ s/./ /g;
        $tmp =~ s/</&lt;/g;
        $tmp =~ s/>/&gt;/g;
        $clip = &l00httpd::urlencode ($OLD[$oii]);
        $clip = "/clip.htm?update=Copy+to+clipboard&clip=$clip";
        $oout = sprintf ("%3d<a href=\"%s\">:</a> %s", $oii + 1, $clip, $tmp);
    } else {
        # make a string of space of same length
        $ospc = sprintf ("%3d: %-${width}s", 0, ' ');
        $ospc =~ s/./ /g;
        $oout = $ospc;
    }
    if (($nii >= 0) && ($nii <= $#NEW)) {
        $tmp = sprintf ("%-${width}s", substr($NEW[$nii],0,$width));
        $tmp =~ s/</&lt;/g;
        $tmp =~ s/>/&gt;/g;
        $clip = &l00httpd::urlencode ($NEW[$nii]);
        $clip = "/clip.htm?update=Copy+to+clipboard&clip=$clip";
		$nout = sprintf ("%3d<a href=\"%s\">:</a> %s", $nii + 1, $clip, $tmp);
    } else {
        $nout = '';
    }

    ($oout, $nout, $ospc);
}

sub l00http_diff_output {
	my ($ctrl, $oanchor) = @_;
    my $sock = $ctrl->{'sock'};     # dereference network socket
	my ($ln, $jj, $oii, $nii, $nfor, $nptr, $hiding, $hiding2);
    my ($out, $lastold, $lastnew, $oout, $nout, $ospc);
    my ($blocksize, $blockstart, $mxblocksize, $mxblockstart);


    $lastold = -1;
    $blocksize = 1;
    $mxblocksize = -1;
    for ($oii = 0; $oii <= $#OLD; $oii++) {
        if ($OA[$oii] < 0) {
            next;
        }
        # not a deleted line so there is a match in NEW
        if (($lastold == -1) ||  # first line is a start of a block
            ($OA[$oii] == 0)) {	# same as first line in NEW is start; not right
            if ($lastold == -1) {
                $blockstart = $oii;
            }
            if (($mxblocksize < 0) || ($blocksize > $mxblocksize)) {
                $mxblocksize  = $blocksize;
                $mxblockstart = $blockstart;
            }
            print $sock "blocksize $blocksize @ $blockstart\n", if ($debug >= 3);
            $blocksize = 1;
            $blockstart = $oii;
            print $sock "nw bk 1 ", if ($debug >= 3);
        } else {
            $lastnew = -1;
            for ($nii = $OA[$oii]; $nii >= 0; $nii --) {
                if ($NA[$nii] < 0) {
                    # added lines
                    next;
                }
                $lastnew = $nii;
                last;
            }
            if ($lastold == $lastnew) {
                if (($mxblocksize < 0) || ($blocksize > $mxblocksize)) {
                    $mxblocksize  = $blocksize;
                    $mxblockstart = $blockstart;
                }
                print $sock "blocksize $blocksize @ $blockstart\n", if ($debug >= 3);
                $blocksize = 1;
                $blockstart = $oii;
                print $sock "nw bk 2 ", if ($debug >= 3);
            } else {
                print $sock "        ", if ($debug >= 3);
                $blocksize++;
            }
        }	
        $lastold = $oii; # old file last 'same' line number
        print $sock "oii $oii -> $OA[$oii]\n", if ($debug >= 3);
    }
    if (($mxblocksize < 0) || ($blocksize > $mxblocksize)) {
        $mxblocksize  = $blocksize;
        $mxblockstart = $blockstart;
    }
    print $sock "blocksize $blocksize @ $blockstart\n", if ($debug >= 3);
    print $sock "mxblocksize $mxblocksize @ $mxblockstart\n", if ($debug >= 3);



    $oii = $mxblockstart;
    $nii = $OA[$oii];

	$out = '';

    # print forward of largest matched block
    $hiding = 0;
    $hiding2 = 0;
	while (($oii <= $#OLD) || ($nii <= $#NEW)) {
        $hiding++;
        # prepare outputs
        ($oout, $nout, $ospc) = &l00http_diff_make_outline($oii, $nii);
		# print $sock deleted
		if (($oii <= $#OLD) && ($OA[$oii] < 0)) {
			$_ = " $oout &lt;\n";
			$out .= $_;
			$oii++;
			next;
		}
		# print $sock added
		if (($nii <= $#NEW) && ($NA[$nii] < 0)) {
            $_ = " $ospc &gt;";
			$_ .= "$nout\n";
			$out .= $_;
			$nii++;
			next;
		}
		# print $sock identical
		if (($oii <= $#OLD) && ($nii <= $#NEW) && ($OA[$oii] == $nii)) {
            if ($hide ne 'checked') {
                # print if not hiding
			    $_ = " $oout =";
			    $_ .= "$nout\n";
			    $out .= $_;
            } else {
                # print a note about hidden lines
                $hiding2++;
                if ($hiding2 != $hiding) {
                    $hiding2 = $hiding;
                    $out .= sprintf ("%-${width}s%-${width}s--- same omitted ---\n", '-'x$width, '-'x$width);
                }
            }
			$oii++;
			$nii++;
			next;
		}
		# print $sock moved block in NEW
		if ($NA[$nii] < $oii) {
			$_ = sprintf ("(%d)", $NA[$nii] + 1);
            substr ($ospc, length ($ospc) - length ($_), length ($_)) = $_;
			$_ = " $ospc [";
			$_ .= "$nout\n";
			$out .= $_;
			$nii++;
			next;
		}
		# print $sock moved block in NEW
		if ($OA[$oii] > $nii) {
			$_ = sprintf (" %s ] (%d)\n", $oout, $OA[$oii] + 1);
			$out .= $_;
			$oii++;
			next;
		}

		# fail safe
		if ($oii < $#OLD) {
			$oii++;
		}
		if ($nii < $#NEW) {
			$nii++;
		}
	}

    $oii = $mxblockstart - 1;
    $nii = $OA[$mxblockstart] - 1;

    # print backward from largest matched block
    $hiding = 0;
    $hiding2 = 0;
	while (($oii >= 0) || ($nii >= 0)) {
        $hiding++;
        # prepare outputs
        ($oout, $nout, $ospc) = &l00http_diff_make_outline($oii, $nii);
		# print $sock deleted
		if (($oii >= 0) && ($OA[$oii] < 0)) {
			$_ = " $oout &lt;\n";
			$out = "$_$out";
			$oii--;
			next;
		}
		# print $sock added
		if (($nii >= 0) && ($NA[$nii] < 0)) {
            $_ = " $ospc &gt;";
			$_ .= "$nout\n";
			$out = "$_$out";
			$nii--;
			next;
		}
		# print $sock identical
		if (($oii >= 0) && ($nii >= 0) && ($OA[$oii] == $nii)) {
            if ($hide ne 'checked') {
                # print if not hiding
			    $_ = " $oout =";
			    $_ .= "$nout\n";
    			$out = "$_$out";
            } else {
                # print a note about hidden lines
                $hiding2++;
                if ($hiding2 != $hiding) {
                    $hiding2 = $hiding;
                    $out .= sprintf ("%-${width}s%-${width}s--- same omitted ---\n", '-'x$width, '-'x$width);
                }
            }
			$oii--;
			$nii--;
			next;
		}
		# print $sock moved block in NEW
		if ($NA[$nii] < $oii) {
			$_ = sprintf ("(%d)", $NA[$nii] + 1);
            substr ($ospc, length ($ospc) - length ($_), length ($_)) = $_;
			$_ = " $ospc [";
			$_ .= "$nout\n";
			$out = "$_$out";
			$nii--;
			next;
		}
		# print $sock moved block in NEW
		if ($OA[$oii] > $nii) {
			$_ = sprintf (" %s ] (%d)\n", $oout, $OA[$oii] + 1);
			$out = "$_$out";
			$oii--;
			next;
		}

		# fail safe
		if ($oii < 0) {
			$oii--;
		}
		if ($nii > 0) {
			$nii--;
		}
    }


    $out;
}

#perl d:\x\diff.pl d:\x\old.txt d:\x\new.txt > d:\x\x10.txt
#perl d:\x\diff.pl d:\x\new.txt d:\x\old.txt > d:\x\x10.txt
#perl d:\x\diff.pl d:\x\old2.txt d:\x\new2.txt > d:\x\x10.txt
sub l00http_diff_compare {
	my ($ctrl, $oname, $nname) = @_;
    my $sock = $ctrl->{'sock'};     # dereference network socket
	my ($ln, $jj, $oii, $nii, $out, $nfor, $nptr);
	my ($text, $mode);

    print $sock "<pre>\n";
    print $sock "&gt; New file: $nname\n";
    print $sock "&lt; Old file: $oname\n\n";


	# A technique for isolating differences between files
	# Paul Heckel
	# http://documents.scribd.com/docs/10ro9oowpo1h81pgh1as.pdf

#$oname = 'c:/x/ram/old.txt';
#$nname = 'c:/x/ram/new.txt';
#$oname = '/sdcard/al/w/diff/old.txt';
#$nname = '/sdcard/al/w/diff/new.txt';

	open (LF, "<$oname") || print $sock "$oname open failed\n";
	open (RT, "<$nname") || print $sock "$nname open failed\n";

    undef @OLD;
	while (<LF>) {
		s/\r//;
		s/\n//;
		push (@OLD, $_);
	}

    undef @NEW;
	while (<RT>) {
		s/\r//;
		s/\n//;
		push (@NEW, $_);
	}


	close (LF);
	close (RT);

	#for ($ln = 0; $ln <= $#OLD; $ln++) {
	#    print $sock "$ln: <  $OLD[$ln]\n";
	#}
	#for ($ln = 0; $ln <= $#NEW; $ln++) {
	#    print $sock "$ln:  > $NEW[$ln]\n";
	#}


	# Index to $SYMBOL
	$OC   = 0;
	$NC   = 1;
	$OLNO = 2;
	$NLNO = 3;

	# Symbol table:
	# $SYMBOL{$text}[$OC]: Old counter: number of occurance of $text in OLD file
	# $SYMBOL{$text}[$NC]: New counter: number of occurance of $text in NEW file
	# $SYMBOL{$text}[$OLNO]: OLD file line number for $text
	# $SYMBOL{$text}[$NLNO]: NEW file line number for $text

	# OA: Old Array
	# $OA[$ln]: if >= 0: NEW file line number of unique and identical $text as $OLD[$ln]
	#           if == -1: all other cases

	# NA: New Array
	# $NA[$ln]: if >= 0: OLD file line number of unique and identical $text as $NEW[$ln]
	#           if == -1: all other cases

    undef %SYMBOL;
	# Pass 1
	if ($debug >= 1) {
		print $sock "Pass 1: Fill SYMBOL table with OLD file content\n";
	}
	for ($ln = 0; $ln <= $#OLD; $ln++) {
		# Examining current line $OLD[$ln]
		# Set OA old array (-1) to point to symbol table (by $SYMBOL{$OLD[$ln]})
		$OA[$ln] = -1;
		# update SYMBOL table
		if (!defined($SYMBOL{$OLD[$ln]})) {
			# Current line has not been seen before
			# Initialize symbol table to: 
			#   OC = 1
			#   NC = 0      # we haven't process NEW file so it must be zero
			#   OLNO = $ln  # current line is line $ln in OLD file
			$SYMBOL{$OLD[$ln]}[$OC] = 1;
			$SYMBOL{$OLD[$ln]}[$NC] = 0;
			$SYMBOL{$OLD[$ln]}[$OLNO] = $ln;
			$SYMBOL{$OLD[$ln]}[$NLNO] = -1;
		} else {
			$SYMBOL{$OLD[$ln]}[$OC]++;
			# as $oc > 1, OLNO is not meaningful
			$SYMBOL{$OLD[$ln]}[$OLNO] = -1;
		}
	}
	if ($debug >= 5) {
		for ($ln = 0; $ln <= $#OLD; $ln++) {
			print $sock "$ln: OC $SYMBOL{$OLD[$ln]}[$OC] OLNO $SYMBOL{$OLD[$ln]}[$OLNO] >$OLD[$ln]<\n";
		}
	}


	# Pass 2
	if ($debug >= 1) {
		print $sock "Pass 2: Fill SYMBOL table with NEW file content\n";
	}
	for ($ln = 0; $ln <= $#NEW; $ln++) {
		# Examining current line $NEW[$ln]
		# Set NA new array (-1) to point to symbol table (by $SYMBOL{$NEW[$ln]})
		$NA[$ln] = -1;
		# update SYMBOL table
		if (!defined($SYMBOL{$NEW[$ln]})) {
			# Current line has not been seen before
			# Initialize symbol table to: 
			#   OC = 1
			#   NC = 0      # we haven't process NEW file so it must be zero
			#   OLNO = $ln  # current line is line $ln in OLD file
			$SYMBOL{$NEW[$ln]}[$OC] = 0;
			$SYMBOL{$NEW[$ln]}[$NC] = 1;
			$SYMBOL{$NEW[$ln]}[$OLNO] = -2; # not relavent for NEW file
			$SYMBOL{$NEW[$ln]}[$NLNO] = $ln;
		} else {
			$SYMBOL{$NEW[$ln]}[$NC]++;
			if ($SYMBOL{$NEW[$ln]}[$NC] == 1) {
				# as $nc == 1, NLNO is NEW file line number
				$SYMBOL{$NEW[$ln]}[$NLNO] = $ln;
			} else {
				# as $nc > 1, NLNO is not meaningful
				$SYMBOL{$NEW[$ln]}[$NLNO] = -1;
			}
		}
	}
	if ($debug >= 5) {
		for ($ln = 0; $ln <= $#NEW; $ln++) {
			print $sock "$ln: NC $SYMBOL{$NEW[$ln]}[$NC] >$NEW[$ln]<\n";
		}
	}


	# Pass 3
	if ($debug >= 1) {
		print $sock "Pass 3: Establish match for unique lines\n";
	}
	foreach $text (keys %SYMBOL) {
		if (($SYMBOL{$text}[$OC] == 1) &&
			($SYMBOL{$text}[$NC] == 1)) {
			# NA NEW array points to OLNO OLD line number
			$NA[$SYMBOL{$text}[$NLNO]] = $SYMBOL{$text}[$OLNO];
			# OA OLD array points to NLNO NEW line number
			$OA[$SYMBOL{$text}[$OLNO]] = $SYMBOL{$text}[$NLNO];
			if ($debug >= 5) {
				print $sock "NA $NA[$SYMBOL{$text}[$NLNO]] OA $OA[$SYMBOL{$text}[$OLNO]] >$text<\n";
			}
		}
	}

	# Pass 4
	if ($debug >= 1) {
		print $sock "Pass 4: Match non unique lines by context going forward\n";
	}
	for ($ln = 0; $ln < $#NEW; $ln++) { # skip last line which has no next
		# $ln is new line number
		# $jj is matching old line number
		$jj = $NA[$ln];
		if ($jj >= 0) {
			# There is a matching line in OLD file
			# Are the next lines in each matching?
			if (($NEW[$ln + 1] eq $OLD[$jj + 1]) &&
				($OA[$jj + 1] < 0) &&
				($NA[$ln + 1] < 0)) {
				# yes
				$OA[$jj + 1] = $ln + 1;
				$NA[$ln + 1] = $jj + 1;
				if ($debug >= 5) {
					print $sock "NA ", $jj + 1, " OA ", $ln + 1, " >", $NEW[$ln + 1], "<\n";
				}
			}
		}
	}


	# Pass 5
	if ($debug >= 1) {
		print $sock "Pass 5: Match non unique lines by context going backword\n";
	}
	for ($ln = $#NEW; $ln > 0; $ln--) { # skip first line which has no previous
		# $ln is new line number
		# $jj is matching old line number
		$jj = $NA[$ln];
		if ($jj >= 0) {
			# There is a matching line in OLD file
			# Are the next lines in each matching?
			if (($NEW[$ln + 1] eq $OLD[$jj - 1]) &&
				($OA[$jj - 1] < 0) &&
				($NA[$ln - 1] < 0)) {
				# yes
				$OA[$jj - 1] = $ln - 1;
				$NA[$ln - 1] = $jj - 1;
				if ($debug >= 5) {
					print $sock "NA ", $jj - 1, " OA ", $ln - 1, " >", $NEW[$ln - 1], "<\n";
				}
			}
		}
	}

	# Pass 6
	if ($debug >= 1) {
		print $sock "Pass 6: Output results\n";
		$oii = 0;
		$nii = 0;
		$out = '';
		while (($oii <= $#OLD) || ($nii <= $#NEW)) {
			if ($oii <= $#OLD) {
				$_ = sprintf ("%3d: OA(%3d) %-${width}s", $oii + 1, substr($OA[$oii],0,$width), substr($OLD[$oii],0,$width));
				$oii++;
			} else {
				$_ = sprintf ("%3d: OA(%3d) %${width}s", $oii + 1, 0, ' ');
				s/./ /g;
			}
			$out .= $_;
			if ($nii <= $#NEW) {
				$_ = sprintf ("%3d: NA(%3d) %-${width}s", $nii + 1, substr($NA[$nii],0,$width), substr($NEW[$nii],0,$width));
				$nii++;
			} else {
				$_ = sprintf ("%3d: NA(%3d) %${width}s", $nii + 1, 0, ' ');
				s/./ /g;
			}
			$out .= $_;
			$out .= "\n";
		}
		print $sock $out;

    	print $sock "--------------------------\n";

		$oii = 0;
		$nii = 0;
		$nfor = 0;
		$nptr = 0;
		while (($oii <= $#OLD) || ($nii <= $#NEW)) {
			# deleted
			if (($oii <= $#OLD) && ($OA[$oii] < 0)) {
				$oii++;
				next;
			}
			# added
			if (($nii <= $#NEW) && ($NA[$nii] < 0)) {
				$nii++;
				next;
			}
			# not deleted nor added, i.e. same or moved
			if (($oii <= $#OLD) && ($nii <= $#NEW)) {
				if ($OA[$oii] >= $nii) {
					# 
				}
				$oii++;
				$nii++;
				next;
			}
			# OLD and NEW points to different lines
			# count OLD pointing forward

			$oii++;
			$nii++;
		}
    }

    print $sock &l00http_diff_output ($ctrl, 0);

    print $sock "</pre>\n";

}

sub l00http_diff_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "diff: diff between two files";
}

sub l00http_diff_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    if ((defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0))) {
        $form->{'path'} =~ s/\r//g;
        $form->{'path'} =~ s/\n//g;
        $_ = $form->{'path'};
        # keep path only
        s/\/[^\/]+$/\//;
        print $sock " Path: <a href=\"/ls.htm?path=$_\">$_</a>";
        $_ = $form->{'path'};
        # keep name only
        s/^.+\/([^\/]+)$/$1/;
        print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$_</a>\n";
    }
    print $sock "<a href=\"/diff.htm\">Refresh</a>\n";
    print $sock "<p>\n";


    if (defined ($form->{'debug'})) {
        if ($form->{'debug'} =~ /(\d+)/) {
            $debug = $1;
        } else {
            $debug = 5;
        }
    }

    if (defined ($form->{'hide'}) && ($form->{'hide'} eq 'on')) {
        $hide = 'checked';
    } else {
        $hide = '';
    }

    if (defined ($form->{'width'})) {
        if ($form->{'width'} =~ /(\d+)/) {
            $width = $1;
        }
    }

    # copy paste target
    if (defined ($form->{'pasteold'})) {
        # if pasting old file
        # this takes precedence over 'path'
        $oldfile = &l00httpd::l00getCB($ctrl);
    } elsif (defined ($form->{'pastenew'})) {
        # if pasting new file
        # this takes precedence over 'path'
        $newfile = &l00httpd::l00getCB($ctrl);
    } elsif (defined ($form->{'path'})) {
        # could be 'compare' or from ls.htm
        if (defined ($form->{'pathold'})) {
            # 'compare' clicked, old file from oldfile field
            $oldfile = $form->{'pathold'};
        } else {
            # from ls.htm, push first file to be oldfile
            $oldfile = $newfile;
        }
        # new file always from 'path' (field or from ls.htm)
        $newfile = $form->{'path'};
    }


    print $sock "<form action=\"/diff.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"compare\" value=\"Compare\">\n";
    print $sock "</td><td>\n";
    print $sock "Width: <input type=\"text\" size=\"4\" name=\"width\" value=\"$width\">\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"pastenew\" value=\"CB>New:\">";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"35\" name=\"path\" value=\"$newfile\">\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"pasteold\" value=\"CB>Old:\">";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"35\" name=\"pathold\" value=\"$oldfile\">\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
#   print $sock "&nbsp;";
    print $sock "<input type=\"checkbox\" name=\"debug\">debug";
    print $sock "</td><td>\n";
    print $sock "<input type=\"checkbox\" name=\"hide\" $hide>Hide same lines\n";
    print $sock "</td></tr>\n";
    print $sock "</table><br>\n";
    print $sock "</form>\n";


#&l00http_diff_compare ($ctrl, '/sdcard/al/w/diff/old.txt', '/sdcard/al/w/diff/new.txt');
#&l00http_diff_compare ($ctrl, '/sdcard/al/w/diff/new.txt', '/sdcard/al/w/diff/old.txt');
    if (defined ($form->{'compare'})) {
	    &l00http_diff_compare ($ctrl, $oldfile, $newfile);
    }


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
