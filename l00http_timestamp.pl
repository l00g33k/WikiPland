use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Copy to Android clipboard

my %config = (proc => "l00http_timestamp_proc",
              desc => "l00http_timestamp_desc");

sub l00http_timestamp_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "timestamp: copy to clipboard";
}

sub l00http_timestamp_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $timestamp);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>timestamp</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<br>\n";

    $timestamp = "$ctrl->{'now_string'} ";
    &l00httpd::l00setCB($ctrl, $timestamp);

    print $sock "<br><form action=\"/timestamp.htm\" method=\"get\">\n";
    print $sock "<input type=\"text\" size=\"20\" name=\"timestamp\" value=\"$timestamp\">\n";
    print $sock "<p><input type=\"submit\" name=\"update\" value=\"New time\"><br>\n";
    #print $sock "<input type=\"radio\" name=\"mode\" value=\"format1\">Format 1:20100926 190321 <br>\n";
    #print $sock "<input type=\"radio\" name=\"mode\" value=\"format2\">Format 2:?? <br>\n";
    print $sock "</form>\n";

    print $sock "'$timestamp' copied to clipboard<br>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
