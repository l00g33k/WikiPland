
use strict;
use warnings;
use IO::Socket;
use IO::Select;
use l00wget;
use l00httpd;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# wget clone to download target

my %config = (proc => "l00http_clipbrdxfer_proc",
              desc => "l00http_clipbrdxfer_desc");
my ($url, $name, $pw);
$url = "127.0.0.1:50337";
$name = 'p';
$pw = 'p';

sub l00http_clipbrdxfer_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "clipbrdxfer: Transfer clipboard between 2 WikiPland servers";
}


sub l00http_clipbrdxfer_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($buf, $tmp, $geturl);
    my ($hdr, $bdy);


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>clipbrdxfer</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<br>\n";

    if (defined ($form->{'url'})) {
        $url = $form->{'url'}
    }
    if (defined ($form->{'name'})) {
        $name = $form->{'name'}
    }
    if (defined ($form->{'pw'})) {
        $pw = $form->{'pw'}
    }

    print $sock "<form action=\"/clipbrdxfer.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";
    print $sock "        <tr>\n";
    print $sock "            <td>Server ip:port:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"url\" value=\"$url\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Name:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"name\" value=\"$name\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Password:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"pw\" value=\"$pw\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Send Clipboard\"></td>\n";
    print $sock "        <td><input type=\"checkbox\" name=\"nofetch\">Don't fetch; generate URL</td>\n";
    print $sock "    </tr>\n";
    print $sock "</table>\n";
    print $sock "</form>\n";

    if (defined ($form->{'submit'})) {
	    $tmp = '';
		if ($ctrl->{'os'} eq 'and') {
            $buf = &l00httpd::l00getCB($ctrl);
            $tmp = &l00httpd::urlencode ($buf);
            $tmp = "clip.htm?update=Copy+to+clipboard&clip=$tmp";
        }
		$geturl = "http://$url/$tmp";
        if ((!defined ($form->{'nofetch'})) ||
            ($form->{'nofetch'} ne 'on')) {
            l00httpd::dbp($config{'desc'}, "Fetching '$geturl'\n");
            #print $sock "<br>Fetching '$geturl'<br>\n";

            if (($name ne '') || ($pw ne '')) {
                ($hdr, $bdy) = &l00wget::wget ($geturl, "$name:$pw");
            } else {
                ($hdr, $bdy) = &l00wget::wget ($geturl);
            }

            if (defined ($hdr)) {
                print $sock "<p>Header length ",length($hdr), " bytes<br>\n";
                print $sock "Body length ",length($bdy), " bytes<br>\n";
                print $sock "<br>Pushing:<pre>$buf</pre>\n";

                print $sock "<p><pre>$hdr</pre>\n";
                $bdy =~ s/</&lt;/g;
                $bdy =~ s/>/&gt;/g;
                print $sock "<pre>$bdy</pre>\n";
            } else {
                print $sock "<p>Failed to push clipboard content to $url<p>\n";
                print $sock "<br>Pushing:<pre>$buf</pre>\n";
            }
        } else {
            print $sock "<p>Failed to fetch '$geturl'\n";
            print $sock "<br>Pushing:<pre>$buf</pre>\n";
        }
    }


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
