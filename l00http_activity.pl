use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_activity_proc",
              desc => "l00http_activity_desc");


sub l00http_activity_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "activity: Android startActivity";
}

sub l00http_activity_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>Android startActivity</title>" .$ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<br>\n";
    print $sock "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";

    print $sock "<form action=\"/activity.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"start\" value=\"Start\">\n";
    print $sock "<input type=\"text\" size=\"16\" name=\"path\" value=\"$form->{'path'}\"><br>\n";
    print $sock "</form>\n";

    if (defined ($form->{'start'})) {
        if (($ctrl->{'os'} eq 'and') && 
            (defined ($form->{'path'})) && 
            (-f $form->{'path'})) {
            $ctrl->{'droid'}->startActivity("android.intent.action.VIEW", "file://$form->{'path'}");
        } else {
            print $sock "<p>Either the server is not Android or '$form->{'path'}' does not exist. Activity not started.\n";
        }
    }

}


\%config;
