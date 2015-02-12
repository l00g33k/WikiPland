use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_view_proc",
              desc => "l00http_view_desc");
my ($buffer);
my ($hostpath);
my ($findtext, $block, $prefmt, $found, $pname, $fname, $maxln, $skip, $hilitetext);
$hostpath = "c:\\x\\";
$findtext = '';
$block = '';
$prefmt = '';
$skip = 0;
$maxln = 1000;
$hilitetext = '';

sub l00http_view_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "view: Simple viewer: just dump as formatted text";
}

sub l00http_view_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($lineno, $buffer, $pname, $fname, $hilite, $clip, $tmp, $hilitetextidx, $tmpno, $tmpln, $tmptop);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#end\">Jump to end</a>\n";
    print $sock "<a name=\"top\"></a>\n";

    $form->{'path'} =~ s/\r//g;
    $form->{'path'} =~ s/\n//g;
    if (defined ($form->{'path'})) {
        $tmp = $form->{'path'};
        if ($ctrl->{'os'} eq 'win') {
            $tmp =~ s/\//\\/g;
        }
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\" target=\"newclip\">Path</a>: ";
        if (($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/) {
            # not ending in / or \, not a dir
            print $sock "<a href=\"/ls.htm?path=$pname\">$pname</a>";
            print $sock "<a href=\"/ls.htm?path=$form->{'path'}\">$fname</a>\n";
        } else {
            print $sock " <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a>\n";
        }
        print $sock " <a href=\"/edit.htm?path=$form->{'path'}\">Edit</a>\n";
    }


    if (defined ($form->{'hilitetext'}) && (length($form->{'hilitetext'}) > 1)) {
        $hilitetext = $form->{'hilitetext'};
    }

    print $sock "<p>\n";
    if (defined ($form->{'update'})) {
        if (defined ($form->{'maxln'})) {
            $maxln = $form->{'maxln'};
        }
        if (defined ($form->{'skip'})) {
            $skip = $form->{'skip'};
        }
#    } else {
#        $skip = 0;
#        $maxln = 1000;
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
        if (($hilite < $skip) || ($hilite > $skip + $maxln)) {
            # but it won't be in view. adjust skip and maxln
#            $skip = $hilite - 500;
            $skip = $hilite - int ($maxln / 2);
            if ($skip < 0) {
                $skip = 0;
            }
#            $maxln = 1000;
        }
    }

    print $sock "<form action=\"/view.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"update\" value=\"Skip\">\n";
    print $sock "<input type=\"text\" size=\"4\" name=\"skip\" value=\"$skip\">\n";
    print $sock "and display at most <input type=\"text\" size=\"4\" name=\"maxln\" value=\"$maxln\"> lines\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "<input type=\"checkbox\" name=\"hidelnno\">Hide line number.\n";
    # skip backward $maxln
    $tmp = $skip - $maxln;
    if ($tmp < 0) {
        $tmp = 0;
    }
    print $sock "Skip to: <a href=\"/view.htm?update=Skip&skip=$tmp&maxln=$maxln&path=$form->{'path'}\">line $tmp</a>\n";
    # skip forward $maxln
    $tmp = int ($skip - $maxln / 2);
    if ($tmp < 0) {
        $tmp = 0;
    }
    print $sock "<a href=\"/view.htm?update=Skip&skip=$tmp&maxln=$maxln&path=$form->{'path'}\">$tmp</a>\n";
    $tmp = int ($skip + $maxln / 2);
    print $sock "<a href=\"/view.htm?update=Skip&skip=$tmp&maxln=$maxln&path=$form->{'path'}\">$tmp</a>\n";
    $tmp = int ($skip + $maxln);
    print $sock "<a href=\"/view.htm?update=Skip&skip=$tmp&maxln=$maxln&path=$form->{'path'}\">$tmp</a>\n";
    print $sock "</form>\n";

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
        $found = '';

        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            $buffer = &l00httpd::l00freadAll($ctrl);

            # Some has only \r as line endings. So convert DOS \r\n to Unix \n
            # then convert \r to Unix \n
            $buffer =~ s/\r\n/\n/g;
            $buffer =~ s/\r/\n/g;

            if (defined ($form->{'find'})) {
                ($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/;
                $found = "<font style=\"color:black;background-color:lime\">Find in this file results:</font> <a href=\"#__find__\">(jump to results end)</a>\n";
                if (defined ($form->{'findtext'})) {
                    $findtext = $form->{'findtext'};
                }
                if (defined ($form->{'block'})) {
                    $block = $form->{'block'};
                }
                if (defined ($form->{'prefmt'})) {
                    $prefmt = 'checked';
                    $found .= "<pre>\n";
                } else {
                    $prefmt = '';
                }
                $found .= &l00httpd::findInBuf ($findtext, $block, $buffer);
                if ($prefmt ne '') {
				    $tmp = '';
					foreach $_ (split("\n", $found)) {
					    if (($tmpno, $tmpln) = /^(\d+):(.+)$/) {
                            # extract if we find parathesis
                            if (($findtext =~ /[^\\]\(.+[^\\]\)/) ||
                                ($findtext =~ /^\(.+[^\\]\)/)) {
                                # found '(...)' and not '\(...\)'
                                # strip and print all
                                if (@_ = ($tmpln =~ /$findtext/)) {
                                    $tmpln = join (' || ', @_);
                                }
                            }
						    $tmptop = $tmpno - 20;
						    $_ = "<a href=\"/view.htm?update=Skip&skip=$tmptop&hiliteln=$tmpno&maxln=100&path=$pname$fname\">$tmpno</a>:$tmpln";
						}
					    $tmp .= "$_\n";
					}
					$found = $tmp;
                    $found .= "</pre>\n";
                }
                $found .= "<br><a name=\"__find__\"></a><font style=\"color:black;background-color:lime\">Find in this file results end</font><hr>\n";
                print $sock &l00wikihtml::wikihtml ($ctrl, $pname, $found, 0);
                print $sock "<p>\n";
            }

            print $sock "<pre>\n";

            print $sock sprintf ("<a name=\"hilitetext_%d\"></a>", 0);
            $hilitetextidx = 1;
            foreach $_ (split ("\n", $buffer)) {
                $lineno++;
                if ($lineno < $skip) {
                    if ($lineno == 1) {
                        print $sock "\nFirst $skip lines skipped\n";
                    }
                    next;
                }
                if (($lineno - $skip) > $maxln) {
                    next;
                }
                s/\r//g;
                s/\n//g;
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
                        print $sock sprintf ("\" target=\"newclip\">%04d</a>: ", $lineno) . "<font style=\"color:black;background-color:lime\">$_</font>\n";
                    } else {
                        if (defined ($form->{'hilitetext'}) && (length($form->{'hilitetext'}) > 1)) {
                            if (/$form->{'hilitetext'}/) {

                                s/($form->{'hilitetext'})/<font style=\"color:black;background-color:lime\">$1<\/font>/g;
                                print $sock "<a name=\"hilitetext_$hilitetextidx\"></a>";
                                $tmp = $hilitetextidx - 1;
                                print $sock sprintf ("<a name=\"line%d\"></a><a href=\"#hilitetext_$tmp\">&lt;</a><a href=\"/clip.htm?update=Copy+to+clipboard&clip=", $lineno);
                                print $sock $clip;
                                $tmp = $hilitetextidx + 1;
                                print $sock sprintf ("\" target=\"newclip\">%04d</a><a href=\"#hilitetext_$tmp\">&gt;</a>", $lineno) . "$_\n";
                                $hilitetextidx++;
                            } else {
                                print $sock sprintf ("<a name=\"line%d\"></a><a href=\"/clip.htm?update=Copy+to+clipboard&clip=", $lineno);
                                print $sock $clip;
                                print $sock sprintf ("\" target=\"newclip\">%04d</a>: ", $lineno) . "$_\n";
                            }
                        } else {
                            print $sock sprintf ("<a name=\"line%d\"></a><a href=\"/clip.htm?update=Copy+to+clipboard&clip=", $lineno);
                            print $sock $clip;
                            print $sock sprintf ("\" target=\"newclip\">%04d</a>: ", $lineno) . "$_\n";
                        }
                    }
                }
            }
            print $sock "</pre>\n";
        }
    }
    print $sock "<hr><a name=\"end\"></a><p>\n";
    if (($lineno + $skip) > $maxln) {
        print $sock "\nAnother " . ($lineno - $skip - $maxln) . " lines skipped<br>\n";
    }
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
            $size, $atime, $mtimea, $ctime, $blksize, $blocks)
                = stat($form->{'path'});
    print $sock "\nThere are $lineno lines and $size bytes in $form->{'path'}<p>\n";

    # skip backward $maxln
    $tmp = $lineno - 200;
    print $sock "View last: <a href=\"/view.htm?update=Skip&skip=$tmp&maxln=200&path=$form->{'path'}#end\">200</a>,\n";
    $tmp = $lineno - 500;
    print $sock "<a href=\"/view.htm?update=Skip&skip=$tmp&maxln=500&path=$form->{'path'}#end\">500</a>,\n";
    $tmp = $lineno - 1000;
    print $sock "<a href=\"/view.htm?update=Skip&skip=$tmp&maxln=1000&path=$form->{'path'}#end\">1000</a> lines.<p>\n";

    # view first X lines
    print $sock "View first: <a href=\"/view.htm?update=Skip&skip=0&maxln=200&path=$form->{'path'}#top\">200</a>,\n";
    print $sock "<a href=\"/view.htm?update=Skip&skip=0&maxln=500&path=$form->{'path'}#top\">500</a>,\n";
    print $sock "<a href=\"/view.htm?update=Skip&skip=0&maxln=1000&path=$form->{'path'}#top\">1000</a> lines.<p>\n";

    print $sock "Click <a href=\"/view.htm?path=$form->{'path'}&update=yes&skip=0&maxln=$lineno\">here</a> to view the entire file<p>\n";

    # highlite
    print $sock "<hr><a name=\"find\"></a>\n";
    print $sock "<form action=\"/view.htm\" method=\"get\">\n";
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
    print $sock "<input type=\"submit\" name=\"find\" value=\"Find\">\n";
    print $sock "</td><td>\n";
    print $sock "Find in this file\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "RegEx:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"12\" name=\"findtext\" value=\"$findtext\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Block mark:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"12\" name=\"block\" value=\"$block\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Formatted:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"checkbox\" name=\"prefmt\" $prefmt>formatted text\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "File:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"12\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";
    print $sock "</table>\n";
    print $sock "</form>\n";
    print $sock "Blockmark: Regex matching start of block. e.g. '^=' or '^\\* '\n";

    print $sock "<p><a href=\"#top\">Jump to top</a> - \n";
    print $sock "<a href=\"/launcher.htm?path=$form->{'path'}\">Launcher</a> - \n";
	print $sock "<a href=\"/ls.htm?find=Find&findtext=%3Ano%5E%3A&block=.&prefmt=on&path=$form->{'path'}\">Find in this file</a>\n";
    print $sock "<p>Send $form->{'path'} to launcher\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
