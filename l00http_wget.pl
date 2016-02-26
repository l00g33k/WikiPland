use strict;
use warnings;
use IO::Socket;
use IO::Select;
use l00wget;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# wget clone to download target

my %config = (proc => "l00http_wget_proc",
              desc => "l00http_wget_desc");
my ($wgetpath, $url);
$url = "http://www.google.com";

sub l00http_wget_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    " B: wget: wget clone to download target";
}


sub l00http_wget_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($fname, $buf);
    my ($server_socket, $cnt, $hdrlen, $bdylen, $hdr, $bdy);
    my ($readable, $ready, $curr_socket, $ret, $mode);
    my ($chunksz, $host, $port, $path, $contlen);
    my ($name, $pw, $followmoves, $moved, $domain);

    $mode = '';

    if (!defined ($wgetpath)) {
        $wgetpath = "l00://wget.htm";
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>wget</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<br>\n";

    if (defined ($form->{'wgetpath'})) {
        $wgetpath = $form->{'wgetpath'}
    }
    if (defined ($form->{'default'})) {
        $wgetpath = "l00://wget.htm";
    }
    if (defined ($form->{'url'})) {
        $url = $form->{'url'}
    }
    if (defined ($form->{'pastepath'})) {
        $wgetpath = &l00httpd::l00getCB($ctrl);
    }
    if (defined ($form->{'paste'})) {
        $url = &l00httpd::l00getCB($ctrl);
        if ($url =~ /(https*:\/\/[^ \n\r\t]+)/) {
            $url = $1;
        }
        if (!($url =~ /https*:\/\//)) {
            # Opera Mini does not include http://
            $url = "http://$url";
        }
        print $sock "URL from clipboard:<br>$url<br>\n";
    }
    if (defined ($form->{'name'})) {
        $name = $form->{'name'}
    } else {
        $name = '';
    }
    if (defined ($form->{'pw'})) {
        $pw = $form->{'pw'}
    } else {
        $pw = '';
    }

    print $sock "<form action=\"/wget.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";
    print $sock "        <tr>\n";
    print $sock "            <td>URL:<input type=\"submit\" name=\"paste\" value=\"CB\"></td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"url\" value=\"$url\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td><input type=\"submit\" name=\"pastepath\" value=\"Save\">path";
    print $sock "<input type=\"submit\" name=\"default\" value=\":\"></td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"wgetpath\" value=\"$wgetpath\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Name:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"name\" value=\"\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "        <tr>\n";
    print $sock "            <td>Password:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"pw\" value=\"\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Fetch URL\"></td>\n";
    print $sock "        <td><input type=\"checkbox\" name=\"nofetch\">Don't fetch; generate URL</td>\n";
    print $sock "    </tr>\n";
    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "<br>Prepend 'proxy:proxy_host:proxy_port' to use HTTP proxy server<br>\n";
    print $sock "e.g. proxy:127.0.0.1:8118:http://www.google.com<br>\n";

    if (defined ($form->{'submit'})) {
       if ((!defined ($form->{'nofetch'})) ||
           ($form->{'nofetch'} ne 'on')) {
            print $sock "Fetching '$url'<br>\n";
            print $sock "<a href=\"/ls.htm?path=$wgetpath\">$wgetpath</a> - \n";
            print $sock "<a href=\"/view.htm?path=$wgetpath\">view $wgetpath</a> - ";
            print $sock "<a href=\"/view.htm?path=l00%3A%2F%2Fwget.hdr\">l00://wget.hdr</a><br>\n";
            print $sock "<a href=\"/launcher.htm?path=$wgetpath\">launcher $wgetpath</a><br>\n";
            print $sock "If you don't see 'Header length' and 'Body length' below, the host may be off-line.<br>\n";

            # 10 follows limit for fail safe
            print $sock "<p>\n";
            for ($followmoves = 0; $followmoves < 10; $followmoves++) {
                print $sock "Pass #$followmoves: <a href=\"$url\">$url</a><br>\n";

                $domain = '';
                if ($url =~ /http:\/\/([^\/]+?)\//) {
                    $domain = $1;
                }
                if (($name ne '') || ($pw ne '')) {
                    ($hdr, $bdy) = &l00wget::wget ($url, "$name:$pw");
                } else {
                    ($hdr, $bdy) = &l00wget::wget ($url);
                }

                # Find HTTP return code
                $moved = '';
                foreach $_ (split("\n", $hdr)) {
                    if (($moved eq '') && (/^HTTP.* 301 /)) {
                        print $sock " 301 moved, \n";
                        $moved = 'moved';
                    }
                    if (($moved eq 'moved') && (/^location: +(.+)/i)) {
                        $url = $1;
                        if (!($url =~ /^http:\/\//)) {
                            $url = "http://$domain$url";
                        }
                        $moved = 'found';
                        print $sock " to: $url<p>\n";
                    }
                }
                if ($moved ne 'found') {
                    # didn't move, last fetch
                    $followmoves = 100;
                }

                if (defined ($hdr)) {
                    print $sock "Header length ",length($hdr), " bytes<br>\n";
                    print $sock "Body length ",length($bdy), " bytes<br>\n";

                    print $sock "<p><pre>$hdr</pre>\n";
                    if (&l00httpd::l00fwriteOpen($ctrl, 'l00://wget.hdr')) {
                        &l00httpd::l00fwriteBuf($ctrl, "$hdr");
                        &l00httpd::l00fwriteClose($ctrl);
                    }
                    if (&l00httpd::l00fwriteOpen($ctrl, $wgetpath)) {
                        &l00httpd::l00fwriteBuf($ctrl, "$bdy");
                        &l00httpd::l00fwriteClose($ctrl);
                        $bdy = substr($bdy, 0, 2000);
                        $bdy =~ s/</&lt;/g;
                        $bdy =~ s/>/&gt;/g;
                        print $sock "<hr>\n";
                        print $sock "<p>Fisrt 2000 bytes of body<p>\n";
                        print $sock "<pre>$bdy</pre>\n";
                    }
                }
            }
        } else {
            print $sock "<p>Failed to fetch '$url'\n";
        }
    }



    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
