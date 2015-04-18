use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# deletes files for now, rename, move and copy possible

my %config = (proc => "l00http_diff_proc",
              desc => "l00http_diff_desc");
my ($treeto, $treefilecnt, $treedircnt);
$treeto = '';

my (@OLD, @NEW, $OC, $NC, $OLNO, $NLNO, @OA, @NA, %SYMBOL);
my ($debug);


sub l00http_diff_output {
	my ($ctrl, $oanchor) = @_;
    my $sock = $ctrl->{'sock'};     # dereference network socket
	my ($ln, $jj, $oii, $nii, $wd, $nfor, $nptr);
    my ($out, $lastold, $lastnew, $wd);
    my ($blocksize, $blockstart, $mxblocksize, $mxblockstart);

    print $sock "In l00http_diff_output\n";

    print $sock "In l00http_diff_output: print start of new blocks\n";

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
            print $sock "blocksize $blocksize @ $blockstart\n";
            $blocksize = 1;
            $blockstart = $oii;
            print $sock "nw bk 1 ";
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
                print $sock "blocksize $blocksize @ $blockstart\n";
                $blocksize = 1;
                $blockstart = $oii;
                print $sock "nw bk 2 ";
            } else {
                print $sock "        ";
                $blocksize++;
            }
        }	
        $lastold = $oii; # old file last 'same' line number
        print $sock "oii $oii -> $OA[$oii]\n";
    }
    if (($mxblocksize < 0) || ($blocksize > $mxblocksize)) {
        $mxblocksize  = $blocksize;
        $mxblockstart = $blockstart;
    }
    print $sock "blocksize $blocksize @ $blockstart\n";
    print $sock "mxblocksize $mxblocksize @ $mxblockstart\n";



    $oii = $mxblockstart;
    $nii = $OA[$oii];

	$out = '';
	$wd = 20;

    # print forward of largest matched block
	while (($oii <= $#OLD) || ($nii <= $#NEW)) {
		# print $sock deleted
		if (($oii <= $#OLD) && ($OA[$oii] < 0)) {
			$_ = sprintf (" %3d: %-${wd}s <\n", $oii, $OLD[$oii]);
			$out .= $_;
			$oii++;
			next;
		}
		# print $sock added
		if (($nii <= $#NEW) && ($NA[$nii] < 0)) {
			$_ = sprintf (" %3d: %-${wd}s  ", $oii, ' ');
			s/./ /g;
			s/.$/>/;
			$_ .= sprintf ("%3d: %-${wd}s\n", $nii, $NEW[$nii]);
			$out .= $_;
			$nii++;
			next;
		}
		# print $sock identical
		if (($oii <= $#OLD) && ($nii <= $#NEW) && ($OA[$oii] == $nii)) {
			$_ = sprintf (" %3d: %-${wd}s =", $oii, $OLD[$oii]);
			$_ .= sprintf ("%3d: %-${wd}s\n", $nii, $NEW[$nii]);
			$out .= $_;
			$oii++;
			$nii++;
			next;
		}
		# print $sock moved block in NEW
		if ($NA[$nii] < $oii) {
			$_ = sprintf (" %3d: %-${wd}s  ", $oii, ' ');
			s/./ /g;
			s/.$/[/;
			$_ .= sprintf ("%3d: %-${wd}s\n", $nii, $NEW[$nii]);
			$out .= $_;
			$nii++;
			next;
		}
		# print $sock moved block in NEW
		if ($OA[$oii] > $nii) {
			$_ = sprintf (" %3d: %-${wd}s ]\n", $oii, $OLD[$oii]);
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
	while (($oii >= 0) || ($nii >= 0)) {
		# print $sock deleted
		if (($oii >= 0) && ($OA[$oii] < 0)) {
			$_ = sprintf (" %3d: %-${wd}s <\n", $oii, $OLD[$oii]);
			$out = "$_$out";
			$oii--;
			next;
		}
		# print $sock added
		if (($nii >= 0) && ($NA[$nii] < 0)) {
			$_ = sprintf (" %3d: %-${wd}s  ", $oii, ' ');
			s/./ /g;
			s/.$/>/;
			$_ .= sprintf ("%3d: %-${wd}s\n", $nii, $NEW[$nii]);
			$out = "$_$out";
			$nii--;
			next;
		}
		# print $sock identical
		if (($oii >= 0) && ($nii >= 0) && ($OA[$oii] == $nii)) {
			$_ = sprintf (" %3d: %-${wd}s =", $oii, $OLD[$oii]);
			$_ .= sprintf ("%3d: %-${wd}s\n", $nii, $NEW[$nii]);
			$out = "$_$out";
			$oii--;
			$nii--;
			next;
		}
		# print $sock moved block in NEW
		if ($NA[$nii] < $oii) {
			$_ = sprintf (" %3d: %-${wd}s  ", $oii, ' ');
			s/./ /g;
			s/.$/[/;
			$_ .= sprintf ("%3d: %-${wd}s\n", $nii, $NEW[$nii]);
			$out = "$_$out";
			$nii--;
			next;
		}
		# print $sock moved block in NEW
		if ($OA[$oii] > $nii) {
			$_ = sprintf (" %3d: %-${wd}s ]\n", $oii, $OLD[$oii]);
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

    print $sock "------ OUTPUT --------\n";
    $out;
}

#perl d:\x\diff.pl d:\x\old.txt d:\x\new.txt > d:\x\x10.txt
#perl d:\x\diff.pl d:\x\new.txt d:\x\old.txt > d:\x\x10.txt
#perl d:\x\diff.pl d:\x\old2.txt d:\x\new2.txt > d:\x\x10.txt
sub l00http_diff_compare {
	my ($ctrl, $oname, $nname) = @_;
    my $sock = $ctrl->{'sock'};     # dereference network socket
	my ($debug, $ln, $jj, $oii, $nii, $wd, $out, $nfor, $nptr);
	my ($text, $mode);

    print $sock "<pre>\n";
    print $sock "old: $oname\n";
    print $sock "new: $nname\n";


	$debug = 5;

	# A technique for isolating differences between files
	# Paul Heckel
	# http://documents.scribd.com/docs/10ro9oowpo1h81pgh1as.pdf

	$oname = 'c:/x/ram/old.txt';
	$nname = 'c:/x/ram/new.txt';
	$oname = '/sdcard/al/w/diff/old.txt';
	$nname = '/sdcard/al/w/diff/new.txt';

	open (LF, "<$oname") || print $sock "$oname open failed\n";
	open (RT, "<$nname") || print $sock "$nname open failed\n";

	while (<LF>) {
		chomp;
		push (@OLD, $_);
	}

	while (<RT>) {
		chomp;
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
		$wd = 20;
		$out = '';
		while (($oii <= $#OLD) || ($nii <= $#NEW)) {
			if ($oii <= $#OLD) {
				$_ = sprintf ("%3d: OA(%3d) %-${wd}s", $oii, $OA[$oii], $OLD[$oii]);
				$oii++;
			} else {
				$_ = sprintf ("%3d: OA(%3d) %${wd}s", $oii, 0, ' ');
				s/./ /g;
			}
			$out .= $_;
			if ($nii <= $#NEW) {
				$_ = sprintf ("%3d: NA(%3d) %-${wd}s", $nii, $NA[$nii], $NEW[$nii]);
				$nii++;
			} else {
				$_ = sprintf ("%3d: NA(%3d) %${wd}s", $nii, 0, ' ');
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

        print $sock &l00http_diff_output ($ctrl, 0);



	print $sock "--------------------------\n";


		$oii = 0;
		$nii = 0;
		$out = '';
		$mode = 1;
		print $sock "mode is $mode\n\n";
		while (($oii <= $#OLD) || ($nii <= $#NEW)) {
			# print $sock deleted
			if (($oii <= $#OLD) && ($OA[$oii] < 0)) {
				$_ = sprintf (" %3d: %-${wd}s <\n", $oii, $OLD[$oii]);
				$out .= $_;
				$oii++;
				next;
			}
			# print $sock added
			if (($nii <= $#NEW) && ($NA[$nii] < 0)) {
				$_ = sprintf (" %3d: %-${wd}s  ", $oii, ' ');
				s/./ /g;
				s/.$/>/;
				$_ .= sprintf ("%3d: %-${wd}s\n", $nii, $NEW[$nii]);
				$out .= $_;
				$nii++;
				next;
			}
			# print $sock identical
			if (($oii <= $#OLD) && ($nii <= $#NEW) && ($OA[$oii] == $nii)) {
				$_ = sprintf (" %3d: %-${wd}s =", $oii, $OLD[$oii]);
				$_ .= sprintf ("%3d: %-${wd}s\n", $nii, $NEW[$nii]);
				$out .= $_;
				$oii++;
				$nii++;
				next;
			}
			# print $sock moved block
			if ($mode) {
				# anchor NEW file
				# print $sock moved block in NEW
				if ($NA[$nii] < $oii) {
					$_ = sprintf (" %3d: %-${wd}s  ", $oii, ' ');
					s/./ /g;
					s/.$/[/;
					$_ .= sprintf ("%3d: %-${wd}s\n", $nii, $NEW[$nii]);
					$out .= $_;
					$nii++;
					next;
				}
				# print $sock moved block in NEW
				if ($OA[$oii] > $nii) {
					$_ = sprintf (" %3d: %-${wd}s ]\n", $oii, $OLD[$oii]);
					$out .= $_;
					$oii++;
					next;
				}
			} else {
				# anchor OLD file
				# print $sock moved block in OLD
				if ($NA[$nii] < $oii) {
					$_ = sprintf (" %3d: %-${wd}s  ", $oii, ' ');
					s/./ /g;
					s/.$/[/;
					$_ .= sprintf ("%3d: %-${wd}s\n", $nii, $NEW[$nii]);
					$out .= $_;
					$nii++;
					next;
				}
				# print $sock moved block in NEW
				if ($OA[$oii] > $nii) {
					$_ = sprintf (" %3d: %-${wd}s ]\n", $oii, $OLD[$oii]);
					$out .= $_;
					$oii++;
					next;
				}
			}

			# fail safe
			if ($oii <= $#OLD) {
				$oii++;
			}
			if ($nii <= $#NEW) {
				$nii++;
			}
		}
		print $sock $out;
	}


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
    my ($buffer, $path2);

$path2 = '';

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
    print $sock "<a href=\"/diff.htm?path=$form->{'path'}\">Refresh</a>\n";
    print $sock "<p>\n";


    # copy paste target
    if (defined ($form->{'paste2'})) {
        $form->{'path2'} = &l00httpd::l00getCB($ctrl);
    }
    if ((defined ($form->{'copy'})) &&
        (defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0)) &&
        (defined ($form->{'path2'}) && 
        (length ($form->{'path2'}) > 0))) {
        if (defined ($form->{'urlonly'})) {
        } else {
            local $/ = undef;
            if (open (IN, "<$form->{'path'}")) {
                $buffer = <IN>;
                close (IN);
                if ((!defined ($form->{'nobak'})) || ($form->{'nobak'} ne 'on')) {
                    &l00backup::backupfile ($ctrl, $form->{'path2'}, 1, 5);
                }
                open (OU, ">$form->{'path2'}");
                print OU $buffer;
                close (OU);
            }
        }
	}




    # copy
    if (!defined ($form->{'path'})) {
        $form->{'path'} = '';
    }
    if (defined ($form->{'urlonly'})) {
        # if from URL only, use path2
        $path2 = $form->{'path2'};
    } else {
        if ((length ($form->{'path'}) > 0) &&
            (length ($form->{'path2'}) == 0)) {
            $path2 = $form->{'path'};
            # if filename contains extension
            if (!($path2 =~ /\/[^\/.]+$/)) {
                # insert '.2' before extension as target file
                $path2 =~ s/(\.[^.]+)$/.2$1/;
            }
        }
    }
    print $sock "<form action=\"/diff.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"copy\" value=\"Copy\">\n";
    #print $sock "<input type=\"submit\" name=\"rename\" value=\"Move\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "fr: <input type=\"text\" size=\"16\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "to: <input type=\"text\" size=\"16\" name=\"path2\" value=\"$path2\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"checkbox\" name=\"nobak\">Do not backup\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"checkbox\" name=\"urlonly\">Make URL only\n";
    print $sock "</td></tr>\n";
    if ($ctrl->{'os'} eq 'and') {
        print $sock "<tr><td>\n";
        print $sock "<input type=\"submit\" name=\"paste2\" value=\"Paste CB to 'to:'\">\n";
        print $sock "</td></tr>\n";
    }
    if (defined ($form->{'copy'}) &&
        (defined ($form->{'urlonly'})) && 
        (defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0)) &&
        (defined ($form->{'path2'}) && 
        (length ($form->{'path2'}) > 0))) {
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/diff.htm?copy=Copy&path=$form->{'path'}&path2=$form->{'path2'}&urlonly=on\">Copy URL</a>\n";
        print $sock "</td></tr>\n";
    }
    print $sock "</table><br>\n";
    print $sock "</form>\n";


	&l00http_diff_compare ($ctrl, '/sdcard/al/w/diff/old.txt', '/sdcard/al/w/diff/new.txt');


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
