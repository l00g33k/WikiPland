use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_blockfilter_proc",
              desc => "l00http_blockfilter_desc");
my (@skipto, @scanto, @fileexclude, @blkstart, @blkstop, @blkrequired, @color, @subst, @blockend);


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
    my ($cnt, $requiredhits, $excludehits, $output, $thisblock, $condition, $ending);
    my ($blkdisplayed, $nonumblock, $blockendhits, $hitlines, $hitlinesthis, $tmp, $skip0scan1);
    my ($inblk, $blkstartfound, $blkendfound, $found, $header, $noblkfound);


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
    &l00http_blockfilter_paste($ctrl, $form, 'subst',       \@subst);

    if (defined ($form->{'process'})) {
        &l00http_blockfilter_paste($ctrl, $form, 'skipto',      \@skipto);
        &l00http_blockfilter_paste($ctrl, $form, 'scanto',      \@scanto);
        &l00http_blockfilter_paste($ctrl, $form, 'fileexclude', \@fileexclude);
        &l00http_blockfilter_paste($ctrl, $form, 'blkstart',    \@blkstart);
        &l00http_blockfilter_paste($ctrl, $form, 'blkstop',     \@blkstop);
        &l00http_blockfilter_paste($ctrl, $form, 'blkrequired', \@blkrequired);
        &l00http_blockfilter_paste($ctrl, $form, 'color',       \@color);
        &l00http_blockfilter_paste($ctrl, $form, 'subst',       \@subst);
    }

    print $sock "<p><form action=\"/blockfilter.htm\" method=\"get\">\n";
    print $sock "<table border=\"3\" cellpadding=\"3\" cellspacing=\"1\">\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"process\" value=\"Process\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"24\" name=\"path\" value=\"$form->{'path'}\"><p>\n";
    print $sock "</td></tr>\n";


    &l00http_blockfilter_form($sock, $form, 'skipto',      'Skip to',           \@skipto);
    &l00http_blockfilter_form($sock, $form, 'scanto',      'Scan to',           \@scanto);
    &l00http_blockfilter_form($sock, $form, 'fileexclude', 'Exclude line (!!)', \@fileexclude);
    &l00http_blockfilter_form($sock, $form, 'blkstart',    'Block Start',       \@blkstart);
    &l00http_blockfilter_form($sock, $form, 'blkstop',     'Block End',         \@blkstop);
    &l00http_blockfilter_form($sock, $form, 'blkrequired', 'Block Required',    \@blkrequired);
    &l00http_blockfilter_form($sock, $form, 'color',       'Colorize',          \@color);
    &l00http_blockfilter_form($sock, $form, 'subst',       'Substitude',        \@subst);

    print $sock "</table><br>\n";
    print $sock "</form>\n";


    if (defined ($form->{'process'}) &&
        defined ($form->{'path'}) &&
        (&l00httpd::l00freadOpen($ctrl, $form->{'path'}))) {
        print $sock "Processing ... \n";
        &l00httpd::l00fwriteOpen($ctrl, 'l00://blockfilter.txt');

        $cnt = 0;
        $blkdisplayed = 0;
        $output = '';

        $requiredhits = 0;
        $excludehits = 0;
        $thisblock = '';
        $nonumblock = '';
        $hitlines = 0;
        $inblk = 0;
        $skip0scan1 = 0;    # skip to/scan to toggle
        $ending = 0;
        $header = '';
        $noblkfound = 0;

        while (1) {
            $_ = &l00httpd::l00freadLine($ctrl);
            if (!defined($_)) {
                last;
            }
            $cnt++;

            # skip beginning of file until skipto hit
            if ($skip0scan1 == 0) {
                # skip to mode
                foreach $condition (@skipto) {
                    if (/$condition/) {
                        # found skip to, now do scan to
                        $skip0scan1 = 1;
                        last;
                    }
                }
                if ($skip0scan1 == 0) {
                    # skip all lines up to first skipto hit
                    next;
                }
            } else {
                # scan to mode
                foreach $condition (@scanto) {
                    if (/$condition/) {
                        # found scan to, now do skip to
                        $skip0scan1 = 0;
                        last;
                    }
                }
            }

            $found = 0;
            foreach $condition (@fileexclude) {
                if (substr($condition, 0, 2) eq '!!') {
                    $tmp = $condition;
                    substr($tmp, 0, 2) = '';
                    if (!/$tmp/) {
                        # not found, exclude
                        $found = 1;
                        last;
                    }
                } else {
                    if (/$condition/) {
                        # found, exclude
                        $found = 1;
                        last;
                    }
                }
            }
            if ($found) {
                # file exclude line
                next;
            }

            &l00httpd::l00fwriteBuf($ctrl, "$_");

            $blkendfound = 0;
            $blkstartfound = 0;
            $found = 0;

            # search for block start
            foreach $condition (@blkstart) {
                if (/$condition/) {
                    # found
                    $found = 1;
                    $inblk = 1;
                    $blkstartfound = 1;
                    last;
                }
            }

            if ($found != 0) {
                # search for block end
                foreach $condition (@blkstop) {
                    if (/$condition/) {
                        # found
                        $inblk = 0;
                        $blkendfound = 1;
                        last;
                    }
                }
            }


            if ($blkendfound) {
                print $sock "$thisblock";
            }

            if ($inblk) {
                $thisblock .= sprintf ("<a href=\"/view.htm?update=Skip&skip=%d&maxln=100&path=%s&hiliteln=%d&refresh=\" target=\"newwin\">%05d</a>: %s", $cnt, $form->{'path'}, $cnt, $cnt, $_); 
#               $thisblock .= sprintf ("%05d: %s", $cnt, $_);
                $hitlinesthis++;
                $nonumblock .= $_;
                if ($blkstartfound) {
                    $header .= "<a href=\"#blk$noblkfound\">$noblkfound</a> ";
                    $noblkfound++;
                    $output .= "\n";
                    $output .= "Block $noblkfound. Jump to: <a href=\"#__top__\">top</a> - <a href=\"#__toc__\">toc</a> - <a href=\"#__end__\">end</a> \n";
                    $output .= "\n";
                    $output .= "<a name=\"blk$noblkfound\"></a><font style=\"color:black;background-color:silver\">$thisblock</font>";
                } else {
                    $output .= $thisblock;
                }
            }




            $blockendhits = 0;
            foreach $condition (@blockend) {
                if (/$condition/) {
                    $blockendhits++;
                }
            }

            if ($blockendhits > $#blockend) {
                # blank line is end of block
                # do we print?
#                if (($requiredhits > $#required) &&
#                    ($excludehits == 0)) {
#                    $blkdisplayed++;
#                    $hitlines += $hitlinesthis;
#                    $output .= $thisblock;
#                    &l00httpd::l00fwriteBuf($ctrl, "$nonumblock");
#                }
                $requiredhits = 0;
                $excludehits = 0;
                $thisblock = '';
                $nonumblock = '';
                $hitlinesthis = 0;
            } else {
#                foreach $condition (@required) {
#                    if (/$condition/) {
#                        $requiredhits++;
#                    }
#                }
#                foreach $condition (@exclude) {
#                    if (/$condition/) {
#                        $excludehits++;
#                    }
#                }
            }
        }

        &l00httpd::l00fwriteClose($ctrl);
        print $sock "Processed $cnt lines. ".
            "Output $blkdisplayed blocks and $hitlines lines to ".
            "<a href=\"/view.htm?path=l00://blockfilter.txt\" target=\"newram\">l00://blockfilter.txt</a> ".
            "<p>\n";
        print $sock "<a name=\"__toc__\"></a>$header<br>\n";
        print $sock "<pre>$output</pre>\n";
        print $sock "<a name=\"__end__\"></a>\n";
        print $sock "<a href=\"#__top__\">jump to top</a>\n";
    } else {
        print $sock "Unable to process $form->{'path'}<br>\n";
    }

    print $sock $ctrl->{'htmlfoot'};
}


\%config;
