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
        $form->{'start'} = 1;
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
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<p>\n";
#   print $sock "Path: <a href=\"/ls.htm?path=$path\">$path</a><p>\n";

    $mime = '';
    if (-f $path) {
        # it's a local file
            if (($path =~ /\.jpeg$/i) ||
                ($path =~ /\.jpg$/i)) {
            $mime = "image/jpeg";
        } elsif ($path =~ /\.pdf$/i) {
            $mime = "application/pdf";
        } elsif ($path =~ /\.kmz$/i) {
            $mime = "application/vnd.google-earth.kml+xml";
        } elsif ($path =~ /\.kml$/i) {
            $mime = "application/vnd.google-earth.kml+xml";
        } elsif ($path =~ /\.wma$/i) {
            $mime = "audio/x-ms-wma";
        } elsif ($path =~ /\.wav$/i) {
            $mime = "audio/wav";
        } elsif ($path =~ /\.3gp$/i) {
            $mime = "audio/3gp";
        } elsif ($path =~ /\.mp3$/i) {
            $mime = "audio/mpeg";
        } elsif ($path =~ /\.m4a$/i) {
            $mime = "video/m4a";
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
                    if ($mime eq '') {
                        $ctrl->{'droid'}->startActivity("android.intent.action.VIEW", "file://$path");
                    } else {
                        $ctrl->{'droid'}->startActivity("android.intent.action.VIEW", "file://$path", $mime);
                    }
                } else {
                    $ctrl->{'droid'}->startActivity("android.intent.action.VIEW", "$path");
                }
            }
        } elsif ($ctrl->{'os'} eq 'tmx') {
            if ($path ne '') {
                if (-f $path) {
                    if ($mime eq '') {
                        `am start -n com.termux/.app.TermuxActivity 1> /dev/null 2> /dev/null ; am start -a "android.intent.action.VIEW" -d "file://$path"`;
                    } else {
                        `am start -n com.termux/.app.TermuxActivity 1> /dev/null 2> /dev/null ; am start -a "android.intent.action.VIEW" -d "file://$path" -t "$mime"`;
                    }
                } else {
                    `am start -n com.termux/.app.TermuxActivity 1> /dev/null 2> /dev/null ; am start -a "android.intent.action.VIEW" -d "$path"`;
                }
            }
        } elsif ($ctrl->{'os'} eq 'win') {
            if ($path ne '') {
                $path =~ s/\//\\/g;
                `cmd /c start \"\" \"$path\"`;
            }
        } elsif ($ctrl->{'os'} eq 'cyg') {
            if ($path ne '') {
                `cmd /c start \"\" \"$path\"`;
            }
        }
    }

    if (defined ($form->{'startlocal'})) {
        if ($ctrl->{'os'} eq 'and') {
            if ($localurl ne '') {
                if (-f $localurl) {
                    if ($mime eq '') {
                        $ctrl->{'droid'}->startActivity("android.intent.action.VIEW", "file://$path");
                    } else {
                        $ctrl->{'droid'}->startActivity("android.intent.action.VIEW", "file://$path", $mime);
                    }
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
    print $sock "<input type=\"submit\" name=\"start\" value=\"S&#818;tart\" accesskey=\"s\">\n";
    print $sock "<input type=\"text\" size=\"16\" name=\"path\" value=\"$path\" accesskey=\"e\"><p>\n";
    if ($localurl ne '') {
        print $sock "<input type=\"submit\" name=\"startlocal\" value=\"Start local\">\n";
        print $sock "<input type=\"text\" size=\"16\" name=\"localurl\" value=\"$localurl\"><p>\n";
    }
    print $sock "<input type=\"submit\" name=\"paste\" value=\"P&#818;aste CB\" accesskey=\"p\">\n";
    print $sock "</form>\n";

    print $sock "$htmlout<p>\n";

    if (-d $path) {
        # local dir
        print $sock &l00wikihtml::wikihtml ($ctrl, '', "ls: [[/ls.htm?path=$path|$path]]", 0);
    } elsif (-f $path) {
        # local file
        print $sock &l00wikihtml::wikihtml ($ctrl, '', " [[/launcher.htm?path=$path|Launcher]] : [[/ls.htm?path=$path|$path]]", 0);
    } else {
        print $sock &l00wikihtml::wikihtml ($ctrl, '', " [[/launcher.htm?path=$path|Launcher]] : [[/ls.htm?path=$path|$path]]", 0);
    }

    print $sock $ctrl->{'htmlfoot'};
}


\%config;
