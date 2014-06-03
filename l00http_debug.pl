use strict;
use warnings;
use l00httpd;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_debug_proc",
              desc => "l00http_debug_desc");
my ($jmpintv);
$jmpintv = 100;

#l00httpd::dbpclr();
#l00httpd::dbp($config{'desc'}, "test\n");
#l00httpd::dbphash($config{'desc'}, 'FORM', $form);

sub l00http_debug_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition

    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    " C: debug: view debug log";
}

sub l00http_debug_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($lnno, $output);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>debug</title>" . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">QUICK</a> <a href=\"/debug.htm\">Refresh</a><p> \n";

    if (defined($form->{'jmpintv'})) {
        $jmpintv = $form->{'jmpintv'};
        if (($jmpintv < 0) || ($jmpintv > 100000)) {
            $jmpintv = 100;
        }
    }

    print $sock "<form action=\"/debug.htm\" method=\"get\">\n";
    print $sock "<table border=\"0\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"clear\" value=\"Clear\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"set\" value=\"Set\"></td>\n";
    print $sock "        <td>jump invertval: <input type=\"text\" size=\"6\" name=\"jmpintv\" value=\"$jmpintv\"></td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "</table>\n";
    print $sock "</form>\n";



    if (defined($form->{'clear'})) {
        l00httpd::dbpclr();
    }

    $output = '';
    $lnno = 1;
    foreach $_ (split("\n", l00httpd::dbpget)) {
        if (($lnno % $jmpintv) == 1) {
            $output .= "</pre>\n";
            $output .= "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a name=\"ln$lnno\"></a>jump: ";
            $output .= "<a href=\"#top\">top</a>\n";
            if ($lnno - $jmpintv > 0) {
                $output .= sprintf ("<a href=\"#ln%d\">line %d</a>\n", $lnno - $jmpintv, $lnno - $jmpintv);
            }
            $output .= sprintf ("<a href=\"#ln%d\">line %d</a>\n", $lnno + $jmpintv, $lnno + $jmpintv);
            $output .= "<a href=\"#end\">end</a>\n";
            $output .= "<pre>\n";
        }
        $output .= sprintf ("%04d: %s\n", $lnno, $_);
        $lnno++;
    }

    print $sock "System debug log (", $lnno-1, " lines): jump <a href=\"#end\">end</a>\n";
    print $sock "<pre>$output</pre>\n";

    print $sock "<a name=\"end\">Jump:</a><a href=\"#top\">top</a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
