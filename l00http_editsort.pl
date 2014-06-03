use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# sort block selected in edit.pl

#l00httpd::dbp($config{'desc'}, "2 contextln $contextln\n");
my %config = (proc => "l00http_editsort_proc",
              desc => "l00http_editsort_desc");
my ($linessorted, @sortbuf, $pathorg, $orgbuf);
$linessorted = 0;
$pathorg = '';
$orgbuf = '';

sub l00http_editsort_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "editsort: sort block selected in edit.pl";
}

sub l00http_editsort_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($lineno, $outbuf, @inbuf, $ii);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a> - ";
    print $sock "<a href=\"#end\">Jump to end</a>\n";
    
    print $sock "<br>\n";


    if (defined ($form->{'init'})) {
        $linessorted = 0;
        if (&l00httpd::l00freadOpen($ctrl, 'l00://editblock')) {
            $orgbuf = &l00httpd::l00freadAll($ctrl);
        }
    }
    if (defined ($form->{'pathorg'})) {
        $pathorg = $form->{'pathorg'};
    }

    if (defined ($form->{'reset'})) {
        $linessorted = 0;
        &l00httpd::l00fwriteOpen($ctrl, 'l00://editblock');
        &l00httpd::l00fwriteBuf($ctrl, $orgbuf);
        &l00httpd::l00fwriteClose($ctrl);
    }


    if (defined ($form->{'pick'})) {
        undef @inbuf;
        if (&l00httpd::l00freadOpen($ctrl, 'l00://editblock')) {
            while ($_ = &l00httpd::l00freadLine($ctrl)) {
                push (@inbuf, $_);
            }
            $outbuf = '';
            # skip first $linessorted line already sorted
            for ($ii = 0; $ii < $linessorted; $ii++) {
                $outbuf .= $inbuf[$ii];
            }
            # insert picked line
            $outbuf .= $inbuf[$form->{'pick'} - 1];
            for ($ii = $linessorted; $ii <= $#inbuf; $ii++) {
                if ($ii != ($form->{'pick'} - 1)) {
                    $outbuf .= $inbuf[$ii];
                }
            }
            &l00httpd::l00fwriteOpen($ctrl, 'l00://editblock');
            &l00httpd::l00fwriteBuf($ctrl, $outbuf);
            &l00httpd::l00fwriteClose($ctrl);
            $linessorted++;
        }
    }


    if (&l00httpd::l00freadOpen($ctrl, 'l00://editblock')) {
        print $sock "<p><pre>\n";
        $lineno = 1;
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            $outbuf .= $_;
            s/\r//g;
            s/\n//g;
            s/</&lt;/g;
            s/>/&gt;/g;
            if (($lineno - 1) < $linessorted) {
                # highlight sorted line
                print $sock sprintf ("<font style=\"color:black;background-color:lime\">".
                                     "%04d</font>: ", $lineno) . "$_\n";
            } else {
                print $sock sprintf ("<a href=\"/editsort.htm?pick=$lineno\">%04d</a>: ", $lineno) . "$_\n";
            }
            $lineno++;
        }
        print $sock "</pre>\n";
    }


    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";

    print $sock "<tr><td>\n";
    print $sock "<form action=\"/edit.htm\" method=\"post\">\n";
    print $sock "<input type=\"submit\" name=\"editsorted\" value=\"Save\">\n";
    print $sock "<input type=\"submit\" name=\"reload\" value=\"Quit\">\n";
    print $sock "<input type=\"hidden\" name=\"pathorg\" value=\"$pathorg\">\n";
    print $sock "</form>\n";
    print $sock "</td>\n";

    print $sock "<td>\n";
    print $sock "<form action=\"/editsort.htm\" method=\"post\">\n";
    print $sock "<input type=\"submit\" name=\"reset\" value=\"Reset\">\n";
    print $sock "</form>\n";
    print $sock "</td></tr>\n";

    print $sock "</table><br>\n";

    print $sock "<a name=\"end\"></a>";
    print $sock "<a href=\"#top\">top</a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
