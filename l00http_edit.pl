use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_edit_proc2",
              desc => "l00http_edit_desc2");
my ($buffer, $editwd, $editht, $editsz);
my ($hostpath, $contextln, $blklineno);
$hostpath = "c:\\x\\";
$editsz = 0;
$editwd = 320;
$editht = 7;
$contextln = 1;
$blklineno = 0;


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
    my (@alllines, $line, $lineno, $blkbuf, $tmp, $outbuf);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a> - ";
    print $sock "<a href=\"#end\">Jump to end</a>\n";
    if (defined ($form->{'path'})) {
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=:hide+edit+$form->{'path'}%0D\">Path</a>: ";
        print $sock " <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a>\n";
        print $sock " <a href=\"/ls.htm?path=$form->{'path'}&editline=on\">Edit line link</a>\n";
    }
    print $sock " <a href=\"/ls.htm?path=$form->{'path'}#__toc__\">toc</a>\n";
    
    print $sock "<br>\n";
    $form->{'path'} =~ s/\r//g;
    $form->{'path'} =~ s/\n//g;

    $buffer = '';
    if (defined ($form->{'buffer'})) {
        $buffer = $form->{'buffer'};
    }
    if (defined ($form->{'blklineno'})) {
        if (defined ($form->{'editline'})) {
		    # This is special edit line invocation from ls.pl. Always set to 1 line mode
#           $contextln = 1;
print $sock "contextln $contextln = 1<p>";
#           $blklineno = $form->{'blklineno'};
        }
		if ($blklineno == 0) {
		    # no in block mode; turn it on
            $blklineno = $form->{'blklineno'};
        } else {
            # in block mode
            if ($form->{'blklineno'} < $blklineno) {
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
        $contextln = $form->{'contextln'};
        if ($contextln =~ /^\.\.(\d+)/) {
		    # ..last line
            $contextln = $1 - $blklineno + 1;
        }
        if (($contextln < 1) || ($contextln > 100)) {
            $contextln = 1;
        }
#       $blklineno = 0;     # cancel block mode
    }
    if (defined ($form->{'noblock'})) {
        $blklineno = 0;     # cancel block mode
        # falls through all cases to else to reload
    }
    if (defined ($form->{'save'})) {
        if ((defined ($form->{'path'}) && 
            (length ($form->{'path'}) > 0))) {
            if (!($form->{'path'} =~ /^l00:\/\//)) {
                if ((!defined ($form->{'nobak'})) || ($form->{'nobak'} ne 'on')) {
                    &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 5);
                } else {
                    &l00backup::backupfile ($ctrl, $form->{'path'}, 0, 5);
                }
            }
            if ($blklineno > 0) {
                $blkbuf = '';
                if ($form->{'path'} =~ /^l00:\/\//) {
                    if (defined($ctrl->{'l00file'})) {
                        if (defined($ctrl->{'l00file'}->{$form->{'path'}})) {
                            $blkbuf = $ctrl->{'l00file'}->{$form->{'path'}};
		                }
		            }
	            } elsif (open (IN, "<$form->{'path'}")) {
                    local $/ = undef;
                    $blkbuf = <IN>;
                    close (IN);
                }
            }
            if ((length ($buffer) == 0) &&
               ($blklineno == 0)) {
                # remove if size 0
                if (!($form->{'path'} =~ /^l00:\/\//)) {
                    # only delete disk file
                    unlink ($form->{'path'});
                } else {
                    $ctrl->{'l00file'}->{$form->{'path'}} = '';
                }
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


                if ($form->{'path'} =~ /^l00:\/\//) {
                    $ctrl->{'l00file'}->{$form->{'path'}} = $outbuf;
	            } elsif (open (OUT, ">$form->{'path'}")) {
                    print OUT $outbuf;
                    close (OUT);
                } else {
                    print $sock "Unable to write '$form->{'path'}'<p>\n";
                }
                $buffer = $outbuf;
            }
            $blklineno = 0;     # cancel block mode
        }
    } elsif (defined ($form->{'tempsize'})) {
        $editsz = 1;
        $editwd = $form->{'editwd'};
        $editht = $form->{'editht'};
    } elsif (defined ($form->{'defsize'})) {
        $editsz = 0;
    } elsif (defined ($form->{'edittocb'})) {
        if ($ctrl->{'os'} eq 'and') {
            $ctrl->{'droid'}->setClipboard ($buffer);
        }
    } elsif (defined ($form->{'cbtoedit'})) {
        if ($ctrl->{'os'} eq 'and') {
            $buffer = $ctrl->{'droid'}->getClipboard();
            $buffer = $buffer->{'result'};
        }
    } elsif (defined ($form->{'edittotxt'})) {
        if ($ctrl->{'os'} eq 'and') {
            $buffer = $ctrl->{'droid'}->getClipboard();
            $buffer = $buffer->{'result'};
            if (defined ($form->{'buffer'})) {
                $buffer = "$form->{'buffer'}$buffer";
            }
        }
    } elsif (defined ($form->{'txttoedit'})) {
        if (defined ($form->{'buffer'})) {
            $buffer = "$form->{'buffer'}||";
        }
    } else {
        if ((defined ($form->{'path'})) && (length ($form->{'path'}) > 0)) {
            $tmp = '';
            if ($form->{'path'} =~ /^l00:\/\//) {
                if (defined($ctrl->{'l00file'})) {
                    if (defined($ctrl->{'l00file'}->{$form->{'path'}})) {
                        $tmp = $ctrl->{'l00file'}->{$form->{'path'}};
		            }
		        }
            } elsif (open (IN, "<$form->{'path'}")) {
                # http://www.perlmonks.org/?node_id=1952
                local $/ = undef;
                $tmp = <IN>;
                close (IN);
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
        }
    }
    if (defined ($form->{'clear'})) {
        $buffer = '';
    }



    print $sock "<form action=\"/edit.htm\" method=\"post\">\n";
    if ($editsz) {
        print $sock "<textarea name=\"buffer\" cols=$editwd rows=$editht>$buffer</textarea>\n";
    } else{
        print $sock "<textarea name=\"buffer\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$buffer</textarea>\n";
    }
    print $sock "<p>\n";

    if ($blklineno > 0) {
        print $sock "In block editing mode: editing line ", $blklineno, 
                    " through line ", $blklineno + $contextln - 1, ".<p>\n";
    }
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"save\" value=\"Save\">\n";
    print $sock "<input type=\"text\" size=\"10\" name=\"path\" value=\"$form->{'path'}\">\n";
    # create shell script for vi
    if (open (OUT, ">$ctrl->{'plpath'}l00http_cmdedit.sh")) {
        print OUT "vim $form->{'path'}\n";
        close (OUT);
    }
    print $sock "</td><td>\n";
    if ($blklineno > 0) {
        print $sock "<input type=\"checkbox\" name=\"nobak\" checked>Do not backup\n";
    } else {
        print $sock "<input type=\"checkbox\" name=\"nobak\">Do not backup\n";
    }
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"cbtoedit\" value=\"CB to edit\">\n";
    print $sock "<input type=\"submit\" name=\"edittocb\" value=\"to CB\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"submit\" name=\"clear\" value=\"Clear\">\n";
    print $sock "<input type=\"submit\" name=\"reload\" value=\"Reload\">\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"edittotxt\" value=\"CB append to edit\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"submit\" name=\"txttoedit\" value=\"Append ||\">\n";
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
        print $sock "<input type=\"hidden\" name=\"blklineno\" value=\"$blklineno\">\n";
    }

    print $sock "</table><br>\n";
    print $sock "</form>\n";


    print $sock "<form action=\"/ls.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"cancel\" value=\"Cancel\">\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</form>\n";

    # list ram files
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr>\n";
    print $sock "<td>names</td>\n";
    print $sock "<td>bytes</td>\n";
    print $sock "<td>launcher</td>\n";
    print $sock "</tr>\n";
    # list ram files
    $tmp = $ctrl->{'l00file'};
    foreach $_ (sort keys %$tmp) {
        if (($_ eq 'l00://ram') || (length($ctrl->{'l00file'}->{$_}) > 0)) {
            print $sock "<tr>\n";
            print $sock "<td><small><a href=\"/ls.htm?path=$_\">$_</a></small></td>\n";
            print $sock "<td><small>" . length($ctrl->{'l00file'}->{$_}) . "</small></td>\n";
            print $sock "<td><small><a href=\"/$ctrl->{'lssize'}.htm?path=$_\">launcher</a></small></td>\n";
            print $sock "</tr>\n";
		}
    }
    print $sock "</table>\n";

    if (defined ($form->{'path'})) {
        my ($path, $fname);
        if (($path, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/) {
            print $sock "<pre>\n";
            #print $sock "adb shell ls -l $path$fname\n";
            print $sock "adb pull \"$path$fname\" \"$hostpath$fname\"\n";
            print $sock "$hostpath$fname\n";
            print $sock "adb push \"$hostpath$fname\" \"$path$fname\"\n";
            print $sock "perl $hostpath"."adb.pl $hostpath"."adb.in\n";
            print $sock "</pre>\n";
            print $sock "Send $path$fname to <a href=\"/launcher.htm?path=$path$fname\">launcher</a><p>\n";
            print $sock "<a href=\"/view.htm/$fname.htm?path=$path$fname\">View</a> $path$fname<p>\n";
        }
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
    if ($form->{'path'} =~ /^l00:\/\//) {
        if (defined($ctrl->{'l00file'})) {
            if (defined($ctrl->{'l00file'}->{$form->{'path'}})) {
                $buffer = $ctrl->{'l00file'}->{$form->{'path'}};
		    }
		}
	} elsif (open (IN, "<$form->{'path'}")) {
        local $/ = undef;
        $buffer = <IN>;
        close (IN);
    }
    $buffer =~ s/\r//g;
    @alllines = split ("\n", $buffer);
    foreach $line (@alllines) {
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
        $line =~ s/\r//g;
        $line =~ s/\n//g;
        $line =~ s/</&lt;/g;
        $line =~ s/>/&gt;/g;
        if ($blklineno == 0) {
            print $sock sprintf ("<a href=\"/edit.htm?path=$form->{'path'}&blklineno=$lineno\">%04d</a>: ", $lineno) . "$line\n";
        } else {
            if (($lineno >= $blklineno) && ($lineno < ($blklineno + $contextln))) {
                # selected lines
                print $sock sprintf ("<font style=\"color:black;background-color:lime\">".
                    "<a href=\"/edit.htm?path=$form->{'path'}&blklineno=$lineno\">%04d</a></font>: ", $lineno) . "$line\n";
            } else {
                print $sock sprintf ("<a href=\"/edit.htm?path=$form->{'path'}&blklineno=$lineno\">%04d</a>: ", $lineno) . "$line\n";
            }
        }
        $lineno++;
    }

    print $sock "</pre>\n";
    print $sock "<hr><a name=\"end\"></a>";
    print $sock "<a href=\"#top\">top</a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
