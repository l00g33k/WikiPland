use strict;
use warnings;
use l00wikihtml;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# plot user graph

my %config = (proc => "l00http_svguser_proc",
              desc => "l00http_svguser_desc");
my ($gwd, $ght) = (500, 300);

sub l00http_svguser_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "svguser: plot user data";
}

sub l00http_svguser_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $svgdata, $tmp);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>l00httpd</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a><br>\n";

    $svgdata = '';
    if (defined ($form->{'paste'})) {
        if ($ctrl->{'os'} eq 'and') {
            $svgdata = $ctrl->{'droid'}->getClipboard();
            $svgdata = $svgdata->{'result'};
        }
    } elsif (defined ($form->{'plot'})) {
        $svgdata = $form->{'svgdata'};
    }

    $svgdata =~ s/\r/ /g;
    $svgdata =~ s/\n/ /g;
    $svgdata =~ s/ +/ /g;

    print $sock "<form action=\"/svguser.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"plot\" value=\"Plot\"> \n";
    if ($ctrl->{'os'} eq 'and') {
        print $sock "<input type=\"submit\" name=\"paste\" value=\"Paste\"> \n";
    }
    print $sock "Width: <input type=\"text\" size=\"6\" name=\"gwd\" value=\"$gwd\">\n";
    print $sock "Height: <input type=\"text\" size=\"6\" name=\"ght\" value=\"$ght\">\n";
    print $sock "<br><textarea name=\"svgdata\" cols=\"32\" rows=\"5\">$svgdata</textarea>\n";
    print $sock "</form>\n";

    &l00svg::plotsvg ('svguser', $svgdata, $gwd, $ght);
    print $sock "<p><a href=\"/svg.htm?graph=svguser&view=\"><img src=\"/svg.htm?graph=svguser\" alt=\"user svg data\"></a>\n";

    print $sock "<p>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
