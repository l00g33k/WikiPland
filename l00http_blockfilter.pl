#iuse strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_blockfilter_proc",
              desc => "l00http_blockfilter_desc");
my (@skipto, @scanuntil, @fileexclude, @blkstart, @blkstop, 
    @blkrequired, @blkexclude, @color, @eval, @blockend, @preeval, @stats,
    @preblkeval, @postblkeval, @colors);
my ($inverexclu, $blockfiltercfg, $reloadcfg, $maxlines, $maxblklines, @hide, 
    $statsidx, $smallform, $wikitize);

$inverexclu = '';
$reloadcfg = '';
$blockfiltercfg = '';
$maxlines = 1000;
$maxblklines = 200;
$statsidx = 0;
$smallform = '';
$wikitize = '';
@colors = (
    'lime', 
    'aqua', 
    'yellow', 
    'green', 
    'fuchsia',
    'hotPink',
    'gold',
    'deepskyblue',
    'sandbybrown',
    'silver',
    'olive'
);

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
    my ($sock, $form, $name, $label, $array, $accesskey) = @_;
    my ($tmp, $accessattr, $accessmsg);

    if (defined($accesskey)) {
        $accessmsg = " $accesskey&#818;";
        $accessattr = "accesskey=\"$accesskey\"";
    } else {
        $accessmsg = '';
        $accessattr = '';
    }


    if ($smallform eq '') {
        print $sock "<tr><td>\n";
        print $sock "<input type=\"submit\" name=\"${name}paste\" value=\"$label\">\n";
        print $sock "pattern (1 per line)$accessmsg\n";
        print $sock "</td><td>\n";
        $tmp = join("\n", @$array);
        print $sock "<textarea name=\"${name}\" cols=24 rows=2 $accessattr>$tmp</textarea>\n";
        print $sock "</td></tr>\n";
    } else {
        print $sock "<input type=\"hidden\" name=\"${name}paste\" value=\"$label\">\n";
        $tmp = join("\n", @$array);
# this seems wrong, todo?
        print $sock "<input type=\"hidden\" name=\"${name}\" value=\"$tmp\">\n";
    }
}

sub l00http_blockfilter_print {
    my ($name, $array) = @_;
    my ($output);

    $output = '';
    $output .= "::::${name}::::\n";
    if (defined($$array[0])) {
        $output .= join("\n", @$array);
    }
    $output .= "\n\n";

    $output;
}

sub l00http_blockfilter_parse {
    my ($name, $blob, $array) = @_;
    my ($condition, $parsenow);

    $parsenow = 0;
    foreach $_ (split("\n", $blob)) {
        s/\n//g;
        s/\r//g;
        if (/^::::${name}::::$/) {
            undef @$array;
            $parsenow = 1;
        } elsif ($parsenow) {
            if (/^$/) {
                $parsenow = 0;
            } else {
                push(@$array, $_);
            }
        }

    }
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
    my ($cnt, $output, $outram, $thisblockram, $thisblockdsp, $condition, $ending, $requiredfound, $requiredfound_currln, $blkexclufound);
    my ($blockendhits, $hitlines, $tmp, $evalName, $evalVals, $skip0scan1done2, $outputed, $link, $original);
    my ($inblk, $blkstartfound, $blkendfound, $found, $header, $noblkfound, $reqfound, $pname, $fname);
    my ($viewskip, $fg, $bg, $regex, $eofoutput, $statsout, $statsoutcnt, $lnno, $tmp2, $ii);
    my ($cntsum, $valsum, $blockfilterstatfmt, $noblkstartOneTime, $stopreadingfile, $hitlinesoutputed);


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>Block filter</title>" .$ctrl->{'htmlhead2'};
    print $sock "<a name=\"__top__\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"#__end__\">jump to end</a> - \n";
    if (defined($form->{'path'})) {
        ($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/;
        print $sock "Path: <a href=\"/ls.htm?path=$pname\">$pname</a>";
        print $sock "<a href=\"/view.htm?path=$form->{'path'}\" target=\"_blank\">$fname</a><p>\n";
    }
    print $sock "<p>\n";



    &l00http_blockfilter_paste($ctrl, $form, 'skipto',      \@skipto);
    &l00http_blockfilter_paste($ctrl, $form, 'scanuntil',   \@scanuntil);
    &l00http_blockfilter_paste($ctrl, $form, 'fileexclude', \@fileexclude);
    &l00http_blockfilter_paste($ctrl, $form, 'blkstart',    \@blkstart);
    &l00http_blockfilter_paste($ctrl, $form, 'blkstop',     \@blkstop);
    &l00http_blockfilter_paste($ctrl, $form, 'blkrequired', \@blkrequired);
    &l00http_blockfilter_paste($ctrl, $form, 'blkexclude',  \@blkexclude);
    &l00http_blockfilter_paste($ctrl, $form, 'color',       \@color);
    &l00http_blockfilter_paste($ctrl, $form, 'eval',        \@eval);
    &l00http_blockfilter_paste($ctrl, $form, 'preeval',     \@preeval);
    &l00http_blockfilter_paste($ctrl, $form, 'preblkeval',  \@preblkeval);
    &l00http_blockfilter_paste($ctrl, $form, 'postblkeval', \@postblkeval);
    &l00http_blockfilter_paste($ctrl, $form, 'stats',       \@stats);
    &l00http_blockfilter_paste($ctrl, $form, 'hide',        \@hide);


    if (defined ($form->{'process'})) {
        &l00http_blockfilter_paste($ctrl, $form, 'skipto',      \@skipto);
        &l00http_blockfilter_paste($ctrl, $form, 'scanuntil',   \@scanuntil);
        &l00http_blockfilter_paste($ctrl, $form, 'fileexclude', \@fileexclude);
        &l00http_blockfilter_paste($ctrl, $form, 'blkstart',    \@blkstart);
        &l00http_blockfilter_paste($ctrl, $form, 'blkstop',     \@blkstop);
        &l00http_blockfilter_paste($ctrl, $form, 'blkrequired', \@blkrequired);
        &l00http_blockfilter_paste($ctrl, $form, 'blkexclude',  \@blkexclude);
        &l00http_blockfilter_paste($ctrl, $form, 'color',       \@color);
        &l00http_blockfilter_paste($ctrl, $form, 'eval',        \@eval);
        &l00http_blockfilter_paste($ctrl, $form, 'preeval',     \@preeval);
        &l00http_blockfilter_paste($ctrl, $form, 'preblkeval',  \@preblkeval);
        &l00http_blockfilter_paste($ctrl, $form, 'postblkeval', \@postblkeval);
        &l00http_blockfilter_paste($ctrl, $form, 'stats',       \@stats);
        &l00http_blockfilter_paste($ctrl, $form, 'hide',        \@hide);

        if ((defined ($form->{'maxlines'})) && ($form->{'maxlines'} =~ /(\d+)/)) {
            $maxlines = $1;
        }
        if (defined ($form->{'maxblklines'})) {
            if ($form->{'maxblklines'} =~ /(\d+)/) {
                # specified
                $maxblklines = $1;
            } else {
                # no, set to 0
                $maxblklines = 0;
            }
        }
    }

    if (!defined($skipto[0])) {
        # skip to regex not defined, make it always a hit
        $skipto[0] = '.';
    }
    if (!defined($blkrequired[0])) {
        # block required regex not defined, make it always a hit
        $blkrequired[0] = '.';
    }


    if (defined ($form->{'reset'})) {
        @skipto = ();
        @scanuntil = ();
        @fileexclude = ();
        @blkstart = ();
        @blkstop = ();
        @blkrequired = ();
        @blkexclude = ();
        @color = ();
        @eval = ();
        @preeval = ();
        @preblkeval = ();
        @postblkeval = ();
        @stats = ();
        @hide = ();
    }

    if (defined ($form->{'process'}) &&
        defined ($form->{'path'})) {
        if (defined($form->{'cfg'}) && (-f $form->{'cfg'})) {
            # may be overwritten by the next clause
            $blockfiltercfg = $form->{'cfg'};
        }
        if ($form->{'path'} =~ /blockfilter/) {
            $blockfiltercfg = $form->{'path'};
            undef $form->{'process'};   # prevent processing config file

            if (&l00httpd::l00freadOpen($ctrl, $blockfiltercfg)) {
                $tmp = &l00httpd::l00freadAll($ctrl);

                &l00http_blockfilter_parse('skipto',      $tmp, \@skipto);
                &l00http_blockfilter_parse('scanuntil',   $tmp, \@scanuntil);
                &l00http_blockfilter_parse('fileexclude', $tmp, \@fileexclude);
                &l00http_blockfilter_parse('blkstart',    $tmp, \@blkstart);
                &l00http_blockfilter_parse('blkstop',     $tmp, \@blkstop);
                &l00http_blockfilter_parse('blkrequired', $tmp, \@blkrequired);
                &l00http_blockfilter_parse('blkexclude',  $tmp, \@blkexclude);
                &l00http_blockfilter_parse('color',       $tmp, \@color);
                &l00http_blockfilter_parse('eval',        $tmp, \@eval);
                &l00http_blockfilter_parse('preeval',     $tmp, \@preeval);
                &l00http_blockfilter_parse('preblkeval',  $tmp, \@preblkeval);
                &l00http_blockfilter_parse('postblkeval', $tmp, \@postblkeval);
                &l00http_blockfilter_parse('stats',       $tmp, \@stats);
                &l00http_blockfilter_parse('hide',        $tmp, \@hide);
            }

            # print target file list
            print $sock "$form->{'path'} is recognized as a blockfilter configuration file. Please select a target below to process:<p>\n";
            ($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/;
            if (opendir (DIR, $pname)) {
                print $sock "<pre>\n";
                foreach $fname (sort readdir (DIR)) {
                    if ($fname eq '.' || $fname eq '..') {
                        next;
                    }
                    print $sock "<a href=\"/view.htm?path=$pname$fname\" target=\"_blank\">view</a> - ";
                    print $sock "blockfilter: <a href=\"/blockfilter.htm?path=$pname$fname\" target=\"_blank\">$fname</a>\n";
                }
                print $sock "</pre>\n";
                closedir (DIR);
            } else {
                print $sock "Failed to open '$pname' as a directory<p>\n";
            }
        } elsif ($reloadcfg ne '') {
            if (&l00httpd::l00freadOpen($ctrl, $blockfiltercfg)) {
                $tmp = &l00httpd::l00freadAll($ctrl);

                &l00http_blockfilter_parse('skipto',      $tmp, \@skipto);
                &l00http_blockfilter_parse('scanuntil',   $tmp, \@scanuntil);
                &l00http_blockfilter_parse('fileexclude', $tmp, \@fileexclude);
                &l00http_blockfilter_parse('blkstart',    $tmp, \@blkstart);
                &l00http_blockfilter_parse('blkstop',     $tmp, \@blkstop);
                &l00http_blockfilter_parse('blkrequired', $tmp, \@blkrequired);
                &l00http_blockfilter_parse('blkexclude',  $tmp, \@blkexclude);
                &l00http_blockfilter_parse('color',       $tmp, \@color);
                &l00http_blockfilter_parse('eval',        $tmp, \@eval);
                &l00http_blockfilter_parse('preeval',     $tmp, \@preeval);
                &l00http_blockfilter_parse('preblkeval',  $tmp, \@preblkeval);
                &l00http_blockfilter_parse('postblkeval', $tmp, \@postblkeval);
                &l00http_blockfilter_parse('stats',       $tmp, \@stats);
                &l00http_blockfilter_parse('hide',        $tmp, \@hide);
            }
        }

        if (defined ($form->{'invert'}) && ($form->{'invert'} eq 'on')) {
            $inverexclu = 'checked';
        } else {
            $inverexclu = '';
        }

        if (defined ($form->{'reloadcfg'}) && ($form->{'reloadcfg'} eq 'on')) {
            $reloadcfg = 'checked';
        } else {
            $reloadcfg = '';
        }

        if (defined ($form->{'smallform'}) && ($form->{'smallform'} eq 'on')) {
            $smallform = 'checked';
        } else {
            $smallform = '';
        }

        if (defined ($form->{'wikitize'}) && ($form->{'wikitize'} eq 'on')) {
            $wikitize = 'checked';
        } else {
            $wikitize = '';
        }
    } elsif (defined ($form->{'path'})) {
        print $sock "Click 'Process' to process $form->{'path'}<br>\n";
    }


    print $sock "<p><form action=\"/blockfilter.htm\" method=\"get\">\n";
    print $sock "<table border=\"3\" cellpadding=\"3\" cellspacing=\"1\">\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"process\" value=\"P&#818;rocess\" accesskey=\"p\"> target file.\n";
    print $sock "<input type=\"checkbox\" name=\"invert\" $inverexclu>Invert EXCLUDE\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"24\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "</td></tr>\n";

    if ($blockfiltercfg ne '') {
        print $sock "<tr><td>\n";
        print $sock "<input type=\"checkbox\" name=\"reloadcfg\" $reloadcfg>Reload cfg before processing\n";
        if ($reloadcfg ne '') {
            # also save config in hidden field
            print $sock "<input type=\"hidden\" name=\"cfg\" value=\"$blockfiltercfg\">\n";
        }
        print $sock "</td><td>\n";
        ($pname, $fname) = $blockfiltercfg =~ /^(.+\/)([^\/]+)$/;
        print $sock "<a href=\"/view.htm?path=$pname$fname\" target=\"_blank\">$fname</a>\n";
        print $sock "</td></tr>\n";
    }

    &l00http_blockfilter_form($sock, $form, 'skipto',      'Skip to',           \@skipto);
    &l00http_blockfilter_form($sock, $form, 'scanuntil',   'Scan until',        \@scanuntil);
    &l00http_blockfilter_form($sock, $form, 'fileexclude', 'Exclude Line (!!)', \@fileexclude);
    &l00http_blockfilter_form($sock, $form, 'blkstart',    'Block Start',       \@blkstart,     's');
    &l00http_blockfilter_form($sock, $form, 'blkstop',     'Block End',         \@blkstop,      'e');
    &l00http_blockfilter_form($sock, $form, 'blkrequired', 'Block Required',    \@blkrequired,  'r');
    &l00http_blockfilter_form($sock, $form, 'blkexclude',  'Block Exclude (!!)',\@blkexclude);
    &l00http_blockfilter_form($sock, $form, 'color',       'Colorize ()',       \@color,        'c');
    &l00http_blockfilter_form($sock, $form, 'eval',        'Perl eval',         \@eval);
    &l00http_blockfilter_form($sock, $form, 'preeval',     'Pre eval',          \@preeval);
    &l00http_blockfilter_form($sock, $form, 'preblkeval',  'Pre blk eval',      \@preblkeval);
    &l00http_blockfilter_form($sock, $form, 'postblkeval', 'Post blk eval',     \@postblkeval);
    &l00http_blockfilter_form($sock, $form, 'stats',       'Statistics',        \@stats);
    &l00http_blockfilter_form($sock, $form, 'hide',        'Hide line (!!)',    \@hide);

    if ($smallform eq '') {
        print $sock "<tr><td>\n";
        print $sock "Maximum lines per block display:\n";
        print $sock "</td><td>\n";
        print $sock "<input type=\"text\" size=\"8\" name=\"maxblklines\" value=\"$maxblklines\"> \n";
        print $sock "</td></tr>\n";

        print $sock "<tr><td>\n";
        print $sock "Maximum lines to display:\n";
        print $sock "</td><td>\n";
        print $sock "<input type=\"text\" size=\"8\" name=\"maxlines\" value=\"$maxlines\"> \n";
        print $sock "<input type=\"submit\" name=\"reset\" value=\"Reset\">\n";
        print $sock "</td></tr>\n";
    } else {
        print $sock "<input type=\"hidden\" size=\"8\" name=\"maxblklines\" value=\"$maxblklines\"> \n";
        print $sock "<input type=\"hidden\" size=\"8\" name=\"maxlines\" value=\"$maxlines\"> \n";
    }

    print $sock "<tr><td>\n";
    print $sock "<input type=\"checkbox\" name=\"smallform\" $smallform accesskey=\"m\">Sm&#818;all form\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"checkbox\" name=\"wikitize\" $wikitize accesskey=\"w\">W&#818;ikitize\n";
    print $sock "</td></tr>\n";



    print $sock "</table><br>\n";
    print $sock "</form>\n";


    if (defined ($form->{'process'}) &&
        defined ($form->{'path'}) &&
        (&l00httpd::l00freadOpen($ctrl, $form->{'path'}))) {

        if ($smallform eq '') {
            print $sock "Processing .";
        }
        &l00httpd::l00fwriteOpen($ctrl, 'l00://blockfilter_output.txt');

        $cnt = 0;
        $output = '';
        $outram = '';

        $thisblockram = '';
        $thisblockdsp = '';
        $hitlines = 0;
        $inblk = 0;
        $skip0scan1done2 = 0;    # skip to/scan to toggle
        $ending = 0;
        $header = 'Block: ';
        $noblkfound = 0;
        $requiredfound = 0;
        $blkexclufound = 0;
        $outputed = 1;  # meaning we haven't anything to output on starting up
        $eofoutput = 0;
        $lnno = 0;
        $noblkstartOneTime = 1;
        $stopreadingfile = 0;
        $hitlinesoutputed = 0;

        # zero statistics
        for ($tmp = 0; $tmp <= $#stats; $tmp++) {
            foreach $condition (sort keys %{$statsout[$tmp]}) {
                $statsout   [$tmp]->{$condition} = undef;
                $statsoutcnt[$tmp]->{$condition} = undef;
            }
        }


        $blockfilterstatfmt = '%10.4g';
        # do pre eval
        foreach $condition (@preeval) {
            eval $condition;
        }

        ## Theory of operation
        # 
        # There will always be block start search hit
        # There may or may not be a block end search hit. Where there 
        #   is no expression, or no hit, the next block start search hit 
        #   serves as block end hit
        # Block start and block end are included in the required search, 
        #   except when the next block start hit serves as the last block end hit,
        #   then block end won't be included in the required search and display
        # 
            ## read a new line
            ## process new line if we are not passed end of file
                ## line exclusion (may exclude block start)
                ## processing skipto or scanuntil
                ## do eval's on all remaining lines in this block
                ## colorize
                ## search for block start
                ## in block processing: block end search, required/exclude, output
                    ## in block: search for block end
                    ## in block: search for required
                    ## in block: search for block exclusion
                    ## in block: gather stats
                    ## in block: hide line
                    ## in block: output
            ## if we have found a new block, output last result
            ## if we have found a new block, prepare for the new block
            ## end of processing
        ## end of theory of operation

        while (1) {
            $blkendfound = 0;
            $requiredfound_currln = 0;

            ## read a new line

            $_ = &l00httpd::l00freadLine($ctrl);
            $lnno++;    # count line number
            # end of file yet?
            if ((!defined($_)) || $stopreadingfile) {
                # end of file
                if ($eofoutput == 0) {
                    $eofoutput = 1;
                    $_ = '';
                    $inblk = 1;     # flag we are inside a found block
                    $blkendfound = 1;   # simulate end found
                } else {
                    last;
                }
            }

            ## process new line if we are not passed end of file

            #   skip to/scan until search
            #   colorize
            #   search for block start/end/required
            if ($eofoutput == 0) {
                # processing while not eof
                s/\r//;
                s/\n//;
                $cnt++;
                if ((($cnt % 1000) == 0) && ($smallform eq '')) {
                    print $sock " .";   # progress indicator
                }

                ## line exclusion (may exclude block start)

                # exclude (!! to include only) lines
                $found = 0;
                foreach $condition (@fileexclude) {
                    if ($condition =~ /^!!/) {
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

                ## processing skipto or scanuntil

                if ($skip0scan1done2 == 0) {
                    # skip to mode
                    if (($#skipto == 0) && 
                        ($skipto[0] =~ /^(\d+)$/)) {
                        # only one condition and it is a number, take it as a line number
                        if ($1 == $lnno) {
                            # found skip to, now do scan until
                            $skip0scan1done2 = 1;
                        }
                    } else {
                        foreach $condition (@skipto) {
                            if (/$condition/i) {
                                # found skip to, now do scan until
                                $skip0scan1done2 = 1;
                                last;
                            }
                        }
                    }
                    if ($skip0scan1done2 == 0) {
                        # skip all lines up to first skipto hit
                        next;
                    }
                } else {
                    # scan until mode
                    if (($#scanuntil == 0) && 
                        ($scanuntil[0] =~ /^(\d+)$/)) {
                        # only one condition and it is a number, take it as a line number
                        if ($1 == $lnno) {
                            # found scan to, now do skip to
                            $skip0scan1done2 = 2;
                        }
                    } else {
                        foreach $condition (@scanuntil) {
                            if (/$condition/i) {
                                # found scan to, now do skip to
                                $skip0scan1done2 = 2;
                                last;
                            }
                        }
                    }
                    if ($skip0scan1done2 == 2) {
                        $stopreadingfile = 1;
                        next;
                    }
                }

                ## do eval's on all remaining lines in this block

                $original = $_;
                # do eval
                foreach $condition (@eval) {
                    eval $condition;
                }
                $link = $_;
                $link =~ s/</&lt;/g;
                $link =~ s/>/&gt;/g;
                $_ = $original;


                ## colorize

                for ($ii = 0; $ii <= $#color; $ii++) {
                    $condition = $color[$ii];
                    if (($fg, $bg, $regex) = $condition =~ /^!!([a-z]+?)!!([a-z]+?)!!(.+)/) {
                        if ($link =~ s/($regex)/<font style="color:$fg;background-color:$bg">$1<\/font>/i) {
                            last; # stops at first hit
                        }
                    } elsif (($bg, $regex) = $condition =~ /^!!([a-z]+?)!!(.+)/) {
                        if ($link =~ s/($regex)/<font style="color:black;background-color:$bg">$1<\/font>/i) {
                            last; # stops at first hit
                        }
                    } else {
                        if ($ii <= $#colors) {
                            $tmp = $colors[$ii];
                        } else {
                            $tmp = $colors[$#colors];
                        }
                        if ($link =~ s/($condition)/<font style="color:black;background-color:$tmp">$1<\/font>/i) {
                            last; # stops at first hit
                        }
                    }
                }


                ## search for block start

                # There are 2 cases:
                # 1) START, ... EN, ..., START, ... EN, ...
                # 2) START, ... START, ...

                $blkstartfound = 0;

                if (($#blkstart < 0) && $noblkstartOneTime) {
                    # blkstart condition not defined, simulate hitting at the start once
                    $noblkstartOneTime = 0;
                    $inblk = 1;     # flag we are inside a found block
                    $blkstartfound = 1;
                } elsif (($#blkstart == 0) && 
                    ($blkstart[0] =~ /^(\d+)$/)) {
                    # only one condition and it is a number, take it as a line number
                    if ($1 == $lnno) {
                        $inblk = 1;     # flag we are inside a found block
                        $blkstartfound = 1;
                    }
                } else {
                    # regex search
                    foreach $condition (@blkstart) {
                        if (/$condition/i) {
                            # found
                            $inblk = 1;     # flag we are inside a found block
                            $blkstartfound = 1;
                            last;
                        }
                    }
                }

                ## in block processing: block end search, required/exclude, output

                if ($inblk != 0) {

                    ## in block: search for block end

                    # search for block end but not on the starting line
                    if ($blkstartfound == 0) {
                        if (($#blkstop == 0) && 
                            ($blkstop[0] =~ /^(\d+)$/)) {
                            # only one condition and it is a number, take it as a line number
                            if ($1 == $lnno) {
                                # found
                                $inblk = 0;
                                $blkendfound = 1;
                            }
                        } else {
                            foreach $condition (@blkstop) {
                                if (/$condition/i) {
                                    # found
                                    $inblk = 0;
                                    $blkendfound = 1;
                                    last;
                                }
                            }
                        }
                    }


                    ## if we have found a new block, or current end of block, output last result

                    if (($blkendfound || $blkstartfound)
                        && ($outputed == 0)) {
                        if (($requiredfound) && ($blkexclufound == 0)) {
                            # found end of block
                            # do post blk eval
                            foreach $condition (@postblkeval) {
                                eval $condition;
                            }

                            $viewskip = $cnt - 10;
                            if ($viewskip < 0) {
                                $viewskip = 0;
                            }
                            $hitlines++;

                            $header .= "<a href=\"#blk$noblkfound\">$noblkfound</a> ";
                            $noblkfound++;
                            if ($wikitize eq '') {
                                $output .= $thisblockdsp;
                                $outram .= $thisblockram;
                            } else {
                                $output .= "</pre>";
                                $output .= &l00wikihtml::wikihtml ($ctrl, '', $thisblockdsp, 0);
                                $output .= "<pre>";
                                $outram .= "</pre>";
                                $outram .= &l00wikihtml::wikihtml ($ctrl, '', $thisblockram, 0);;
                                $outram .= "<pre>";
                            }

                            # displayed line accounting
                            if (($maxblklines == 0) || ($hitlines < $maxblklines)) {
                                # if block length is unlimited or greater than displayed
                                $hitlinesoutputed += $hitlines;
                            } else {
                                # if only partial block was displayed
                                $hitlinesoutputed += $maxblklines;
                            }
                            $hitlines = 0;
                        }

                        $outputed = 1;
                    }


                    ## in block: search for required

                    foreach $condition (@blkrequired) {
                        if (/$condition/i) {
                            # found
                            $requiredfound = 1;
                            $requiredfound_currln = 1;
                            last;
                        }
                    }

                    ## in block: search for block exclusion

                    $found = 0;
                    foreach $condition (@blkexclude) {
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
                    if ($found) {
                        # this block to be excluded
                        $blkexclufound = 1;
                        next;
                    }


                    ## in block: gather stats

                    $statsidx = 0;
                    foreach $condition (@stats) {
                        ($evalName, $evalVals) = eval $condition;
                        if (defined($evalName)) {
                            if (!defined($evalVals)) {
                                $evalVals = 1;
                            }
                            if (!defined($statsout   [$statsidx]->{$evalName})) {
                                         $statsout   [$statsidx]->{$evalName}  = $evalVals + 0;
                                         $statsoutcnt[$statsidx]->{$evalName} = 1;
                            } else {
                                         $statsout   [$statsidx]->{$evalName} += $evalVals + 0;
                                         $statsoutcnt[$statsidx]->{$evalName}++;
                            }
                        }
                        $statsidx++;
                    }

                    ## in block: hide line

                    $found = 0;
                    foreach $condition (@hide) {
                        if ($condition =~ /^!!/) {
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
                    if (!$found) {
                        # not hide line
                        ## in block: collect output in this block

                        $viewskip = $cnt - 10;
                        if ($viewskip < 0) {
                            $viewskip = 0;
                        }
                        $hitlines++;
                        if ($wikitize eq '') {
                            $thisblockram .= sprintf ("<a href=\"/view.htm?update=Skip&skip=%d&maxln=100&path=%s&hiliteln=%d&refresh=\" target=\"_blank\">%05d</a>: %s\n", $viewskip, $form->{'path'}, $cnt, $cnt, $link); 
                            if (($maxblklines == 0) || ($hitlines < $maxblklines)) {
                                $thisblockdsp .= sprintf ("<a href=\"/view.htm?update=Skip&skip=%d&maxln=100&path=%s&hiliteln=%d&refresh=\" target=\"_blank\">%05d</a>: %s\n", $viewskip, $form->{'path'}, $cnt, $cnt, $link); 
                            }
                        } else {
                            $thisblockram .= "$link\n";
                            if (($maxblklines == 0) || ($hitlines < $maxblklines)) {
                                $thisblockdsp .= "$link\n";
                            }
                        }
                    }
                }
            } else {
                # EOF, anything left to output?    
                if (($outputed == 0) && ($blkexclufound == 0)) {
                    # found end of block
                    # do post blk eval
                    foreach $condition (@postblkeval) {
                        eval $condition;
                    }

                    $viewskip = $cnt - 10;
                    if ($viewskip < 0) {
                        $viewskip = 0;
                    }
                    $hitlines++;

                    $header .= "<a href=\"#blk$noblkfound\">$noblkfound</a> ";
                    $noblkfound++;
                    if ($wikitize eq '') {
                        $output .= $thisblockdsp;
                        $outram .= $thisblockram;
                    } else {
                        $output .= "</pre>";
                        $output .= &l00wikihtml::wikihtml ($ctrl, '', $thisblockdsp, 0);
                        $output .= "<pre>";
                        $outram .= "</pre>";
                        $outram .= &l00wikihtml::wikihtml ($ctrl, '', $thisblockram, 0);;
                        $outram .= "<pre>";
                    }

                    # displayed line accounting
                    if (($maxblklines == 0) || ($hitlines < $maxblklines)) {
                        # if block length is unlimited or greater than displayed
                        $hitlinesoutputed += $hitlines;
                    } else {
                        # if only partial block was displayed
                        $hitlinesoutputed += $maxblklines;
                    }
                }
            }

            ## if we have found a new block, prepare for the new block

            # found new start
            if ($blkstartfound) {
                # do pre blk eval
                foreach $condition (@preblkeval) {
                    eval $condition;
                }

                $outputed = 0;
                # $requiredfound_currln is reset to 0 for each new line
                # When $requiredfound_currln is 1 it means the required 
                # condition is found on the current line which is also 
                # the start line, so remember it as found.
                $requiredfound = $requiredfound_currln;
                $blkexclufound = 0;

                $hitlines = 1;

                if ($wikitize eq '') {
                    $thisblockram  = "<a name=\"blk$noblkfound\"></a>\n";
                    $thisblockram .= "Block $noblkfound. Jump to: ";
                    $thisblockram .= "<a href=\"#__top__\">top</a> - ";
                    $thisblockram .= "<a href=\"#__toc__\">toc</a> - ";
                    $thisblockram .= "<a href=\"#__end__\">end</a> -- ";
                    $tmp = $noblkfound - 1;
                    $thisblockram .= "<a href=\"#blk$tmp\">last</a> - ";
                    $tmp = $noblkfound + 1;
                    $thisblockram .= "<a href=\"#blk$tmp\">next</a> \n";
                    $thisblockram .= "\n";

                    if ($hitlines + $hitlinesoutputed < $maxlines) {
                        $thisblockdsp  = "<a name=\"blk$noblkfound\"></a>\n";
                        $thisblockdsp .= "Block $noblkfound. Jump to: ";
                        $thisblockdsp .= "<a href=\"#__top__\">top</a> - ";
                        $thisblockdsp .= "<a href=\"#__toc__\">toc</a> - ";
                        $thisblockdsp .= "<a href=\"#__end__\">end</a> -- ";
                        $tmp = $noblkfound - 1;
                        $thisblockdsp .= "<a href=\"#blk$tmp\">last</a> - ";
                        $tmp = $noblkfound + 1;
                        $thisblockdsp .= "<a href=\"#blk$tmp\">next</a> \n";
                        $thisblockdsp .= "\n";
                    } else {
                        $thisblockdsp  = '';
                    }
                } else {
                    $thisblockram  = "<a name=\"blk$noblkfound\"></a>\n";
                    $thisblockram .= "Block $noblkfound. Jump to: ";
                    $thisblockram .= "<a href=\"#__top__\">top</a> - ";
                    $thisblockram .= "<a href=\"#__toc__\">toc</a> - ";
                    $thisblockram .= "<a href=\"#__end__\">end</a> -- ";
                    $tmp = $noblkfound - 1;
                    $thisblockram .= "<a href=\"#blk$tmp\">last</a> - ";
                    $tmp = $noblkfound + 1;
                    $thisblockram .= "<a href=\"#blk$tmp\">next</a> \n";
                    $thisblockram .= "\n";

                    if ($hitlines + $hitlinesoutputed < $maxlines) {
                        $thisblockdsp  = "<a name=\"blk$noblkfound\"></a>\n";
                        $thisblockdsp .= "Block $noblkfound. Jump to: ";
                        $thisblockdsp .= "<a href=\"#__top__\">top</a> - ";
                        $thisblockdsp .= "<a href=\"#__toc__\">toc</a> - ";
                        $thisblockdsp .= "<a href=\"#__end__\">end</a> -- ";
                        $tmp = $noblkfound - 1;
                        $thisblockdsp .= "<a href=\"#blk$tmp\">last</a> - ";
                        $tmp = $noblkfound + 1;
                        $thisblockdsp .= "<a href=\"#blk$tmp\">next</a> \n";
                        $thisblockdsp .= "\n";
                    } else {
                        $thisblockdsp  = '';
                    }
                }

                $viewskip = $cnt - 10;
                if ($viewskip < 0) {
                    $viewskip = 0;
                }
                if ($wikitize eq '') {
                    $thisblockram .= sprintf ("<font style=\"color:black;background-color:silver\"><a href=\"/view.htm?update=Skip&skip=%d&maxln=100&path=%s&hiliteln=%d&refresh=\" target=\"_blank\">%05d</a>: %s</font>\n", $viewskip, $form->{'path'}, $cnt, $cnt, $link); 
                    if ($hitlines + $hitlinesoutputed < $maxlines) {
                        $thisblockdsp .= sprintf ("<font style=\"color:black;background-color:silver\"><a href=\"/view.htm?update=Skip&skip=%d&maxln=100&path=%s&hiliteln=%d&refresh=\" target=\"_blank\">%05d</a>: %s</font>\n", $viewskip, $form->{'path'}, $cnt, $cnt, $link); 
                    }
                } else {
                    $thisblockram .= sprintf ("<font style=\"color:black;background-color:silver\"><a href=\"/view.htm?update=Skip&skip=%d&maxln=100&path=%s&hiliteln=%d&refresh=\" target=\"_blank\">%05d</a>: %s</font>\n", $viewskip, $form->{'path'}, $cnt, $cnt, $link);
                    if ($hitlines + $hitlinesoutputed < $maxlines) {
                        $thisblockdsp .= sprintf ("<font style=\"color:black;background-color:silver\"><a href=\"/view.htm?update=Skip&skip=%d&maxln=100&path=%s&hiliteln=%d&refresh=\" target=\"_blank\">%05d</a>: %s</font>\n", $viewskip, $form->{'path'}, $cnt, $cnt, $link);
                    }
                }
            }

            ## end of processing

        }
        ($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/;
        if ($hitlines > $maxlines) {
            $output = "<font style=\"color:black;background-color:yellow\">Output truncated</font>. View <a href=\"/view.htm?path=l00://blockfilter_output.txt\" target=\"_blank\">l00://blockfilter_output.txt</a> for complete output\n$output";
            $output .= "\n<font style=\"color:black;background-color:yellow\">Output truncated</font>. View <a href=\"/view.htm?path=l00://blockfilter_output.txt\" target=\"_blank\">l00://blockfilter_output.txt</a> for complete output; ";
            $output .= "<a href=\"/filemgt.htm?path=l00://blockfilter_cfg.txt&path2=l00://blockfilter_cfg.txt.$fname\" target=\"_blank\">copy it to</a>...\n";
        }


        &l00httpd::l00fwriteBuf($ctrl, "<br><a name=\"__top__\"></a>Processed $cnt lines. ".
            "Output $noblkfound blocks and $hitlines lines to l00://blockfilter_output.txt<p>\n");
        &l00httpd::l00fwriteBuf($ctrl, "<a name=\"__toc__\"></a>$header<br>\n");
        &l00httpd::l00fwriteBuf($ctrl, "<pre>$outram</pre>\n");
        &l00httpd::l00fwriteBuf($ctrl, "<a name=\"__end__\"></a>\n");
        &l00httpd::l00fwriteBuf($ctrl, "<a href=\"#__top__\">jump to top</a><p>\n");
        &l00httpd::l00fwriteClose($ctrl);

        # make no tag version of output
        $_ = $ctrl->{'l00file'}->{"l00://blockfilter_output.txt"};
        s/<.+?>//gms;
        s/^\d+: //gms;
        $ctrl->{'l00file'}->{"l00://blockfilter_output_notag.txt"} = $_;

        if ($smallform eq '') {
            print $sock "<br>Processed $cnt lines. ".
                "Output $noblkfound blocks and $hitlines lines to:<br>".
                "View <a href=\"/view.htm?path=l00://blockfilter_output.txt\" target=\"_blank\">l00://blockfilter_output.txt</a>; ".
                "<a href=\"/filemgt.htm?path=l00://blockfilter_cfg.txt&path2=l00://blockfilter_cfg.txt.$fname\" target=\"_blank\">copy it to</a> ... ".
                "View <a href=\"/view.htm?path=l00://blockfilter_output_notag.txt\" target=\"_blank\">l00://blockfilter_output_notag.txt</a>".
                "<p>\n";
        }
        print $sock "<a name=\"__toc__\"></a>$header\n";
        print $sock "<pre>$output</pre>\n";
        print $sock "<a name=\"__end__\"></a>\n";
        print $sock "<a href=\"#__top__\">jump to top</a><p>\n";

        # print statistics
        $output = '';
        for ($tmp = 0; $tmp <= $#stats; $tmp++) {
            $cnt = 0;
            $cntsum = 0;
            $valsum = 0;
            $tmp2 = "statistics #$tmp\n";
            foreach $condition (sort keys %{$statsout[$tmp]}) {
                if (defined($statsoutcnt[$tmp]->{$condition}) && 
                    defined($statsout[$tmp]->{$condition})) {
                    $cntsum += $statsoutcnt[$tmp]->{$condition};
                    $valsum += $statsout[$tmp]->{$condition};
                    $tmp2 .= sprintf ("%7d $blockfilterstatfmt  %-60s\n", $statsoutcnt[$tmp]->{$condition}, $statsout[$tmp]->{$condition}, $condition);
                    $cnt++;
                }
            }
            if ($cnt > 0) {
                $tmp2 .= sprintf ("%7d $blockfilterstatfmt  &lt;- total\n", $cntsum, $valsum);
                $output .= "$tmp2\n";
            }
        }
        if ($output ne '') {
            print $sock "Statistics:<pre>$output</pre>\n";
        }

        # print control parameters
        $output = '';
        $output .= &l00http_blockfilter_print('skipto',      \@skipto);
        $output .= &l00http_blockfilter_print('scanuntil',   \@scanuntil);
        $output .= &l00http_blockfilter_print('fileexclude', \@fileexclude);
        $output .= &l00http_blockfilter_print('blkstart',    \@blkstart);
        $output .= &l00http_blockfilter_print('blkstop',     \@blkstop);
        $output .= &l00http_blockfilter_print('blkrequired', \@blkrequired);
        $output .= &l00http_blockfilter_print('blkexclude',  \@blkexclude);
        $output .= &l00http_blockfilter_print('color',       \@color);
        $output .= &l00http_blockfilter_print('eval',        \@eval);
        $output .= &l00http_blockfilter_print('preeval',     \@preeval);
        $output .= &l00http_blockfilter_print('preblkeval',  \@preblkeval);
        $output .= &l00http_blockfilter_print('postblkeval', \@postblkeval);
        $output .= &l00http_blockfilter_print('stats',       \@stats);
        $output .= &l00http_blockfilter_print('hide',        \@hide);

        &l00httpd::l00fwriteOpen($ctrl, 'l00://blockfilter_cfg.txt');
        &l00httpd::l00fwriteBuf($ctrl, "$output");
        &l00httpd::l00fwriteClose($ctrl);

        if ($smallform eq '') {
            print $sock "<a href=\"/view.htm?path=l00://blockfilter_cfg.txt\" target=\"_blank\">l00://blockfilter_cfg.txt</a> , \n";
            ($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/;
            print $sock "<a href=\"/filemgt.htm?path=l00://blockfilter_cfg.txt&path2=${pname}blockfilter_.txt\" target=\"_blank\">filemgt</a><p>\n";

            #print $sock "List of all parameters:<p>\n";
            #print $sock "<pre>$output</pre>\n";
        }
    } else {
        if (defined ($form->{'process'})) {
            print $sock "Unable to process $form->{'path'}<br>\n";
        }

        # print control parameters
        $output = '';
        $output .= &l00http_blockfilter_print('skipto',      \@skipto);
        $output .= &l00http_blockfilter_print('scanuntil',   \@scanuntil);
        $output .= &l00http_blockfilter_print('fileexclude', \@fileexclude);
        $output .= &l00http_blockfilter_print('blkstart',    \@blkstart);
        $output .= &l00http_blockfilter_print('blkstop',     \@blkstop);
        $output .= &l00http_blockfilter_print('blkrequired', \@blkrequired);
        $output .= &l00http_blockfilter_print('blkexclude',  \@blkexclude);
        $output .= &l00http_blockfilter_print('color',       \@color);
        $output .= &l00http_blockfilter_print('eval',        \@eval);
        $output .= &l00http_blockfilter_print('preeval',     \@preeval);
        $output .= &l00http_blockfilter_print('preblkeval',  \@preblkeval);
        $output .= &l00http_blockfilter_print('postblkeval', \@postblkeval);
        $output .= &l00http_blockfilter_print('stats',       \@stats);
        $output .= &l00http_blockfilter_print('hide',        \@hide);

        &l00httpd::l00fwriteOpen($ctrl, 'l00://blockfilter_cfg.txt');
        &l00httpd::l00fwriteBuf($ctrl, "$output");
        &l00httpd::l00fwriteClose($ctrl);
        print $sock "<a href=\"/view.htm?path=l00://blockfilter_cfg.txt\" target=\"_blank\">l00://blockfilter_cfg.txt</a><p>\n";

        #print $sock "List of all parameters:<p>\n";
        #print $sock "<pre>$output</pre>\n";
    }

    print $sock $ctrl->{'htmlfoot'};
}


\%config;
