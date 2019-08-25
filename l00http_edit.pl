use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

#l00httpd::dbp($config{'desc'}, "2 contextln $contextln\n");
my %config = (proc => "l00http_edit_proc2",
              desc => "l00http_edit_desc2");
my ($buffer, $editwd, $editht, $editsz);
my ($contextln, $blklineno, $blkfname, $lineeval);
$editsz = 0;
$editwd = 0;
$editht = 0;
$contextln = 1;
$blklineno = 0;
$blkfname = '';
$lineeval = 's/a/a/g';

sub l00http_edit_desc2 {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "edit: must be invoked through ls.pl file view";
}

sub l00http_edit_proc2 {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno, $blkbuf, $tmp, $outbuf, $st, $en);
	my ($pname, $fname, $rsyncpath, $lineclip, $diffurl, $lineno1);
    my ($thischlvl, $lastchlvl, @chlvls, @el, $ii);

    $diffurl  = '';

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#end\">Jump to end</a>\n";

    if ($editwd == 0) {
        if (defined($ctrl->{'txtwbig'})) {
            $editwd = $ctrl->{'txtwbig'};
        } else {
            $editwd = 160;
        }
    }
    if ($editht == 0) {
        if (defined($ctrl->{'txthbig'})) {
            $editht = $ctrl->{'txthbig'};
        } else {
            $editht = 30;
        }
    }

    l00httpd::dbphash($config{'desc'}, 'FORM', $form), if ($ctrl->{'debug'} >= 5);

    if ((defined($form->{'pathorg'})) &&
        ($contextln > 1) &&
        ($blklineno > 0)) {
        $form->{'path'} = $form->{'pathorg'};
        if (defined($form->{'editsorted'})) {
			if (&l00httpd::l00freadOpen($ctrl, 'l00://editblock.txt')) {
                $form->{'buffer'} = &l00httpd::l00freadAll($ctrl);
                $form->{'save'} = 1;    # fake a save from buffer
			}
        }
    }

    if (defined ($form->{'path'})) {
        ($pname, $fname) = $form->{'path'} =~ /^(.+[\\\/])([^\\\/]+)$/;
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$form->{'path'}%0D\">Path</a>: ";
        print $sock " <a href=\"/ls.htm?path=$pname\">$pname</a>";
        print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$fname</a> \n";
        print $sock " <a href=\"/ls.htm?path=$form->{'path'}&editline=on\">Edit line link</a>\n";
    }
    print $sock " <a href=\"/ls.htm?path=$form->{'path'}#__toc__\">toc</a>\n";
    
    print $sock "<br>\n";
    $form->{'path'} =~ s/\r//g;
    $form->{'path'} =~ s/\n//g;

    if ($blkfname ne $form->{'path'}) {
        # cancel block mode because we are on different file
        $blklineno = 0;
   		$contextln = 1;
		$blkfname = '';
	}

    $buffer = '';
    if (defined ($form->{'buffer'})) {
        $buffer = $form->{'buffer'};
    }
    if (defined ($form->{'clip'})) {
        # A non-interactive feature. Allow [[/edit.htm?path=$&clip=30-45|edit.htm]]
        # to copy specified lines directly to clipboard
        if (($blklineno, $contextln) = $form->{'clip'} =~ /(\d+)-(\d+)/) {
            # but $contextln is provided as line number
            $contextln -= $blklineno - 1;
        } elsif (($blklineno, $contextln) = $form->{'clip'} =~ /(\d+)_(\d+)/) {
            # $contextln is provided as number of lines
        } else {
            $blklineno = 0;     # cancel block mode
            $contextln = 1;
		    $blkfname = '';
            $form->{'clip'} = undef;
        }
    }
    if (defined ($form->{'blklineno'})) {
		$blkfname = $form->{'path'};
        if (defined ($form->{'editline'})) {
            # edit line from ls.pl
            $contextln = 1;
            $blklineno = $form->{'blklineno'};
        } elsif ($blklineno == 0) {
		    # no in block mode; turn it on
            $blklineno = $form->{'blklineno'};
        } else {
		    # in block mode
            if (($form->{'blklineno'} == $blklineno) && ($contextln > 1)) {
                # when a block has been selected, selecting the first line clears block
                $form->{'noblock'} = 1;
            } elsif (($form->{'blklineno'} == ($blklineno + $contextln - 1) &&
			    $contextln >= 1)) {
                # when a block has been selected, selecting the last line clears block 
                # and reselect the last line
           	    $blklineno = $form->{'blklineno'};
       	        $contextln = 1;
            } elsif ($form->{'blklineno'} < $blklineno) {
			    # selected line before start, expand start
       	        $contextln += ($blklineno - $form->{'blklineno'});
           	    $blklineno = $form->{'blklineno'};
            } elsif ($form->{'blklineno'} > ($blklineno + $contextln - 1)) {
			    # selected line after end, expand end
       	        $contextln += ($form->{'blklineno'} - ($blklineno + $contextln - 1));
           	} elsif ($form->{'blklineno'} < ($blklineno + $contextln / 2)) {
		    	# selected line after start but before half, move start
                $contextln -= $form->{'blklineno'} - $blklineno;
   	            $blklineno = $form->{'blklineno'};
       	    } else {
			    # selected line after start and after  half, move end
               	$contextln -= ($blklineno + $contextln - 1) - $form->{'blklineno'};
           	}
        }
    }
    if (defined ($form->{'context'})) {
        # setting number of lines as context
        $contextln = $form->{'contextln'};
        if ($contextln =~ /^\.\.(\d+)/) {
		    # ..last line
            $contextln = $1 - $blklineno + 1;
        }
        if (($contextln < 1) || ($contextln > 100)) {
            $contextln = 1;
        }
    }
    if (defined ($form->{'noblock'})) {
        $blklineno = 0;     # cancel block mode
        $contextln = 1;
		$blkfname = '';
        # falls through all cases to else to reload
    }

    if (defined ($form->{'arc'}) &&
        (defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0))) {
        # save to {'path'].datestamp.arc
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            ($tmp) = $ctrl->{'now_string'} =~ /^(\d+) /;
            $tmp = "$form->{'path'}.$tmp.arc";
            &l00httpd::l00fwriteOpen($ctrl, $tmp);
            &l00httpd::l00fwriteBuf($ctrl, &l00httpd::l00freadAll($ctrl));
            &l00httpd::l00fwriteClose($ctrl);
        }
    } elsif (defined ($form->{'save'})) {
        if ((defined ($form->{'path'}) && 
            (length ($form->{'path'}) > 0))) {
            if (!($form->{'path'} =~ /^l00:\/\//)) {
                if ((!defined ($form->{'nobak'})) || ($form->{'nobak'} ne 'on')) {
                    &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 5);
                    $diffurl = "URL to <a href=\"/diff.htm?compare=Compare&width=20".
                        "&pathnew=$form->{'path'}".
                        "&pathold=$form->{'path'}.bak".
                        "&hide=on&maxline=4000#diffchanges\" target=\"_blank\">".
                        "compare previous and current versions</a><p>\n";
                } else {
                    &l00backup::backupfile ($ctrl, $form->{'path'}, 0, 5);
                    $diffurl = "URL to <a href=\"/diff.htm?compare=Compare&width=20".
                        "&pathnew=$form->{'path'}".
                        "&pathold=$form->{'path'}.-.bak".
                        "&hide=on&maxline=4000#diffchanges\" target=\"_blank\">".
                        "compare previous and current versions</a><p>\n";
                }
            }
            # allow &clear=&save= to delete file from URL
            if (defined ($form->{'clear'})) {
                $buffer = '';
            }
            if ($blklineno > 0) {
                $blkbuf = '';
                if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
                    $blkbuf = &l00httpd::l00freadAll($ctrl);
                }
            }
            if ((length ($buffer) == 0) &&
               ($blklineno == 0)) {
                # remove if size 0
                &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
                &l00httpd::l00fwriteClose($ctrl);
            } else {
                $outbuf = '';
                # http://www.perlmonks.org/?node_id=1952
                # block mode: write before context
                if ($blklineno > 0) {
                    $blkbuf =~ s/\r//g;
                    $lineno = 1;
                    foreach $line (split ("\n", $blkbuf)) {
                        if ($lineno >= ($blklineno)) {
                            last;
                        }
                        $line =~ s/\n//g;
                        $outbuf .= "$line\n";
                        $lineno++;
                    }
                }
                $buffer =~ s/\r//g;
                @alllines = split ("\n", $buffer);
                foreach $line (@alllines) {
                    $line =~ s/\n//g;
                    $outbuf .= "$line\n";
                }
                # block mode: write after context
                if ($blklineno > 0) {
                    $lineno = 0;
                    foreach $line (split ("\n", $blkbuf)) {
                        $lineno++;
                        if ($lineno <= ($blklineno + $contextln - 1)) {
                            next;
                        }
                        $line =~ s/\n//g;
                        $outbuf .= "$line\n";
                    }
                }
                close (OUT);


                &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
                &l00httpd::l00fwriteBuf($ctrl, $outbuf);
                if (&l00httpd::l00fwriteClose($ctrl)) {
                    print $sock "Unable to write '$form->{'path'}'<p>\n";
                }
                $buffer = $outbuf;
            }
            $blklineno = 0;     # cancel block mode
            $contextln = 1;
			$blkfname = '';
        }
    } elsif (defined ($form->{'lineproc'}) || defined ($form->{'linesave'})) {
        # line processor
        if (defined ($form->{'lineeval'}) && (length ($form->{'lineeval'}) > 0)) {
            $lineeval = $form->{'lineeval'};
        } else {
            $lineeval = 's/a/a/g';
        }
        $buffer = '';
        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            print $sock "Line processor running: '$lineeval'<p>\n<pre>\n";
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                if ($lineeval ne '') {
                    eval "$lineeval";
                }
                $buffer .= $_;
            }
            print $sock "</pre>\n";
        }
        if (defined ($form->{'linesave'})) {
            &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
        } else {
            &l00httpd::l00fwriteOpen($ctrl, 'l00://lineproc.txt');
        }
        &l00httpd::l00fwriteBuf($ctrl, $buffer);
        &l00httpd::l00fwriteClose($ctrl);
    } elsif (defined ($form->{'tempsize'})) {
        $editsz = 1;
        $editwd = $form->{'editwd'};
        $editht = $form->{'editht'};
    } elsif (defined ($form->{'defsize'})) {
        $editsz = 0;
    } elsif (defined ($form->{'cut'})) {
        &l00httpd::l00setCB($ctrl, $buffer);
        $buffer = '';
    } elsif (defined ($form->{'edittocb'})) {
        &l00httpd::l00setCB($ctrl, $buffer);
    } elsif (defined ($form->{'cbtoedit'})) {
        $buffer = &l00httpd::l00getCB($ctrl);
    } elsif (defined ($form->{'delchno'})) {
        @alllines = split ("\n", $buffer);
        $buffer = '';
        foreach $line (@alllines) {
            $line =~ s/\n//g;
            if ($line =~ /^(=+)(\d+[0-9.]*\. )(.+)$/) {
                $line = "$1$3";
            }
            $buffer .= "$line\n";
        }
    } elsif (defined ($form->{'addchno'})) {
        @alllines = split ("\n", $buffer);
        $buffer = '';
        undef $lastchlvl;
        foreach $line (@alllines) {
            $line =~ s/\n//g;
            # first remove prefix, if any
            if ($line =~ /^(=+)(\d+[0-9.]*\. )(.+)$/) {
                $line = "$1$3";
            }
            # then add prefix
            if (@el = $line =~ /^(=+)([^=]+?)(=+)(.*)$/) {
                if ($el[0] eq $el[2]) {
                    $thischlvl = length($el[0]);
                    if (defined ($lastchlvl)) {
                        # increment current chapter level
                        if ($lastchlvl == $thischlvl) {
                            # increment current level
                            if (!defined ($chlvls[$thischlvl])) {
                                # 1 if non existent
                                $chlvls[$thischlvl] = 1;
                            } else {
                                # else increment
                                $chlvls[$thischlvl]++;
                            }
                            # create if non existence
                            for ($ii = 1; $ii < $thischlvl; $ii++) {
                                if (!defined ($chlvls[$ii])) {
                                    # 1 if non existent
                                    $chlvls[$ii] = 1;
                                }
                            }
                        } elsif ($lastchlvl > $thischlvl) {
                            # increment higher level
                            $chlvls[$thischlvl]++;
                        } else { # ($lastchlvl < $thischlvl)
                            # increment lower level
                            for ($ii = $lastchlvl + 1; $ii <= $thischlvl; $ii++) {
                                $chlvls[$ii] = 1;
                            }
                        }
                    } else {
                        # this is the first time ever.  Everything starts at 1.1.
                        for ($ii = 1; $ii <= $thischlvl; $ii++) {
                            $chlvls[$ii] = 1;
                        }
                    }
                    $tmp = '';
                    for ($ii = 1; $ii <= $thischlvl; $ii++) {
                        $tmp .= "$chlvls[$ii].";
                    }
                    $lastchlvl = $thischlvl;
                    # no line number in chapter title # $el[1] = "$tmp $el[1] ($lnno)";
                    if ($line =~ /^(=+)(.+)$/) {
                        $line = "$1$tmp $2";
                    }
                }
            }
            $buffer .= "$line\n";
        }
    } elsif (defined ($form->{'prependtotxt'})) {
        $buffer = &l00httpd::l00getCB($ctrl);
        if (defined ($form->{'buffer'})) {
            $buffer = "$buffer$form->{'buffer'}";
        }
    } elsif (defined ($form->{'edittotxt'})) {
        $buffer = &l00httpd::l00getCB($ctrl);
        if (defined ($form->{'buffer'})) {
            $buffer = "$form->{'buffer'}$buffer";
        }
    } elsif (defined ($form->{'txttoedit'})) {
        if (defined ($form->{'buffer'})) {
            $buffer = "$form->{'buffer'}||";
        }
    } else {
        if ((defined ($form->{'path'})) && (length ($form->{'path'}) > 0)) {
            $tmp = '';
            if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
                $tmp = &l00httpd::l00freadAll($ctrl);
            }
            $lineno = 1;
            $buffer = '';
            foreach $_ (split ("\n", $tmp)) {
                $_ .= "\n";
                if ($blklineno == 0) {
                    $buffer .= $_;
                } else {
                    # block mode
                    if (($lineno >= ($blklineno)) && 
                        ($lineno <= ($blklineno + $contextln - 1))) {
                        $buffer .= $_;
                    }
                }
                $lineno++;
            }
            if (defined ($form->{'appbookmark'})) {
                # append %BOOKMARK% and %END%
                $buffer .= "%BOOKMARK%\n* \n\n%END%\n";
            }
        }
    }
    if (defined ($form->{'clear'})) {
        $buffer = '';
    }

    if (defined ($form->{'clip'})) {
        &l00httpd::l00setCB($ctrl, $buffer);
    }


    print $sock "<form action=\"/edit.htm\" method=\"post\">\n";
    if ($editsz) {
        print $sock "<textarea name=\"buffer\" cols=$editwd rows=$editht accesskey=\"e\">$buffer</textarea>\n";
    } else{
        print $sock "<textarea name=\"buffer\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'} accesskey=\"e\">$buffer</textarea>\n";
    }

    if ($blklineno > 0) {
        $_ = $blklineno - 1;
        print $sock "<br>In block editing mode: editing line ", 
                    "<a href=\"#line$_\">$blklineno</a>", 
                    " through line ", $blklineno + $contextln - 1, ".\n";
        print $sock "<a href=\"/editsort.htm?init=on&pathorg=$form->{'path'}\">Sort selected block.</a><p>\n";

    }
    print $sock "<table border=\"3\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"save\" value=\"S&#818;ave\" accesskey=\"s\">\n";
    print $sock "<input type=\"text\" size=\"10\" name=\"path\" value=\"$form->{'path'}\">\n";
    # create shell script for vi
    if (open (OUT, ">$ctrl->{'plpath'}l00http_cmdedit.sh")) {
        if ($blklineno > 0) {
            $_ = "+$blklineno";
        } else {
            $_ = '';
        }
        print OUT "vim $_ $form->{'path'}\n";
        close (OUT);
    }
    print $sock "</td><td>\n";
    if ($blklineno > 0) {
        print $sock "<input type=\"checkbox\" name=\"nobak\" checked>No backup\n";
    } else {
        print $sock "<input type=\"checkbox\" name=\"nobak\">No backup\n";
    }
    print $sock "<input type=\"submit\" name=\"arc\" value=\"arc\">\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"cbtoedit\" value=\"CB to edit\">\n";
    print $sock "<input type=\"submit\" name=\"edittocb\" value=\"t&#818;o CB\" accesskey=\"t\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"submit\" name=\"clear\" value=\"Clear\">\n";
    print $sock "<input type=\"submit\" name=\"reload\" value=\"R&#818;eload\" accesskey=\"r\">\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"edittotxt\" value=\"append to edit\">\n";
    print $sock "<input type=\"submit\" name=\"prependtotxt\" value=\"pre\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"submit\" name=\"txttoedit\" value=\"Append ||\">\n";
    print $sock "<input type=\"submit\" name=\"cut\" value=\"Cut\">\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"appbookmark\" value=\"Add BKMK\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"submit\" name=\"addchno\" value=\"Add #ch prefix\">\n";
    print $sock "<input type=\"submit\" name=\"delchno\" value=\"Del\">\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"tempsize\" value=\"Edit box size\"><br>\n";
    print $sock "wd <input type=\"text\" size=\"4\" name=\"editwd\" value=\"$editwd\">\n";
    print $sock "ht <input type=\"text\" size=\"4\" name=\"editht\" value=\"$editht\">\n";
    print $sock "</td><td>\n";
    print $sock "&nbsp;\n";
    print $sock "<input type=\"submit\" name=\"defsize\" value=\"Default edit size\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"context\" value=\"Set #lines\"><br>\n";
    print $sock "#ln <input type=\"text\" size=\"3\" name=\"contextln\" value=\"$contextln\">\n";
    print $sock "<a href=\"/edit.htm?path=$form->{'path'}&context=Set+context&contextln=1\">#1</a>\n";
    print $sock "<a href=\"/edit.htm?path=$form->{'path'}&context=Set+context&contextln=2\">#2</a>\n";
    print $sock "<a href=\"/edit.htm?path=$form->{'path'}&context=Set+context&contextln=3\">#3</a>\n";
    print $sock "<a href=\"/edit.htm?path=$form->{'path'}&context=Set+context&contextln=4\">#4</a>\n";
    print $sock "<a href=\"/edit.htm?path=$form->{'path'}&context=Set+context&contextln=5\">#5</a>\n";
    print $sock " or ..last</td><td>\n";
    print $sock "<input type=\"submit\" name=\"noblock\" value=\"Cancel block mode\"><br>\n";
    print $sock "</td></tr>\n";

    if ($blklineno > 0) {
#        print $sock "<input type=\"hidden\" name=\"blklineno\" value=\"$blklineno\">\n";
    }

    print $sock "</table><br>\n";
    print $sock "</form>\n";

    print $sock "<p>$diffurl\n";


    print $sock "<form action=\"/ls.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"cancel\" value=\"Cancel\">\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</form>\n";


    print $sock "<p>\n";
    print $sock "<form action=\"/edit.htm\" method=\"post\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"lineproc\" value=\"Process\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"10\" name=\"lineeval\" value=\"$lineeval\">\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"linesave\" value=\"Process & Save\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"10\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "&nbsp;";
    print $sock "</td><td>\n";
    print $sock "<a href=\"/diff.htm?compare=Compare&width=20&pathnew=l00%3A%2F%2Flineproc.txt&pathold=$form->{'path'}&maxline=4000\" target=\"_blank\">diff results</a>\n";
    print $sock "</td></tr>\n";

    print $sock "</table><br>\n";
    print $sock "</form>\n";

    if (defined ($form->{'path'})) {
        my ($path, $fname);
        if (($path, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/) {
            print $sock "Send $path$fname to <a href=\"/launcher.htm?path=$path$fname\">launcher</a><p>\n";
            print $sock "<a href=\"/view.htm/$fname.htm?path=$path$fname\">View</a>: $path$fname<p>\n";
            print $sock "<a href=\"/timestamp.htm\">Timestamp</a><p>\n";
        }
        print $sock &l00httpd::pcSyncCmdline($ctrl, $form->{'path'});
        #print $sock "You can connect from your desktop, copy the buffer content and paste into your favorite editor, and paste it back into the edit area after your editing.<p>\n";

        print $sock "<a href=\"/ls.htm?path=$form->{'path'}.bak\">bak</a> \n";
        print $sock "<a href=\"/ls.htm?path=$form->{'path'}.2.bak\">2.bak</a> \n";
        print $sock "<a href=\"/ls.htm?path=$form->{'path'}.3.bak\">3.bak</a> \n";
        print $sock "<a href=\"/ls.htm?path=$form->{'path'}.-.bak\">(-.bak)</a> \n";
        print $sock "<br>\n";
    }

    # get submitted name and print greeting
    print $sock "<p><pre>\n";
    $lineno = 1;
    $buffer = '';
    if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
        $buffer = &l00httpd::l00freadAll($ctrl);
    }
    $buffer =~ s/\r//g;
    @alllines = split ("\n", $buffer);
    if ($blklineno > 0) {
        &l00httpd::l00fwriteOpen($ctrl, 'l00://editblock.txt');
    }
    $st = 0;
    $en = $#alllines;
    # handling big file
    if ($en > 5000) {
        # arbitrary partial file handling for files longer than 5000 lines
        if ($blklineno > 0) {
            # block editing
            $st = $blklineno - 20;
            if ($st < 0) {
                $st = 0;
            }
            $en = $blklineno + $contextln + 2000;
            if ($en > $#alllines) {
                $en = $#alllines;
            }
        } else {
            # not block editing
            # just list first 5000 lines
            $en = 5000;
        }
    }
    for ($lineno = $st; $lineno <= $en; $lineno++) {
        $line = $alllines[$lineno];
        if ($blklineno != 0) {
            if (($lineno + 1 >= $blklineno) && ($lineno + 1 < ($blklineno + $contextln))) {
                # because $lineno is 0 base, $blklineno is 1 base
                # also send selected lines to ram file
                &l00httpd::l00fwriteBuf($ctrl, "$line\n");
            }
        }
        print $sock "<a name=\"line$lineno\"></a>";
	    if (($lineno % 100) == 1) {
            print $sock "    jump to line ";
            print $sock "<a href=\"#top\">top</a> ";
            if ($lineno - 100 > 0) {
                print $sock "<a href=\"#line",$lineno - 100 ."\">",$lineno - 100 ."</a> ";
			}
            if ($lineno + 100 <= $#alllines + 1) {
                print $sock "<a href=\"#line",$lineno + 100 ."\">",$lineno + 100 ."</a> ";
			} else {
                print $sock "<a href=\"#line",$#alllines + 1 ."\">",$#alllines + 1 ."</a> ";
			}
            print $sock "<a href=\"#end\">end</a> ";
            print $sock "\n";
		}
        $lineclip = &l00httpd::urlencode ($line);
        $lineclip = "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=" . $lineclip . "\" target=\"_blank\">cb</a>";
        $line =~ s/\r//g;
        $line =~ s/\n//g;
        $line =~ s/</&lt;/g;
        $line =~ s/>/&gt;/g;
        $lineno1 = $lineno + 1;
        if ($blklineno == 0) {
            print $sock sprintf ("<a href=\"/edit.htm?path=$form->{'path'}&blklineno=$lineno1\">%04d</a>-%s: ", $lineno1, $lineclip) . "$line\n";
        } else {
            if (($lineno1 >= $blklineno) && ($lineno1 < ($blklineno + $contextln))) {
                # selected lines
                print $sock sprintf ("<font style=\"color:black;background-color:lime\">".
                    "<a href=\"/edit.htm?path=$form->{'path'}&blklineno=$lineno1\">%04d</a></font>-%s: ", $lineno1, $lineclip) . "$line\n";
            } else {
                print $sock sprintf ("<a href=\"/edit.htm?path=$form->{'path'}&blklineno=$lineno1\">%04d</a>-%s: ", $lineno1, $lineclip) . "$line\n";
            }
        }
    }
    if ($en < $#alllines) {
        $en++;
        $tmp = $#alllines + 1;
        print $sock "Only $en lines of the total $tmp lines are displayed\n";
    }

    if ($blklineno > 0) {
        &l00httpd::l00fwriteClose($ctrl);
    }

    print $sock "</pre>\n";
    print $sock "<hr><a name=\"end\"></a>";
    print $sock "<a href=\"#top\">top</a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
