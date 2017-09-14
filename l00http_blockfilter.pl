#use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_blockfilter_proc",
              desc => "l00http_blockfilter_desc");
my (@skipto, @scanto, @fileexclude, @blkstart, @blkstop, 
    @blkrequired, @color, @eval, @blockend, @preeval, @stats, $inverexclu);

$inverexclu = '';

#  &l00http_blockfilter_paste($form, 'skipto', \@skipto);
sub l00http_blockfilter_paste {
    my ($ctrl, $form, $name, $array) = @_;
    my ($condition);

    if (defined ($form->{"${name}paste"})) {
        undef @$array;
        foreach $condition (split("\n", &l00httpd::l00getCB($ctrl))) {
            $condition =~ s/\n//g;
            $condition =~ s/\r//g;
            if (length($condition) > 0) {
                push(@$array, $condition);
            }
        }
    }

    if (defined ($form->{$name})) {
        undef @$array;
        foreach $condition (split("\n", $form->{$name})) {
            $condition =~ s/\n//g;
            $condition =~ s/\r//g;
            if (length($condition) > 0) {
                push(@$array, $condition);
            }
        }
    }

}

sub l00http_blockfilter_form {
    my ($sock, $form, $name, $label, $array) = @_;
    my ($tmp);

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"${name}paste\" value=\"$label\">\n";
    print $sock "pattern (1 per line)\n";
    print $sock "</td><td>\n";
    $tmp = join("\n", @$array);
    print $sock "<textarea name=\"${name}\" cols=24 rows=2>$tmp</textarea>\n";
    print $sock "</td></tr>\n";

}

sub l00http_blockfilter_print {
    my ($sock, $form, $name, $label, $array) = @_;
    my ($tmp);

    print $sock "<tr>\n";
    print $sock "  <td>$label:</td>\n";
    print $sock "  <td>\n<pre>";
    if (!defined($$array[0])) {
        $tmp = ' ';
    } else {
        $tmp = join("\n", @$array);
    }
    print $sock "$tmp</pre>";
    print $sock "  </td>\n";
    print $sock "</tr>\n";

}

sub l00http_blockfilter_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "blockfilter: A block display filter";
}

sub l00http_blockfilter_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($cnt, $output, $thisblocklink, $thisblockbare, $condition, $ending, $requiredfound);
    my ($blkdisplayed, $blockendhits, $hitlines, $tmp, $skip0scan1, $outputed, $link, $bare);
    my ($inblk, $blkstartfound, $blkendfound, $found, $header, $noblkfound, $reqfound, $pname, $fname);
    my ($viewskip, $fg, $bg, $regex, $eofoutput, $statsidx);


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>Block filter</title>" .$ctrl->{'htmlhead2'};
    print $sock "<a name=\"__top__\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"#__end__\">jump to end</a> - \n";
    print $sock "Path: <a href=\"/view.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";

    &l00http_blockfilter_paste($ctrl, $form, 'skipto',      \@skipto);
    &l00http_blockfilter_paste($ctrl, $form, 'scanto',      \@scanto);
    &l00http_blockfilter_paste($ctrl, $form, 'fileexclude', \@fileexclude);
    &l00http_blockfilter_paste($ctrl, $form, 'blkstart',    \@blkstart);
    &l00http_blockfilter_paste($ctrl, $form, 'blkstop',     \@blkstop);
    &l00http_blockfilter_paste($ctrl, $form, 'blkrequired', \@blkrequired);
    &l00http_blockfilter_paste($ctrl, $form, 'color',       \@color);
    &l00http_blockfilter_paste($ctrl, $form, 'eval',        \@eval);
    &l00http_blockfilter_paste($ctrl, $form, 'preeval',     \@preeval);
    &l00http_blockfilter_paste($ctrl, $form, 'stats',       \@stats);

    if (defined ($form->{'process'})) {
        &l00http_blockfilter_paste($ctrl, $form, 'skipto',      \@skipto);
        &l00http_blockfilter_paste($ctrl, $form, 'scanto',      \@scanto);
        &l00http_blockfilter_paste($ctrl, $form, 'fileexclude', \@fileexclude);
        &l00http_blockfilter_paste($ctrl, $form, 'blkstart',    \@blkstart);
        &l00http_blockfilter_paste($ctrl, $form, 'blkstop',     \@blkstop);
        &l00http_blockfilter_paste($ctrl, $form, 'blkrequired', \@blkrequired);
        &l00http_blockfilter_paste($ctrl, $form, 'color',       \@color);
        &l00http_blockfilter_paste($ctrl, $form, 'eval',        \@eval);
        &l00http_blockfilter_paste($ctrl, $form, 'preeval',     \@preeval);
        &l00http_blockfilter_paste($ctrl, $form, 'stats',       \@stats);
    }

    if (defined ($form->{'invert'}) && ($form->{'invert'} eq 'on')) {
        $inverexclu = 'check';
    } else {
        $inverexclu = '';
    }

    print $sock "<p><form action=\"/blockfilter.htm\" method=\"get\">\n";
    print $sock "<table border=\"3\" cellpadding=\"3\" cellspacing=\"1\">\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"process\" value=\"Process\"> target file.\n";
    print $sock "<input type=\"checkbox\" name=\"invert\" $inverexclu>Invert EXCLUDE\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"24\" name=\"path\" value=\"$form->{'path'}\"><p>\n";
    print $sock "</td></tr>\n";


    &l00http_blockfilter_form($sock, $form, 'skipto',      'Skip to',           \@skipto);
    &l00http_blockfilter_form($sock, $form, 'scanto',      'Scan to',           \@scanto);
    &l00http_blockfilter_form($sock, $form, 'fileexclude', 'Exclude Line (!!)', \@fileexclude);
    &l00http_blockfilter_form($sock, $form, 'blkstart',    'BLOCK START',       \@blkstart);
    &l00http_blockfilter_form($sock, $form, 'blkstop',     'Block End',         \@blkstop);
    &l00http_blockfilter_form($sock, $form, 'blkrequired', 'Block Required',    \@blkrequired);
    &l00http_blockfilter_form($sock, $form, 'color',       'Colorize ()',       \@color);
    &l00http_blockfilter_form($sock, $form, 'eval',        'Perl eval',         \@eval);
    &l00http_blockfilter_form($sock, $form, 'preeval',     'Pre eval',          \@preeval);
    &l00http_blockfilter_form($sock, $form, 'stats',       'Statistics',        \@stats);

    print $sock "</table><br>\n";
    print $sock "</form>\n";


    if (defined ($form->{'process'}) &&
        defined ($form->{'path'}) &&
        (&l00httpd::l00freadOpen($ctrl, $form->{'path'}))) {

        if ($form->{'path'} =~ /blockfilter/) {
            print $sock "$form->{'path'} is recognized as a blockfilter configuration file. Please select a target below to process:<p>\n";
            ($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/;
            if (opendir (DIR, $pname)) {
                print $sock "<pre>\n";
                foreach $fname (sort readdir (DIR)) {
                    if ($fname eq '.' || $fname eq '..') {
                        next;
                    }
                    print $sock "<a href=\"/view.htm?path=$pname$fname\" target=\"view\">view</a> - ";
                    print $sock "<a href=\"/blockfilter.htm?path=$pname$fname\" target=\"blockfilter\">blockfilter $fname</a>\n";
                }
                print $sock "</pre>\n";
                closedir (DIR);
            } else {
                print $sock "Failed to open '$pname' as a directory<p>\n";
            }
        }

        if (!defined($blkstart[0])) {
            print $sock "BLOCK START pattern not defined. Define at least 1 matching pattern.<p>\n";
        }
        print $sock "Processing .";
        &l00httpd::l00fwriteOpen($ctrl, 'l00://blockfilter.txt');

        $cnt = 0;
        $blkdisplayed = 0;
        $output = '';

        $thisblocklink = '';
        $thisblockbare = '';
        $hitlines = 0;
        $inblk = 0;
        $skip0scan1 = 0;    # skip to/scan to toggle
        $ending = 0;
        $header = '';
        $noblkfound = 1;
        $requiredfound = 0;
        $outputed = 1;  # meaning we haven't anything to output on starting up
        $eofoutput = 0;

        # do pre eval
        foreach $condition (@preeval) {
            eval $condition;
        }

        while (1) {
            $_ = &l00httpd::l00freadLine($ctrl);
            # end of file yet?
            if (!defined($_)) {
                # end of file
                if ($eofoutput == 0) {
                    $eofoutput = 1;
                    $_ = '';
                    $blkendfound = 1;   # simulate end found
                } else {
                    last;
                }
            }

            if ($eofoutput == 0) {
                # processing while not eof
                s/\r//;
                s/\n//;
                $cnt++;
                if (($cnt % 1000) == 0) {
                    print $sock ".";
                }

                # skipto or scanto
                if ($skip0scan1 == 0) {
                    # skip to mode
                    if (!defined($skipto[0])) {
                        # skip to regex not defined, make it always a hit
                        $skip0scan1 = 1;
                    } else {
                        foreach $condition (@skipto) {
                            if (/$condition/i) {
                                # found skip to, now do scan to
                                $skip0scan1 = 1;
                                last;
                            }
                        }
                    }
                    if ($skip0scan1 == 0) {
                        # skip all lines up to first skipto hit
                        next;
                    }
                } else {
                    # scan to mode
                    foreach $condition (@scanto) {
                        if (/$condition/i) {
                            # found scan to, now do skip to
                            $skip0scan1 = 0;
                            last;
                        }
                    }
                }

                # exclude (!! to include only) lines


                $bare = $_;
                # do eval
                foreach $condition (@eval) {
                    eval $condition;
                }
                $link = $_;
                $_ = $bare;

                # colorize
                foreach $condition (@color) {
                    if (($fg, $bg, $regex) = $condition =~ /^!!([a-z]+?)!!([a-z]+?)!!(.+)/) {
                        $link =~ s/($regex)/<font style="color:$fg;background-color:$bg">$1<\/font>/i;
                    } else {
                        $link =~ s/($condition)/<font style="color:black;background-color:lime">$1<\/font>/i;
                    }
                }


                $blkendfound = 0;
                $blkstartfound = 0;

                # search for block start
                foreach $condition (@blkstart) {
                    if (/$condition/i) {
                        # found
                        $inblk = 1;     # flag we are inside a found block
                        $blkstartfound = 1;
                        $blkendfound = 1;   # when non end provided
                        last;
                    }
                }
                if ($inblk != 0) {
                    # search for block end
                    foreach $condition (@blkstop) {
                        if (/$condition/i) {
                            # found
                            $inblk = 0;
                            $blkendfound = 1;
                            last;
                        }
                    }
                    # search for required
                    if (!defined($blkrequired[0])) {
                        # no regex defined, always hit required
                        $requiredfound = 1;
                    } else {
                        foreach $condition (@blkrequired) {
                            if (/$condition/i) {
                                # found
                                $requiredfound = 1;
                                last;
                            }
                        }
                    }
                }
            }

            if ($blkendfound && ($outputed == 0)) {
                # found end of block
                if ($requiredfound) {
                    $thisblockbare .= "$bare\n";
                    &l00httpd::l00fwriteBuf($ctrl, "$thisblockbare");

                    $viewskip = $cnt - 10;
                    if ($viewskip < 0) {
                        $viewskip = 0;
                    }
                    $hitlines++;
                    $thisblocklink .= sprintf ("<a href=\"/view.htm?update=Skip&skip=%d&maxln=100&path=%s&hiliteln=%d&refresh=\" target=\"newblkfltwin\">%05d</a>: %s\n", $viewskip, $form->{'path'}, $cnt, $cnt, $link); 

                    $header .= "<a href=\"#blk$noblkfound\">$noblkfound</a> ";
                    $noblkfound++;
                    $output .= $thisblocklink;
                }
                $outputed = 1;
            }

            if ($blkstartfound) {
                $outputed = 0;
                $requiredfound = 0;

                $hitlines++;

                $thisblockbare  = "\nBlock $noblkfound:\n\n";
                $thisblocklink  = "<a name=\"blk$noblkfound\"></a>\n";
                $thisblocklink .= "Block $noblkfound. Jump to: ";
                $thisblocklink .= "<a href=\"#__top__\">top</a> - ";
                $thisblocklink .= "<a href=\"#__toc__\">toc</a> - ";
                $thisblocklink .= "<a href=\"#__end__\">end</a> -- ";
                $tmp = $noblkfound - 1;
                $thisblocklink .= "<a href=\"#blk$tmp\">last</a> - ";
                $tmp = $noblkfound + 1;
                $thisblocklink .= "<a href=\"#blk$tmp\">next</a> \n";
                $thisblocklink .= "\n";

                $viewskip = $cnt - 10;
                if ($viewskip < 0) {
                    $viewskip = 0;
                }
                $thisblocklink .= sprintf ("<font style=\"color:black;background-color:silver\"><a href=\"/view.htm?update=Skip&skip=%d&maxln=100&path=%s&hiliteln=%d&refresh=\" target=\"newblkfltwin\">%05d</a>: %s</font>\n", $viewskip, $form->{'path'}, $cnt, $cnt, $link); 
            } elsif ($inblk) {
                # exclude (!! to include only) lines
                $found = 0;
                foreach $condition (@fileexclude) {
                    if (substr($condition, 0, 2) eq '!!') {
                        $tmp = $condition;
                        substr($tmp, 0, 2) = '';
                        if (!/$tmp/i) {
                            # not found, exclude
                            $found = 1;
                            last;
                        }
                    } else {
                        if (/$condition/i) {
                            # found, exclude
                            $found = 1;
                            last;
                        }
                    }
                }
                if ($inverexclu eq '') {
                    if ($found) {
                        # file exclude line
                        next;
                    }
                } else {
                    # invert sense of exclude
                    if (!$found) {
                        # file exclude line
                        next;
                    }
                }

                # not excluded
                $thisblockbare .= "$bare\n";

                # gather stats
                $statsidx = 0;
                foreach $condition (@stats) {
                    ($tmp) = eval $condition;
                    if (defined($tmp)) {
print "hitlines $hitlines statsidx $statsidx tmp $tmp\n";
                        $statsidx++;
                    } else {
print "hitlines $hitlines NO HIT\n";
                    }
                }

                $viewskip = $cnt - 10;
                if ($viewskip < 0) {
                    $viewskip = 0;
                }
                $hitlines++;
                $thisblocklink .= sprintf ("<a href=\"/view.htm?update=Skip&skip=%d&maxln=100&path=%s&hiliteln=%d&refresh=\" target=\"newblkfltwin\">%05d</a>: %s\n", $viewskip, $form->{'path'}, $cnt, $cnt, $link); 
            }
        }


        &l00httpd::l00fwriteClose($ctrl);
        print $sock " Processed $cnt lines. ".
            "Output $blkdisplayed blocks and $hitlines lines to ".
            "<a href=\"/view.htm?path=l00://blockfilter.txt\" target=\"newram\">l00://blockfilter.txt</a> ".
            "<p>\n";
        print $sock "<a name=\"__toc__\"></a>$header<br>\n";
        print $sock "<pre>$output</pre>\n";
        print $sock "<a name=\"__end__\"></a>\n";
        print $sock "<a href=\"#__top__\">jump to top</a><p>\n";

        print $sock "List of all parameters:<p>\n";
        print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
        &l00http_blockfilter_print($sock, $form, 'skipto',      'Skip to',           \@skipto);
        &l00http_blockfilter_print($sock, $form, 'scanto',      'Scan to',           \@scanto);
        &l00http_blockfilter_print($sock, $form, 'fileexclude', 'Exclude Line (!!)', \@fileexclude);
        &l00http_blockfilter_print($sock, $form, 'blkstart',    'BLOCK START',       \@blkstart);
        &l00http_blockfilter_print($sock, $form, 'blkstop',     'Block End',         \@blkstop);
        &l00http_blockfilter_print($sock, $form, 'blkrequired', 'Block Required',    \@blkrequired);
        &l00http_blockfilter_print($sock, $form, 'color',       'Colorize ()',       \@color);
        &l00http_blockfilter_print($sock, $form, 'eval',        'Perl eval',         \@eval);
        &l00http_blockfilter_print($sock, $form, 'preeval',     'Pre eval',          \@preeval);
        &l00http_blockfilter_print($sock, $form, 'stats',       'Statistics',        \@stats);
        print $sock "</table>\n";
    } else {
        if (defined ($form->{'process'})) {
            print $sock "Unable to process $form->{'path'}<br>\n";
        } else {
            print $sock "Click 'Process' to process $form->{'path'}<br>\n";
        }
    }

    print $sock $ctrl->{'htmlfoot'};
}


\%config;
