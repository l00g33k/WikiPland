use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Play local audio files


my %config = (proc => "l00http_play_proc",
              desc => "l00http_play_desc");


sub l00http_play_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "play: Play local audio files";
}

sub l00http_play_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($path, $type, $vol);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>play</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}\n";
    print $sock "<a href=\"/screen.pl\">Brightness</a><p>\n";

    if ($ctrl->{'os'} eq 'and') {
        if (defined ($form->{'midvol'})) {
            $ctrl->{'droid'}->setMediaVolume (0);
        }
        if (defined ($form->{'maxvol'})) {
            $ctrl->{'droid'}->setMediaVolume (15);
        }
        if ((defined ($form->{'newvol'})) &&
            (defined ($form->{'vol'}))) {
            $ctrl->{'droid'}->setMediaVolume ($form->{'vol'});
        }
        $vol = $ctrl->{'droid'}->getMediaVolume ();
        $vol = $vol->{'result'};
    } else {
        $vol = 'N/A';
    }

    print $sock "<form action=\"/play.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";
    print $sock "        <tr>\n";
    print $sock "            <td>New vol:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"vol\" value=\"$vol\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"newvol\" value=\"Set vol\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"midvol\" value=\"Mute\"> <input type=\"submit\" name=\"maxvol\" value=\"Max vol\"></td>\n";
    print $sock "    </tr>\n";
    print $sock "</table>Vol: \n";
    for ($vol = 0; $vol < 16; $vol++) {
        print $sock "<a href=\"/play.htm?vol=$vol&newvol=Set+vol\">=$vol</a>\n";
    }
    print $sock "</form>\n";


    if (defined ($form->{'path'})) {
        $path = $form->{'path'};
        if (open (IN, "<$path")) {
            close (IN);
            $type = '';
                if ($path =~ /\.wav$/) {
                $type = 'audio/wav';
            }
            if ($path =~ /\.3gp$/) {
                $type = 'audio/3pg';
            }
            if ($path =~ /\.mp3$/) {
                $type = 'audio/mp3';
            }
            if ($path =~ /\.m4a$/) {
                $type = 'audio/m4a';
            }
            if ($path =~ /\.wma$/) {
                $type = 'audio/x-ms-wma';
            }
            if ($ctrl->{'os'} eq 'and') {
                if ($type eq '') {
                    $ctrl->{'droid'}->view ('file://'.$path); 
                } else {
                    $ctrl->{'droid'}->view ('file://'.$path, $type); 
                }
            }
        }
        print $sock "Playing '$path', type '$type'<p>\n";
    }

    print $sock "<p>Go to ls.pl, set \"'Size' send to'\" to 'play', then click the file you want to play\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
