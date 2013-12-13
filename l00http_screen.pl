use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Set screen brightness


my %config = (proc => "l00http_screen_proc",
              desc => "l00http_screen_desc");


sub l00http_screen_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "screen: Set screen brightness";
}

sub l00http_screen_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($path, $type, $vol, $ii);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>screen</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a><p>\n";

    if ($ctrl->{'os'} eq 'and') {
        if (defined ($form->{'setmax'})) {
            $ctrl->{'droid'}->setScreenBrightness (255);
        } elsif (defined ($form->{'setmin'})) {
            $ctrl->{'droid'}->setScreenBrightness (0);
        } elsif (defined ($form->{'bright'})) {
            $ctrl->{'droid'}->setScreenBrightness ($form->{'bright'});
        } elsif (defined ($form->{'-10'})) {
            $vol = $ctrl->{'droid'}->getScreenBrightness ();
            $vol = $vol->{'result'} - 10;
            $ctrl->{'droid'}->setScreenBrightness ($vol);
        } elsif (defined ($form->{'+10'})) {
            $vol = $ctrl->{'droid'}->getScreenBrightness ();
            $vol = $vol->{'result'} + 10;
            $ctrl->{'droid'}->setScreenBrightness ($vol);
        }
        $vol = $ctrl->{'droid'}->getScreenBrightness ();
        $vol = $vol->{'result'};
        # reset to selected brightness (Slide lost screen brightness after camera)
        $ctrl->{'screenbrightness'} = $vol;
    } else {
        $vol = 'N/A';
    }

    print $sock "<form action=\"/screen.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";
    print $sock "        <tr>\n";
    print $sock "            <td>New brightness:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"bright\" value=\"$vol\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"setbright\" value=\"Set brightness\"></td>\n";
    print $sock "        <td>0 - 255</td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"setmax\" value=\"Max brightness\"></td>\n";
    print $sock "        <td>255</td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"setmin\" value=\"Min  brightness\"></td>\n";
    print $sock "        <td>0</td>\n";
    print $sock "    </tr>\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"+10\" value=\"+10\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"-10\" value=\"-10\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    for ($ii = 0; $ii < 15; $ii++) {
        print $sock "&nbsp;<p>\n";
    }

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
