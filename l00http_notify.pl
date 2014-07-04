use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Put a notification on the notification bar

my $title = 'l00 Notify';
my $msg = '';
my %config = (proc => "l00http_notify_proc",
              desc => "l00http_notify_desc");

sub l00http_notify_set {
    my ($ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($ttl, $msg);

    if (open (IN, "<$ctrl->{'workdir'}/l00_notify.txt")) {
        $ttl = '';
        $msg = '';
        while (<IN>) {
            s/\r//g;
            s/\n//g;
            if (/^TTL:(.+)/) {
                $ttl = $1;
            }
            if (/^MSG:(.+)/) {
                $msg = $1;
            }
            if (($ttl ne '') && ($msg ne '')) {
                if ($ctrl->{'os'} eq 'and') {
                    $ctrl->{'droid'}->notify ($msg, $ttl);
                }
                $ttl = '';
                $msg = '';
            }
        }
        close (IN);
    }
}

sub l00http_notify_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/

    &l00http_notify_set ($ctrl);

    "notify: Put Notification on the bar Notification ";
}

sub l00http_notify_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my $stt;
    my $msgsub;

    $msg = '';
    if (defined ($form->{'repost'})) {
        &l00http_notify_set ($ctrl);
    }
    if (defined ($form->{'title'})) {
        $title = $form->{'title'};
    }
    if (defined ($form->{'msg'})) {
        $msg = $form->{'msg'};
    }
    if ((defined ($form->{'paste'})) && ($ctrl->{'os'} eq 'and')) {
        $msg = $ctrl->{'droid'}->getClipboard()->{'result'};
    }
    if ((defined ($form->{'pasteset'})) && ($ctrl->{'os'} eq 'and')) {
        $msg = $ctrl->{'droid'}->getClipboard()->{'result'};
        $form->{'submit'} = 'x'; # fake paste then submit
    }
    if (defined ($form->{'speech'})) {
        if ($ctrl->{'os'} eq 'and') {
            $stt = $ctrl->{'droid'}->recognizeSpeech ();
            $msg = $stt->{'result'};
        }
    }
    if (defined ($form->{'submit'})) {
        $msgsub = $msg;
        $msgsub =~ s/\r/ /g;
        $msgsub =~ s/\n/ /g;
        $msg = '';
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>notify</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} ";
    print $sock "<a href=\"/notify.htm\">Notify</a> \n";
    print $sock "<a href=\"/ls.htm?path=$ctrl->{'workdir'}l00_notify.txt\">$ctrl->{'workdir'}l00_notify.txt</a>:<p>";

    print $sock "<form action=\"/notify.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Title:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"title\" value=\"$title\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Message:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"msg\" value=\"$msg\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
#   print $sock "        <td><input type=\"submit\" name=\"paste\" value=\"PasteSet\"> <input type=\"submit\" name=\"speech\" value=\"Speech2Txt\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"pasteset\" value=\"PasteSet\"></td>\n";
    print $sock "        <td valign=\"top\"><input type=\"submit\" name=\"submit\" value=\"Set\"> <input type=\"submit\" name=\"paste\" value=\"Paste\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "<p><input type=\"submit\" name=\"repost\" value=\"Re-post\">\n";
    print $sock "</form>\n";

    if (defined ($form->{'submit'})) {
        if ($ctrl->{'os'} eq 'and') {
            $ctrl->{'droid'}->notify ($msgsub, $title);
        }
        # get submitted name and print greeting
        print $sock "<p>Sent Notification:<br>Title= $title<br>Message= $msgsub<p>\n";
        if (open (OU, ">>$ctrl->{'workdir'}/l00_notify.txt")) {
            print OU "TTL:$title\nMSG:$msgsub\n";
            close (OU);
        }
    }

    if (open (IN, "<$ctrl->{'workdir'}/l00_notify.txt")) {
        while (<IN>) {
            if (/^TTL:/) {
                print $sock "<pre>\n$_</pre>\n";
            } else {
                print $sock "$_\n";
            }
        }
        close (IN);
    }
    

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
