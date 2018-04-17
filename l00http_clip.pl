use strict; use warnings;
use l00wikihtml;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Copy to Android clipboard

my %config = (proc => "l00http_clip_proc",
              desc => "l00http_clip_desc");

my ($url);
$url = '';

sub l00http_clip_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    " A: clip: Copy to Android clipboard";
}

sub l00http_clip_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $clip, $tmp, $words);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>clip</title>";
    if (defined ($form->{'update'}) && defined ($form->{'url'})) {
        $url = $form->{'url'};
    }
    if (($url ne '') && (defined ($form->{'jumpurl'}))) {
        # fake a 'Save' click
        $form->{'update'} = 1;
        # and setup redirect after we have saved
        print $sock "<meta http-equiv=\"refresh\" content=\"0; url=$url\">";
    }
    print $sock $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
    print $sock "Go to <a href=\"/scratch.htm\">scratch</a> - \n";
    print $sock "<a href=\"/httpd.htm#ram\">RAM files</a><br>\n";

    $clip = '';
    if (defined ($form->{'clear'})) {
        # clears
        $form->{'clip'} = '';
    }
    if (defined ($form->{'append'})) {
        $clip = $form->{'clip'};
        $clip .= &l00httpd::l00getCB($ctrl);
    } elsif (defined ($form->{'clip'})) {
        $clip = $form->{'clip'};
        if (defined ($form->{'update'})) {
            print $sock "<br>Also copied to <a href=\"/view.htm?path=l00://clipboard.txt\">l00://clipboard.txt</a>. \n";
            $tmp = &l00httpd::urlencode ($clip);
            print $sock "Send to server <a href=\"http://127.0.0.1:20337/clip.htm?update=update&clip=$tmp\" target=\"_blank\">20337</a><p>\n";
            &l00httpd::l00setCB($ctrl, $clip);
                if (defined ($form->{'url'})) {
                    # clears
                    $url = $form->{'url'};
                }
        } elsif (defined ($form->{'link'})) {
            # send text [[/clip.pl?...|show text]] to clipboard
            if ($clip =~ /^\s*(\S+ +\S+)/)  {
                $words = $1;
            } else {
                $words = 'more..';
            }
            $tmp = &l00httpd::urlencode ($clip);
            $tmp = sprintf ("* [[/clip.htm?update=Copy+to+clipboard&clip=%s|%s]]", $tmp, $words);
            printf $sock ("Sent:<p><i>%s</i><p>to clipboard.\n", $tmp);
#           printf $sock ("Sent:<br><pre>%s</pre>to clipboard.\n", $tmp);
            &l00httpd::l00setCB($ctrl, $tmp);
            $tmp = &l00httpd::urlencode ($tmp);
            printf $sock ("View in <a href=\"/clip.htm?update=Copy+to+clipboard&clip=%s\">clip.htm</a><p>\n", $tmp);
        }
    }

    print $sock "<form action=\"/clip.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"update\" value=\"C&#818;opy to CB\" accesskey=\"c\"> \n";
    print $sock "<input type=\"submit\" name=\"append\" value=\"A&#818;ppend\" accesskey=\"a\"> \n";
    print $sock "<input type=\"submit\" name=\"clear\" value=\"Cl&#818;ear\" accesskey=\"l\">\n";

    if (defined ($form->{'clip'}) && defined ($form->{'update'})) {
        # we actually set clipboard
        # now present button to send text [[/clip.pl?...|show text]] to clipboard
        print $sock "<input type=\"submit\" name=\"link\" value=\"mk wiki\"><br>\n";
    } else {
        print $sock "<br>\n";
    }
    print $sock "<textarea name=\"clip\" cols=\"32\" rows=\"5\" accesskey=\"e\">$clip</textarea>\n";
    print $sock "<br>Jump URL: <input type=\"text\" size=\"10\" name=\"url\" value=\"$url\">\n";

    print $sock "View <a href=\"/view.htm?path=l00://clipboard.txt\">l00://clipboard.txt</a>, \n";
    print $sock "<a href=\"/launcher.htm?path=l00://clipboard.txt\">launcher</a>.\n";
    if (($ctrl->{'os'} eq 'win') || ($ctrl->{'os'} eq 'cyg') || ($ctrl->{'os'} eq 'and')) {
        print $sock "<a href=\"/activity.htm?paste=yes\">Activity</a>.\n";
    }
    if ($url ne '') {
        print $sock "<br><input type=\"submit\" name=\"jumpurl\" value=\"2CB&URL\"> \n";
        print $sock "<a href=\"$url\">$url</a>.\n";
    }
    print $sock "</form>\n";
    print $sock "<p>\n";

    print $sock "<p>\n";
    print $sock &l00wikihtml::wikihtml ($ctrl, "", $clip." <p><p>", 0);

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
