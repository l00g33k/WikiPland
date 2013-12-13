use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple bookmark


my %config = (proc => "l00http_mobizoom_proc",
              desc => "l00http_mobizoom_desc");
my ($url, $zoom, $para, $here);
$url = '';
$zoom = 120;
$para = 1;

sub l00http_mobizoom_wget {
    my ($url, $zoom) = @_;
    my ($wget, $wget2, $pre, $gurl, $post, $hdr);

    $wget = '';
    if (length ($url) > 6) {
	    # mobilize:

	    #http://www.google.com/gwt/x?u=http%3A%2F%2Fwww.a.com
	    $url =~ s|:|%3A|g;
	    $url =~ s|/|%2F|g;
	    $url =~ s|(https*%3A%2F%2F[^ ]+)|http://www.google.com/gwt/x?u=$1&wsc=pb&ct=pg1&whp=30|g;

	    #print $sock "$url";

	    ($hdr, $wget) = &l00wget::wget ($url);
        $wget =~ s/<br\/><br\/>/\n<br\/><br\/>/g;
        $wget2 = '';
        foreach $_ (split("\n", $wget)) {
            s/<br\/><br\/>/<br\/><br\/><a name="__para$para\__"><\/a><small><a href="#__para$para\__">$para<\/a><\/small> /;
            $para++;
            $wget2 .= "$_\n";
        }
        $wget = $wget2;


        # remote various HTML tags
        $wget =~ s/<\/*html.*?>//gm;
        $wget =~ s/<\/*body.*?>//gm;
        $wget =~ s/<\/*span.*?>//gm;
        $wget =~ s/<\/*div.*?>//gm;

	    $wget =~ s/\r//g;
	    $wget =~ s/\n//g;
	    $wget =~ s/^.+<body.*?>\n//g;
	    $wget =~ s/<\/body.*$>\n//g;
	    $wget =~ s/^.+>(This page adapted for your browser comes from )/$1/g;  # cut off before This page adapted
	    $wget =~ s/<\/wml.*$>\n//g;

	    $wget = "<span style=\"font-size : $zoom%;\">$wget</span>";
    }

    $wget2 = $wget;
    $wget2 =~ s/</\n</g;
    $wget2 =~ s/>/>\n/g;


    $wget = '';
    foreach $_ (split ("\n", $wget2)) {
        if (($pre,$gurl,$post) = /(<.+?)='(\/gwt\/.+?)'(.*>)/) {
            if ($gurl =~ /^\/xxxxxxxgwt\//) {
                # test only
                # don't change
                $gurl =~ s/&/%26/g;
                $gurl =~ s/\?/%3F/g;
                $gurl = "/mobizoom.htm?zoom=$zoom&url=http://google.com$gurl";
            } elsif ($pre =~ /img +src/) {
                $gurl = "http://google.com$gurl";
            } else {
                # THIS CLAUSE MAKES IT WORK
                if ($gurl =~ /=(http.*?)(&amp;.*)$/) {
                    # extract original URL from Google's /gwt/ link
                    $gurl = $1.$2;
                    #print "$2\n";
                }
                $gurl =~ s|:|%3A|g;
                $gurl =~ s|/|%2F|g;
                $gurl =~ s/\?/%3F/g;
                $gurl =~ s/=/%3D/g;     # THIS CLAUSE MAKES IT WORK
                $gurl =~ s/&amp;/%26/g; # THIS CLAUSE MAKES IT WORK
                $gurl = "/mobizoom.htm?zoom=$zoom&url=$gurl";
            }
            $_ = "$pre='$gurl'$post";
        }
        $wget .= "$_\n";
    }

    $wget .= "<br>\n";
    $wget .= "<font style=\"color:black;background-color:lime\">\n";
    $wget .= "<a href=\"#__top__\">TOP</a>";
    $wget .= "</font>\n";
    $wget .= "<font style=\"color:black;background-color:lime\">\n";
    $wget .= "<a href=\"#__here".($here -1 ) ."__\">last</a>";
    $wget .= "</font>\n";
    $wget .= "<font style=\"color:black;background-color:lime\">\n";
    $wget .= "<a href=\"#__here$here\__\">here$here</a>";
    $wget .= "</font>\n";
    $wget .= "<font style=\"color:black;background-color:lime\">\n";
    $wget .= "<a href=\"#__here". ($here + 1) ."__\">next</a>";
    $wget .= "<a name=\"__here$here\__\"></a>\n";
	$here++;
    $wget .= "</font>\n";
    $wget .= "<font style=\"color:black;background-color:lime\">\n";
    $wget .= "<a href=\"#__end__\">END</a>";
    $wget .= "</font>\n";
    $wget .= "<br>\n";

    $wget;
}

sub l00http_mobizoom_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition

    # Descriptions to be displayed in the list of modules table
    " A: mobizoom: Allowing font zoom on Google Mobilizer results";
}

# mobizoom API:
# standard WikiPland module API: these are set by the form in the module:
#   $form->{'paste'}
#   $form->{'zoom'}
#   $form->{'zoomradio'}
#   $form->{'fetch'}
#   $form->{'url'} : this is dual use:
#       if http(s)://, then fetch
#       if a local file, then use its content instead of fetching
# direct API: these are set by reader.pl when invoking directly to download off-line cache:
#   $form->{'path'} : fetch and save web page to this file
#   $form->{'url'} : URL
#   $form->{'fetch'} : defined

sub l00http_mobizoom_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($wget, $getmore, $nextpage, $mobiurl, $mode1online2offline4download);

    $url = '';
    if (defined ($form->{'url'})) {
	    $url = $form->{'url'};
    }

    if (defined ($form->{'path'})) {
        $mode1online2offline4download = 4;
    } elsif (&l00httpd::readOpen($ctrl, $url)) {
        $mode1online2offline4download = 2;
        $wget = &l00httpd::readAll($ctrl);
    } else {
        $mode1online2offline4download = 1;
    }

    if ($mode1online2offline4download & 3) {
        # standard mode
        print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>Mobilizer Zoom</title>" . $ctrl->{'htmlhead2'};
        print $sock "<a name=\"__top__\"></a>\n";
        print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a> \n";
        print $sock "<a href=\"#__end__\">Jump to end</a><hr>\n";
	}

    if (defined ($form->{'zoom'})) {
	    if ($form->{'zoom'} =~ /(\d+)/) {
            # is a number (zoom %)
		    $zoom = $1;
	    }
    }
    if (defined ($form->{'zoomradio'})) {
        $zoom = $form->{'zoomradio'};
    }
    if (defined ($form->{'paste'}) && ($ctrl->{'os'} eq 'and')) {
        $url = $ctrl->{'droid'}->getClipboard()->{'result'};
		if (!($url =~ /^\//)) {
		    # extract URL only if it doesn't look like a local file
            if ($url =~ /(https*:\/\/[^ \n\r\t]+)/) {
                $url = $1;
            }
            if (!($url =~ /https*:\/\//)) {
                # Opera Mini does not include http://
                $url = "http://$url";
            }
        } else {
			# must be reading locally cached file
            $form->{'paste'} = undef;
            $form->{'fetch'} = 1;
            if (&l00httpd::readOpen($ctrl, $url)) {
                $mode1online2offline4download = 2;
                $wget = &l00httpd::readAll($ctrl);
			}
		}
        #print "From clipboard:\n$url\n", if ($ctrl->{'debug'} >= 3);
    }

    if ($url =~ /google\.com\/url\?.*&q=(http.+)[^&]/) {
        $url = $1;
    }


    if ($mode1online2offline4download & 3) {
    print $sock "<form action=\"/mobizoom.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"fetch\" value=\"Fetch\">\n";
    print $sock "URL:<input type=\"text\" size=\"16\" name=\"url\" value=\"$url\"></td>\n";
    print $sock "zoom:<input type=\"text\" size=\"3\" name=\"zoom\" value=\"$zoom\"></td>\n";
    if ($ctrl->{'os'} eq 'and') {
        print $sock "<input type=\"submit\" name=\"paste\" value=\"CB paste\">\n";
    }
    print $sock "<input type=\"radio\" name=\"zoomradio\" value=\"100\">100% ";
    print $sock "<input type=\"radio\" name=\"zoomradio\" value=\"110\">110% ";
    print $sock "<input type=\"radio\" name=\"zoomradio\" value=\"121\">121% ";
    print $sock "<input type=\"radio\" name=\"zoomradio\" value=\"133\">133% ";
    print $sock "<input type=\"radio\" name=\"zoomradio\" value=\"146\">146% ";
    print $sock "<input type=\"radio\" name=\"zoomradio\" value=\"160\">160% ";
    print $sock "<input type=\"radio\" name=\"zoomradio\" value=\"176\">176% ";
    print $sock "<input type=\"radio\" name=\"zoomradio\" value=\"194\">194% ";
    print $sock "<input type=\"radio\" name=\"zoomradio\" value=\"300\">300% ";
    print $sock "<input type=\"radio\" name=\"zoomradio\" value=\"400\">400% ";
    print $sock "<input type=\"radio\" name=\"zoomradio\" value=\"500\">500% ";
    print $sock "<input type=\"radio\" name=\"zoomradio\" value=\"600\">600% ";
    print $sock "</form>\n";
    }

    $mobiurl = $url;
	#http://www.google.com/gwt/x?u=http%3A%2F%2Fwww.a.com
	$mobiurl =~ s|:|%3A|g;
	$mobiurl =~ s|/|%2F|g;
	$mobiurl =~ s|(https*%3A%2F%2F[^ ]+)|http://www.google.com/gwt/x?u=$1&wsc=pb&ct=pg1&whp=30|g;

    if ($mode1online2offline4download & 3) {
    print $sock "<hr>\n";
    print $sock "URL: <a href=\"$url\">original</a> \n";
    print $sock "<a href=\"$mobiurl\">Google Mobilizer</a> \n";
    print $sock "<font style=\"color:black;background-color:lime\"><a href=\"#__here1__\">next</a></font>\n";
    print $sock "<hr>\n";
    }

	$here = 1;
    if (defined ($form->{'paste'}) || defined ($form->{'fetch'})) {
        $para = 1;
        $nextpage = $url;
        if ($mode1online2offline4download == 4) {
            &l00httpd::writeOpen($ctrl, $form->{'path'});
        } else {
            &l00httpd::writeOpen($ctrl, 'l00://mobizoom.pl');
        }
        if ($mode1online2offline4download == 2) {
            # <span style="font-size : 144%;">
            $wget =~ s/(<span style="font-size : )\d+(%;)">/$1$zoom$2/g;
            print $sock $wget;
        } else {
            do {
                $getmore = 0;
                $wget = &l00http_mobizoom_wget ($nextpage, $zoom);
                if ($wget =~ /<a href=.+?url=(.+?)'>\nNext page /) {
                    $nextpage = $1;
	    		    $nextpage =~ s/\%([a-fA-F0-9]{2})/pack("C", hex($1))/seg;
                    #print "$nextpage \nNext page\n";
                    $getmore = 1;
                }
                if ($mode1online2offline4download & 3) {
                    print $sock $wget;
                }
                &l00httpd::writeBuf($ctrl, $wget);
            } while ($getmore);
            &l00httpd::writeClose($ctrl);
        }
    }

    if ($mode1online2offline4download & 3) {
    print $sock "<hr><a name=\"__end__\"></a>Goto sections:\n";
    for (1..$here){
        print $sock "<a href=\"#__here$_\__\">$_</a> ";
    }
    print $sock "<p><a href=\"#__top__\">Jump to top</a>\n";

    print $sock "<p>Goto paragraph:\n";
    for (1..$para){
        print $sock "<a href=\"#__para$_\__\">$_</a> ";
    }
    print $sock "<p><a href=\"#__top__\">Jump to top</a>\n";

    print $sock $ctrl->{'htmlfoot'};
	}
}


\%config;
