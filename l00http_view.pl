use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_view_proc",
              desc => "l00http_view_desc");
my ($buffer);
my ($hostpath, $lastpath, $refresh, $refreshfile);
my ($findtext, $block, $wraptext, $nohdr, $found, $pname, $fname, $maxln, $skip, $hilitetext, $sortfind);
my ($findmaxln, $findskip, $eval, $evalbox, $literal, @colors, $lastfew, $nextfew, $ansi, %ansicode);
my ($findstart, $findlen, $excludeinfound);
$hostpath = "c:\\x\\";
$findtext = '';
$block = '.';
$excludeinfound = '';
$wraptext = '';
$literal = '';
$nohdr = '';
$skip = 0;
$maxln = 200;
$findskip = 0;
$findmaxln = 1000;
$hilitetext = '';
$lastpath = '';
$refresh = '';
$refreshfile = '';
$eval = '';
$evalbox = '';
$lastfew = 0;
$nextfew = 0;
$ansi = 0;
$sortfind = '';
$findstart = 0;
$findlen = 0;

%ansicode = (
    '[30m' => '<font style="color:black;background-color:white">',
    '[31m' => '<font style="color:red;background-color:white">',
    '[32m' => '<font style="color:lime;background-color:white">',
    '[33m' => '<font style="color:#FFC706;background-color:white">',
    '[34m' => '<font style="color:blue;background-color:white">',
    '[35m' => '<font style="color:magenta;background-color:white">',
    '[36m' => '<font style="color:aqua;background-color:white">',
    '[37m' => '<font style="color:silver;background-color:white">',
    '[90m' => '<font style="color:gray;background-color:white">',
    '[91m' => '<font style="color:red;background-color:white">',
    '[92m' => '<font style="color:green;background-color:white">',
    '[93m' => '<font style="color:yellow;background-color:white">',
    '[94m' => '<font style="color:blue;background-color:white">',
    '[95m' => '<font style="color:hotpink;background-color:white">',
    '[96m' => '<font style="color:aqua;background-color:white">',
    '[97m' => '<font style="color:white;background-color:white">',
    '[0m' => '</font>'
);


@colors = (
    'aqua',
    'lime',
    'deepPink',
    'deepSkyBlue',
    'fuchsia',
    'yellow',
    'silver',
    'brown',
    'red',
    'gray',
    'olive',
    'lightGray',
    'teal'
);


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
    my ($lineno, $buffer, $pname, $pnameurl, $fname, $fnameurl, $hilite, $clip, $tmp, $hilitetextidx);
    my ($tmpno, $tmpln, $tmptop, $foundcnt, $totallns, $skip0, $refreshtag, $hit, @findCount, $findidx);
    my ($foundfullrst, $foundfullrstnew, @foundfullarray, $actualSt, $actualEn, $pattern, $ii, $color);
    my ($displayed, $onefindtext, $tmplnallhits, $pnameurl2, $fnameurl2, $jumptable);

    $skip0  = 0;
    $pnameurl = '';
    $fnameurl = '';
    $pnameurl2 = '';
    $fnameurl2 = '';

    if (defined ($form->{'path'})) {
        $form->{'path'} =~ s/\r//g;
        $form->{'path'} =~ s/\n//g;
        if ($refreshfile ne $form->{'path'}) {
            # viewing different file, reset auto-refresh
            $refreshfile = $form->{'path'};
            $refresh = '';
        }
        if ($lastpath ne $form->{'path'}) {
            $nohdr = '';
        }
    } else {
        $nohdr = '';
    }

    if (defined ($form->{'clr'})) {
        undef $form->{'findtext'};
        $findtext = '';
        undef $form->{'excludeinfound'};
        $excludeinfound = '';
    }

    if (defined ($form->{'cbpaste'})) {
        $findtext = &l00httpd::l00getCB($ctrl);
        $form->{'findtext'} = $findtext;
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
        if ((defined($form->{'evalbox'})) && ($form->{'evalbox'} eq 'on')) {
            $evalbox = 'checked';
        } else {
            $evalbox = '';
        }
        if (defined($form->{'eval'})) {
            $eval = $form->{'eval'};
        }
        if ((defined($form->{'nohdr'})) && ($form->{'nohdr'} eq 'on')) {
            $nohdr = 'checked';
        } else {
            $nohdr = '';
        }
    }
    if (defined($form->{'cb2eval'})) {
        $eval = &l00httpd::l00getCB($ctrl);
    }
    if (defined($form->{'clreval'})) {
        $eval = '';
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
        if ($lastpath ne $form->{'path'}) {
            # reset skip and length for different file
            $skip = 0;
            $maxln = 200;
            $lastpath = $form->{'path'};
            $nohdr = '';
        }
        if ($nohdr eq '') {
            $tmp = $form->{'path'};
            if (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
                $tmp =~ s/\//\\/g;
            }
            print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\" target=\"_blank\">Path</a>: ";
            if (($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/) {
                $pnameurl = $pname;
                $fnameurl = $fname;
                $pnameurl =~ s/\+/%2B/g;
                $fnameurl =~ s/\+/%2B/g;
                $pnameurl2 = $pnameurl;
                $fnameurl2 = $fnameurl;
                $pnameurl2 =~ s/%/%%/g;
                $fnameurl2 =~ s/%/%%/g;
                # not ending in / or \, not a dir
                if ($pnameurl eq 'l00://') {
                    print $sock "<a href=\"/#ram\">l00://</a>";
                    print $sock "<a href=\"/ls.htm?path=l00://$fname\">$fname</a>\n";
                } else {
                    print $sock "<a href=\"/ls.htm?path=$pnameurl\">$pname</a>";
                    print $sock "<a href=\"/ls.htm?path=$pnameurl$fname\">$fname</a>\n";
                }
            } else {
                print $sock " <a href=\"/ls.htm?path=$pnameurl$fnameurl\">$form->{'path'}</a>\n";
            }
            print $sock " <a href=\"/edit.htm?path=$pnameurl$fnameurl\">Edit</a>/";
            print $sock "<a href=\"/view.htm?path=$pnameurl$fnameurl\">vw</a>/";
            print $sock "<a href=\"/view.htm?path=$pnameurl$fnameurl&exteditor=on\">ext</a>\n";
        }
    }


    if (defined ($form->{'clrhilite'})) {
        $hilitetext = '';
    }

    if (defined ($form->{'dohilite'})) {
        if (defined ($form->{'ansi'})) {
            $ansi = 'checked';
        } else {
            $ansi = '';
        }
        if (defined ($form->{'hilitetext'})) {
            $hilitetext = $form->{'hilitetext'};
        }
    }


    print $sock "<p>\n";
    if (defined ($form->{'find'})) {
        if (defined ($form->{'findmaxln'})) {
            $findmaxln = $form->{'findmaxln'};
        }
        if (defined ($form->{'findskip'})) {
            $findskip = $form->{'findskip'};
        }
        if (defined ($form->{'lastfew'})) {
            $lastfew = $form->{'lastfew'};
        }
        if (defined ($form->{'nextfew'})) {
            $nextfew = $form->{'nextfew'};
        }

        if (defined ($form->{'findstart'})) {
            $findstart = $form->{'findstart'};
        } else {
            $findstart = 0;
        }
        if (defined ($form->{'findlen'})) {
            $findlen = $form->{'findlen'};
        } else {
            $findlen = 0;
        }
    }
    if (defined ($form->{'update'})) {
        if (defined ($form->{'maxln'})) {
            $maxln = $form->{'maxln'};
            if ($maxln =~ /^ *(\d+) *([+-]) *(\d+) *$/) {
                if ($2 eq '+') {
                    $maxln = $1 + $3;
                } else {
                    $maxln = $1 - $3;
                }
            }
        }
        if (defined ($form->{'skip'})) {
            $skip = $form->{'skip'};
            if ($skip =~ /^ *(\d+) *([+-]) *(\d+) *$/) {
                if ($2 eq '+') {
                    $skip = $1 + $3;
                } else {
                    $skip = $1 - $3;
                }
            }
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
        print $sock "<form action=\"/view.htm\" method=\"get\">\n";
        print $sock "<input type=\"submit\" name=\"update\" value=\"S&#818;kip\" accesskey=\"s\">\n";
        print $sock "<input type=\"text\" size=\"4\" name=\"skip\" value=\"$skip\">\n";
        print $sock "and display at most <input type=\"text\" size=\"4\" name=\"maxln\" value=\"$maxln\"> lines\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
        print $sock "<input type=\"checkbox\" name=\"hidelnno\">\n";
        print $sock "<a href=\"/view.htm?path=$pnameurl$fnameurl&hidelnno=on&update=S%CC%B2kip&skip=$skip&maxln=$maxln\">Hide line number.</a>\n";
        print $sock "<input type=\"checkbox\" name=\"nohdr\" $nohdr>No header.\n";
        print $sock "Auto-refresh (0=off) <input type=\"text\" size=\"3\" name=\"refresh\" value=\"\"> sec.\n";

        print $sock "(<input type=\"checkbox\" name=\"evalbox\" $evalbox> Eval each \$_:\n";
        print $sock "<input type=\"text\" size=\"6\" name=\"eval\" value=\"$eval\">\n";
        print $sock "<input type=\"submit\" name=\"cb2eval\" value=\"<-CB\"> \n";
        print $sock "<input type=\"submit\" name=\"clreval\" value=\"clr\"> )\n";

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
        print $sock "Skip to: <a href=\"/view.htm?update=Skip&skip=$tmp&maxln=$maxln&path=$pnameurl$fnameurl\">line $tmp</a>\n";
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
        print $sock "<a href=\"/view.htm?update=Skip&skip=$tmp&maxln=$maxln&path=$pnameurl$fnameurl\">$tmp</a>\n";
        if ($skip >= 0) {
            # only if skipping from the start
            $tmp = int ($skip + $maxln / 2);
        } else {
            $tmp = 0;
        }
        print $sock "<a href=\"/view.htm?update=Skip&skip=$tmp&maxln=$maxln&path=$pnameurl$fnameurl\">$tmp</a>\n";
        if ($skip >= 0) {
            # only if skipping from the start
            $tmp = int ($skip + $maxln);
        } else {
            $tmp = 0;
        }
        print $sock "<a href=\"/view.htm?update=Skip&skip=$tmp&maxln=$maxln&path=$pnameurl$fnameurl\">$tmp</a>\n";
        print $sock "</form>\n";
    }

    if ($hilite > 0) {
        # and now we add a jump to link
        $tmp = $hilite - 10;
        if ($tmp < 1) {
            $tmp = 1;
        }
        print $sock "Jump to <a href=\"#line$tmp\">line $hilite</a>.\n";
        print $sock "<a href=\"/blog.htm?path=$pnameurl$fnameurl&stylecurr=blog&setnewstyle=Bare+sty%CC%B2le+add&stylenew=bare&keepnl=on&afterline=$hilite\">Blog insert</a> after line $hilite.\n";
#       print $sock "Open highlighted line in editor <a href=\"/edit.htm?path=$pnameurl$fnameurl&blklineno=$hilite\">single line edit mode</a>.\n";
        print $sock "Send highlighted line to <a href=\"/blog.htm?path=$pnameurl$fnameurl&setnewstyle=yes&stylenew=star&afterline=$hilite\">blog</a>.\n";
        print $sock "Expand ";
        $tmp = $hilite - 200;
        if ($tmp < 1) {
            $tmp = 1;
        }
        print $sock sprintf ("<a href=\"view.htm?path=$pnameurl2$fnameurl2&update=Skip&hiliteln=$hilite&lineno=on&skip=%d&maxln=%d#line%d\">200</a>", $tmp, 600, $hilite);
        $tmp = $hilite - 500;
        if ($tmp < 1) {
            $tmp = 1;
        }
        print $sock sprintf (", <a href=\"view.htm?path=$pnameurl2$fnameurl2&update=Skip&hiliteln=$hilite&lineno=on&skip=%d&maxln=%d#line%d\">500</a>", $tmp, 2000, $hilite);
        $tmp = $hilite - 1000;
        if ($tmp < 1) {
            $tmp = 1;
        }
        print $sock sprintf (", <a href=\"view.htm?path=$pnameurl2$fnameurl2&update=Skip&hiliteln=$hilite&lineno=on&skip=%d&maxln=%d#line%d\">1000</a>", $tmp, 3000, $hilite);
        $tmp = $hilite - 2000;
        if ($tmp < 1) {
            $tmp = 1;
        }
        print $sock sprintf (", <a href=\"view.htm?path=$pnameurl2$fnameurl2&update=Skip&hiliteln=$hilite&lineno=on&skip=%d&maxln=%d#line%d\">2000</a>", $tmp, 5000, $hilite);
        print $sock " lines of context.";
    }


    $lineno = 0;
    if ((defined ($form->{'path'})) && (length ($form->{'path'}) > 0)) {
        $found = '';
        $displayed = '';

        if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {
            # launch editor
            if (($ctrl->{'os'} eq 'and') && 
                defined ($form->{'exteditor'}) &&
                (!($form->{'path'} =~ /^l00:\/\//))) {
                $ctrl->{'droid'}->startActivity("android.intent.action.VIEW", "file://$form->{'path'}", "text/plain");
            }

            if ($evalbox eq 'checked') {
                $buffer = '';
                while ($_ = &l00httpd::l00freadLine($ctrl)) {
                    s/[\n\r]//g;
                    eval $eval;
                    $buffer .= "$_\n";
                }
            } else {
                $buffer = &l00httpd::l00freadAll($ctrl);

                # Some has only \r as line endings. So convert DOS \r\n to Unix \n
                # then convert \r to Unix \n
                $buffer =~ s/\r\n/\n/g;
                $buffer =~ s/\r/\n/g;
            }


            if (defined ($form->{'find'})) {
                ($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/;
                $pnameurl = $pname;
                $fnameurl = $fname;
                $pnameurl =~ s/\+/%2B/g;
                $fnameurl =~ s/\+/%2B/g;
                $pnameurl2 = $pnameurl;
                $fnameurl2 = $fnameurl;
                $pnameurl2 =~ s/%/%%/g;
                $fnameurl2 =~ s/%/%%/g;
                $found = "<font style=\"color:black;background-color:lime\">Find in this file results:</font> <a href=\"#__find__\">(jump to results end)</a>. ";
                $found .= "View <a href=\"/view.htm?path=l00://find.htm\" target=\"_blank\">l00://find.htm</a> - ";
                $found .= "<a href=\"/view.htm?path=l00://find.txt\" target=\"_blank\">.txt</a>; ";
                $found .= "<a href=\"/filemgt.htm?path=l00://find.htm&path2=l00://find.htm.$fname\" target=\"_blank\">copy it to</a>...\n";

                if ($findlen != 0) { 
                    $found .= "<strong>Find range limited to starting from line $findstart for $findlen lines.</strong>\n";
                }

                if (defined ($form->{'findtext'})) {
                    $findtext = $form->{'findtext'};
                }
                if (defined ($form->{'excludeinfound'})) {
                    $excludeinfound = $form->{'excludeinfound'};
                }
                if (defined ($form->{'block'})) {
                    $block = $form->{'block'};
                    if (length($block) <= 0) {
                        $block = '.';
                    }
                }
                if (defined ($form->{'wraptext'})) {
                    $wraptext = 'checked';
                } else {
                    $wraptext = '';
                }
                if (defined ($form->{'literal'})) {
                    $literal = 'checked';
                } else {
                    $literal = '';
                }
                if (defined ($form->{'sortfind'})) {
                    $sortfind = 'checked';
                } else {
                    $sortfind = '';
                }
                #print "\n\nexcludeinfound >$excludeinfound<\n\n";
                ($foundfullrst, @findCount) = &l00httpd::findInBuf ($findtext, $block, 
                    $buffer, ($literal eq 'checked'), $lastfew, 
                    $nextfew, ($sortfind eq 'checked'), $findstart, 
                    $findlen, $excludeinfound);
                # l00httpd::findInBuf should return the number of matches
                @foundfullarray = split("\n", $foundfullrst);
                if ($wraptext eq '') {
                    $found .= "<pre>\n";
				    $foundfullrstnew = '';
                    $foundcnt = 0;
					foreach $_ (@foundfullarray) {
                        $foundcnt++;

                        # do ANSI color
                        if ($ansi ne '') {
                            if(/\x1b\[\d+m/) {
                                foreach $ii (keys %ansicode) {
                                    $tmp = "\\$ii";
                                    s/$tmp/$ansicode{$ii}/g;
                                }
                                # patch up unknown code
                                s/\x1b\[\d+m/<font style="color:gray;background-color:white">/g;
                            }                            
                        }

					    if (($tmpno, $tmpln) = /^(\d+):(.+)$/) {
                            # extract if we find parathesis
                            if (($findtext =~ /[^\\]\(.+[^\\]\)/) ||
                                ($findtext =~ /^\(.+[^\\]\)/)) {
                                # found '(...)' and not '\(...\)'
                                # strip and print all
                                if ($findtext =~ /\|\|/) {
                                    # multiple findtext
                                    $tmplnallhits = '';
# this is broken
# $tmplnallhits .= ' xxx ';
                                    foreach $onefindtext (split('\|\|', $findtext)) {
                                        if (($onefindtext =~ /[^\\]\(.+[^\\]\)/) ||
                                            ($onefindtext =~ /^\(.+[^\\]\)/)) {
# $tmplnallhits .= ' xx1 ';
# print "tmpln >$tmpln< =~ onefindtext />$onefindtext<\n";
                                            if (@_ = $tmpln =~ /$onefindtext/) {
# $tmplnallhits .= ' xx2 ';
                                                $tmplnallhits .= join (' --- ', @_);
                                            }
                                        } else {
# $tmplnallhits .= ' xx3 ';
                                            if ($tmpln =~ /$onefindtext/) {
# $tmplnallhits .= ' xx4 ';
                                                $tmplnallhits .= $tmpln;
                                            }
                                        }
                                    }
# $tmplnallhits .= ' xx5 ';
                                    $tmpln = $tmplnallhits;
# print "END tmpln >$tmpln<\n";
                                } else {
                                    # one findtext
                                    if (@_ = $tmpln =~ /$findtext/) {
                                        $tmpln = join (' --- ', @_);
                                    }
                                }
                            }
						    $tmptop = $tmpno - 20;
                            if ($tmptop < 0) {
                                $tmptop = 0;
                            }
                            if ($literal eq 'checked') {
                                # show < and > as literal and not HTML tags
#                                $tmpln =~ s/</&lt;/g;
#                                $tmpln =~ s/>/&gt;/g;
                            }
						    $_ = "<a href=\"/view.htm?update=Skip&skip=$tmptop&hiliteln=$tmpno&maxln=100&path=$pnameurl$fnameurl\">$tmpno</a>".
                                " <a href=\"/view.htm?path=$pnameurl$fnameurl&hiliteln=$tmpno#line$tmpno\" target=\"_blank\">:</a>".
                                "$tmpln";
						}

                        # hilite text
                        if (length($hilitetext) > 0) {
                            $ii = 0;
                            foreach $pattern (split ('\|\|', $hilitetext)) {
                                if ($ii <= $#colors) {
                                    $color = $colors[$ii];
                                } else {
                                    $color = $colors[$#colors];
                                }
                                if ($pattern =~ /^\(\((\d+)\)\)$/) {
                                    # highlight ((line_number))
                                    if ($lineno == $1) {
                                        $_ = "<font style=\"color:black;background-color:$color\">$_<\/font>";
                                    }
                                } else {
                                    s/($pattern)/<font style=\"color:black;background-color:$color\">$1<\/font>/gi;
                                }
                                $ii++;
                            }
                        }

					    $foundfullrstnew .= "$_\n";
                        if ($findskip >= 0) {
                            if ($foundcnt <= $findmaxln) {
                                $found .= "$_\n";
                            }
                        } else {
                            if ($foundcnt >= $#foundfullarray - $findmaxln) {
                                $found .= "$_\n";
                            }
                        }
					}
                    $foundfullrst = "<pre>\n$foundfullrstnew\n</pre>\n";
                    $found .= "</pre>\n";
                } else {
                    $foundcnt = 0;
					foreach $_ (split("\n", $foundfullrst)) {
                        $foundcnt++;
                        if ($findskip >= 0) {
                            if ($foundcnt <= $findmaxln) {
                                $found .= $_;
                            }
                        } else {
                            if ($foundcnt >= $#foundfullarray - $findmaxln) {
                                $found .= $_;
                            }
                        }
                    }
                }

                #$foundcnt -= 2; # adjustment
                if ($foundcnt > $findmaxln) {
                    $tmp = $foundcnt - $findmaxln;
                    $found .= "There are $tmp more results: ".
                        "<a href=\"/view.htm?path=l00://find.htm&update=Skip\" target=\"_blank\">View l00://find.htm</a> - ".
                        "<a href=\"/view.htm?path=l00://find.txt&update=Skip\" target=\"_blank\">View l00://find.txt</a>. ".
                        "<a href=\"/ls.htm?path=l00://find.htm\" target=\"_blank\">Full page l00://find.htm</a>\n";
                }
                $found .= "<br><a name=\"__find__\"></a><font style=\"color:black;background-color:lime\">Find in this file results end</font>.\n";
                $found = "Found $foundcnt matches. $found";
                $found .= "<hr>\n";

                # path=./ substitution
                $found =~ s/path=\.\//path=$pnameurl/g;
                # path=$ substitution
                $found =~ s/path=\$/path=$pnameurl$fnameurl/g;

                print $sock &l00wikihtml::wikihtml ($ctrl, $pname, $found, 0);
                print $sock "<p>\n";
                # save in RAM file too
                &l00httpd::l00fwriteOpen($ctrl, 'l00://find.htm');
                &l00httpd::l00fwriteBuf($ctrl, $foundfullrst);
                &l00httpd::l00fwriteClose($ctrl);

                $foundfullrst =~ s/<.+?>//gm;   # remove HTML tags
                $foundfullrst =~ s/\n\d+ : /\n/gm;   # remove line numbers
                &l00httpd::l00fwriteOpen($ctrl, 'l00://find.txt');
                &l00httpd::l00fwriteBuf($ctrl, $foundfullrst);
                &l00httpd::l00fwriteClose($ctrl);
            }

            print $sock "<pre>\n";

            print $sock sprintf ("<a name=\"hilitetext_%d\"></a>", 0);
            $hilitetextidx = 1;
            if ($skip < 0) {
                @_ = split ("\n", $buffer);
                $totallns = $#_ + 1;
                $skip0  = $totallns - $maxln + 1;
            } else {
                $skip0  = $skip;
            }
            $actualSt = -1;
            $actualEn = -1;
            foreach $_ (split ("\n", $buffer)) {
                $lineno++;
                if ($lineno < $skip0) {
                    if ($lineno == 1) {
                        print $sock "\nFirst $skip0 lines skipped\n";
                    }
                    next;
                }
                if (($lineno - $skip0) > $maxln) {
                    next;
                }
                s/\r//g;
                s/\n//g;
                $displayed .= "$_\n";
                s/&/&amp;/g;
                s/</&lt;/g;
                s/>/&gt;/g;
                # record lines actually displayed
                if ($actualSt < 0) {
                    $actualSt = $lineno;
                }
                $actualEn = $lineno;
                if (defined($form->{'hidelnno'}) && 
                    ($form->{'hidelnno'} eq 'on')) {
                    if ($hilite == $lineno) {
                        print $sock "<font style=\"color:black;background-color:lime\">$_</font>\n";
                    } else {
                        # do ANSI color
                        if ($ansi ne '') {
                            if(/\x1b\[\d+m/) {
                                foreach $ii (keys %ansicode) {
                                    $tmp = "\\$ii";
                                    s/$tmp/$ansicode{$ii}/g;
                                }
                                # patch up unknown code
                                s/\x1b\[\d+m/<font style="color:gray;background-color:white">/g;
                            }                            
                        }
                        if (length($hilitetext) > 0) {
                            $ii = 0;
                            foreach $pattern (split ('\|\|', $hilitetext)) {
                                if ($ii <= $#colors) {
                                    $color = $colors[$ii];
                                } else {
                                    $color = $colors[$#colors];
                                }
                                if ($pattern =~ /^\(\((\d+)\)\)$/) {
                                    # highlight ((line_number))
                                    if ($lineno == $1) {
                                        $_ = "<font style=\"color:black;background-color:$color\">$_<\/font>";
                                    }
                                } else {
                                    s/($pattern)/<font style=\"color:black;background-color:$color\">$1<\/font>/gi;
                                }
                                $ii++;
                            }
                        }

                        print $sock "$_\n";
                    }
                } else {
                    $clip = &l00httpd::urlencode ($_);
					# = "clip.htm?update=Copy+to+clipboard&clip=$tmp
                    if ($hilite == $lineno) {
                        print $sock sprintf ("<a name=\"line%d\"></a><a href=\"/clip.htm?update=Copy+to+clipboard&clip=", $lineno);
                        print $sock $clip;
                        print $sock sprintf ("\" target=\"_blank\">%04d</a> <font style=\"color:black;background-color:lime\"><a href=\"edit.htm?path=$pnameurl2$fnameurl2&blklineno=%d\">:</a> ", $lineno, $lineno) . "$_</font>\n";
                    } else {
                        # do ANSI color
                        if ($ansi ne '') {
                            if(/\x1b\[\d+m/) {
                                foreach $ii (keys %ansicode) {
                                    $tmp = "\\$ii";
                                    s/$tmp/$ansicode{$ii}/g;
                                }
                                # patch up unknown code
                                s/\x1b\[\d+m/<font style="color:gray;background-color:white">/g;
                            }                            
                        }
                        if (length($hilitetext) > 0) {
                            $hit = 0;
                            $ii = 0;
                            foreach $pattern (split ('\|\|', $hilitetext)) {
                                if ($ii <= $#colors) {
                                    $color = $colors[$ii];
                                } else {
                                    $color = $colors[$#colors];
                                }
                                if ($pattern =~ /^\(\((\d+)\)\)$/) {
                                    # highlight ((line_number))
                                    if ($lineno == $1) {
                                        $_ = "<font style=\"color:black;background-color:$color\">$_<\/font>";
                                    }
                                } elsif (/$pattern/) {
                                    s/($pattern)/<font style=\"color:black;background-color:$color\">$1<\/font>/gi;
                                    $hit = 1;
                                }

                                $ii++;
                            }
                            if ($hit) {
                                print $sock "<a name=\"hilitetext_$hilitetextidx\"></a>";
                                $tmp = $hilitetextidx - 1;
                                print $sock sprintf ("<a name=\"line%d\"></a><a href=\"/view.htm?path=$pnameurl2$fnameurl2&hiliteln=$lineno&lineno=on#hilitetext_$tmp\">&lt;</a><a href=\"/clip.htm?update=Copy+to+clipboard&clip=", $lineno);
                                print $sock $clip;
                                $tmp = $hilitetextidx + 1;
                                #line%d
                                print $sock sprintf ("\" target=\"_blank\">%04d</a><a href=\"/view.htm?path=$pnameurl2$fnameurl2&hiliteln=$lineno&lineno=on#hilitetext_$tmp\">&gt;</a>", $lineno) . " $_\n";
                                $hilitetextidx++;
                            } else {
                                print $sock sprintf ("<a name=\"line%d\"></a><a href=\"/clip.htm?update=Copy+to+clipboard&clip=", $lineno);
                                print $sock $clip;
                                print $sock sprintf ("\" target=\"_blank\">%04d</a> <a href=\"/view.htm?path=$pnameurl2$fnameurl2&hiliteln=$lineno&lineno=on#line%d\">:</a> ", $lineno, $lineno - 5) . "$_\n";
                            }
                        } else {
                            print $sock sprintf ("<a name=\"line%d\"></a><a href=\"/clip.htm?update=Copy+to+clipboard&clip=", $lineno);
                            print $sock $clip;
                            print $sock sprintf ("\" target=\"_blank\">%04d</a> <a href=\"view.htm?path=$pnameurl2$fnameurl2&hiliteln=$lineno&lineno=on#line%d\">:</a> ", $lineno, $lineno - 5) . "$_\n";
                        }
                    }
                }
            }
            print $sock "</pre>\n";
            &l00httpd::l00fwriteOpen($ctrl, 'l00://displayed.txt');
            &l00httpd::l00fwriteBuf($ctrl, $displayed);
            &l00httpd::l00fwriteClose($ctrl);
        }
    }
    print $sock "<hr><a name=\"end\"></a><p>\n";
    if ($skip >= 0) {
        # only if skipping from the start
        if (($lineno + $skip) > $maxln) {
            print $sock "\nAnother " . ($lineno - $skip - $maxln) . " lines skipped<br>\n";
        }
    }
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
            $size, $atime, $mtimea, $ctime, $blksize, $blocks);
    if ($form->{'path'} =~ /^l00:\/\//) {
        # RAM file
        $size = &l00httpd::l00fstat($ctrl, $form->{'path'});
    } else {
        # disk file
        ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, 
            $size, $atime, $mtimea, $ctime, $blksize, $blocks)
                = stat($form->{'path'});
    }


    $jumptable = '';
    if (!defined($size)) {
        $size = 0;
    }
    $jumptable .= "\nThere are $lineno lines and $size bytes in $form->{'path'}<p>\n";

    # skip backward $maxln
    $jumptable .= "View last: <a href=\"/view.htm?update=Skip&skip=-1&maxln=10&path=$pnameurl$fnameurl#end\">10</a>,\n";
    $jumptable .= "<a href=\"/view.htm?update=Skip&skip=-1&maxln=200&path=$pnameurl$fnameurl#end\">200</a>,\n";
    $jumptable .= "<a href=\"/view.htm?update=Skip&skip=-1&maxln=500&path=$pnameurl$fnameurl#end\">500</a>,\n";
    $jumptable .= "<a href=\"/view.htm?update=Skip&skip=-1&maxln=1000&path=$pnameurl$fnameurl#end\">1000</a>,\n";
    $jumptable .= "<a href=\"/view.htm?update=Skip&skip=-1&maxln=2000&path=$pnameurl$fnameurl#end\">2000</a>,\n";
    $jumptable .= "<a href=\"/view.htm?update=Skip&skip=-1&maxln=5000&path=$pnameurl$fnameurl#end\">5000</a>,\n";
    $jumptable .= "<a href=\"/view.htm?update=Skip&skip=-1&maxln=10000&path=$pnameurl$fnameurl#end\">10000</a> lines.<p>\n";

    # view first X lines
    $jumptable .= "View first: <a href=\"/view.htm?update=Skip&skip=0&maxln=10&path=$pnameurl$fnameurl#top\">10</a>,\n";
    $jumptable .= "<a href=\"/view.htm?update=Skip&skip=0&maxln=200&path=$pnameurl$fnameurl#top\">200</a>,\n";
    $jumptable .= "<a href=\"/view.htm?update=Skip&skip=0&maxln=500&path=$pnameurl$fnameurl#top\">500</a>,\n";
    $jumptable .= "<a href=\"/view.htm?update=Skip&skip=0&maxln=1000&path=$pnameurl$fnameurl#top\">1000</a>,\n";
    $jumptable .= "<a href=\"/view.htm?update=Skip&skip=0&maxln=2000&path=$pnameurl$fnameurl#top\">2000</a>,\n";
    $jumptable .= "<a href=\"/view.htm?update=Skip&skip=0&maxln=5000&path=$pnameurl$fnameurl#top\">5000</a>,\n";
    $jumptable .= "<a href=\"/view.htm?update=Skip&skip=0&maxln=10000&path=$pnameurl$fnameurl#top\">10000</a> lines.<p>\n";

    $jumptable .= "Click <a href=\"/view.htm?path=$pnameurl$fnameurl&update=yes&skip=0&maxln=$lineno\">here</a> to view the entire file. \n";
    $jumptable .= "ls between <a href=\"/ls.htm?path=$pnameurl$fnameurl&skipto=$actualSt&stopat=$actualEn&submit=Submit\">$actualSt - $actualEn</a> - \n";
    $jumptable .= "with <a href=\"/ls.htm?path=$pnameurl$fnameurl&skipto=$actualSt&stopat=$actualEn&submit=Submit&lfisbr=on&embedpic=on\">paragraphs and images</a><p>\n";
    $jumptable .= "View <a href=\"/view.htm?path=l00://displayed.txt\" target=\"_blank\">l00://displayed.txt</a> - \n";
    $jumptable .= "<a href=\"/filemgt.htm?copy=copy&path=l00://displayed.txt&path2=l00://$fname.$skip-$maxln.txt\" target=\"_blank\">filemgt</a><p>\n";
    print $sock $jumptable;

    # highlite
    print $sock "<hr><a name=\"find\"></a>\n";
    print $sock "<form action=\"/view.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"dohilite\" value=\"Hi&#818;Lite\" accesskey=\"i\">\n";
    print $sock "</td><td>\n";
    $_ = $hilitetext;
    s/"/&quot;/g;   # can't use " in input value
    print $sock "regex&#818; <input type=\"text\" size=\"12\" name=\"hilitetext\" value=\"$_\" accesskey=\"x\">\n";
    print $sock "<input type=\"checkbox\" name=\"ansi\" $ansi>ANSI\n";
    print $sock "<input type=\"submit\" name=\"clrhilite\" value=\"clr\"></td></tr>\n";
    print $sock "</table>\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
    if (defined($form->{'hidelnno'}) && ($form->{'hidelnno'} eq 'on')) {
        print $sock "<input type=\"hidden\" name=\"hidelnno\" value=\"on\">\n";
    }
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
    print $sock "RegE&#818;x (||): <input type=\"submit\" name=\"cbpaste\" value=\"C&#818;B\">\n";
    print $sock "</td><td>\n";
    $_ = $findtext;
    s/"/&quot;/g;   # can't use " in input value
    print $sock "<input type=\"text\" size=\"12\" name=\"findtext\" value=\"$_\" accesskey=\"e\"> <input type=\"submit\" name=\"clr\" value=\"clr\">\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Exclude in found:\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"12\" name=\"excludeinfound\" value=\"$excludeinfound\">\n";
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
    print $sock "<input type=\"checkbox\" name=\"sortfind\" $sortfind>sort'\n";
    print $sock "</td></tr>\n";
    print $sock "<tr><td>\n";
    print $sock "Pre context: <input type=\"text\" size=\"4\" name=\"lastfew\" value=\"$lastfew\">\n";
    print $sock "</td><td>\n";
    print $sock "Post context: <input type=\"text\" size=\"4\" name=\"nextfew\" value=\"$nextfew\">\n";
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
    print $sock "<tr><td>\n";
    print $sock "Find start <input type=\"text\" size=\"4\" name=\"findstart\" value=\"$findstart\">\n";
    print $sock "</td><td>\n";
    print $sock "Find len <input type=\"text\" size=\"4\" name=\"findlen\" value=\"$findlen\"> lines\n";
    print $sock "</td></tr>\n";
    print $sock "</table>\n";
    print $sock "</form>\n";

    # print hilite regex:
    if ($hilitetext ne '') {
        print $sock "<pre>Sorted hilite regex:\n";
        foreach $_ (sort (split('\|\|', $hilitetext))) {
            print $sock "$_\n";
        }
        print $sock "</pre>\n";
    }
    # print find regex:
    if ($findtext ne '') {
        print $sock "<pre>Sorted find count and regex:\n";
        $findidx = 0;
        foreach $_ (sort (split('\|\|', $findtext))) {
            printf $sock ("% 5d: %s\n", $findCount[$findidx], $_);
            $findidx++;
        }
        print $sock "</pre>\n";
    }

    print $sock "Blockmark: Regex matching start of block. e.g. '^=' or '^\\* '\n";

    print $sock "<p><a href=\"#top\">Jump to top</a> - \n";
    print $sock "<a href=\"/launcher.htm?path=$pnameurl$fnameurl\">Launcher</a> - \n";
    print $sock "<a href=\"/ls.htm?find=Find&findtext=%3Ano%5E%3A&block=.&path=$pnameurl$fnameurl\">Find in this file</a>\n";

    if (defined($ctrl->{'sshsync'}) &&
        (($tmp, $tmpln) = $ctrl->{'sshsync'} =~ /^(.+?):(.+)$/)) {
        $tmpln .= '/';
    } else {
        $tmp = 'ssh user@host';
        $tmpln = '';
    }
    print $sock "<p>sshsync.pl command line:\n<pre>".
        "echo -e \"\\\n".
        "$tmp  \\`  $form->{'path'}  \\`  bash -c  \\`  $fname \\n\\\n".
        "\" | perl ${tmpln}sshsync.pl</pre>\n";


    print $sock $jumptable;

    print $sock "<p>Jump to line: ";
    print $sock "<a href=\"#top\">top</a> - \n";
    $tmp = 200;
    $tmpln = $skip + $tmp - 1;
    $tmpln -= $tmpln % $tmp;
    $tmpln++;
    $tmptop = $skip + $maxln;
    if ($tmptop > $lineno) {
        $tmptop = $lineno;
    }
    while ($tmpln < $tmptop) {
        print $sock "<a href=\"#line$tmpln\">$tmpln</a> - \n";
        $tmpln += $tmp;
    }


    if (defined ($ctrl->{'FOOT'})) {
        print $sock "$ctrl->{'FOOT'}\n";
    }

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
