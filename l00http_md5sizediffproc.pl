use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_md5sizediffproc_proc",
              desc => "l00http_md5sizediffproc_desc");
my ($required, $exclude);
$required = '';
$exclude = '';

sub l00http_md5sizediffproc_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "md5sizediffproc: Special processor for md5sizediff text outputs";
}

sub l00http_md5sizediffproc_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($cnt, $requiredhits, $excludehits, $output, $thisblock, $condition);
    my ($blkdisplayed, $nonumblock);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>Android startActivity</title>" .$ctrl->{'htmlhead2'};
    print $sock "<a name=\"__top__\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"#__end__\">jump to end</a> - \n";
    print $sock "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";

    if (defined ($form->{'process'})) {
        if (defined ($form->{'required'})) {
            $required = $form->{'required'};
        }
        if (defined ($form->{'exclude'})) {
            $exclude = $form->{'exclude'};
        }
    }

    print $sock "<form action=\"/md5sizediffproc.htm\" method=\"get\">\n";
    print $sock "<table border=\"3\" cellpadding=\"3\" cellspacing=\"1\">\n";

    print $sock "<tr><td>\n";
    print $sock "<input type=\"submit\" name=\"process\" value=\"Process\">\n";
    print $sock "</td><td>\n";
    print $sock "<input type=\"text\" size=\"16\" name=\"path\" value=\"$form->{'path'}\"><p>\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "Required condition (1 per line)\n";
    print $sock "</td><td>\n";
    print $sock "<textarea name=\"required\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$required</textarea>\n";
    print $sock "</td></tr>\n";

    print $sock "<tr><td>\n";
    print $sock "Exclude condition (1 per line)\n";
    print $sock "</td><td>\n";
    print $sock "<textarea name=\"exclude\" cols=$ctrl->{'txtw'} rows=$ctrl->{'txth'}>$exclude</textarea>\n";
    print $sock "</td></tr>\n";

    print $sock "</table><br>\n";
    print $sock "</form>\n";


    if (defined ($form->{'process'}) &&
        defined ($form->{'path'}) &&
        (&l00httpd::l00freadOpen($ctrl, $form->{'path'}))) {
        &l00httpd::l00fwriteOpen($ctrl, 'l00://md5sizediffproc.txt');

        $cnt = 0;
        $blkdisplayed = 0;
        $output = '';

        $requiredhits = 0;
        $excludehits = 0;
        $thisblock = '';
        $nonumblock = '';
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            $cnt++;
            $thisblock .= sprintf ("%05d: %s", $cnt, $_);
            $nonumblock .= $_;
            if (/^ *$/) {
                # blank line is end of block
                # do we print?
                if (($requiredhits > 0) &&
                    ($excludehits == 0)) {
                    $blkdisplayed++;
                    $output .= $thisblock;
                    &l00httpd::l00fwriteBuf($ctrl, "$nonumblock");
                }
                $requiredhits = 0;
                $excludehits = 0;
                $thisblock = '';
                $nonumblock = '';
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
        print $sock "Displaying $blkdisplayed blocks. View ".
            "<a href=\"/view.htm?path=l00://md5sizediffproc.txt\">l00://md5sizediffproc.txt</a><br>\n";
        print $sock "<pre>$output</pre>\n";
        print $sock "<a name=\"__end__\"></a>\n";
        print $sock "<a href=\"#__top__\">jump to top</a>\n";
    }

    print $sock $ctrl->{'htmlfoot'};
}


\%config;
