use strict;
use warnings;
use l00backup;
use l00httpd;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# deletes files for now, rename, move and copy possible

my %config = (proc => "l00http_diff_proc",
              desc => "l00http_diff_desc");
my ($treeto, $treefilecnt, $treedircnt, $width, $oldfile, $newfile);
my ($hide, $maxline, @diffout);
$treeto = '';
$width = 20;
#$form->{'path'}
$oldfile = '';
$newfile = '';
$hide = '';
$maxline = 1000;

my (@OLD, @NEW, $OC, $NC, $OLNO, $NLNO, @OA, @NA, %SYMBOL);
my ($debug);

$debug = 0;

sub l00http_diff_make_outline {
    my ($oii, $nii) = @_;
    my ($oout, $nout, $ospc, $tmp, $clip, $view, $lineno0, $lineno);


    if (($oii >= 0) && ($oii <= $#OLD)) {
        $tmp = sprintf ("%-${width}s", substr($OLD[$oii],0,$width));
        $ospc = sprintf ("%3d: %-${width}s", $oii + 1, ' ');
        $ospc =~ s/./ /g;
        $tmp =~ s/</&lt;/g;
        $tmp =~ s/>/&gt;/g;
        #$clip = &l00httpd::urlencode ($OLD[$oii]);
        #$clip = "/clip.htm?update=Copy+to+clipboard&clip=$clip";

        $lineno = $oii + 1;
        $lineno0 = $lineno - 3;
        if ($lineno0 < 1) {
            $lineno0 = 1;
        }
        $view = "/view.htm?path=$oldfile&hiliteln=$lineno&lineno=on#line$lineno0";
        $oout = sprintf ("%3d<a href=\"%s\">:</a> %s", $oii + 1, $view, $tmp);
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
        #$clip = &l00httpd::urlencode ($NEW[$nii]);
        #$clip = "/clip.htm?update=Copy+to+clipboard&clip=$clip";

        $lineno = $nii + 1;
        $lineno0 = $lineno - 3;
        if ($lineno0 < 1) {
            $lineno0 = 1;
        }
        $view = "/view.htm?path=$newfile&hiliteln=$lineno&lineno=on#line$lineno0";
		$nout = sprintf ("%3d<a href=\"%s\">:</a> %s", $nii + 1, $view, $tmp);
    } else {
        $nout = '';
    }

    ($oout, $nout, $ospc);
}

sub l00http_diff_output {
	my ($ln, $jj, $oii, $nii, $nfor, $nptr, $hiding, $hiding2);
    my ($lastold, $lastnew, $oout, $nout, $ospc, $out);
    my ($blocksize, $blockstart, $mxblocksize, $mxblockstart);
    my ($outlinks, $deleted, $added, $moved, $same, $lastact, $firstact, $anchor);


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
            print "blocksize $blocksize @ $blockstart\n", if ($debug >= 3);
            $blocksize = 1;
            $blockstart = $oii;
            print "nw bk 1 ", if ($debug >= 3);
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
                print "blocksize $blocksize @ $blockstart\n", if ($debug >= 3);
                $blocksize = 1;
                $blockstart = $oii;
                print "nw bk 2 ", if ($debug >= 3);
            } else {
                print "        ", if ($debug >= 3);
                $blocksize++;
            }
        }	
        $lastold = $oii; # old file last 'same' line number
        print "oii $oii -> $OA[$oii]\n", if ($debug >= 3);
    }
    if (($mxblocksize < 0) || ($blocksize > $mxblocksize)) {
        $mxblocksize  = $blocksize;
        $mxblockstart = $blockstart;
    }
    print "blocksize $blocksize @ $blockstart\n", if ($debug >= 3);
    print "mxblocksize $mxblocksize @ $mxblockstart\n", if ($debug >= 3);



    $oii = $mxblockstart;
    $nii = $OA[$oii];

	undef @diffout;
    $outlinks = '';

    # collect statistics
    $deleted = 0;
    $added = 0;
    $moved = 0;
    $same = 0;
    $lastact = '';
    $firstact = '';
    $anchor = 1;

    # print forward of largest matched block
    $hiding = 0;
    $hiding2 = 0;
	while (($oii <= $#OLD) || ($nii <= $#NEW)) {
        $hiding++;
        # prepare outputs
        ($oout, $nout, $ospc) = &l00http_diff_make_outline($oii, $nii);
		# print deleted
		if (($oii <= $#OLD) && ($OA[$oii] < 0)) {
            if ($lastact ne '<') {
                $lastact = '<';
                # make link to changes
                $_ = $oii + 1;
                $outlinks .= "<a href=\"#change$anchor\">delete($_)</a> ";
                push (@diffout, "<a name=\"change$anchor\"></a>");
                $anchor++;
            }
            if ($firstact eq '') {
                $firstact = $lastact;
            }

		    push (@diffout, " $oout &lt;\n");
			$oii++;
            $deleted++;
			next;
		}
		# print added
		if (($nii <= $#NEW) && ($NA[$nii] < 0)) {
            if ($lastact ne '>') {
                $lastact = '>';
                # make link to changes
                $_ = $nii + 1;
                $outlinks .= "<a href=\"#change$anchor\">add[$_]</a> ";
                push (@diffout, "<a name=\"change$anchor\"></a>");
                $anchor++;
            }
            if ($firstact eq '') {
                $firstact = $lastact;
            }

            push (@diffout, " $ospc &gt;$nout\n");
			$nii++;
            $added++;
			next;
		}
		# print identical
		if (($oii <= $#OLD) && ($nii <= $#NEW) && ($OA[$oii] == $nii)) {
            if ($hide ne 'checked') {
                # print if not hiding
                if ($lastact ne '=') {
                    # make link to changes
                    $_ = $nii + 1;
                    $outlinks .= "<a href=\"#change$anchor\">same[$_]</a> ";
                    push (@diffout, "<a name=\"change$anchor\"></a>");
                    $anchor++;
                }
			    push (@diffout, " $oout =$nout\n");
            } else {
                # print a note about hidden lines
                $hiding2++;
                if ($hiding2 != $hiding) {
                    $hiding2 = $hiding;
                    push (@diffout, sprintf ("%-${width}s%-${width}s--- same omitted ---\n", '-'x$width, '-'x$width));
                }
            }
            $lastact = '=';
            if ($firstact eq '') {
                $firstact = $lastact;
            }
			$oii++;
			$nii++;
            $same++;
			next;
		}
		# print moved block in NEW
		if ($NA[$nii] < $oii) {
            if ($lastact ne '[') {
                $lastact = '[';
                # make link to changes
                $_ = $nii + 1;
                $outlinks .= "<a href=\"#change$anchor\">move[$_]</a> ";
                push (@diffout, "<a name=\"change$anchor\"></a>");
                $anchor++;
            }
            if ($firstact eq '') {
                $firstact = $lastact;
            }
			$_ = sprintf ("(%d)", $NA[$nii] + 1);
            substr ($ospc, length ($ospc) - length ($_), length ($_)) = $_;
			push (@diffout, " $ospc [$nout\n");
			$nii++;
            $moved++;
			next;
		}
		# print moved block in OLD
		if ($OA[$oii] > $nii) {
            if ($lastact ne ']') {
                $lastact = ']';
                # make link to changes
                $_ = $oii + 1;
                $outlinks .= "<a href=\"#change$anchor\">move($_)</a> ";
                push (@diffout, "<a name=\"change$anchor\"></a>");
                $anchor++;
            }
            if ($firstact eq '') {
                $firstact = $lastact;
            }
			push (@diffout, sprintf (" %s ] (%d)\n", $oout, $OA[$oii] + 1));
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
    $lastact = $firstact;
    #$outlinks = "backward debug " . $outlinks;

	while (($oii >= 0) || ($nii >= 0)) {
        $hiding++;
        # prepare outputs
        ($oout, $nout, $ospc) = &l00http_diff_make_outline($oii, $nii);
		# print deleted
		if (($oii >= 0) && ($OA[$oii] < 0)) {
            if ($lastact ne '<') {
                # make link to changes
                if ($lastact eq '>') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">add[$_]</a> " . $outlinks;
                    }
                } elsif ($lastact eq '=') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">1same[$_]</a> " . $outlinks;
                    }
                } elsif ($lastact eq ']') {
                    if ($oii >= 0) {
                        $_ = $oii + 2;
                        $outlinks = "<a href=\"#change$anchor\">move($_)</a> " . $outlinks;
                    }
                } elsif ($lastact eq '[') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">move[$_]</a> " . $outlinks;
                    }
                }
                unshift (@diffout, "<a name=\"change$anchor\"></a>");
                $anchor++;
                $lastact = '<';
            }

			unshift (@diffout, " $oout &lt;\n");
			$oii--;
            $deleted++;
			next;
		}
		# print added
		if (($nii >= 0) && ($NA[$nii] < 0)) {
            if ($lastact ne '>') {
                # make link to changes
                if ($lastact eq '<') {
                    if ($oii >= 0) {
                        $_ = $oii + 2;
                        $outlinks = "<a href=\"#change$anchor\">delete($_)</a> " . $outlinks;
                    }
                } elsif ($lastact eq '=') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">2same[$_]</a> " . $outlinks;
                    }
                } elsif ($lastact eq '[') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">move[$_]</a> " . $outlinks;
                    }
                } elsif ($lastact eq ']') {
                    if ($oii >= 0) {
                        $_ = $oii + 2;
                        $outlinks = "<a href=\"#change$anchor\">move($_)</a> " . $outlinks;
                    }
                }
                unshift (@diffout, "<a name=\"change$anchor\"></a>");
                $anchor++;
                $lastact = '>';
            }

            unshift (@diffout, " $ospc &gt;$nout\n");
			$nii--;
            $added++;
			next;
		}
		# print identical
		if (($oii >= 0) && ($nii >= 0) && ($OA[$oii] == $nii)) {
            if ($hide ne 'checked') {
                # print if not hiding
                if ($lastact ne '=') {
                    # make link to changes
                    if ($lastact eq '>') {
                        if ($nii >= 0) {
                            $_ = $nii + 2;
                            $outlinks = "<a href=\"#change$anchor\">add[$_]</a> " . $outlinks;
                        }
                    } elsif ($lastact eq '<') {
                        if ($oii >= 0) {
                            $_ = $oii + 2;
                            $outlinks = "<a href=\"#change$anchor\">delete($_)</a> " . $outlinks;
                        }
                    } elsif ($lastact eq '[') {
                        if ($nii >= 0) {
                            $_ = $nii + 2;
                            $outlinks = "<a href=\"#change$anchor\">move[$_]</a> " . $outlinks;
                        }
                    } elsif ($lastact eq ']') {
                        if ($oii >= 0) {
                            $_ = $oii + 2;
                            $outlinks = "<a href=\"#change$anchor\">move($_)</a> " . $outlinks;
                        }
                    }
                    unshift (@diffout, "<a name=\"change$anchor\"></a>");
                    $anchor++;
                    $lastact = '=';
                }

			    unshift (@diffout, " $oout =$nout\n");
            } else {
                # print a note about hidden lines
                $hiding2++;
                if ($hiding2 != $hiding) {
                    $hiding2 = $hiding;
                    push (@diffout, sprintf ("%-${width}s%-${width}s--- same omitted ---\n", '-'x$width, '-'x$width));
                }
            }
            $lastact = '=';

			$oii--;
			$nii--;
            $same++;
			next;
		}
		# print moved block in NEW
		if ($NA[$nii] < $oii) {
            if ($lastact ne '[') {
                # make link to changes
                if ($lastact eq '>') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">add[$_]</a> " . $outlinks;
                    }
                } elsif ($lastact eq '<') {
                    if ($oii >= 0) {
                        $_ = $oii + 2;
                        $outlinks = "<a href=\"#change$anchor\">delete($_)</a> " . $outlinks;
                    }
                } elsif ($lastact eq '=') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">3same[$_]</a> " . $outlinks;
                    }
                } elsif ($lastact eq ']') {
                    if ($oii >= 0) {
                        $_ = $oii + 2;
                        $outlinks = "<a href=\"#change$anchor\">move($_)</a> " . $outlinks;
                    }
                }
                unshift (@diffout, "<a name=\"change$anchor\"></a>");
                $anchor++;
                $lastact = '[';
            }

			$_ = sprintf ("(%d)", $NA[$nii] + 1);
            substr ($ospc, length ($ospc) - length ($_), length ($_)) = $_;
			unshift (@diffout, " $ospc [$nout\n");
			$nii--;
            $moved++;
			next;
		}
		# print moved block in OLD
		if ($OA[$oii] > $nii) {
            if ($lastact ne ']') {
                # make link to changes
                if ($lastact eq '>') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">add[$_]</a> " . $outlinks;
                    }
                } elsif ($lastact eq '<') {
                    if ($oii >= 0) {
                        $_ = $oii + 2;
                        $outlinks = "<a href=\"#change$anchor\">delete($_)</a> " . $outlinks;
                    }
                } elsif ($lastact eq '=') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">4same[$_]</a> " . $outlinks;
                    }
                } elsif ($lastact eq '[') {
                    if ($nii >= 0) {
                        $_ = $nii + 2;
                        $outlinks = "<a href=\"#change$anchor\">move[$_]</a> " . $outlinks;
                    }
                }
                unshift (@diffout, "<a name=\"change$anchor\"></a>");
                $anchor++;
                $lastact = ']';
            }

			unshift (@diffout, sprintf (" %s ] (%d)\n", $oout, $OA[$oii] + 1));
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

    $outlinks = sprintf ("Deleted %4d lines\n" .
                         "Added   %4d lines\n" . 
                         "Moved   %4d lines\n" . 
                         "Same    %4d lines\n", 
                         $deleted, $added, $moved, $same) . 
                "</pre>Links to modified blocks, (old line#), [new line#]: " . $outlinks . "<pre>\n";

    $out = '';
    for ($ln = 0; $ln <= $#diffout; $ln++) {
        $out .= $diffout [$ln];
        if ($ln >= $maxline) {
            last;
        }
    }
    $outlinks . $out;
    #."\n</pre>Links to modified blocks, (old line#), [new line#]: " . $outlinks . "<pre>\n";
}

#perl d:\x\diff.pl d:\x\old.txt d:\x\new.txt > d:\x\x10.txt
#perl d:\x\diff.pl d:\x\new.txt d:\x\old.txt > d:\x\x10.txt
#perl d:\x\diff.pl d:\x\old2.txt d:\x\new2.txt > d:\x\x10.txt
sub l00http_diff_compare {
	my ($sock) = @_;
	my ($ln, $jj, $oii, $nii, $out, $nfor, $nptr);
	my ($text, $mode, $cnt);

    print $sock "<pre>\n";


	# A technique for isolating differences between files
	# Paul Heckel
	# http://documents.scribd.com/docs/10ro9oowpo1h81pgh1as.pdf

	open (LF, "<$oldfile") || print $sock "$oldfile open failed\n";

    print $sock "&lt; Old file: $oldfile\n";
    undef @OLD;
    $cnt = 0;
	while (<LF>) {
        $cnt++;
		s/\r//;
		s/\n//;
		push (@OLD, $_);
	}
    print $sock "    read $cnt lines\n";

	open (RT, "<$newfile") || print $sock "$newfile open failed\n";

    print $sock "&gt; New file: $newfile\n";
    undef @NEW;
    $cnt = 0;
	while (<RT>) {
        $cnt++;
		s/\r//;
		s/\n//;
		push (@NEW, $_);
	}
    print $sock "    read $cnt lines\n\n";

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

    print $sock &l00http_diff_output ();

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
    if (defined ($form->{'maxline'})) {
        if ($form->{'maxline'} =~ /(\d+)/) {
            $maxline = $1;
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

    print $sock "<tr><td>\n";
    print $sock "&nbsp;";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"4\" name=\"maxline\" value=\"$maxline\"> lines max\n";
    print $sock "</td></tr>\n";
    print $sock "</table><br>\n";
    print $sock "</form>\n";


    if (defined ($form->{'compare'})) {
	    &l00http_diff_compare ($sock);
    }


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
