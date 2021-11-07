use strict;
use warnings;
#use File::Find;    # not available on Android ASE

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# This module allows directory browsing and file retrieval.
# It also render a very rudimentary set of Wikiwords


# What it does:
# 1) Determine operating path and mode
# 2) If the path is not a directory:
# 2.1) If in raw mode, send raw binary
# 2.2) If not, try reading 30 lines and look for Wikitext
# 2.3) If Wikitexts were found, render rudimentary Wiki
# 2.4) If no Wikitext were found, a <br> as linefeed
# 3) If the path is a directory, make a table with links
# 4) If not in raw mode, also display a control table


my %config = (proc => "l00http_find_proc",
              desc => "l00http_find_desc");
my ($atime, $blksize, $blocks, $buf, $bulvl, $ctime, $dev);
my ($el, $file, $fullpath, $gid, $hits, $hour, $ii);
my ($ino, $intbl, $isdst, $len, $ln, $lv, $lvn, $lsmaxitems);
my ($mday, $min, $mode, $mon, $mtime, $nlink, $raw_st, $rdev);
my ($readst, $sec, $size, $ttlbytes, $tx, $uid, $url, $recursive, $context, $lnctx, $findctrl);
my ($fmatch, $fmatches, $content, $pathregex, $fullname, $lineno, $lineno0, $maxlines, $sock);
my ($wday, $yday, $year, @cols, @el, @els, $sendto, $wraptext, $filenameonly, $srcdoc, $sortoffset);

my ($path);
my ($ramtxt, $ramhtml);

$recursive = 'checked';
$fmatches = '';
$content = '';
$maxlines = 4000;
$sendto = 'view';
$wraptext = '';
$filenameonly = '';
$srcdoc = '';
$context = 0;
$sortoffset = 0;
$pathregex = '';
$lsmaxitems = 1000;

sub findsort {
    $a =~ s/<.+?>//g;
    $b =~ s/<.+?>//g;
    if ($findctrl->{'debug'} >= 3) {
        print substr($b, $sortoffset, 9999) . "\n";
    }
    substr($b, $sortoffset, 9999) cmp substr($a, $sortoffset, 9999);
}

sub l00http_find_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    "find: Find files and find in files using Regular Expression";
}

sub l00http_find_search {
    my ($mypath, $ctrl) = @_;
    my $hitcnt = 0;
    my $filecnt = 0;
    my $totalbytes = 0;
    my $totalfiles = 0;
    my ($paren, @allparen, $lineend, $tmp, $fstat, $lnout);
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $output, $output2,
	 $size, $atime, $mtime, $ctime, $blksize, $blocks);
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);
    my ($contents, $pathregex2, $sockout, $foundcnt);

    if ($content =~ /\(/) {
        $paren = 1;
    } else {
        $paren = 0;
    }
    $lineend = '<br>';
    if ($wraptext eq '') {
        $lineend = '';
        print $sock "<pre>\n";
    }


    $output = '';
    foreach $fmatch (split ('\|\|\|', $fmatches)) {
        ($mypath) = @_;     # reset for restarting searches
        if ((length ($fmatch) > 0) && defined ($mypath)) {
            my @allpaths = $mypath;
            # reference http://www.perlmonks.org/?node_id=489552
            # is a stack. new ones are pushed into it. we pop until there is none.
            while (@allpaths) {
                $mypath = pop (@allpaths);

                if (opendir (DIR, $mypath)) {
                    foreach $file (sort {lc($a) cmp lc($b)} readdir (DIR)) {
                        next if $file eq '.';
                        next if $file eq '..';
                        $fullname = $mypath . $file;
                        if (-d $fullname) {
                            # directory, recurse?
                            if ($recursive eq "checked") {
                                # only or exclude path
                                if (length($pathregex) > 0) {
                                    # $pathregex defined
                                    if ($pathregex =~ /^!!/) {
                                        $pathregex2 = substr ($pathregex, 2, length ($pathregex) - 2);
                                        # starts with ^!! so regex is skip if match found or search if no match
                                        if (!($fullname =~ /$pathregex2/i)) {
                                            # not a match, so don't skip
                                            push (@allpaths, $fullname.'/');
                                        }
                                    } else {
                                        # does not start with ^!! so regex search if match found
                                        if ($fullname =~ /$pathregex/i) {
                                            # a match, so search it
                                            push (@allpaths, $fullname.'/');
                                        }
                                    }
                                } else {
                                    # no regex, so always search
                                    push (@allpaths, $fullname.'/');
                                }
                            }
                        } else {
                            if ($fullname =~ /$fmatch/i) {
                                if (length ($content) > 0) {
                                    $contents = $content;
                                    foreach $content (split ('\|\|\|', $contents)) {
                                        # find in files
                                        if (open (IN, "<$fullname")) {
                                            my $hit = 0;
                                            my ($content2, $bang);
                                            if ($content =~ /^!!/) {
                                                $content2 = substr ($content, 2, length ($content) - 2);
                                                $bang = 1;
                                            } else {
                                                $content2 = $content;
                                                $bang = 0;
                                            }
                                            $lineno = 0;
                                            while (<IN>) {
                                                $lineno++;
                                                if (@allparen = /$content2/i) {
                                                    $hitcnt++;
                                                    $hit++;
                                                    if ($bang) {
                                                        next;
                                                    }
                                                    # ! processing??
                                                    if ($paren) {
                                                        $_ = $1;
                                                    }
                                                    # print all occurances
                                            
                                                    s/</&lt;/g;  # no HTML tags
                                                    s/>/&gt;/g;
                                                    if ($paren) {
                                                        $output .= join (' ', @allparen) . "$lineend\n";
                                                        #print $sock join (' ', @allparen) . "$lineend\n";
                                                    } else  {
                                                        $lineno0 = $lineno - 3;
                                                        if ($lineno0 < 1) {
                                                            $lineno0 = 1;
                                                        }
                                                        if ($srcdoc eq '') {
                                                            $output .= 
                                                                "<a href=\"/ls.htm?path=$mypath\">$mypath</a>".
                                                                "<a href=\"/$sendto.htm?path=$fullname&hiliteln=$lineno&lineno=on#line$lineno0\">$file</a>";
                                                            #$output .= "($lineno): $_$lineend";
                                                            $output .= "(<a href=\"/view.htm?path=$fullname&hiliteln=$lineno&lineno=on#line$lineno0\">$lineno</a>): $_$lineend";
                                                            #print $sock 
                                                            #   "<a href=\"/ls.htm?path=$mypath\">$mypath</a>".
                                                            #   "<a href=\"/$sendto.htm?path=$fullname&hiliteln=$lineno&lineno=on#line$lineno0\">$file</a>";
                                                            #print $sock "($lineno): $_$lineend";
                                                        } else {
                                                            $lnout = $_;
                                                            if ($context > 0) {
                                                                if (open (FRAG, "<$fullname")) {
                                                                    $lnctx = 1;
                                                                    while (<FRAG>) {
                                                                        if (($lnctx > ($lineno - $context)) &&
                                                                            ($lnctx <  $lineno)) {
                                                                            $output .= " " x (length ($fullname) + 8) . $_;
                                                                            #print $sock " " x (length ($fullname) + 8) . $_;
                                                                        }
                                                                        $lnctx++;
                                                                    }
                                                                    close (FRAG);
                                                                }
                                                            }
                                                            $output .= 
                                                                "<a href=\"/ls.htm?path=$mypath\" target=\"_blank\">$mypath</a>".
                                                                "<a href=\"/$sendto.htm?path=$fullname&hiliteln=$lineno&lineno=on#line$lineno0\" target=\"source\">$file</a>";
                                                            $tmp = "&tgtline=$lineno";
                                                            $output .= "(<a href=\"/srcdoc.htm?path=$fullname&lineno=on$srcdoc$tmp#line$lineno\">$lineno</a>): $lnout$lineend";
                                                            $tmp = "&tgtline=$lineno";
                                                            if ($context > 0) {
                                                                if (open (FRAG, "<$fullname")) {
                                                                    $lnctx = 1;
                                                                    while (<FRAG>) {
                                                                        if (($lnctx >  $lineno) &&
                                                                            ($lnctx < ($lineno + $context))) {
                                                                            $output .= " " x (length ($fullname) + 8) . $_;
                                                                            #print $sock " " x (length ($fullname) + 8) . $_;
                                                                        }
                                                                        $lnctx++;
                                                                    }
                                                                    $output .= "<hr>\n";
                                                                    #print $sock "<hr>\n";
                                                                    close (FRAG);
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                                if ($lineno >= $maxlines) {
                                                    # up to max
                                                    last;
                                                }
                                            } # end serch loop
                                            close (IN);
                                            if ($bang) {
                                                if (!$hit) {
                                                    # find files not containing
                                                    $filecnt++;
                                                    $output .= 
                                                        "<a href=\"/ls.htm?path=$mypath\">$mypath</a>".
                                                        "<a href=\"/$sendto.htm?path=$fullname\">$file</a>$lineend\n";
                                                    #print $sock 
                                                    #   "<a href=\"/ls.htm?path=$mypath\">$mypath</a>".
                                                    #   "<a href=\"/$sendto.htm?path=$fullname\">$file</a>$lineend";
                                                }
                                            } else {
                                                if ($hit) {
                                                    $filecnt++;
                                                }
                                            }
                                        } else {
                                            # unexpected?
                                            $output .= "Can't open: $fullname$lineend";
                                            #print $sock "Can't open: $fullname$lineend";
                                        }
                                    } # multiple search pattern loop
                                } else {
                                    # find files
                                    $filecnt++;
									# get file info
									($dev, $ino, $mode, $nlink, $uid, $gid, $rdev,
									 $size, $atime, $mtime, $ctime, $blksize, $blocks)
									  = stat($mypath.$file);
								    ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst)
									  = localtime($mtime);
									$fstat = 
									 sprintf ("%9d %4d/%02d/%02d %02d:%02d:%02d", $size, 1900+$year, 1+$mon, $mday, $hour, $min, $sec);
                                    if ($filenameonly eq '') {
                                        $output .= 
                                            "$fstat ".
                                            "<a href=\"/ls.htm?path=$mypath\">$mypath</a>".
                                            "<a href=\"/$sendto.htm?path=$fullname\">$file</a>".
                                            "$lineend\n";
                                    } else {
                                        # filename only
                                        $output .= "$mypath$file\n";
                                    }
                                    $totalfiles++;
                                    $totalbytes += $size;
                                    #print $sock 
                                    #   "$fstat ".
                                    #   "<a href=\"/ls.htm?path=$mypath\">$mypath</a>".
                                    #   "<a href=\"/$sendto.htm?path=$fullname\">$file</a>".
                                    #   "$lineend\n";
                                }
                            }
                        }
                    }
                    closedir (DIR);
                }
            }
        }
    }
    if (defined ($sortoffset) && (length($sortoffset) > 0) && 
        ($sortoffset > 0) && 
        ($content eq '') &&
        ($wraptext eq '')) {
        $output2 = join("\n", sort findsort split("\n", $output));

        $foundcnt = 0;
        $sockout = '';
        foreach $_ (split("\n", $output2)) {
            if ($foundcnt++ < $lsmaxitems) {
                $sockout .= "$_\n";
            } else {
                last;
            }
        }
        $ramhtml .= "$output2\n";

        $output2 =~ s/<.+?>//g;
        &l00httpd::l00fwriteBuf($ctrl, $output2);
    } else {
        $foundcnt = 0;
        $sockout = '';
        foreach $_ (split("\n", $output)) {
            if ($foundcnt++ < $lsmaxitems) {
                $sockout .= "$_\n";
            } else {
                last;
            }
        }
        $ramhtml .= "$output\n";

        $output =~ s/<.+?>//g;
        &l00httpd::l00fwriteBuf($ctrl, $output);
    }
    print $sock $sockout;

    if ($wraptext eq '') {
        print $sock "</pre>\n";
    }

    ($mypath) = @_;
    if ($content =~ /^!!/) {
        print $sock "<p>$filecnt file(s) not containing pattern in '$mypath'\n";
    } else {
        print $sock "<p>Found $hitcnt occurance(s) in $filecnt file(s) in '$mypath'<br>".
            "Click path to visit directory, click filename to view file\n";
    }
    print $sock "<br>Total $totalbytes bytes in $totalfiles files -- \n";
    print $sock "<a href=\"/view.htm?path=l00://find_in_files.html\" target=\"_blank\">l00://find_in_files.html</a> - \n";
    print $sock "<a href=\"/view.htm?path=l00://find_in_files.txt\" target=\"_blank\">l00://find_in_files.txt</a><p>\n";

    print $sock "Found results also in <a href=\"/view.htm?path=l00://findinfile.htm\" target=\"_blank\">l00://findinfile.htm</a>\n";

    1;
}

sub l00http_find_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    $sock = $ctrl->{'sock'};
    my $form = $ctrl->{'FORM'};
    my ($thispath, $pathcnt, $dirlist, $dirlist1000, $dirlisttxt, $listcnt);


    if (defined($ctrl->{'lsmaxitems'}) && ($ctrl->{'lsmaxitems'} =~ /(\d+)/)) {
        $lsmaxitems = $1;
    }


    $findctrl = $ctrl;

    # special srcdoc.pl integration
    $srcdoc = '';
    if (defined ($form->{'srcdoc'})) {
        $srcdoc = $form->{'srcdoc'};
    }

    # 1) Determine operating path and mode

    $path = $form->{'path'};
    if (!defined ($path) || (length ($path) < 1)) {
        $path = $ctrl->{'plpath'};
    } elsif (defined ($form->{'path'}) && (length ($form->{'path'}) >= 1)) {
        $path = $form->{'path'};
    }

    if (defined ($form->{'recursive'})) {
        $recursive = "checked";
    } else {
        $recursive = "";
    }
    if (defined ($form->{'filenameonly'})) {
        $filenameonly = 'checked';
    } else {
        $filenameonly = '';
    }
    if (defined ($form->{'wraptext'})) {
        $wraptext = 'checked';
    } else {
        $wraptext = '';
    }
    if (defined ($form->{'fmatch'})) {
        $fmatches = $form->{'fmatch'};
    }
    if (defined ($form->{'cb2name'})) {
        $fmatches = &l00httpd::l00getCB($ctrl);
    }
    if (defined ($form->{'content'})) {
        $content = $form->{'content'};
    } else {
        $content = '';
	}
    if (defined ($form->{'pathregex'})) {
        $pathregex = $form->{'pathregex'};
    } else {
        $pathregex = '';
	}
    if (defined ($form->{'cb2cont'})) {
        $content = &l00httpd::l00getCB($ctrl);
    }
    if (defined ($form->{'maxlines'})) {
        $maxlines = $form->{'maxlines'};
    }
    if (defined ($form->{'sendto'})) {
        $sendto = $form->{'sendto'};
    }
    if (defined ($form->{'sortoffset'})) {
        $sortoffset = $form->{'sortoffset'};
    }
    if (defined ($form->{'cbclrname'})) {
        $fmatches = '';
        $content = '';
        $pathregex = '';
        $maxlines = 4000;
    }

    $dirlist = '';
    $dirlist1000 = '';
    $dirlisttxt = '';
    $listcnt = 0;
    $pathcnt = 0;
    foreach $thispath (split ('\|\|\|', $path)) {
        $pathcnt++;
        $thispath =~ tr/\\/\//;     # converts all \ to /, which work on Windows too
        # drop filename
        $thispath =~ s/\/[^\/]+$/\//;

        # try to open as a directory
        if (!opendir (DIR, $thispath)) {

            # 2) If the path is not a directory:
            if ($pathcnt == 1) {
                print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
            } else {
                print $sock "<hr><p>\n";
            }
            print $sock "Not expecting a file: $thispath<hr>\n";
            print $sock "<a href=\"/find.htm?/./\">/./</a><br>\n";
        } else {
            #.dir
            # yes, it is a directory, read files in the directory
        
            if ($pathcnt == 1) {
                print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
            } else {
                print $sock "<hr><p>\n";
            }

            print $sock "<a name=\"__top__\"></a>\n";
            print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<br>\n";
            print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$thispath\">Path</a>: <a href=\"/ls.htm/ls.htm?path=$thispath\">$thispath</a> - \n";
            print $sock "<a href=\"#list\">Jump to list</a> - \n";
            print $sock "<a href=\"#end\">Jump to end</a><hr>\n";
            if ($srcdoc ne '') {
                print $sock "<font style=\"color:black;background-color:lime\">Step 3: Find text and choose by clicking line number on the right of filename</font>\n";
            }


            $dirlist1000 .= "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
            $dirlist1000 .= "<tr>\n";
            $dirlist1000 .= "<td>names</td>\n";
            $dirlist1000 .= "<td>bytes</td>\n";
            $dirlist1000 .= "<td>date/time</td>\n";
            $dirlist1000 .= "</tr>\n";
                   
            # 3) If the path is a directory, make a table with links

            foreach $file (sort {lc($a) cmp lc($b)} readdir (DIR)) {
                if (-d $thispath.$file) {
                    # it's a directory, print a link to a directory
                    if ($file =~ /^\.$/) {
                        next;
                    }
                    $fullpath = $thispath . $file;
                    if ($file =~ /^\.\.$/) {
                        $fullpath =~ s!/[^/]+/\.\.!!;
                        if ($fullpath eq "/..") {
                            $fullpath = "";
                        }
                    }

                    if ($listcnt++ <= $lsmaxitems) {
                        $dirlist1000 .= "<tr>\n";
                        $dirlist1000 .= "<td><small><a href=\"/find.htm?path=$fullpath/\">$file/</a></small></td>\n";
                        $dirlist1000 .= "<td><small>&lt;dir&gt;</small></td>\n";
                        $dirlist1000 .= "<td>&nbsp;</td>\n";
                        $dirlist1000 .= "</tr>\n";
                    }

                    $dirlisttxt .= "$fullpath/\n";
                
                    $dirlist .= "$listcnt: <a href=\"/find.htm?path=$fullpath/\">$file/</a><br>\n";
                }
            }

            $dirlist1000 .= "</table>\n";
            closedir (DIR);
        }
    }

    # 4) If not in raw mode, also display a control table

    print $sock "<a name=\"find\"></a>\n";
    print $sock "<form action=\"/find.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td>Settings</td>\n";
    print $sock "        <td>Descriptions</td>\n";
    print $sock "    </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Filename (regex; |||):</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"fmatch\" value=\"$fmatches\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Content ((regex); !!,|||):</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"content\" value=\"$content\" accesskey=\"e\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Path ((regex); !!):</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"pathregex\" value=\"$pathregex\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Max. lines:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"maxlines\" value=\"$maxlines\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td><input type=\"checkbox\" name=\"recursive\" $recursive accesskey=\"r\">R&#818;ecursive</td>\n";
    print $sock "            <td>Sort offset: <input type=\"text\" size=\"4\" name=\"sortoffset\" value=\"$sortoffset\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"S&#818;ubmit\" accesskey=\"s\"> <input type=\"submit\" name=\"cbclrname\" value=\"Clr\"></td>\n";
    print $sock "        <td><input type=\"checkbox\" name=\"wraptext\" $wraptext>Wrapped text</td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"cb2name\" value=\"CB2name\"> <input type=\"submit\" name=\"cb2cont\" value=\"2cont\"></td>\n";
    print $sock "        <td><input type=\"checkbox\" name=\"filenameonly\" $filenameonly>Filename only</td>\n";
    print $sock "    </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Send file to:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"sendto\" value=\"$sendto\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "</table>\n";
    print $sock "<input type=\"hidden\" name=\"path\" value=\"$path\">\n";
    if ($srcdoc ne '') {
        print $sock "<input type=\"hidden\" name=\"srcdoc\" value=\"$srcdoc\">\n";
    }
    print $sock "</form>\n";

    print $sock "<br>!!: Prefix '!!' to regex to list files without matching pattern<p>\n";

    if ($content ne '!!') {
        $ramtxt = '';
        $ramhtml = '';
        &l00httpd::l00fwriteOpen($ctrl, 'l00://findinfile.htm');
        if (defined ($form->{'submit'})) {
            foreach $thispath (split ('\|\|\|', $path)) {
                &l00http_find_search ($thispath, $ctrl);
            }
        }
        &l00httpd::l00fwriteClose($ctrl);

        $ramtxt = $ramhtml;
        $ramtxt =~ s/<.+?>//gms;
        &l00httpd::l00fwriteOpen($ctrl, "l00://find_in_files.html");
        &l00httpd::l00fwriteBuf($ctrl, "<pre>\n$ramhtml</pre>\n");
        &l00httpd::l00fwriteClose($ctrl);
        &l00httpd::l00fwriteOpen($ctrl, "l00://find_in_files.txt");
        &l00httpd::l00fwriteBuf($ctrl, $ramtxt);
        &l00httpd::l00fwriteClose($ctrl);
    }


    print $sock "<a name=\"list\"></a>\n";
    print $sock "<p><a href=\"#__top__\">Jump to top</a><p>\n";


    &l00httpd::l00fwriteOpen($ctrl, 'l00://find_dirlist.htm');
    &l00httpd::l00fwriteBuf($ctrl, $dirlist);
    &l00httpd::l00fwriteClose($ctrl);
    print $sock "There are $listcnt listings in: <a href=\"/view.htm?path=l00://find_dirlist.htm\" target=\"_blank\">l00://find_dirlist.htm</a>.\n";
    if ($listcnt > $lsmaxitems) {
        print $sock "Only 1000 are listed below.\n";
    }
    &l00httpd::l00fwriteOpen($ctrl, 'l00://find_dirlist.txt');
    &l00httpd::l00fwriteBuf($ctrl, $dirlisttxt);
    &l00httpd::l00fwriteClose($ctrl);
    print $sock " - <a href=\"/view.htm?path=l00://find_dirlist.txt\" target=\"_blank\">l00://find_dirlist.txt</a>.\n";
    print $sock "<p>\n";

    print $sock "<hr>\n";

    print $sock $dirlist1000;

    print $sock "<a name=\"end\"></a>\n";
    print $sock "<p><a href=\"#__top__\">Jump to top</a><p>\n";

    print $sock $ctrl->{'htmlfoot'};

}


\%config;
