use strict;
use warnings;

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
    my ($path);

    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
    } else {
        $path = '';
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>Android startActivity</title>" .$ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<br>\n";
    print $sock "Path: <a href=\"/ls.htm?path=$path\">$path</a><br>\n";

    if (defined ($form->{'paste'})) {
        $path = &l00httpd::l00getCB($ctrl);
    }

    # extract URL
    if ($path =~ /(https*:\/\/\S+)/) {
        $path = $1;
    }

    if (defined ($form->{'start'})) {
        if ($ctrl->{'os'} eq 'and') {
            if ($path ne '') {
                if (-f $path) {
                    $ctrl->{'droid'}->startActivity("android.intent.action.VIEW", "file://$path");
                } else {
                    $ctrl->{'droid'}->startActivity("android.intent.action.VIEW", "$path");
                }
            }
        }
        if (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
            if ($path ne '') {
                `start \"$path\"`;
            }
        }
    }

    print $sock "<form action=\"/activity.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"start\" value=\"Start\">\n";
    print $sock "<input type=\"text\" size=\"16\" name=\"path\" value=\"$path\"><p>\n";
    print $sock "<input type=\"submit\" name=\"paste\" value=\"Paste CB\">\n";
    print $sock "</form>\n";

    print $sock $ctrl->{'htmlfoot'};
}


\%config;
