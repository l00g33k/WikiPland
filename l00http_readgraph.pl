use strict;
use warnings;
use l00wikihtml;
use l00svg;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# read graph


my %config = (proc => "l00http_readgraph_proc",
              desc => "l00http_readgraph_desc");
my ($lastx, $lasty, $lastoff, $lastpath, $xoff, $yoff);

$lastx = undef;
$lasty = undef;
$lastpath = undef;
$xoff = 4;
$yoff = 2;

sub l00http_readgraph_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "readgraph: Read out values from a graph";
}

sub l00http_readgraph_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($xpix, $ypix, $pname, $fname, $dx, $dy);


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>l00httpd</title>" . $ctrl->{'htmlhead2'};

    if (defined ($form->{'path'}) &&
        (($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/)) {
        print $sock "<form action=\"/readgraph.htm\" method=\"get\">\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$pname$fname\">\n";
        print $sock "<input type=image style=\"float:none\" src=\"/ls.htm/$fname?path=$pname$fname\"><br>\n";
        if (defined ($form->{'x'})) {
            $xpix = $form->{'x'} + $xoff;
            $ypix = $form->{'y'} + $yoff;
            print $sock "<div style=\"position: absolute; left:$xpix"."px; top:$ypix"."px;\">\n";
            print $sock "<font color=\"red\">+</font></div>\n";
        }
        print $sock "</form>\n";
    }


    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}\n";
    print $sock "Click graph above.\n";
    if (defined ($form->{'path'}) && (defined ($form->{'x'}))) {
        print $sock "You clicked: ($form->{'x'},$form->{'y'})<br>\n";
        if ($lastpath ne undef) {
            $dx = $xpix - $lastx;
            $dy = $ypix - $lasty;
            print $sock "Delta: ($dx, $dy)<br>\n";
        }
        $lastx = $xpix;
        $lasty = $ypix;
        $lastpath = $form->{'path'};
    }

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};

}


\%config;
