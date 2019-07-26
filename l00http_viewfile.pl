use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_viewfile_proc",
              desc => "l00http_viewfile_desc");
my ($hostpath, $lastpath, $refresh, $refreshfile);
my ($findtext, $block, $wraptext, $nohdr, $pname, $fname, $maxln, $skip, $hilitetext);
my ($findmaxln, $findskip, $literal);
$hostpath = "c:\\x\\";
$findtext = '';
$block = '.';
$wraptext = '';
$literal = '';
$nohdr = '';
$skip = 0;
$maxln = 1000;
$findskip = 0;
$findmaxln = 1000;
$hilitetext = '';
$lastpath = '';
$refresh = '';
$refreshfile = '';


sub l00http_viewfile_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "viewfile: like view.htm, but using filesystem I/O for huge files";
}

sub l00http_viewfile_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($lineno, $buffer, $pname, $fname, $hilite, $clip, $tmp, $hilitetextidx);
    my ($tmpno, $tmpln, $tmptop, $totallns, $skip0, $refreshtag);
    my (@foundfullarray, $byteskipped);

    if (defined ($form->{'path'})) {
        $form->{'path'} =~ s/\r//g;
        $form->{'path'} =~ s/\n//g;
        if ($refreshfile ne $form->{'path'}) {
            # viewing different file, reset auto-refresh
            $refreshfile = $form->{'path'};
            $refresh = '';
        }
    }

    if (defined ($form->{'nohdr'})) {
        $nohdr = 'checked';
    } else {
        $nohdr = '';
    }

    if (defined ($form->{'update'})) {
        if (defined ($form->{'refresh'})) {
            $refresh = '';
            if ($form->{'refresh'} =~ /(\d+)/) {
                $refresh = $1;
                if ($refresh <= 0) {
                    $refresh = '';
                }
            }
        }
    }

    if ($refresh eq '') {
        $refreshtag = '';
    } else {
        $refreshtag = "<meta http-equiv=\"refresh\" content=\"$refresh\"> ";
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $refreshtag . $ctrl->{'htmlhead2'};
    if ($nohdr eq '') {
        print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
        print $sock "<a href=\"#end\">Jump to end</a>\n";
    }
    print $sock "<a name=\"top\"></a>\n";

    if (defined ($form->{'path'})) {
        if ($nohdr eq '') {
            $tmp = $form->{'path'};
            if (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
                $tmp =~ s/\//\\/g;
            }
            print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\" target=\"_blank\">Path</a>: ";
            if (($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/) {
                # not ending in / or \, not a dir
                print $sock "<a href=\"/ls.htm?path=$pname\">$pname</a>";
                print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$fname</a>\n";
            } else {
                print $sock " <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a>\n";
            }
            print $sock " <a href=\"/edit.htm?path=$form->{'path'}\">Edit</a>/";
            print $sock "<a href=\"/viewfile.htm?path=$form->{'path'}&exteditor=on\">ext</a>\n";
        }
        if ($lastpath ne $form->{'path'}) {
            # reset skip and length for different file
            $skip = 0;
            $maxln = 1000;
            $lastpath = $form->{'path'};
        }
    }


    if (defined ($form->{'hilitetext'}) && (length($form->{'hilitetext'}) > 1)) {
        $hilitetext = $form->{'hilitetext'};
    }

    print $sock "<p>\n";
    if (defined ($form->{'find'})) {
        if (defined ($form->{'findmaxln'})) {
            $findmaxln = $form->{'findmaxln'};
        }
        if (defined ($form->{'findskip'})) {
            $findskip = $form->{'findskip'};
        }
    }
    if (defined ($form->{'update'})) {
        if (defined ($form->{'maxln'})) {
            $maxln = $form->{'maxln'};
        }
        if (defined ($form->{'skip'})) {
            $skip = $form->{'skip'};
        }
    }

    $hilite = 0;
    if (defined ($form->{'hiliteln'})) {
        $hilite = $form->{'hiliteln'};
    }
    if (defined ($form->{'hilite'})) {
        $hilite = $form->{'hilite'};
    }
    # bring high lighted line into view
    if ($hilite > 0) {
        # we are highlighting
        if (($skip >= 0) && 
            (($hilite < $skip) || ($hilite > $skip + $maxln))) {
            # only if skipping from the start
            # but it won't be in view. adjust skip and maxln
            $skip = $hilite - int ($maxln / 2);
            if ($skip < 0) {
                $skip = 0;
            }
        }
    }

    if ($nohdr eq '') {
        print $sock "<form action=\"/viewfile.htm\" method=\"get\">\n";
        print $sock "<input type=\"submit\" name=\"update\" value=\"Skip\">\n";
        print $sock "<input type=\"text\" size=\"4\" name=\"skip\" value=\"$skip\">\n";
        print $sock "and display at most <input type=\"text\" size=\"4\" name=\"maxln\" value=\"$maxln\"> lines\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
        print $sock "<input type=\"checkbox\" name=\"hidelnno\">Hide line number.\n";
        print $sock "<input type=\"checkbox\" name=\"nohdr\" $nohdr>No header.\n";
        print $sock "Auto-refresh (0=off) <input type=\"text\" size=\"3\" name=\"refresh\" value=\"\"> sec.\n";
        # skip backward $maxln
        if ($skip >= 0) {
            # only if skipping from the start
            $tmp = $skip - $maxln;
            if ($tmp < 0) {
                $tmp = 0;
            }
        } else {
            $tmp = 0;
        }
        print $sock "Skip to: <a href=\"/viewfile.htm?update=Skip&skip=$tmp&maxln=$maxln&path=$form->{'path'}\">line $tmp</a>\n";
        # skip forward $maxln
        if ($skip >= 0) {
            # only if skipping from the start
            $tmp = int ($skip - $maxln / 2);
            if ($tmp < 0) {
                $tmp = 0;
            }
        } else {
            $tmp = 0;
        }
        print $sock "<a href=\"/viewfile.htm?update=Skip&skip=$tmp&maxln=$maxln&path=$form->{'path'}\">$tmp</a>\n";
        if ($skip >= 0) {
            # only if skipping from the start
            $tmp = int ($skip + $maxln / 2);
        } else {
            $tmp = 0;
        }
        print $sock "<a href=\"/viewfile.htm?update=Skip&skip=$tmp&maxln=$maxln&path=$form->{'path'}\">$tmp</a>\n";
        if ($skip >= 0) {
            # only if skipping from the start
            $tmp = int ($skip + $maxln);
        } else {
            $tmp = 0;
        }
        print $sock "<a href=\"/viewfile.htm?update=Skip&skip=$tmp&maxln=$maxln&path=$form->{'path'}\">$tmp</a>\n";
        print $sock "</form>\n";
    }

    if ($hilite > 0) {
        # and now we add a jump to link
        $tmp = $hilite - 10;
        if ($tmp < 1) {
            $tmp = 1;
        }
        print $sock "Jump to <a href=\"#line$tmp\">line $hilite</a>\n";
    }


    $lineno = 0;
    if ((defined ($form->{'path'})) && (length ($form->{'path'}) > 0)) {
        if (open (IN, "<$form->{'path'}")) {
            if ($skip < 0) {
                print $sock "Negative skip, search for last line. May take some times. ".
                    "Prints '.' per 65k lines on the console.<br>\n";
                $skip = 0;
                while (<IN>) {
                    if (($skip & 0xffff) == 0) {
                        print ".";
                    }
                    $skip++;
                }
                close (IN);
                print $sock "There are $skip lines in $form->{'path'}<br>\n";
                $skip -= $maxln;
                print "\n";
                open (IN, "<$form->{'path'}");
            }

            print $sock "<pre>\n";

            print $sock sprintf ("<a name=\"hilitetext_%d\"></a>", 0);
            $hilitetextidx = 1;
            $skip0  = $skip;
            $byteskipped = 0;
            while (<IN>) {
                $lineno++;
                if ($lineno < $skip0) {
                    if ($lineno == 1) {
                        print $sock "\nFirst $skip0 lines skipped\n";
                    }
                    $byteskipped += length ($_);
                    next;
                }
                if (($lineno - $skip0) > $maxln) {
                    last;
                }
                s/\r//g;
                s/\n//g;
                s/&/&amp;/g;
                s/</&lt;/g;
                s/>/&gt;/g;
                if (defined($form->{'hidelnno'}) && 
                    ($form->{'hidelnno'} eq 'on')) {
                    if ($hilite == $lineno) {
                        print $sock "<font style=\"color:black;background-color:lime\">$_</font>\n";
                    } else {
                        if (defined ($form->{'hilitetext'}) && (length($form->{'hilitetext'}) > 1)) {
                            s/($form->{'hilitetext'})/<font style=\"color:black;background-color:lime\">$1<\/font>/g;
                        }
                        print $sock "$_\n";
                    }
                } else {
                    $clip = &l00httpd::urlencode ($_);
					# = "clip.htm?update=Copy+to+clipboard&clip=$tmp
                    if ($hilite == $lineno) {
                        print $sock sprintf ("<a name=\"line%d\"></a><a href=\"/clip.htm?update=Copy+to+clipboard&clip=", $lineno);
                        print $sock $clip;
                        print $sock sprintf ("\" target=\"_blank\">%04d</a> : ", $lineno) . "<font style=\"color:black;background-color:lime\">$_</font>\n";
                    } else {
                        if (defined ($form->{'hilitetext'}) && (length($form->{'hilitetext'}) > 1)) {
                            if (/$form->{'hilitetext'}/) {
                                s/($form->{'hilitetext'})/<font style=\"color:black;background-color:lime\">$1<\/font>/g;
                                print $sock "<a name=\"hilitetext_$hilitetextidx\"></a>";
                                $tmp = $hilitetextidx - 1;
                                print $sock sprintf ("<a name=\"line%d\"></a><a href=\"#hilitetext_$tmp\">&lt;</a><a href=\"/clip.htm?update=Copy+to+clipboard&clip=", $lineno);
                                print $sock $clip;
                                $tmp = $hilitetextidx + 1;
                                print $sock sprintf ("\" target=\"_blank\">%04d</a><a href=\"#hilitetext_$tmp\">&gt;</a>", $lineno) . "$_\n";
                                $hilitetextidx++;
                            } else {
                                print $sock sprintf ("<a name=\"line%d\"></a><a href=\"/clip.htm?update=Copy+to+clipboard&clip=", $lineno);
                                print $sock $clip;
                                print $sock sprintf ("\" target=\"_blank\">%04d</a> <a href=\"viewfile.htm?path=$form->{'path'}&hiliteln=$lineno&lineno=on#line%d\">:</a> ", $lineno, $lineno - 5) . "$_\n";
                            }
                        } else {
                            print $sock sprintf ("<a name=\"line%d\"></a><a href=\"/clip.htm?update=Copy+to+clipboard&clip=", $lineno);
                            print $sock $clip;
                            print $sock sprintf ("\" target=\"_blank\">%04d</a> <a href=\"viewfile.htm?path=$form->{'path'}&hiliteln=$lineno&lineno=on#line%d\">:</a> ", $lineno, $lineno - 5) . "$_\n";
                        }
                    }
                }
            }
            print $sock "</pre>\n";
            close (IN);
        }
    }
    print $sock "<hr><a name=\"end\"></a><p>\n";

    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
            $size, $atime, $mtimea, $ctime, $blksize, $blocks);
    # disk file
    ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
        $size, $atime, $mtimea, $ctime, $blksize, $blocks)
            = stat($form->{'path'});
    print $sock "\nThere are $size bytes in $form->{'path'}<br>$byteskipped bytes skipped from start<p>\n";

    # view first X lines
    print $sock "View first: <a href=\"/viewfile.htm?update=Skip&skip=0&maxln=10&path=$form->{'path'}#top\">10</a>,\n";
    print $sock "<a href=\"/viewfile.htm?update=Skip&skip=0&maxln=200&path=$form->{'path'}#top\">200</a>,\n";
    print $sock "<a href=\"/viewfile.htm?update=Skip&skip=0&maxln=500&path=$form->{'path'}#top\">500</a>,\n";
    print $sock "<a href=\"/viewfile.htm?update=Skip&skip=0&maxln=1000&path=$form->{'path'}#top\">1000</a> lines,\n";
    print $sock "<a href=\"/viewfile.htm?update=Skip&skip=0&maxln=10000&path=$form->{'path'}#top\">10000</a> lines.<p>\n";

    print $sock "Click <a href=\"/viewfile.htm?path=$form->{'path'}&update=yes&skip=0&maxln=$lineno\">here</a> to view the entire file<p>\n";

    # highlite
    print $sock "<hr><a name=\"find\"></a>\n";
    print $sock "<form action=\"/viewfile.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"dohilite\" value=\"HiLite\">\n";
    print $sock "</td><td>\n";
    print $sock "regex <input type=\"text\" size=\"12\" name=\"hilitetext\" value=\"$hilitetext\">\n";
    print $sock "</td></tr>\n";
    print $sock "</table>\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</form>\n";

    # find
    print $sock "<form action=\"/view.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"find\" value=\"F&#818;ind\" accesskey=\"f\">\n";
    print $sock "</td><td>\n";
    print $sock "Find in this file\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "RegE&#818;x:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"12\" name=\"findtext\" value=\"$findtext\" accesskey=\"e\"> <input type=\"submit\" name=\"clr\" value=\"clr\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Block mark:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"12\" name=\"block\" value=\"$block\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Formatted:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"checkbox\" name=\"wraptext\" $wraptext>wrap text\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Literal:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"checkbox\" name=\"literal\" $literal>show '&lt;' &amp; '&gt;'\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "File:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"12\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Skip <input type=\"text\" size=\"4\" name=\"findskip\" value=\"$findskip\">\n";
    print $sock "</td><td>\n";
    print $sock "max. <input type=\"text\" size=\"4\" name=\"findmaxln\" value=\"$findmaxln\"> lines\n";
    print $sock "</td></tr>\n";
    print $sock "</table>\n";
    print $sock "</form>\n";
    print $sock "Blockmark: Regex matching start of block. e.g. '^=' or '^\\* '\n";

    print $sock "<p><a href=\"#top\">Jump to top</a> - \n";
    print $sock "<a href=\"/launcher.htm?path=$form->{'path'}\">Launcher</a> - \n";
	print $sock "<a href=\"/ls.htm?find=Find&findtext=%3Ano%5E%3A&block=.&path=$form->{'path'}\">Find in this file</a>\n";
    print $sock "<p>Send $form->{'path'} to launcher\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
