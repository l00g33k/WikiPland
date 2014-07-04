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
my ($ino, $intbl, $isdst, $len, $ln, $lv, $lvn);
my ($mday, $min, $mode, $mon, $mtime, $nlink, $raw_st, $rdev);
my ($readst, $sec, $size, $ttlbytes, $tx, $uid, $url, $recursive, $context, $lnctx);
my ($fmatch, $fmatches, $content, $fullname, $lineno, $lineno0, $maxlines, $sock);
my ($wday, $yday, $year, @cols, @el, @els, $sendto, $prefmt, $srcdoc, $sortoffset);

my ($path);

$recursive = 'checked';
$fmatches = '';
$content = '';
$maxlines = 4000;
$sendto = 'ls';
$prefmt = 'checked';
$srcdoc = '';
$context = 0;
$sortoffset = '';

sub findsort {
    substr($b, $sortoffset, 9999) cmp substr($a, $sortoffset, 9999);
}

sub l00http_find_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    "find: Find files and find in files using Regular Expression";
}

sub l00http_find_search {
    my ($mypath, $ctrl) = @_;
#   my ($ctrl, $mypath) = @_;
    my $hitcnt = 0;
    my $filecnt = 0;
    my ($paren, @allparen, $lineend, $tmp, $fstat, $lnout);
    my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $output, $output2,
	 $size, $atime, $mtime, $ctime, $blksize, $blocks);
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst);

    if ($content =~ /\(/) {
        $paren = 1;
    } else {
        $paren = 0;
    }
    $lineend = '<br>';
    if ($prefmt eq '') {
        $lineend = '';
        print $sock "<pre>\n";
#       $ctrl->{'l00file'}->{'l00://find.pl'} .= "<pre>\n";
        &l00httpd::l00fwriteBuf($ctrl, "<pre>\n");
    }


    $output = '';
    foreach $fmatch (split ('\|\|\|', $fmatches)) {
        ($mypath) = @_;     # reset for restarting searches
        if ((length ($fmatch) > 0) && defined ($mypath)) {
            my @allpaths = $mypath;
            # reference http://www.perlmonks.org/?node_id=489552
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
                                push (@allpaths, $fullname.'/');
                            }
                        } else {
                            if ($fullname =~ /$fmatch/i) {
                                if (length ($content) > 0) {
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
                                                        $output .= "($lineno): $_$lineend";
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
                                                            "<a target=\"source\" href=\"/ls.htm?path=$mypath\">$mypath</a>".
                                                            "<a target=\"source\" href=\"/$sendto.htm?path=$fullname&hiliteln=$lineno&lineno=on#line$lineno0\">$file</a>";
                                                        $tmp = "&tgtline=$lineno";
                                                        $output .= "(<a href=\"/srcdoc.htm?path=$fullname&lineno=on$srcdoc$tmp#line$lineno\">$lineno</a>): $lnout$lineend";
                                                        #print $sock 
                                                        #   "<a target=\"source\" href=\"/ls.htm?path=$mypath\">$mypath</a>".
                                                        #   "<a target=\"source\" href=\"/$sendto.htm?path=$fullname&hiliteln=$lineno&lineno=on#line$lineno0\">$file</a>";
                                                        $tmp = "&tgtline=$lineno";
                                                        #print $sock "(<a href=\"/srcdoc.htm?path=$fullname&lineno=on$srcdoc$tmp#line$lineno\">$lineno</a>): $lnout$lineend";
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
                                        }
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
                                        close (IN);
                                    } else {
                                        # unexpected?
                                        $output .= "Can't open: $fullname$lineend";
                                        #print $sock "Can't open: $fullname$lineend";
                                    }
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
                                    $output .= 
                                        "$fstat ".
                                        "<a href=\"/ls.htm?path=$mypath\">$mypath</a>".
                                        "<a href=\"/$sendto.htm?path=$fullname\">$file</a>".
                                        "$lineend\n";
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
        ($prefmt eq '')) {
        $output2 = join("\n", sort findsort split("\n", $output));
        print $sock $output2;
#       $ctrl->{'l00file'}->{'l00://find.pl'} .= $output2;
        &l00httpd::l00fwriteBuf($ctrl, $output2);
    } else {
        print $sock $output;
#       $ctrl->{'l00file'}->{'l00://find.pl'} .= $output;
        &l00httpd::l00fwriteBuf($ctrl, $output);
    }

    if ($prefmt eq '') {
        print $sock "</pre>\n";
#       $ctrl->{'l00file'}->{'l00://find.pl'} .= "</pre>\n";
        &l00httpd::l00fwriteBuf($ctrl, "</pre>\n");
    }

    ($mypath) = @_;
    if ($content =~ /^!!/) {
        print $sock "<p>$filecnt file(s) not containing pattern in '$mypath'\n";
    } else {
        print $sock "<p>Found $hitcnt occurance(s) in $filecnt file(s) in '$mypath'<br>".
            "Click path to visit directory, click filename to view file\n";
    }
    print $sock "<p>Find results also in <a href=\"/ls.htm?path=l00://find.pl\">l00://find.pl</a>\n";

    1;
}

sub l00http_find_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    $sock = $ctrl->{'sock'};
    my $form = $ctrl->{'FORM'};
    my ($thispath, $pathcnt);


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
    if (defined ($form->{'prefmt'})) {
        $prefmt = 'checked';
    } else {
        $prefmt = '';
    }
    if (defined ($form->{'fmatch'})) {
        $fmatches = $form->{'fmatch'};
    }
    if (defined ($form->{'content'})) {
        $content = $form->{'content'};
    } else {
        $content = '';
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
            print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$thispath\">Path</a>: <a href=\"/ls.htm/ls.htm?path=$thispath\">$thispath</a> \n";
            print $sock "<a href=\"#end\">Jump to end</a>\n";
            print $sock "<a href=\"#find\">Find</a><hr>\n";
            if ($srcdoc ne '') {
                print $sock "<font style=\"color:black;background-color:lime\">Step 3: Find text and choose by clicking line number on the right of filename</font>\n";
            }
            print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";


            print $sock "<tr>\n";
            print $sock "<td>names</td>\n";
            print $sock "<td>bytes</td>\n";
            print $sock "<td>date/time</td>\n";
            print $sock "</tr>\n";
        
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
                
                    print $sock "<tr>\n";
                    print $sock "<td><small><a href=\"/find.htm?path=$fullpath/\">$file/</a></small></td>\n";
                    print $sock "<td><small>&lt;dir&gt;</small></td>\n";
                    print $sock "<td>&nbsp;</td>\n";
                    print $sock "</tr>\n";
                }
            }

            print $sock "</table>\n";
            closedir (DIR);
        }
    }

    # 4) If not in raw mode, also display a control table

    print $sock "<hr>\n";
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
    print $sock "            <td>Content (regex; !!):</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"content\" value=\"$content\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Max. lines:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"maxlines\" value=\"$maxlines\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td><input type=\"checkbox\" name=\"recursive\" $recursive>Recursive</td>\n";
    print $sock "            <td>Sort offset: <input type=\"text\" size=\"4\" name=\"sortoffset\" value=\"$sortoffset\"></td>\n";
    print $sock "        </tr>\n";


    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Submit\"></td>\n";
    print $sock "        <td><input type=\"checkbox\" name=\"prefmt\" $prefmt>Unformatted text</td>\n";
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

    print $sock "!!: Prefix !! to regex to list files without matching pattern<p>\n";

    if ($content ne '!!') {
#       $ctrl->{'l00file'}->{'l00://find.pl'} = '';
        &l00httpd::l00fwriteOpen($ctrl, 'l00://find.pl');
        foreach $thispath (split ('\|\|\|', $path)) {
            &l00http_find_search ($thispath, $ctrl);
        }
        &l00httpd::l00fwriteClose($ctrl);
    }

    print $sock "<a name=\"end\"></a>\n";
    print $sock "<p><a href=\"#__top__\">Jump to top</a><p>\n";
    print $sock $ctrl->{'htmlfoot'};

}


\%config;
