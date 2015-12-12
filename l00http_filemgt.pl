use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my %config = (proc => "l00http_filemgt_proc",
              desc => "l00http_filemgt_desc");
my ($treeto, $treefilecnt, $treedircnt, $nodirmask, $nofilemask);
$treeto = '';
$nodirmask = '';
$nofilemask = '';

sub copytree {
    my ($ctrl, $fr, $to) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($buf, $file);

    #print "($fr, $to)\n";

    $treedircnt++;
    if ((!($to =~ /^\./)) && (!-d $to)) {
        # assume target doesn't exist, make it
        # and not hidden .*
        #print "mkdir >$to<\n";
        mkdir ($to);
	}

    if ((!($to =~ /^\./)) && (-d $to)) {
        # check again, act only target dir exist
        if (opendir (DIR, $fr)) {
            foreach $file (readdir (DIR)) {
                if (($file =~ /^\./) ||
                    ($file =~ /\.orig$/) ||
                    ($file =~ /\.tmp$/) ||
                    ($file =~ /\.bak$/)) {
                    # skip .*, *.orig, *.bak
                    next;
                }
                if (-d $fr.$file) {
                    # directory $file
                    #print "dir >$file<\n";
                    if (($nodirmask eq '') || !($file =~ /$nodirmask/i)) {
                        # if no mask or matched mask, case insensitive
                        &copytree($ctrl, "$fr$file/", "$to$file/");
                    }
                } else {
                    if (($nofilemask eq '') || !($file =~ /$nofilemask/i)) {
                        # if no mask or matched mask, case insensitive
                        #print "cp $to$file\n";
                        # This is not available on Android: use File::Copy qw(copy); 
                        # manually copying...
                        if (open(IN, "<$fr$file")) {
                            if (open(OU, ">$to$file")) {
                                local ($/);
                                $/ = undef;
                                $buf = <IN>;
                                print OU $buf;
                                close(OU);
                                $treefilecnt++;
                            }
                            close(IN);
                        }
                    }
                }
             }
         }
     }

}

sub l00http_filemgt_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "filemgt: Simple file management: delete only";
}

sub l00http_filemgt_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($buffer, $path2);

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
    print $sock "<a href=\"/filemgt.htm?path=$form->{'path'}\">Refresh</a>\n";
    print $sock "<p>\n";

    if ((defined ($form->{'delete'})) &&
        (defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0))) {
        if ($form->{'path'} =~ /^l00:\/\//) {
            # delete original RAM file
            &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
            &l00httpd::l00fwriteClose($ctrl);
        } else {
            if ((!defined ($form->{'nobak'})) || ($form->{'nobak'} ne 'on')) {
                &l00backup::backupfile ($ctrl, $form->{'path'}, 1, 5);
            }
            # delete original disk file
            unlink ($form->{'path'});
            print $sock "Deleted $form->{'path'}<p>\n";
            undef $form->{'path'};
        }
    }

    # copy paste target
    if (defined ($form->{'paste4'})) {
        $form->{'path'} = &l00httpd::l00getCB($ctrl);
    }
    if (defined ($form->{'paste2'})) {
        $form->{'path2'} = &l00httpd::l00getCB($ctrl);
    }
    if ((defined ($form->{'copy'}) || defined ($form->{'append'})) &&
        (defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0)) &&
        (defined ($form->{'path2'}) && 
        (length ($form->{'path2'}) > 0))) {
        if (defined ($form->{'urlonly'})) {
            # URL only, do nothing
        } else {
            $path2 = $form->{'path2'};
            if ($path2 =~ /[\\\/]$/) {
                # $path2 is a directory
                # get name from source
                if ($form->{'path'} =~ /[\\\/]([^\\\/]+)$/) {
                    $path2 .= $1;
                }
            }
            local $/ = undef;
            if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
                if ((!($form->{'path'} =~ /^l00:\/\//)) && 
                    ((!defined ($form->{'nobak'})) || ($form->{'nobak'} ne 'on'))) {
                    &l00backup::backupfile ($ctrl, $path2, 1, 5);
                }
                $buffer = &l00httpd::l00freadAll($ctrl);
                # %TIMESTAMP% replacement: make timestamp
                $_ = $ctrl->{'now_string'};
                s/ /_/g;
                # %TIMESTAMP% replacement: make replacement
                $path2 =~ s/%TIMESTAMP%/$_/;
                if (defined ($form->{'copy'})) {
                    $_ = &l00httpd::l00fwriteOpen($ctrl, $path2);
                } else {
                    $_ = &l00httpd::l00fwriteOpenAppend($ctrl, $path2);
                }
                if ($_) {
                    &l00httpd::l00fwriteBuf($ctrl, $buffer);
                    &l00httpd::l00fwriteClose($ctrl);
                }
            }
        }
    }

    if ((defined ($form->{'move'})) &&
        (defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0)) &&
        (defined ($form->{'path2'}) && 
        (length ($form->{'path2'}) > 0))) {
        if (defined ($form->{'urlonly'})) {
            # URL only, do nothing
        } else {
            $path2 = $form->{'path2'};
            if ($path2 =~ /[\\\/]$/) {
                # $path2 is a directory
                # get name from source
                if ($form->{'path'} =~ /[\\\/]([^\\\/]+)$/) {
                    $path2 .= $1;
                }
            }
            local $/ = undef;
            if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
                if ((!($form->{'path'} =~ /^l00:\/\//)) && 
                    ((!defined ($form->{'nobak'})) || ($form->{'nobak'} ne 'on'))) {
                    &l00backup::backupfile ($ctrl, $path2, 1, 5);
                }
                $buffer = &l00httpd::l00freadAll($ctrl);
                if (&l00httpd::l00fwriteOpen($ctrl, $path2)) {
                    &l00httpd::l00fwriteBuf($ctrl, $buffer);
                    &l00httpd::l00fwriteClose($ctrl);

                    if ($form->{'path'} =~ /^l00:\/\//) {
                        # delete original RAM file
                        &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
                        &l00httpd::l00fwriteClose($ctrl);
                    } else {
                        # delete original disk file
                        unlink ($form->{'path'});
                    }
                }
            }
        }
    }


    # copy tree
    if ((defined ($form->{'treeto'}) && 
        (length ($form->{'treeto'}) > 0))) {
        $treeto = $form->{'treeto'};
    }
    if ((defined ($form->{'copytree'})) &&
        (defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0)) &&
        (defined ($form->{'treeto'}) && 
        (length ($form->{'treeto'}) > 0))) {
        if (defined ($form->{'nodirmask'})) {
            $nodirmask = $form->{'nodirmask'};
        }
        if (defined ($form->{'nofilemask'})) {
            $nofilemask = $form->{'nofilemask'};
        }
        if ((!defined ($form->{'urlonly2'})) || ($form->{'urlonly2'} ne 'on')) {
            $treefilecnt = 0;
            $treedircnt = 0;
            &copytree($ctrl, $form->{'path'}, $form->{'treeto'});
            print $sock "<p>Tree copied $treedircnt directories and $treefilecnt files<p>\n";
        } else {
            print $sock "<p>Made URL<p>\n";
        }
    }
    # copy tree paste target
    if (defined ($form->{'pasteto'})) {
        $treeto = &l00httpd::l00getCB($ctrl);
    }
    if (defined ($form->{'pastefr'})) {
        $form->{'path'} = &l00httpd::l00getCB($ctrl);
    }

    # delete
    if (!defined ($form->{'path'})) {
        $form->{'path'} = '';
    }
    print $sock "<form action=\"/filemgt.htm\" method=\"post\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"delete\" value=\"Delete\">\n";
    print $sock "<input type=\"text\" size=\"10\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</td><td>\n";
    if ((!defined ($form->{'nobak'})) || ($form->{'nobak'} ne 'on')) {
        $_ = '';
    } else {
        $_ = 'checked';
    }
    print $sock "<input type=\"checkbox\" name=\"nobak\" $_>Do not backup\n";
    print $sock "</td></tr>\n";
    print $sock "</table><br>\n";
    print $sock "</form>\n";

    # copy
    if (!defined ($form->{'path'})) {
        $form->{'path'} = '';
    }
    if (defined ($form->{'urlonly'})) {
        # if from URL only, use path2
        $path2 = $form->{'path2'};
    } else {
        if ((length ($form->{'path'}) > 0) &&
            ((!defined ($form->{'path2'})) ||
            (length ($form->{'path2'}) == 0))) {
            $path2 = $form->{'path'};
            # if filename contains extension
            if (!($path2 =~ /\/[^\/.]+$/)) {
                # insert '.2' before extension as target file
                $path2 =~ s/(\.[^.]+)$/.2$1/;
            }
        } else {
            $path2 = $form->{'path2'};
        }
    }
    print $sock "<form action=\"/filemgt.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"copy\" value=\"Copy\">\n";
    print $sock "<input type=\"submit\" name=\"move\" value=\"Move\">\n";
    print $sock "<input type=\"submit\" name=\"append\" value=\"Append\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<a href=\"/launcher.htm?path=$form->{'path'}\">fr:</a> <input type=\"text\" size=\"16\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<a href=\"/launcher.htm?path=$path2\">to:</a> "; #<input type=\"text\" size=\"16\" name=\"path2\" value=\"$path2\">\n";
    print $sock "<textarea name=\"path2\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$path2</textarea>\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    if ((!defined ($form->{'nobak'})) || ($form->{'nobak'} ne 'on')) {
        $_ = '';
    } else {
        $_ = 'checked';
    }
    print $sock "<input type=\"checkbox\" name=\"nobak\" $_>Do not backup\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"checkbox\" name=\"urlonly\">Make URL only\n";
    print $sock "</td></tr>\n";
    if ($ctrl->{'os'} eq 'and') {
        print $sock "<tr><td>\n";
        print $sock "Paste CB to ";
        print $sock "<input type=\"submit\" name=\"paste4\" value=\"'fr:'\"> ";
        print $sock "<input type=\"submit\" name=\"paste2\" value=\"'to:'\">\n";
        print $sock "</td></tr>\n";
    }
    if (defined ($form->{'copy'}) &&
        (defined ($form->{'urlonly'})) && 
        (defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0)) &&
        (defined ($form->{'path2'}) && 
        (length ($form->{'path2'}) > 0))) {
        print $sock "<tr><td>\n";
        print $sock "<a href=\"/filemgt.htm?copy=Copy&path=$form->{'path'}&path2=$form->{'path2'}&urlonly=on\">Copy target URL of this link</a>\n";
        print $sock "</td></tr>\n";
    }
    print $sock "<tr><td>\n";
    print $sock "%TIMESTAMP% is replaced by timestamp in copy to: filename\n";
    print $sock "</td></tr>\n";
    print $sock "</table><br>\n";
    print $sock "</form>\n";

    # copy directory Tree
	# Remove filename leaving directory as source
    $form->{'path'} =~ s/\/[^\/]+$/\//;
    print $sock "<form action=\"/filemgt.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"copytree\" value=\"Copy Tree\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<a href=\"/tree.htm?path=$form->{'path'}\">fr:</a> <input type=\"text\" size=\"16\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<a href=\"/tree.htm?path=$treeto\">to:</a> "; #<input type=\"text\" size=\"16\" name=\"treeto\" value=\"$treeto\">\n";
    print $sock "<textarea name=\"treeto\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$treeto</textarea>\n";
    print $sock "</td></tr>\n";
    if ($ctrl->{'os'} eq 'and') {
        print $sock "<tr><td>\n";
        print $sock "Paste CB to ";
        print $sock "<input type=\"submit\" name=\"pastefr\" value=\"'fr:'\"> ";
        print $sock "<input type=\"submit\" name=\"pasteto\" value=\"'to:'\">\n";
        print $sock "</td></tr>\n";
    }
    print $sock "<tr><td>\n";
    print $sock "Exclude dirs: <input type=\"text\" size=\"16\" name=\"nodirmask\" value=\"$nodirmask\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Exclude files: <input type=\"text\" size=\"16\" name=\"nofilemask\" value=\"$nofilemask\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"checkbox\" name=\"urlonly2\">Make URL only\n";
    print $sock "</td></tr>\n";
#   if ((defined ($form->{'urlonly2'})) && ($form->{'urlonly2'} eq 'on')) {
#       print $sock "<tr><td>\n";
#       print $sock "<a href=\"/filemgt.htm?path=$form->{'path'}&treeto=$form->{'treeto'}&urlonly2=on\">Copy tree URL</a>\n";
#       print $sock "</td></tr>\n";
#   }
    print $sock "</table><br>\n";
    print $sock "</form>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
