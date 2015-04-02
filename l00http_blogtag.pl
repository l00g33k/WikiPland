use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_blogtag_proc",
              desc => "l00http_blogtag_desc");
my ($buffer, $lastbuf);
$lastbuf = '';


sub l00http_blogtag_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "blogtag: Simple blogger: must be invoked through ls.pl file view; insert after %BLOGTAG%";
}

sub l00http_blogtag_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno, $path, $buforg, $tag, $tagfound, $fname);

    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        ($fname) = $path =~ /[\\\/]([^\\\/]+)$/;
    } else {
        $path = '(none)';
        $fname = '(none)';
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>$fname blogtag</title>" .$ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"#end\">Jump to end</a><br>\n";
    if (defined ($form->{'path'})) {
        print $sock "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";
    }

    if (defined ($form->{'tag'})) {
        $tag = $form->{'tag'};
        if ($tag =~ /^ *$/) {
            # form always defines it but may be blank
            $tag = '%BLOGTAG%';
        }
    } else {
        $tag = '%BLOGTAG%';
    }

    $buffer = '';
    if (defined ($form->{'timesave'})) {
        if (defined ($form->{'buffer'})) {
            if (defined ($form->{'blog'})) {
                if ($form->{'blog'} eq "on") {
                    $buffer = substr ($form->{'buffer'}, 25, 9999);
                } else {
                    $buffer = $form->{'buffer'};
                }
            } else {
                $buffer = substr ($form->{'buffer'}, 16, 9999);
            }
        } else {
            $buffer = '';
        }
        if (defined ($form->{'blog'})) {
            if ($form->{'blog'} eq "on") {
                $form->{'buffer'} = "===$ctrl->{'now_string'}===\n* ";
            } else {
                # 'blog' = none
                $form->{'buffer'} = "";
            }
        } else {
            $form->{'buffer'} = $ctrl->{'now_string'} . ' ';
        }
        $form->{'buffer'} .= $buffer;
        $form->{'save'} = 1;
    }
    if (defined ($form->{'pastesave'})) {
        if (defined ($form->{'blog'})) {
            if ($form->{'blog'} eq "on") {
                $form->{'buffer'} = "===$ctrl->{'now_string'}===\n* ";
            } else {
                # 'blog' = none
                $form->{'buffer'} = "";
            }
        } else {
            $form->{'buffer'} = $ctrl->{'now_string'} . ' ';
        }
        $form->{'buffer'} .= &l00httpd::l00getCB($ctrl);
        $form->{'save'} = 1;
    }
    if (defined ($form->{'save'})) {
        if ((defined ($form->{'buffer'})) &&
            ((defined ($form->{'path'})) && 
            (length ($form->{'path'}) > 0))) {
            $buffer = $form->{'buffer'};
            if (($buffer ne $lastbuf) &&
                !($buffer =~ /^\d{8,8} \d{6,6} $/)) {
                $lastbuf = $buffer;
                # don't backup when just appending
                local $/ = undef;
                if (open (IN, "<$form->{'path'}")) {
                    # http://www.perlmonks.org/?node_id=1952
                    local $/ = undef;
                    $buforg = <IN>;
                    close (IN);
                } else {
                    $buforg = '';
                    print $sock "Unable to read original '$form->{'path'}'<p>\n";
                }
                &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 9);
                if (open (OUT, ">$form->{'path'}")) {
                    foreach $line (split ("\n", $buforg)) {
                        if ($line =~ /$tag/) {
                            print OUT "$line\n";
                            last;
                        }
                        print OUT "$line\n";
                    }
                    @alllines = split ("\n", $buffer);
                    foreach $line (@alllines) {
                        $line =~ s/\r//g;
                        $line =~ s/\n//g;
                        if (defined ($form->{'blog'})) {
                            if ($form->{'blog'} eq "on") {
                                print OUT "$line\n";
                            } else {
                                # all on one line
                                print OUT "$line ";
                            }
                        } else {
                            # all on one line
                            print OUT "$line ";
                        }
                    }
                    if (!defined ($form->{'blog'}) || ($form->{'blog'} ne "on")) {
                        print OUT "\n";
                    }
                    $tagfound = 0;
                    foreach $line (split ("\n", $buforg)) {
                        if ($line =~ /$tag/) {
                            $tagfound = 1;
                        } elsif ($tagfound == 1) {
                            print OUT "$line\n";
                        }
                    }
                    close (OUT);
                    $buffer = '';
                     $form->{'buffer'} = '';
                } else {
                    print $sock "Unable to write '$form->{'path'}'<p>\n";
                }
            }
        }
    }
    # do funny tricks to switch log style
    if (defined ($form->{'logstyle'})) {
        $form->{'cancel'} = 'NewTime';
        $form->{'blog'} = undef;
    }
    if (defined ($form->{'blogstyle'})) {
        $form->{'cancel'} = 'NewTime';
        $form->{'blog'} = 'on';
    }
    if (defined ($form->{'blog'})) {
        if ($form->{'blog'} eq "on") {
            $buffer = "===$ctrl->{'now_string'}===\n* ";
        } else {
            $buffer = '';
            if (defined ($form->{'buffer'})) {
                $buffer = $form->{'buffer'};
            }
        }
    } else {
        $buffer = $ctrl->{'now_string'} . ' ';
    }
    if (defined ($form->{'cancel'}) && defined ($form->{'buffer'})) {
        # do funny tricks to switch log style
        if (defined ($form->{'logstyle'})) {
            $buffer .= substr ($form->{'buffer'}, 25, 9999);
        } elsif (defined ($form->{'blogstyle'})) {
            $buffer .= substr ($form->{'buffer'}, 16, 9999);
        } elsif (defined ($form->{'blog'})) {
            if ($form->{'blog'} eq "on") {
                $buffer .= substr ($form->{'buffer'}, 25, 9999);
            } else {
                $buffer = $form->{'buffer'};
            }
        } else {
            $buffer .= substr ($form->{'buffer'}, 16, 9999);
        }
    }
    if (defined ($form->{'paste'})) {
        $buffer .= &l00httpd::l00getCB($ctrl);
    }

    print $sock "<form action=\"/blogtag.htm\" method=\"get\">\n";
    print $sock "<textarea name=\"buffer\" cols=\"$ctrl->{'txtw'}\" rows=\"$ctrl->{'txth'}\">$buffer</textarea>\n";
    print $sock "<p>\n";
    print $sock "<input type=\"submit\" name=\"save\" value=\"Save\">\n";
    print $sock "<input type=\"submit\" name=\"pastesave\" value=\"PasteSave\">\n";
    print $sock "<input type=\"submit\" name=\"paste\" value=\"Paste\">\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    if (defined ($form->{'blog'})) {
        print $sock "<input type=\"hidden\" name=\"blog\" value=\"$form->{'blog'}\">\n";
    }
    print $sock "<br><input type=\"submit\" name=\"timesave\" value=\"TimeSave\">\n";
    print $sock "<input type=\"submit\" name=\"cancel\" value=\"NewTime\">\n";
    if (defined ($form->{'blog'})) {
        print $sock "<input type=\"submit\" name=\"logstyle\" value=\"Log style add\">\n";
    } else {
        print $sock "<input type=\"submit\" name=\"blogstyle\" value=\"Blog style add\">\n";
    }
    print $sock "<br>BLOGTAG: <td><input type=\"text\" size=\"12\" name=\"tag\" value=\"$tag\"></td>\n";
    print $sock "</form><br>Append '&blog=' to URL for bare style\n";

    # get submitted name and print greeting
    if (open (IN, "<$form->{'path'}")) {
        $lineno = 1;
        print $sock "<pre>\n";
        while (<IN>) {
            s/\r//g;
            s/\n//g;
            # limit sneak preview to 'blogmaxln' lines and 'blogwd' wide
            if ($lineno < $ctrl->{'blogmaxln'}) {
                if (length($_) > $ctrl->{'blogwd'}) {
                    $_ = substr($_, 0, $ctrl->{'blogwd'});
                }
                print $sock sprintf ("%04d: ", $lineno) . "$_\n";
            }
            $lineno++;
        }
        close (IN);
        if ($lineno >= $ctrl->{'blogmaxln'}) {
            print $sock sprintf ("(lines skipped)\n");
            print $sock sprintf ("%04d: ", $lineno) . "$line\n";
        }
        print $sock "</pre>\n";
        print $sock "Path: <a href=\"/view.htm?path=$form->{'path'}\">View full formatted text</a><br>\n";
    }
    print $sock "<hr><a name=\"end\">end</a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
