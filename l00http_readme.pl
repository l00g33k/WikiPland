use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple bookmark

my $bookmark;

my %config = (proc => "l00http_readme_proc",
              desc => "l00http_readme_desc");

sub l00http_readme_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    $bookmark = 
    " 1: readme: -> ".
    "<a href=\"/ls.htm/l00httpd__readme.htm?path=$ctrl->{'plpath'}docs_demo/l00httpd__readme.txt\">l00httpd__readme.txt</a> ";
        
    # Descriptions to be displayed in the list of modules table
    $bookmark;
}

sub l00http_readme_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket

    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>readme</title>" . $ctrl->{'htmlhead2'};

    print $sock $bookmark;

    print $sock $ctrl->{'htmlfoot'};
}


\%config;
