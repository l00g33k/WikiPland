use strict;
use warnings;
use l00wikihtml;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_srcdoc_proc",
              desc => "l00http_srcdoc_desc");
my ($editwd, $editht, $editsz, $root, $filter);
my ($hostpath, $contextln, $blklineno, $level);
$hostpath = "c:\\x\\";
$editsz = 0;
$editwd = 320;
$editht = 7;
$contextln = 0;
$blklineno = 0;
$root = '';
$filter = '\.c$|||\.cpp$|||\.h$';
$level = 3;

sub l00http_srcdoc_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "srcdoc: source documentation helper";
}

sub l00http_srcdoc_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno, $blkbuf, $tgtline, $tgtln);
    my ($pname, $fname, $comment, $buffer, $tmp, $tmp2, $lnno, $uri, $ii, $cmd, $lasthdrlvl);
    my ($gethdr);

if (defined ($form->{'navigate'})) {
        # create two-pane frameset
        print $sock "<html>\n";
        print $sock "<head>\n";
        print $sock "<title>$form->{'path'}</title>\n";
        print $sock "</head>\n";
        print $sock "<frameset cols=\"60%,*\">\n";
#       print $sock "<frame name=\"nav\" src=\"http://localhost:20337/srcdoc.htm?path=$form->{'path'}\">\n";
        print $sock "<frame name=\"nav\" src=\"/srcdoc.htm?path=$form->{'path'}\">\n";
        print $sock "<frame name=\"content\">\n";
        print $sock "</frameset>\n";

        print $sock $ctrl->{'htmlfoot'};
} else {
    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a> - ";
    print $sock "<a href=\"#end\">Jump to end</a>\n";
	print $sock "<a href=\"#__toc__\">toc</a>\n";
    # process now because we need to print Path: ...
    $uri = '';
    if (defined ($form->{'srcdocpath'})) {
        #http://localhost:20337/srcdoc.htm?path=D:/wal/wk/Android/workspace/com.mds.Mmote.MainActivity/src/com/mds/Mmote/MainActivity.java&lineno=on#line31
        $tmp = $form->{'path'};
        $form->{'path'} = $form->{'srcdocpath'};
        $form->{'srcdocpath'} = $tmp;
        $form->{'lnno'} = $form->{'docline'};
        # http://localhost:20337/view.htm?path=D:/wal/wk/Android/workspace/com.mds.Mmote.MainActivity/src/com/mds/Mmote/MainActivity.java&lineno=on#line31
        $tmp = $form->{'tgtline'} - 10;
        if ($tmp < 0) {
            $tmp = 1;
        }
        $uri = "/view.htm?path=$form->{'srcdocpath'}&lineno=on&hilite=$form->{'tgtline'}#line$tmp";
    }
    if (defined ($form->{'path'})) {
        $form->{'path'} =~ s/\r//g;
        $form->{'path'} =~ s/\n//g;
        print $sock " Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a>\n";
    }
    print $sock "<br>\n";


    if (defined ($form->{'srcdocpath'})) {
        print $sock "<font style=\"color:black;background-color:lime\">Step 3: Enter notes in 'Desc'</font><br>\n";
        print $sock "First line of 'Desc' is heading.  Additional lines are bullet items<br>\n";
    }

    # save heading level hint
    if (defined ($form->{'lnnolvl'})) {
        $level = $form->{'lnnolvl'};
    }

    # got target line, process
    if (defined ($form->{'lnno'})) {
        if (defined ($form->{'pastesave'})) {
            if ($ctrl->{'os'} eq 'and') {
                $form->{'url'} = $ctrl->{'droid'}->getClipboard()->{'result'};
                $form->{'save'} = 1;
            }
        }
        if (defined ($form->{'save'})) {
            if ((defined ($form->{'path'}) && 
                (length ($form->{'path'}) > 0)) &&
                (defined ($form->{'comment'}) && 
                (length ($form->{'comment'}) > 0))) {
                if (open (IN, "<$form->{'path'}")) {
                    print $sock "<font style=\"color:black;background-color:yellow\">Repeat: Choose 'Insert notes here'</font><br>\n";
                    $buffer = '';
                    $tmp = 0;
                    while (<IN>) {
                        $tmp++;
                        if ($tmp == $form->{'lnno'}) {
                            $comment = '';
                            if (defined ($form->{'comment'})) {
                                $comment = $form->{'comment'};
                            }
                            $ii = 0;
                            $gethdr = 1;
                            foreach $cmd (split("\n", $comment)) {
                                $cmd =~ s/\r//;
                                $ii++;
                                if (($ii == 1) && 
                                    ($cmd =~ /^([C-Z]:\\.+?)\((\d+)\):/)) {
                                    # MSDEV input
                                    #D:\w\ATI_PR3\unfuddle\casa\TDD\tddDlg.cpp(1031): ButtonDisable(m_bmap);
                                    $tmp = $2 - 10;
                                    if ($tmp < 1) {
                                        $tmp = 1;
                                    }
                                    $form->{'url'} = "/view.htm?path=$1&lineno=on&hilite=$2#line$tmp";
                                } elsif ($gethdr) {
                                    $gethdr = 0;
                                    if (defined ($form->{'level'})) {
								        $level = $form->{'level'};
									}
						            $tmp2 = "=" x $level;
                                    $buffer .= "$tmp2$cmd$tmp2\n";
                                } else {
                                    $buffer .= "* $cmd\n";
                                }
                            }
                            if (defined ($form->{'url'}) && 
                                (length ($form->{'url'}) > 0)) {
                                # remove http://ip:port
                                $form->{'url'} =~ s|http://[^/]+/|/|;
                                #$buffer .= "* <a target=\"source\" href=\"$form->{'url'}\">view source</a>";
                                # /view.htm?path=D:/w/ATI_PR3/unfuddle/casa/TDD/tddDlg.cpp&lineno=on&hilite=1021#line1011
                                if (($fname, $tgtline) = $form->{'url'} =~ /path=(.+?)&.*hilite=(\d+)/) {
								    if (open (SRC, "<$fname")) {
									    $tmp2 = $_;
										$tgtln = $tgtline;
    								    while (<SRC>) {
    								        if ($tgtline-- == 1) {
											    s/ /+/g;
												s/:/%3A/g;
												s/&/%26/g;
												s/=/%3D/g;
												s/"/%22/g;
												s/\//%2F/g;
												s/\|/%7C/g;
												s/\n//;
												s/\r//;
                                                if (!($root =~ /\|\|\|/)) {
                                                    $fname =~ s/^$root//;
                                                }
                                                # change \ or /
                                                if ($ctrl->{'os'} eq 'and') {
                                                    $fname =~ tr/\\/\//;
                                                }
                                                if ($ctrl->{'os'} eq 'win') {
                                                    $fname =~ tr/\//\\/;
                                                }
                                                $buffer .= "<pre>View <i><a target=\"content\" href=\"$form->{'url'}\">$fname($tgtln):</a></i>";
												s/\+/ /g;
												s/\%([a-fA-F0-9]{2})/pack("C", hex($1))/seg;
                                                # prevent wikiwords
                                                s/ ([A-Z]+[a-z])/ !$1/g;
                                                $buffer .= "\n$_</pre>";
                                                $buffer .= "<!-- :file:line:$fname:$tgtln: -->";
											    last;
                                            }
                                        }
									    $_ = $tmp2;
									    close (SRC);
                                    }
                                }
                                $buffer .= "\n";
                            }
                        }
                        $buffer .= $_;
                    }
                    close (IN);
                    open (OUT, ">$form->{'path'}");
                    print OUT $buffer;
                    close (OUT);
                } else {
                    print $sock "Unable to write '$form->{'path'}'<p>\n";
                }
            }
        } else {
            if (!defined ($form->{'srcdocpath'})) {
                print $sock "<font style=\"color:black;background-color:lime\">Step 2:</font>\n";
                $tmp = "$form->{'path'}&docline=$form->{'lnno'}";
                $tmp =~ s/&/%26/g;
                $tmp =~ s/=/%3D/g;
                $tmp =~ s/\//%2F/g;
                $tmp =~ s/\\/%2F/g;
                $tmp2 = $filter;
                $tmp2 =~ s/\\/%5C/g;
                $tmp2 =~ s/\|/%7C/g;
                $tmp2 =~ s/\$/%24/g;
                print $sock " <a href=\"find.htm?path=$root&srcdoc=$form->{'path'}&fmatch=$tmp2&recursive=on&prefmt=on&sendto=view&content=!!&srcdoc=%26srcdocpath%3D$tmp#find\">Search</a> \n";
                print $sock "<font style=\"color:black;background-color:lime\">for source line to comment</font>\n";
            }
            foreach $tmp (split ('\|\|\|', $root)) {
                if (!-d $tmp) {
                    print $sock "<p>The working direct has not been set in the document file.  Example:\n";
                    print $sock "<pre>%SRCDOC:ROOT:/sdcard/Mmote/%\n";
                    print $sock "%SRCDOC:ROOT:c:/x/Mmote/%</pre>\n";
                }
            }
            if ($filter eq '') {
                print $sock "<p>The file find filter is not set. Example:\n";
                print $sock "<pre>%SRCDOC:FILTER:\.java$|||\.xml$%</pre>\n";
            }
            print $sock "<br>\n";
        }
        print $sock "<form action=\"/srcdoc.htm\" method=\"post\">\n";
        print $sock "<table border=\"1\" cellpadding=\"2\" cellspacing=\"0\">\n";

        print $sock "<tr><td>\n";

        print $sock "Desc:";
        print $sock "<textarea name=\"comment\" cols=\"20\" rows=\"3\"></textarea>\n";
       #print $sock "<textarea name=\"comment\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}></textarea>\n";

        print $sock "</td></tr><tr><td>\n";
        print $sock "<input type=\"submit\" name=\"save\" value=\"Save\">\n";
        print $sock "<input type=\"text\" size=\"15\" name=\"url\" value=\"$uri\">\n";

        print $sock "</td></tr><tr><td>\n";
		for ($ii = 1; $ii <= 9; $ii++) {
		    if ($ii == $level) {
			    $tmp = 'checked';
			} else {
			    $tmp = '';
			}
            print $sock "<input type=\"radio\" name=\"level\" value=\"$ii\" $tmp>$ii ";
        }
        print $sock "</td></tr><tr><td>\n";
        if (!defined ($form->{'lnnolvl'})) {
            $form->{'lnnolvl'} = 1;
        }
        print $sock "Insert notes at line $form->{'lnno'} L$form->{'lnnolvl'}. ";
        print $sock "<a href=\"srcdoc.htm?path=$form->{'path'}\">Change</a>\n";
        print $sock "</td></tr><tr><td>\n";
        print $sock "Desc: First line is heading. Additional lines are bullets\n";
        print $sock "</td></tr>\n";
        print $sock "</table><br>\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
        print $sock "<input type=\"hidden\" name=\"lnno\" value=\"$form->{'lnno'}\">\n";
        if (defined ($form->{'tgtline'})) {
            print $sock "<input type=\"hidden\" name=\"tgtline\" value=\"$form->{'tgtline'}\">\n";
        }
        print $sock "</form>\n";
    } elsif (defined ($form->{'instemplate'})) {
        # insert template
        if (open (IN, "<$form->{'path'}")) {
            $buffer = '';
            $tmp = 1;
            while (<IN>) {
                $buffer .= $_;
                if (/^\%SRCDOC:.+\%/) {
                    $tmp = 0;
                }
            }
            if ($tmp) {
                $buffer .= 
                    "\%TOC\%\n".
                    "\n".
                    "=START=\n".
                    "=END=\n".
                    "\%SRCDOC:ROOT:C:\\srcdoc\\\%\n".
                    "\%SRCDOC:FILTER:\\.c\$|||\\.cpp\$|||\\.h\$\%\n";
            }
            close (IN);
            open (OUT, ">$form->{'path'}");
            print OUT $buffer;
            close (OUT);
        }
    } else {
        print $sock "<font style=\"color:black;background-color:lime\">Step 1: Choose 'Insert notes</font> here'<br>\n";
    }

    # get submitted name and print greeting
    if (open (IN, "<$form->{'path'}")) {
#       print $sock "<p><a href=\"/srcdoc.htm?path=$form->{'path'}&search=on\">special</a><p>\n";

        $buffer = '';
        $lnno = 0;
        $root = '';
        $lasthdrlvl = 1;
        while (<IN>) {
            $lnno++;
            # find root
            # %SRCDOC:ROOT:/sdcard/al/aide/apps-for-android/Mmote/%
            if (/^\%SRCDOC:ROOT:(.+)\%/) {
                $tmp = $1;
                $tmp =~ tr/\\/\//;;
                if (-d $tmp) {
                    # dir exist
                    if ($root eq '') {
                        $root = $tmp;
                    } else {
                        $root .= "|||$tmp";
                    }
                    print $sock "<i><strong>Source directory is:</strong></i> <a href=\"tree.htm?path=$tmp\">$tmp</a>\n";
                    # generate navigation page
                    print $sock "<a href=\"srcdoc.htm?navigate=on&path=$form->{'path'}\">navigation</a>\n";
                    print $sock "<br>\n";
                }
            }
            # file find filter
            # %SRCDOC:FILTER:\.java$|||\.xml$%
            if (/^\%SRCDOC:FILTER:(.+)\%/) {
                $filter = $1;
                print $sock "<i><strong>File find filter is:</strong></i> $filter<br>\n";
            }


            if (($tmp) = /^(=+)/) {
                $buffer .= "<font style=\"color:black;background-color:yellow\"><strong><i>Insert notes</font> <a href=\"srcdoc.htm?path=$form->{'path'}&lnno=$lnno&lnnolvl=$lasthdrlvl\">here (line $lnno)</a></i></strong>\n";
                # find heading level
                $lasthdrlvl = length ($tmp);
            }
            $buffer .= $_;
        }
        if (($root eq '') && (!defined ($form->{'instemplate'}))) {
            # did not find %SRCDOC:ROOT:C:\srcdoc\% specficied, off to automatically insert template
            $buffer .= "<p><font style=\"color:black;background-color:red\">This document does not appear to contain 'srcdoc' control definitions.</font><br>".
                " Click <a href=\"/srcdoc.htm?path=$form->{'path'}&instemplate=yes\">this link</a> to append a template that you can modify. In particular, you have to update 'SRCDOC:ROOT:'<p>";
        }
        close (IN);
    }
    $buffer =~ s/\r//g;
    ($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/;
    print $sock &l00wikihtml::wikihtml ($ctrl, $pname, $buffer, 2);

    print $sock "<hr><a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
} # simplest way to skip over codes
}


\%config;
