use strict;
use warnings;
use l00wikihtml;
use l00svg;

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
    my (@alllines, $line, $svgdata, $tmp, $buf);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>l00httpd</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<br>\n";

    $buf = '';
    if (defined ($form->{'paste'})) {
        $buf = &l00httpd::l00getCB($ctrl);
    } elsif (defined ($form->{'plot'})) {
        $buf = $form->{'svgdata'};
    }
    if ((defined ($form->{'gwd'})) && ($form->{'gwd'} =~ /(\d+)/)) {
        $gwd = $1;
    }
    if ((defined ($form->{'ght'})) && ($form->{'ght'} =~ /(\d+)/)) {
        $ght = $1;
    }

    $svgdata = '';
    foreach $_ (split("\n", $buf)) {
        # split into one line at a time
        @_ = split(",", $_);
        if ($svgdata ne '') {
            $svgdata .= ' ';
        }
        foreach $_ (@_) {
            # make comma separated numbers only
            if (/^[0-9.eE+\-]+$/) {
                if (($svgdata !~ / $/) && ($svgdata ne '')) {
                    $svgdata .= ',';
                }
                $svgdata .= $_;
            } else {
                last;
            }
        }
    }

    print $sock "<form action=\"/svguser.htm\" method=\"post\">\n";
    print $sock "Width: <input type=\"text\" size=\"6\" name=\"gwd\" value=\"$gwd\">\n";
    print $sock "Height: <input type=\"text\" size=\"6\" name=\"ght\" value=\"$ght\">\n";
    print $sock "<input type=\"submit\" name=\"paste\" value=\"Pa&#818;ste\" accesskey=\"a\"> \n";
    print $sock "<input type=\"submit\" name=\"plot\" value=\"P&#818;lot\" accesskey=\"p\"> \n";
    print $sock "<br><textarea name=\"svgdata\" cols=\"32\" rows=\"5\" accesskey=\"e\">$buf</textarea>\n";
    print $sock "</form>\n";

    &l00svg::plotsvg2 ('svguser', $svgdata, $gwd, $ght);
    print $sock "<p><a href=\"/svg2.htm?graph=svguser&view=\"><img src=\"/svg2.htm?graph=svguser\" alt=\"user svg data\"></a>\n";

    print $sock "<p>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
