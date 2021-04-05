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
    "A: timestamp: copy to clipboard";
}

my (@date2name);

@date2name = (
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun'
);

sub l00http_timestamp_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $timestamp, $clipdate);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>timestamp</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<br>\n";

    $timestamp = "$ctrl->{'now_string'} ";
    $clipdate = "WAL - ".
                substr($timestamp,0,4).'/'.
                substr($timestamp,4,2).'/'.
                substr($timestamp,6,2).' '.
                substr($timestamp,9,2).':'.
                substr($timestamp,11,2).':'.
                substr($timestamp,13,2).' '.
                $date2name[$ctrl->{'now_day'}];

    print $sock "<br><form action=\"/timestamp.htm\" method=\"get\">\n";
    print $sock "<input type=\"text\" size=\"20\" name=\"timestamp\" value=\"$timestamp\">\n";
    print $sock "<p><input type=\"submit\" name=\"update\" value=\"N&#818;ew time\" accesskey=\"n\">\n";
    #print $sock "<input type=\"radio\" name=\"mode\" value=\"format1\">Format 1:20100926 190321 <br>\n";
    #print $sock "<input type=\"radio\" name=\"mode\" value=\"format2\">Format 2:?? <br>\n";
    print $sock "<input type=\"submit\" name=\"clipdate\" value=\"C&#818;lipdate\" accesskey=\"c\"><br>\n";
    print $sock "</form>\n";

    print $sock "<code>$timestamp</code><br>\n";
    print $sock "<code>$clipdate</code><br>\n";
    print $sock "<br>\n";

    if (defined($ctrl->{'FORM'}->{'clipdate'})) {
        &l00httpd::l00setCB($ctrl, $clipdate);
        print $sock "'$clipdate' copied to clipboard<br>\n";
    } else {
        &l00httpd::l00setCB($ctrl, $timestamp);
        print $sock "'$timestamp' copied to clipboard<br>\n";
    }

    # echo -n "$(date +'WAL - %Y/%m/%d %H:%M:%S %a')" > /dev/clipboard
    print $sock "bash command:<br><code>echo -n \"\$(date +'WAL - \%Y/\%m/\%d \%H:\%M:\%S \%a')\" > /dev/clipboard</code><br>\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
