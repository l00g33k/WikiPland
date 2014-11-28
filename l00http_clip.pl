use strict;
use warnings;
use l00wikihtml;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Copy to Android clipboard

my %config = (proc => "l00http_clip_proc",
              desc => "l00http_clip_desc");

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
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>l00httpd</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<br>\n";

    $clip = "";
    if (defined ($form->{'clear'})) {
	    # clears
    } elsif (defined ($form->{'append'})) {
        $clip = $form->{'clip'};
        if ($ctrl->{'os'} eq 'and') {
            $tmp = $ctrl->{'droid'}->getClipboard();
            $tmp = $tmp->{'result'};
            $clip .= $tmp;
        }
    } elsif (defined ($form->{'clip'})) {
        $clip = $form->{'clip'};
        if (defined ($form->{'update'})) {
            print $sock "<br>Also copied to <a href=\"/launcher.htm?path=l00://clip\">l00://clip</a><p>\n";
            &l00httpd::l00fwriteOpen($ctrl, 'l00://clip');
            &l00httpd::l00fwriteBuf($ctrl, $clip);
            &l00httpd::l00fwriteClose($ctrl);
            if ($ctrl->{'os'} eq 'and') {
                $ctrl->{'droid'}->setClipboard ($clip);
            }
            if ($ctrl->{'os'} eq 'win') {
                `echo $clip | clip`;
                print $sock "<br>Copied to Windows clipboard using clip.exe\n";
            }
        } elsif (defined ($form->{'link'})) {
            # send text [[/clip.pl?...|show text]] to clipboard
            if ($clip =~ /^\s*(\S+ +\S+)/)  {
                $words = $1;
            } else {
                $words = 'more..';
            }
            $tmp = &l00httpd::urlencode ($clip);
            $tmp = sprintf ("[[/clip.htm?update=Copy+to+clipboard&clip=%s|%s]]", $tmp, $words);
            printf $sock ("Sent:<br><pre>%s</pre>to clipboard.\n", $tmp);
            if ($ctrl->{'os'} eq 'and') {
                $ctrl->{'droid'}->setClipboard ($tmp);
            }
            if ($ctrl->{'os'} eq 'win') {
                `echo tmp | clip`;
                print $sock "<br>Copied to Windows clipboard using clip.exe<br>\n";
            }
            $tmp = &l00httpd::urlencode ($tmp);
            printf $sock ("View in <a href=\"/clip.htm?update=Copy+to+clipboard&clip=%s\">clip.htm</a><p>\n", $tmp);
        }
    }

    print $sock "<form action=\"/clip.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"update\" value=\"Copy to CB\"> \n";
    print $sock "<input type=\"submit\" name=\"append\" value=\"Append\"> \n";
    print $sock "<input type=\"submit\" name=\"clear\" value=\"Clear\">\n";
    if (defined ($form->{'clip'}) && defined ($form->{'update'})) {
        # we actually set clipboard
        # now present button to send text [[/clip.pl?...|show text]] to clipboard
        print $sock "<input type=\"submit\" name=\"link\" value=\"mk wiki\"><br>\n";
    } else {
        print $sock "<br>\n";
    }
    print $sock "<textarea name=\"clip\" cols=\"32\" rows=\"5\">$clip</textarea>\n";
    print $sock "</form>\n";

    print $sock "View <a href=\"/view.htm?path=l00://clip\">l00://clip</a>, \n";
    print $sock "<a href=\"/launcher.htm?path=l00://clip\">launcher</a>.\n";
    print $sock "<a href=\"/scratch.htm\">scratch</a>.<p>\n";

    print $sock "<p>\n";
    print $sock &l00wikihtml::wikihtml ($ctrl, "", $clip, 0);

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
