use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple bookmark

my $bookmark;

my %config = (proc => "l00http_myfriends_proc",
              desc => "l00http_myfriends_desc");

sub l00http_myfriends_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    $bookmark = 
    "Demo: myfriends: My friends, CLICK HERE TO START-> ".
    "<a href=\"/ls.htm?path=$ctrl->{'workdir'}pub/index.txt\">index.txt</a> ";
        
    # Descriptions to be displayed in the list of modules table
    $bookmark;
}

sub l00http_myfriends_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket

    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>myfirends</title>" . $ctrl->{'htmlhead2'};

    print $sock $bookmark;
    print $sock "<p><a href=\"/ls.htm?path=$ctrl->{'workdir'}pub/nopw/\">dir nopw</a><p>\n";

    print $sock $ctrl->{'htmlfoot'};
}


\%config;
