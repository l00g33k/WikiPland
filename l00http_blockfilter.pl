use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_blockfilter_proc",
              desc => "l00http_blockfilter_desc");
my (@required, @exclude, @blockend, @skipto, @skiptail);
@required = undef;
@exclude = undef;
@blockend = undef;
@skipto = undef;
@skiptail = undef;

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
    my ($blkdisplayed, $nonumblock, $blockendhits, $hitlines, $hitlinesthis, $tmp, $findskipto);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>Block filter</title>" .$ctrl->{'htmlhead2'};
    print $sock "<a name=\"__top__\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"#__end__\">jump to end</a> - \n";
    print $sock "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a> - \n";
    print $sock "<a href=\"/view.htm?path=$form->{'path'}\">view</a><br>\n";

    if (defined ($form->{'skiptopaste'})) {
        undef @skipto;
        foreach $condition (split("\n", &l00httpd::l00getCB($ctrl))) {
            $condition =~ s/\n//g;
            $condition =~ s/\r//g;
            if (length($condition) > 0) {
                push(@skipto, $condition);
            }
        }
    }
    if (defined ($form->{'skiptailpaste'})) {
        undef @skiptail;
        foreach $condition (split("\n", &l00httpd::l00getCB($ctrl))) {
            $condition =~ s/\n//g;
            $condition =~ s/\r//g;
            if (length($condition) > 0) {
                push(@skiptail, $condition);
            }
        }
    }
    if (defined ($form->{'blockpaste'})) {
        undef @blockend;
        foreach $condition (split("\n", &l00httpd::l00getCB($ctrl))) {
            $condition =~ s/\n//g;
            $condition =~ s/\r//g;
            if (length($condition) > 0) {
                push(@blockend, $condition);
            }
        }
    }
    if (defined ($form->{'requiredpaste'})) {
        undef @required;
        foreach $condition (split("\n", &l00httpd::l00getCB($ctrl))) {
            $condition =~ s/\n//g;
            $condition =~ s/\r//g;
            if (length($condition) > 0) {
                push(@required, $condition);
            }
        }
    }
    if (defined ($form->{'excludepaste'})) {
        undef @exclude;
        foreach $condition (split("\n", &l00httpd::l00getCB($ctrl))) {
            $condition =~ s/\n//g;
            $condition =~ s/\r//g;
            if (length($condition) > 0) {
                push(@exclude, $condition);
            }
        }
    }

    if (defined ($form->{'process'})) {
        if (defined ($form->{'skipto'})) {
            undef @skipto;
            foreach $condition (split("\n", $form->{'skipto'})) {
                $condition =~ s/\n//g;
                $condition =~ s/\r//g;
                if (length($condition) > 0) {
                    push(@skipto, $condition);
                }
            }
        }
        if (defined ($form->{'skiptail'})) {
            undef @skiptail;
            foreach $condition (split("\n", $form->{'skiptail'})) {
                $condition =~ s/\n//g;
                $condition =~ s/\r//g;
                if (length($condition) > 0) {
                    push(@skiptail, $condition);
                }
            }
        }
        if (defined ($form->{'blockend'})) {
            undef @blockend;
            foreach $condition (split("\n", $form->{'blockend'})) {
                $condition =~ s/\n//g;
                $condition =~ s/\r//g;
                if (length($condition) > 0) {
                    push(@blockend, $condition);
                }
            }
        }
        if (defined ($form->{'required'})) {
            undef @required;
            foreach $condition (split("\n", $form->{'required'})) {
                $condition =~ s/\n//g;
                $condition =~ s/\r//g;
                if (length($condition) > 0) {
                    push(@required, $condition);
                }
            }
        }
        if (defined ($form->{'exclude'})) {
            undef @exclude;
            foreach $condition (split("\n", $form->{'exclude'})) {
                $condition =~ s/\n//g;
                $condition =~ s/\r//g;
                if (length($condition) > 0) {
                    push(@exclude, $condition);
                }
            }
        }
    }

    print $sock "<form action=\"/blockfilter.htm\" method=\"get\">\n";
    print $sock "<table border=\"3\" cellpadding=\"3\" cellspacing=\"1\">\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"process\" value=\"Process\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"16\" name=\"path\" value=\"$form->{'path'}\"><p>\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"skiptopaste\" value=\"Skip to\">\n";
    print $sock "pattern (1 per line)\n";
    print $sock "</td><td>\n";
    $tmp = join("\n", @skipto);
    print $sock "<textarea name=\"skipto\" cols=24 rows=7>$tmp</textarea>\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"blockpaste\" value=\"Block\">\n";
    print $sock "ending pattern (1 per line)\n";
    print $sock "</td><td>\n";
    $tmp = join("\n", @blockend);
    print $sock "<textarea name=\"blockend\" cols=24 rows=7>$tmp</textarea>\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"requiredpaste\" value=\"Required\">\n";
    print $sock "pattern (1 per line)\n";
    print $sock "</td><td>\n";
    $tmp = join("\n", @required);
    print $sock "<textarea name=\"required\" cols=24 rows=7>$tmp</textarea>\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"excludepaste\" value=\"Exclude\">\n";
    print $sock "pattern (1 per line)\n";
    print $sock "</td><td>\n";
    $tmp = join("\n", @exclude);
    print $sock "<textarea name=\"exclude\" cols=24 rows=7>$tmp</textarea>\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"skiptailpaste\" value=\"Ending\">\n";
    print $sock "pattern (1 per line)\n";
    print $sock "</td><td>\n";
    $tmp = join("\n", @skiptail);
    print $sock "<textarea name=\"skiptail\" cols=24 rows=7>$tmp</textarea>\n";
    print $sock "</td></tr>\n";

    print $sock "</table><br>\n";
    print $sock "</form>\n";


    if (defined ($form->{'process'}) &&
        defined ($form->{'path'}) &&
        (&l00httpd::l00freadOpen($ctrl, $form->{'path'}))) {
        &l00httpd::l00fwriteOpen($ctrl, 'l00://blockfilter.txt');

        $cnt = 0;
        $blkdisplayed = 0;
        $output = '';

        $requiredhits = 0;
        $excludehits = 0;
        $thisblock = '';
        $nonumblock = '';
        $hitlines = 0;
        $findskipto = 1;
        $ending = 0;

        $output .= "Skip to pattern\n";
        foreach $condition (@skipto) {
            $output .= "    >$condition<\n";
        }
        $output .= "Block ending pattern\n";
        foreach $condition (@blockend) {
            $output .= "    >$condition<\n";
        }
        $output .= "Required pattern\n";
        foreach $condition (@required) {
            $output .= "    >$condition<\n";
        }
        $output .= "Exclude pattern\n";
        foreach $condition (@exclude) {
            $output .= "    >$condition<\n";
        }
        $output .= "Filtered output:\n\n";
        $output .= "Skip to pattern\n";
        foreach $condition (@skipto) {
            $output .= "    >$condition<\n";
        }

        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            $cnt++;

            if ($findskipto) {
                foreach $condition (@skipto) {
                    if (/$condition/) {
                        $findskipto = 0;
                        last;
                    }
                }
                if ($findskipto) {
                    next;
                }
            }

&l00httpd::l00fwriteBuf($ctrl, "$_");

            foreach $condition (@skiptail) {
                if (/$condition/) {
                    $ending = 1;
                    last;
                }
            }
            if ($ending) {
last;
            }


            $thisblock .= sprintf ("%05d: %s", $cnt, $_);
            $hitlinesthis++;
            $nonumblock .= $_;

            $blockendhits = 0;
            foreach $condition (@blockend) {
                if (/$condition/) {
                    $blockendhits++;
                }
            }

            if ($blockendhits > $#blockend) {
                # blank line is end of block
                # do we print?
                if (($requiredhits > $#required) &&
                    ($excludehits == 0)) {
                    $blkdisplayed++;
                    $hitlines += $hitlinesthis;
                    $output .= $thisblock;
                    &l00httpd::l00fwriteBuf($ctrl, "$nonumblock");
                }
                $requiredhits = 0;
                $excludehits = 0;
                $thisblock = '';
                $nonumblock = '';
                $hitlinesthis = 0;
            } else {
                foreach $condition (@required) {
                    if (/$condition/) {
                        $requiredhits++;
                    }
                }
                foreach $condition (@exclude) {
                    if (/$condition/) {
                        $excludehits++;
                    }
                }
            }
        }
        &l00httpd::l00fwriteClose($ctrl);
        print $sock "Processed $cnt lines. ".
            "Output $blkdisplayed blocks and $hitlines lines to ".
            "<a href=\"/view.htm?path=l00://blockfilter.txt\">l00://blockfilter.txt</a> ".
            "<br>\n";
        print $sock "<pre>$output</pre>\n";
        print $sock "<a name=\"__end__\"></a>\n";
        print $sock "<a href=\"#__top__\">jump to top</a>\n";
    }

    print $sock $ctrl->{'htmlfoot'};
}


\%config;
