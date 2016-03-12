use strict;
use warnings;
use l00wikihtml;
use l00svg;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# read graph


my %config = (proc => "l00http_readgraph_proc",
              desc => "l00http_readgraph_desc");
my ($lastx, $lasty, $lastoff);

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
    my ($xpix, $ypix);


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>l00httpd</title>" . $ctrl->{'htmlhead2'};

    print $sock "<form action=\"/readgraph.htm\" method=\"get\">\n";
#    print $sock "<input type=image style=\"float:none\" src=\"/svg.htm?graph=demo\"><br>\n";
    print $sock "<input type=image style=\"float:none\" src=\"/ls.htm/Screenshot_2016-02-02-07-20-41.png?path=/sdcard/Pictures/Screenshots/Screenshot_2016-02-02-07-20-41.png\"><br>\n";
# /sdcard/Pictures/Screenshots/Screenshot_2016-02-02-07-20-41.png
#http://127.0.0.1:30337
#/ls.htm/Screenshot_2016-02-02-07-20-41.png?path=/sdcard/Pictures/Screenshots/Screenshot_2016-02-02-07-20-41.png

    if (defined ($form->{'x'})) {
        $xpix = 100;
        $ypix = 100;
        print $sock "<div style=\"position: absolute; left:$xpix"."px; top:$ypix"."px;\">\n";
        print $sock "<font color=\"red\">X</font></div>\n";
    }

    print $sock "<input type=\"hidden\" name=\"graph\" value=\"demo\">\n";
    print $sock "<input type=\"hidden\" name=\"view\">\n";
    print $sock "</form>\n";

    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}\n";
    print $sock "Click graph above.\n";
    if (defined ($form->{'x'})) {
        print $sock "You clicked: ($form->{'x'},$form->{'y'})<br>\n";
    }

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};

}


\%config;
