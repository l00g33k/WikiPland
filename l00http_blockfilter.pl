use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_blockfilter_proc",
              desc => "l00http_blockfilter_desc");
my ($required, $exclude, $blockend);
$required = '';
$exclude = '';
$blockend = '';

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
    my ($cnt, $requiredhits, $excludehits, $output, $thisblock, $condition);
    my ($blkdisplayed, $nonumblock, $blockendhits, $hitlines, $hitlinesthis);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>Block filter</title>" .$ctrl->{'htmlhead2'};
    print $sock "<a name=\"__top__\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"#__end__\">jump to end</a> - \n";
    print $sock "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";

    if (defined ($form->{'blockpaste'})) {
        $blockend = &l00httpd::l00getCB($ctrl);
    }
    if (defined ($form->{'requiredpaste'})) {
        $required = &l00httpd::l00getCB($ctrl);
    }
    if (defined ($form->{'excludepaste'})) {
        $exclude = &l00httpd::l00getCB($ctrl);
    }

    if (defined ($form->{'process'})) {
        if (defined ($form->{'blockend'})) {
            $blockend = $form->{'blockend'};
        }
        if (defined ($form->{'required'})) {
            $required = $form->{'required'};
        }
        if (defined ($form->{'exclude'})) {
            $exclude = $form->{'exclude'};
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
    print $sock "<input type=\"submit\" name=\"blockpaste\" value=\"Block\">\n";
    print $sock "ending (1 per line)\n";
    print $sock "</td><td>\n";
    print $sock "<textarea name=\"blockend\" cols=24 rows=7>$blockend</textarea>\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"requiredpaste\" value=\"Required\">\n";
    print $sock "condition (1 per line)\n";
    print $sock "</td><td>\n";
    print $sock "<textarea name=\"required\" cols=24 rows=7>$required</textarea>\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"excludepaste\" value=\"Exclude\">\n";
    print $sock "condition (1 per line)\n";
    print $sock "</td><td>\n";
    print $sock "<textarea name=\"exclude\" cols=24 rows=7>$exclude</textarea>\n";
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
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            $cnt++;
            $thisblock .= sprintf ("%05d: %s", $cnt, $_);
            $hitlinesthis++;
            $nonumblock .= $_;

            $blockendhits = 0;
            foreach $condition (split("\n", $blockend)) {
                if (/$condition/) {
                    $blockendhits++;
                }
            }

            if ($blockendhits > 0) {
                # blank line is end of block
                # do we print?
                if (($requiredhits > 0) &&
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
                foreach $condition (split("\n", $required)) {
                    if (/$condition/) {
                        $requiredhits++;
                    }
                }
                foreach $condition (split("\n", $exclude)) {
                    if (/$condition/) {
                        $excludehits++;
                    }
                }
            }
        }
        &l00httpd::l00fwriteClose($ctrl);
        print $sock "Displaying $blkdisplayed blocks and $hitlines lines. View ".
            "<a href=\"/view.htm?path=l00://blockfilter.txt\">l00://blockfilter.txt</a><br>\n";
        print $sock "<pre>$output</pre>\n";
        print $sock "<a name=\"__end__\"></a>\n";
        print $sock "<a href=\"#__top__\">jump to top</a>\n";
    }

    print $sock $ctrl->{'htmlfoot'};
}


\%config;
