use strict;
use warnings;

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


my %config = (proc => "l00http_search_proc",
              desc => "l00http_search_desc");
my ($atime, $blksize, $blocks, $buf, $bulvl, $ctime, $dev);
my ($el, $file, $fullpath, $gid, $hits, $hour, $ii);
my ($ino, $intbl, $isdst, $len, $ln, $lv, $lvn);
my ($mday, $min, $mode, $mon, $mtime, $nlink, $raw_st, $rdev);
my ($readst, $sec, $size, $ttlbytes, $tx, $uid, $url, $recursive, $linemode, $linemark);
my ($fmatch, $condition, $content, $fullname, $lineno, $maxlines, $sock);
my ($wday, $yday, $year, @cols, @el, @els, $sendto, $sort, @sorts, $tableout, $pretext);

my $path;

$recursive = 'checked';
$fmatch = "";
$content = "";
$condition = '';
$maxlines = 1000;
$sendto = 'ls';
$sort = '';
$linemode = 0;
$linemark = '^=';
$tableout = 'checked';
$pretext = 'checked';

sub l00http_search_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    "search: Seach file content using Regular Expression and display results in table";
}

sub fn {
    my (@allfielda, @allfieldb, $retval, $sortlvl, $ii);

    $retval = 0;

    @allfielda = split ('<`>', $a);
    @allfieldb = split ('<`>', $b);

    for ($ii = 0; $ii <= $#allfielda; $ii++) {
        $allfielda[$ii] =~ s/<.+?>//g;
    }
    for ($ii = 0; $ii <= $#allfieldb; $ii++) {
        $allfieldb[$ii] =~ s/<.+?>//g;
    }

    # don't know why content of @sorts get destroy; recreae
    @sorts = split('\|\|\|', $sort);
    foreach $sortlvl (@sorts) {
        if ($retval == 0) {
            if ($sortlvl > 0) {
                $sortlvl--;
                if ($allfielda [$sortlvl] gt $allfieldb [$sortlvl]) {
                    $retval = 1;
                } elsif ($allfielda [$sortlvl] lt $allfieldb [$sortlvl]) {
                    $retval = -1;
                }
            } else {
                $sortlvl = -$sortlvl - 1;
                if ($allfielda [$sortlvl] lt $allfieldb [$sortlvl]) {
                    $retval = 1;
                } elsif ($allfielda [$sortlvl] gt $allfieldb [$sortlvl]) {
                    $retval = -1;
                }
            }
        }
    }

    $retval;
}


sub l00http_search_search {
    my ($ctrl, $form, $mypath) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $hitcnt = 0;
    my $filecnt = 0;
    my ($anchor, $tmp);
    my (@output, @outputsorted, $line, @cols, $item, @conditions, @contents, $anchorline, @allhits);
    my ($condi, $conte, %rowOutput, %conditionsFound, $conditionsFoundCnt, $lineout);

    $line = '';
    undef @output;

    # split search terms
    @conditions = split('\|\|\|', $condition);
    # split sort terms
    @sorts = split('\|\|\|', $sort);

    # split content report terms or set context
    if (length($content) == 0) {
        # if content not specified, default to some words arounds the conditions
        foreach $condi (@conditions) {
            if ($condi =~ /\(.+\)/) {
                push (@contents, $condi);
            } else {
                push (@contents, "(.{0,64}$condi.{0,64})");
            }
        }
    } else {
        @contents = split('\|\|\|', $content);
    }
#foreach $conte (@contents) {
#print "conte >$conte<\n";
#}

    # search for results
    if ((length ($fmatch) > 0) && defined ($mypath)) {
        # valid path and name pattern
        my @allpaths = $mypath; # into which we will push when recursing
        # reference http://www.perlmonks.org/?node_id=489552
        while (@allpaths) {
            # current path
            $mypath = pop (@allpaths);

            print "Fmatch $fmatch\n", if ($ctrl->{'debug'} >= 3);
            if (opendir (DIR, $mypath)) {
                # searching this directory
                foreach $file (sort readdir (DIR)) {
                    print "Found $mypath$file\n", if ($ctrl->{'debug'} >= 5);
                    next if $file eq '.';
                    next if $file eq '..';
                    $fullname = $mypath . $file;
                    if (-d $fullname) {
                        # directory, recurse?
                        if ($recursive eq "checked") {
                            # yes, recurse
                            push (@allpaths, $fullname.'/');
                        }
                    } else {
                        # it's a file
                        if ($fullname =~ /$fmatch/i) {
                            # and match the file filter pattern
                            print "Search $mypath$file\n", if ($ctrl->{'debug'} >= 5);
                            # find in files
                            if (open (IN, "<$fullname")) {
                                my $hit = 0;
                                $lineno = 0;
                                $anchor = '';
                                # searching target file
                                undef %conditionsFound;
                                undef %rowOutput;
                                $anchorline = 0;
                                while (<IN>) {
                                    # for each line in the file
                                    $lineno++;
                                    if (/$linemark/i || $linemode) {
                                        # new heading, terminate and output last search
                                        $conditionsFoundCnt = -1;
                                        foreach $condi (@conditions) {
                                            if (defined($conditionsFound{$condi})) {
                                                $conditionsFoundCnt++;
                                            }
                                        }
                                        if ($conditionsFoundCnt >= $#conditions) {
                                            # conditions satisfied
                                            # print all occurances
                                            $hitcnt++;
                                            $hit++;
                                            # construct output
                                            if ($linemode) {
                                                $line = "<a href=\"/$sendto.htm?hiliteln=$lineno&lineno=on&path=$fullname#line$lineno\">$file:$lineno</a>";
                                            } else {
                                                $line = "<a href=\"/$sendto.htm?path=$fullname#$anchor\">$file:$anchorline</a>";
                                            }
                                            foreach $conte (@contents) {
                                                $lineout = $rowOutput{$conte};
                                                if (defined($lineout)) {
                                                    $lineout =~ s/</&lt;/g;  # no HTML tags
                                                    $lineout =~ s/>/&gt;/g;
                                                    $line .= "<`>$lineout";
                                                } else {
                                                    $line .= "<`>(blank)";
                                                }
                                            }
                                            # save output
                                            push (@output, $line);
                                        }
                                        # restart
                                        undef %conditionsFound;
                                        undef %rowOutput;
                                    }

                                    if (/^=+(.+?)=+$/) {
#                                   if (/($linemark)/i) 
                                        # save anchor
                                        $anchor = $1;
                                        $anchor =~ s/[^0-9A-Za-z]/_/g;
                                        $anchorline = $lineno;
                                    }
                                    # search for conditions
                                    foreach $condi (@conditions) {
                                        if (/$condi/i) {
                                            $conditionsFound{$condi} = 1;
                                        }
                                    }
                                    # search for each contents
                                    foreach $conte (@contents) {
                                        # clear newlines
                                        s/\n/ /g;
                                        s/\r/ /g;
                                        if (@allhits = /$conte/i) {
                                            # hits
                                            if ($conte =~ /\(.*\)/) {
                                                # if (), shows only () matches
                                                $_ = join (' ', @allhits);
                                            }
                                            if (defined($rowOutput{$conte})) {
                                                # concatenate results
                                                $rowOutput{$conte} .= " ||| $_";
                                            } else {
                                                $rowOutput{$conte} = $_;
                                            }
                                        }
                                    }
                                    if ($lineno >= $maxlines) {
                                        # up to max
                                        last;
                                    }
                                }
                                # finish up last record
                                # new heading, terminate and output last search
                                $conditionsFoundCnt = -1;
                                foreach $condi (@conditions) {
                                    if (defined($conditionsFound{$condi})) {
                                        $conditionsFoundCnt++;
                                    }
                                }
                                if ($conditionsFoundCnt >= $#conditions) {
                                    # conditions satisfied
                                    # print all occurances
                                    $hitcnt++;
                                    $hit++;
                                    # construct output
                                    $line = "<a href=\"/$sendto.htm?path=$fullname#$anchor\">$file:$anchorline</a>";
                                    foreach $conte (@contents) {
                                        $lineout = $rowOutput{$conte};
                                        if (defined($lineout)) {
                                            $lineout =~ s/</&lt;/g;  # no HTML tags
                                            $lineout =~ s/>/&gt;/g;
                                            $line .= "<`>$lineout";
                                        } else {
                                            $line .= "<`>(blank)";
                                        }
                                    }
                                    # save output
                                    push (@output, $line);
                                }
                                if ($hit) {
                                    $filecnt++;
                                }
                                close (IN);
                            } else {
                                # unexpected?
                                print $sock "Can't open: $fullname<br>";
                            }
                        }
                    }
                }
                closedir (DIR);
            }
        }
    }


    # generate output table
    if ($#output >= 0) {
        # sort output
        @outputsorted = sort fn @output;

        # if saving outputs to file
        if (defined ($form->{'saveresults'}) &&
            defined ($form->{'savepath'}) &&
            (length ($form->{'savepath'}) > 1)) {
            print $sock "Results saved: <a href=\"/ls.htm?path=$form->{'savepath'}\">$form->{'savepath'}</a><br>\n";
#           if (open (OU, ">$form->{'savepath'}")) {
            if (&l00httpd::l00fwriteOpen($ctrl, $form->{'savepath'})) {
                foreach $line (@outputsorted) {
                    @cols = split('<`>', $line);
#                   print OU "||";
                    &l00httpd::l00fwriteBuf($ctrl, "||");
                    foreach $item (@cols) {
#                       print OU "$item||";
                        &l00httpd::l00fwriteBuf($ctrl, "$item||");
                    }
#                   print OU "\n";
                    &l00httpd::l00fwriteBuf($ctrl, "\n");
                }
#               close (OU);
				&l00httpd::l00fwriteClose($ctrl);
            }
        }

        if ($tableout eq 'checked') {
            # print output table
            print $sock "<table border=\"1\" cellpadding=\"1\" cellspacing=\"1\">\n";
            $line = $outputsorted[0];
            @cols = split('<`>', $line);
            print $sock "<tr>\n";
            print $sock "    <td>File:line</td>\n";
            foreach $conte (@contents) {
                print $sock "    <td>$conte</td>\n";
            }
            print $sock "</tr>\n";
            foreach $line (@outputsorted) {
                @cols = split('<`>', $line);
                print $sock "<tr>\n";
                foreach $item (@cols) {
                    print $sock "    <td>$item</td>\n";
                }
                print $sock "</tr>\n";
            }
            print $sock "</table>\n";
        } else {
            foreach $line (@outputsorted) {
#print ">>>>$line<<<<\n\n";
                @cols = split('<`>', $line);
                $tmp = 0;
                foreach $item (@cols) {
#print ">$item<\n";
                    if ($tmp == 0) {
                        print $sock "<p><font style=\"color:black;background-color:lime\">$item</font><br>\n";
                        if ($pretext eq 'checked') {
                            print $sock "<pre>";
                        }
                    } else {
                        if ($pretext eq 'checked') {
                            $item =~ s/</&lt;/g;
                            $item =~ s/>/&gt;/g;
                            $item =~ s/\|\|\|/\n/g;
                            print $sock "$item\n";
                        } else {
                            print $sock "$item<br>\n";
                        }
                    }
                    $tmp++;
                }
                if ($pretext eq 'checked') {
                    print $sock "</pre>";
                }
            }
        }
    } else {
        print $sock "Nothing found\n";
    }

    print $sock "<p>Found $hitcnt occurance(s) in $filecnt file(s)<br>".
        "Click path to visit directory, click filename to view file\n";


    1;
}

sub l00http_search_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    $sock = $ctrl->{'sock'};
    my $form = $ctrl->{'FORM'};
    my ($path);


    # 1) Determine operating path and mode

    $path = $form->{'path'};
    if (!defined ($path) || (length ($path) < 1)) {
        $path = $ctrl->{'plpath'};
    } elsif (defined ($form->{'path'}) && (length ($form->{'path'}) >= 1)) {
        $path = $form->{'path'};
    }
    $path =~ tr/\\/\//;     # converts all \ to /, which work on Windows too

    if (defined ($form->{'recursive'})) {
        $recursive = "checked";
    } else {
        $recursive = "";
    }
    if (defined ($form->{'fmatch'})) {
        $fmatch = $form->{'fmatch'};
    } else {
        $fmatch = '';
    }
    if (defined ($form->{'condition'})) {
        $condition = $form->{'condition'};
    }
    if (defined ($form->{'content'})) {
        $content = $form->{'content'};
    }
    if (defined ($form->{'maxlines'})) {
        $maxlines = $form->{'maxlines'};
    }
    if (defined ($form->{'sendto'})) {
        $sendto = $form->{'sendto'};
    }
    if (defined ($form->{'linemark'})) {
        $linemark = $form->{'linemark'};
    }
    if (defined ($form->{'linemode'})) {
        $linemode = 1;
    } else {
        $linemode = 0;
    }
    if (defined ($form->{'sort'})) {
        $sort = $form->{'sort'};
    }
    if (defined ($form->{'tableout'}) && ($form->{'tableout'} eq 'on')) {
        $tableout = "checked";
    } else {
        $tableout = '';
    }
    if (defined ($form->{'pretext'}) && ($form->{'pretext'} eq 'on')) {
        $pretext = 'checked';
    } else {
        $pretext = '';
    }

    # if $path is a file, use its path and filename
    if ($fmatch eq '') {
        if (open(IN, "<$path")) {
            close(IN);
            if (($path, $fmatch) = $path =~ /^(.*[\\\/])([^\\\/]+)$/) {
           }
        }
    }

    print "($path, $fmatch)\n", if ($ctrl->{'debug'} >= 2);

    # try to open as a directory
    if (!opendir (DIR, $path)) {

        # 2) If the path is not a directory:

        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
        print $sock "Not expecting a file: $path<hr>\n";
        print $sock "<a href=\"/search.htm?/./\">/./</a><br>\n";
    } else {
        #.dir
        # yes, it is a directory, read files in the directory
        
        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
        print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a><br>\n";
        print $sock "Path: <a href=\"/ls.htm?path=$path\">$path</a> \n";
        print $sock "<a href=\"#end\">Jump to end</a><hr>\n";

        closedir (DIR);

    }

    if (length($condition) > 0) {
        &l00http_search_search ($ctrl, $form, $path);
    }

    # 4) If not in raw mode, also display a control table

    print $sock "<hr><a name=\"end\"></a>\n";

    print $sock "<form action=\"/search.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"1\" cellspacing=\"1\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td>Settings</td>\n";
    print $sock "        <td>Descriptions</td>\n";
    print $sock "    </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Full filename (regex):</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"fmatch\" value=\"$fmatch\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Conditions (regex):</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"condition\" value=\"$condition\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Contents (regex):</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"content\" value=\"$content\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Sorts (2|||-1):</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"sort\" value=\"$sort\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Max. lines:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"maxlines\" value=\"$maxlines\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td><input type=\"checkbox\" name=\"recursive\" $recursive>Recursive</td>\n";
    print $sock "            <td>into sub-directories</td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    if ($linemode) {
        print $sock "            <td><input type=\"checkbox\" name=\"linemode\" checked>Line mode</td>\n";
    } else {
        print $sock "            <td><input type=\"checkbox\" name=\"linemode\">Line mode</td>\n";
    }
    print $sock "            <td>Overwrites 'Line marker'</td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Line marker:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"linemark\" value=\"$linemark\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Submit\"></td>\n";
    print $sock "        <td><input type=\"text\" size=\"16\" name=\"path\" value=\"$path\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td><input type=\"checkbox\" name=\"tableout\" $tableout>Tabulate</td>\n";
    print $sock "            <td><input type=\"checkbox\" name=\"pretext\" $pretext>Preformatted text</td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td><input type=\"checkbox\" name=\"saveresults\">Save <a href=\"/ls.htm?path=l00://search.pl\">results</a></td>\n";
#   print $sock "            <td><input type=\"text\" size=\"16\" name=\"savepath\" value=\"$path"."TmpSearchResults.txt\"></td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"savepath\" value=\"l00://search.pl\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Send file to:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"sendto\" value=\"$sendto\"></td>\n";
    print $sock "        </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "<p>\n";

print $sock <<eop
Block is defined by 'record delimiter'.<br>
'Conditions' is separated by |||<br>
All 'Conditions' are searched within the 'Block'<br>
If 'Conditions' is met, 'Contents' are evaluated and tabulated; each 'Contents' separated by ||| is a column<br>
The table is sorted by multiple columns as specified by 'Sorts'<br>
eop
;


    print $sock $ctrl->{'htmlfoot'};

}


\%config;
