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
    " A: activity: Android startActivity";
}

sub l00http_activity_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($path, $htmlout, $localurl, $mime);

    $htmlout = '';
    $localurl = '';

    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
    } else {
        $path = '';
    }

    if (defined ($form->{'paste'})) {
        $path = &l00httpd::l00getCB($ctrl);
    }

    # extract URL
    if ($path =~ /(https*:\/\/\S+)/) {
        $path = $1;
        if ($path =~ /http:\/\/(localhost|127\.0\.0\.1):\d+(\/.*)/) {
            $localurl = $2;
            $htmlout = "<p>local server: <a href=\"$localurl\">$localurl</a><p>\n";
        }
    }


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>Android startActivity</title>" .$ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<br>\n";
    print $sock "Path: <a href=\"/ls.htm?path=$path\">$path</a><p>\n";

    $mime = '';
    if (-f $path) {
        # it's a local file
            if (($path =~ /\.jpeg$/i) ||
                ($path =~ /\.jpg$/i)) {
            $mime = "image/jpeg";
        } elsif ($path =~ /\.wma$/i) {
            $mime = "audio/x-ms-wma";
        } elsif ($path =~ /\.3gp$/i) {
            $mime = "audio/3gp";
        } elsif ($path =~ /\.mp3$/i) {
            $mime = "audio/mpeg";
        } elsif ($path =~ /\.mp4$/i) {
            $mime = "video/mpeg";
        } elsif ($path =~ /\.gif$/i) {
            $mime = "image/gif";
        } elsif ($path =~ /\.png$/i) {
            $mime = "image/png";
        }
    }
    if (defined ($form->{'start'})) {
        if ($ctrl->{'os'} eq 'and') {
            if ($path ne '') {
                if (-f $path) {
#                   $ctrl->{'droid'}->startActivity("android.intent.action.VIEW", "file://$path");
                    $ctrl->{'droid'}->startActivity("android.intent.action.VIEW", "file://$path", $mime);
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

    if (defined ($form->{'startlocal'})) {
        if ($ctrl->{'os'} eq 'and') {
            if ($localurl ne '') {
                if (-f $localurl) {
#                   $ctrl->{'droid'}->startActivity("android.intent.action.VIEW", "file://$path");
                    $ctrl->{'droid'}->startActivity("android.intent.action.VIEW", "file://$path", $mime);
                } else {
                    $ctrl->{'droid'}->startActivity("android.intent.action.VIEW", "$localurl");
                }
            }
        }
        if (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg')) {
            if ($localurl ne '') {
                `start \"$localurl\"`;
            }
        }
    }

    print $sock "<form action=\"/activity.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"start\" value=\"Start\">\n";
    print $sock "<input type=\"text\" size=\"16\" name=\"path\" value=\"$path\"><p>\n";
    if ($localurl ne '') {
        print $sock "<input type=\"submit\" name=\"startlocal\" value=\"Start local\">\n";
        print $sock "<input type=\"text\" size=\"16\" name=\"localurl\" value=\"$localurl\"><p>\n";
    }
    print $sock "<input type=\"text\" size=\"16\" name=\"path\" value=\"$path\"><p>\n";
    print $sock "<input type=\"submit\" name=\"paste\" value=\"Paste CB\">\n";
    print $sock "</form>\n";

    print $sock "$htmlout\n";

    print $sock $ctrl->{'htmlfoot'};
}


\%config;
