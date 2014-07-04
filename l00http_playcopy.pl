use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Allows a quick
# Makes it possible to play a local audio file with minimum 
# clicks and touches from a local wiki page
# The view method works great requiring only a single click
# but it requires a live data connection, won't work if
# you are travelling and don't have data roaming
# This works by having presviously set up the Music player
# to play a predefined playlist having a predefined song
# When you click the link, it copies the selected file 
# to the predefined file and then launch the Music player
# You just click to play


my %config = (proc => "l00http_playcopy_proc",
              desc => "l00http_playcopy_desc");


sub l00http_playcopy_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "playcopy: Play copied local audio files and launch Music";
}

sub l00http_playcopy_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($path, $type, $vol, $buf);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>playcopy</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<p>\n";

    if ($ctrl->{'os'} eq 'and') {
        if (defined ($form->{'midvol'})) {
            $ctrl->{'droid'}->setMediaVolume (6);
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

    print $sock "<form action=\"/playcopy.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";
    print $sock "        <tr>\n";
    print $sock "            <td>New vol:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"vol\" value=\"$vol\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"newvol\" value=\"Set vol\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"midvol\" value=\"Mid vol\"> <input type=\"submit\" name=\"maxvol\" value=\"Max vol\"></td>\n";
    print $sock "    </tr>\n";
    print $sock "</table>\n";
    print $sock "</form>\n";


    if (defined ($ctrl->{'playcopy'})) {
        if (defined ($form->{'path'})) {
            $path = $form->{'path'};
            if (-f $path) {
                $buf = "$ctrl->{'bbox'}cp $path $ctrl->{'playcopy'}";
                `$buf`;
                if (-f $ctrl->{'playcopy'}) {
                    #$app = $ctrl->{'droid'}->getLaunchableApplications();
                    #&dumphash ("app", $app);
                    print $sock "'$buf' and launching Music<p>\n";
                    if ($ctrl->{'os'} eq 'and') {
                        $ctrl->{'droid'}->launch("com.android.music.MusicBrowserActivity");
                    }
                } else {
                    print $sock "Target file '$ctrl->{'playcopy'}' does not exist<p>";
                }
            } else {
                print $sock "File '$path' does not exist<p>\n";
            }
        }
    } else {
        print $sock "'playcopy' not set in 'l00httpd.cfg'"; 
    }

    print $sock "<p>Go to ls.pl, set \"'Size' send to'\" to 'playcopy', then click the file you want to play\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
