use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_twitter_proc",
              desc => "l00http_twitter_desc",
              perio => "l00http_twitter_perio");
my ($buf, $count, $id, $logpath, $results, $tmp);
my ($interval, $lastcalled, $fetches);
$interval = 0;
$lastcalled = 0;
$fetches = 0;
$results = 0;
        

sub l00http_twitter_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "twitter: Polling Twitter followers count";
}

sub l00http_twitter_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data

    # extrace parameters
    if (defined ($form->{"id"}) && (length ($form->{"id"}) > 1)) {
        $id = $form->{"id"};
    } else {
        $id = "";
    }
    if (defined ($form->{"interval"}) && ($form->{"interval"} >= 0)) {
        $interval = $form->{"interval"};
    } else {
        $interval = 0;
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>twitter</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} \n";

    print $sock "Twitter follower count pollster<br>\n";
    print $sock "Poll fetches: $fetches<br>\n";
    print $sock "Poll results: $results<br>\n";
    print $sock "<form action=\"/twitter.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Twitter ID:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"id\" value=\"$id\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Poll interval (sec):</td>\n";
    print $sock "            <td><input type=\"text\" size=\"6\" name=\"interval\" value=\"$interval\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Submit\"></td>\n";
    print $sock "        <td>&nbsp;</td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";


    if ($ctrl->{'os'} eq 'and') {
        $buf = `busybox tail $ctrl->{'workdir'}$id.log`;
    } else {
        $buf = `tail $ctrl->{'workdir'}$id.log`;
    }
    print $sock "tail <a href=\"/ls.htm?path=$ctrl->{'workdir'}$id.log\">$ctrl->{'workdir'}$id.log</a><br>\n<pre>\n$buf\n</pre>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_twitter_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition

    if (($interval > 0) && 
        (length ($id) > 1) &&
        (($lastcalled == 0) || (time >= ($lastcalled + $interval)))) {
        $fetches++;
        $lastcalled = time;
        $tmp = "$ctrl->{'workdir'}twitter.tmp";
        $logpath = $ctrl->{'workdir'};
        if ($ctrl->{'os'} eq 'and') {
            `busybox wget http://168.143.162.42/$id -q -O $tmp`;
        } else {
            `wget http://twitter.com/$id -q -O $tmp`;
        }
        if (open (IN, "<$tmp")) {
            while (<IN>) {
                print,  if ($ctrl->{'debug'} >= 5);
                #<span id="follower_count" class="stats_count numeric">28,935 </span>
                if ((/Followers:.*>([^<]+)</) || (/\"follower_count\".+>([0-9,]+)/)) {
                    $count=$1;
                    $count=~s/,//;
                    my $time_now = localtime;
                    print "$time_now,$count\n";
                    if (open (OUT, ">>$logpath$id.log")) {
                        print OUT "$time_now,$count\n";
                        $results++;
                        close (OUT);
                    }
                    last;
                }
            }
            close (IN);
        }
    }

    $interval;
}


\%config;
