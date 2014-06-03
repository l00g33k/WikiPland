use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my %config = (proc => "l00http_periocalrem_proc",
              desc => "l00http_periocalrem_desc",
              perio => "l00http_periocalrem_perio");



sub l00http_periocalrem_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "periocalrem: Calendar reminder";
}


my($calremcnt);
$calremcnt = 0;

sub l00http_periocalrem_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} - <a href=\"/periocalrem.htm\">Refresh</a><br> \n";

    print $sock "Calendar reminder.\n";

    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_periocalrem_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition

printf ("    $calremcnt cal rem $ctrl->{'now_string'}\n");
if ($calremcnt++ > 10) {
    $calremcnt = 0;
    $ctrl->{'BANNER:periocalrem'} = '<center><font style=\"color:red;background-color:yellow\">periocalrem</font></center><br>';
} else {
    undef $ctrl->{'BANNER:periocalrem'};
}

    0;  # not a periodic task; just take advantage so we get call on page load
}


\%config;
