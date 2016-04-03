#<!-- ::mobizoom::orgurl::http... -->
my ($wgetorg, $enableNewCode);

use strict;
use warnings;

use l00httpd;
use l00crc32;

use l00wget;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# a trivial web page mobilizer

# Dropping the defunct Google mobilizer and start a local 
# implementation. Last Google version in commit 1ea84e6

# Deleting historical fragments. See:
# git diff HEAD fe707 -- l00http_md5sizediff.pl

my %config = (proc => "l00http_mobizoom_proc",
              desc => "l00http_mobizoom_desc");
my ($url, $zoom, $para, $here, $prolog);
$url = '';
$zoom = 120;
$para = 1;


sub wgetfollow2 {
    my ($ctrl, $url, $nmpw, $opentimeout, $readtimeout, $debug) = @_;
    my ($hdr, $bdy, $shortbdy, $followmoves, $domain, $moved);
    my ($journal, $rwgeturl, $wgetjournal);


    $hdr = '';
    $bdy = '';
    $journal = '';

    for ($followmoves = 0; $followmoves < 10; $followmoves++) {
        if ($followmoves > 0) {
            $journal .= "<p><hr>";
        }
        $domain = '';
        $url =~ s/\r//g;
        $url =~ s/\n//g;
        if ($url =~ /https*:\/\/([^\/]+?)\//) {
            $domain = $1;
        }
        $wgetjournal = '';
        if ($url =~ /https:\/\//) {
            if (defined($ctrl->{'rwgetshell'}) &&
                defined($ctrl->{'rwgetfetch'})) {
                $wgetjournal .= "\n";
                # shell rwget to wget
                $rwgeturl = "\"$url\"";
#                $rwgeturl = &l00httpd::urlencode ("\"$url\"");
$rwgeturl =~ s/%/%25/g;
$rwgeturl =~ s/"/%22/g;
$rwgeturl =~ s/&/%26/g;
$rwgeturl =~ s/\+/%2B/g;
$rwgeturl =~ s/\//%2F/g;
$rwgeturl =~ s/:/%3A/g;
$rwgeturl =~ s/=/%3D/g;
$rwgeturl =~ s/\?/%3F/g;
                $rwgeturl = "$ctrl->{'rwgetshell'}$rwgeturl";
                $wgetjournal .= "rwgetshell: <a href=\"$rwgeturl\">$rwgeturl</a>\n";
                ($hdr, $bdy) = &l00wget::wget ($rwgeturl, undef, $opentimeout, $readtimeout, $debug);
                $wgetjournal .= sprintf("rwgetshell: HDR (%d B), BDY (%d B)\n", 
                    length($hdr), length($bdy));
                # fetch rwget file
                $rwgeturl = $ctrl->{'rwgetfetch'};
                $wgetjournal .= "rwgetfetch: <a href=\"$rwgeturl\">$rwgeturl</a>\n";
                ($hdr, $bdy) = &l00wget::wget ($rwgeturl, undef, $opentimeout, $readtimeout, $debug);
                $wgetjournal .= sprintf("rwgetfetch: HDR (%d B), BDY (%d B)\n", 
                    length($hdr), length($bdy));
            } else {
                $journal .= "'rwgetshell' and 'rwgetfetch' are not defined in 'l00httpd.cfg'. Not using rwget server to fetch https\n";
                $hdr = '';
                $bdy = '';
                last;
            }
        } else {
($hdr, $bdy) = &l00wget::wget ($url, $nmpw, $opentimeout, $readtimeout, $debug);
        }
        $journal .= sprintf("PASS #%d: HDR (%d B), BDY (%d B)\nURL: %s\n", 
            $followmoves, length($hdr), length($bdy), $url);
        $journal .= sprintf ("URL is %3d bytes long and CRC32 is 0x%08x. ",
            length($url), &l00crc32::crc32($url));
        $_ = length($hdr);
        $journal .= "Header length $_ bytes. ";
        if (defined($bdy)) {
            $_ = length($bdy);
            $journal .= "Body length $_ bytes. ";
            if ($_ > 1000) {
                $shortbdy = substr($bdy, 0, 1000);
            } else {
                $shortbdy = $bdy;
            }
        } else {
            $journal .= "Body length undef bytes. ";
            $shortbdy = '';
        }
        $journal .= $wgetjournal;
        $journal .= "Header:<pre>$hdr</pre>\n";
        $shortbdy =~ s/</&lt;/gs;
        $shortbdy =~ s/>/&gt;/gs;
        $journal .= "First 1000 bytes of body:\n<pre>$shortbdy</pre>\n";

        # Find HTTP return code
        $moved = '';
        foreach $_ (split("\n", $hdr)) {
            if (($moved eq '') && (/^HTTP.* 30[12] /)) {
                $moved = 'moved';
            }
            if (($moved eq 'moved') && (/^location: +(.+)/i)) {
                $url = $1;
                if (!($url =~ /^https*:\/\//)) {
                    $url = "http://$domain$url";
                }
                $journal .= "Moved to: $url\n";
                $moved = 'found';
            }
        }
        if ($moved ne 'found') {
            # didn't move, last fetch
            last;
        }
    }


    ($hdr, $bdy, $domain, $journal);
}


sub l00http_mobizoom_mobilize {
    my ($ctrl, $url, $zoom, $wget) = @_;
    my ($on_slashdot_org, $wget2);
    my ($clip, $last);
    my ($on_slashdot_org, $threads, $endanchor, $title);

    # This trivial mobilizer will process in two different mode:
    # Processed mode: the original cached file has the HTML tags 
    #   already striped, so the only processing is to remove 
    #   the <head>, <body>, and <form> tags
    # Raw mode: the new cache file format is identical to the 
    #   result of wget, i.e. complete HTML file, and in addition 
    #   the original URL is prepended as <!-- ::mobizoom::orgurl::http... -->

    # remote various HTML tags
    $wget =~ s/<head.*?>.*?<\/head.*?>//gs;
    $wget =~ s/<\/*body.*?>//gs;

    # form
    $wget =~ s/<form.+?<\/form *\n*\r*>//sg;


    if (!($wget =~ /<html/im) || !($wget =~ /<\/html/im)) {
#        $wget = "<h1>STRIPED</h1><p>$wget";
        &l00httpd::dbp($config{'desc'}, "Will not mobilize page\n"), 
                                        if ($ctrl->{'debug'} >= 3);
    } else {
#        $wget = "<h1>FULL HTML</h1><p>$wget";
        &l00httpd::dbp($config{'desc'}, "Will mobilize page\n"), 
                                        if ($ctrl->{'debug'} >= 3);

        $threads = '';
        $title = "<title>mobizoom $url</title>\n";

        if ($url =~ /slashdot\.org/i) {
            $on_slashdot_org = 1;
        } else {
            $on_slashdot_org = 0;
        }

        # find title
        if ($wget =~ /(<title>.+?<\/title.*?>)/s) {
            $title = "$1\n";
        }
        # 2) add navigation and content clip link for each paragraph


        # 3) drop HTML tags and add font-size as specified:
        ## <html>
        ## <body>
        ## <span>
        ## <div>

        # remote various HTML tags
        $wget =~ s/<\/*html.*?>//gs;

#    # remote various HTML tags
#    $wget =~ s/<\/*html.*?>//gs;
#    $wget =~ s/<head.*?>.*?<\/head.*?>//gs;
#    $wget =~ s/<\/*body.*?>//gs;

$wget =~ s/<(\w+)/&lt;$1&gt; <$1/gs;
$wget =~ s/<\/(\w+)(.*?)>/<\/$1$2> &lt;\/$1&gt;/gs;

        $wget =~ s/<\/*span.*?>//gs;
        $wget =~ s/<\/*div.*?>//gs;
        $wget =~ s/<\/*aside.*?>//gs;
        $wget =~ s/<\/*figure.*?>//gs;
        $wget =~ s/<\/*article.*?>//gs;
        $wget =~ s/<\/*section.*?>//gs;

        $wget =~ s/<!.+?>//gs;
        $wget =~ s/<script.+?<\/script *\n*\r*>//sg;
        $wget =~ s/<iframe.+?<\/iframe>//sg;
        $wget =~ s/<style.+?<\/style>//sg;
        $wget =~ s/<figcaption.+?<\/figcaption>//sg;

        if ($on_slashdot_org) {
            # slashdot special: eliminate list
            $wget =~ s/<li.*?>/<br>/sg;
            $wget =~ s/<\/li.*?>//sg;
            $wget =~ s/<\/*ul.*?>//sg;
        }
        $wget =~ s/<p.*?>/<br>/sg;
        $wget =~ s/<\/p>/<\/br>/sg;

#        $wget =~ s/\r//g;
#        $wget =~ s/\n//g;
#        $wget =~ s/^.+<body.*?>\n//g;
#        $wget =~ s/<\/body.*$>\n//g;
#        $wget =~ s/^.+>(This page adapted for your browser comes from )/$1/g;  # cut off before This page adapted
#        $wget =~ s/<\/wml.*$>\n//g;

        $wget =~ s/<img src="(.+?)".*?>/ <a href="$1"><img src=\"$1\" width=\"200\" height=\"200\"><\/a>/sg;


        $wget = "<span style=\"font-size : $zoom%;\">$wget</span>";
        $wget =~ s/<h(\d).*?>/<\/span><h$1>/sg;
        $wget =~ s/<\/h(\d).*?>/<\/h$1><span style="font-size : $zoom%;">/sg;


        # make sure there is at most one <tag> per new line
        $wget2 = $wget;
        $wget2 =~ s/</\n</g;
        $wget2 =~ s/>/>\n/g;

        $wget = '';
        $last = '';
        foreach $_ (split ("\n", $wget2)) {
            chomp;
            if (/^ *$/) {
                next;
            }

            $clip = $_;
            $clip =~ s/<.+?>//g;    # drop all HTML tags
            $clip = &l00httpd::urlencode ($clip);

            # insert navigation and clip links 
            ## change this:
            ## <br/><br/>
            ## to:
            ## <br/><br/>
            ##  <a name="p$para"></a>
            ##  <small>
            ##    <a href="#__end__">V</a> &nbsp; 
            ##    <a href="#p$para">$para</a> &nbsp; 
            ##    <a href="/clip.htm?update=Copy+to+CB&clip=$clip" target="clip"> : </a> &nbsp; 
            ##  </small> /;

            if ($on_slashdot_org) {
                #<a id="comment_link_50359309" name="comment_link_50359309" href="//developers.slashdot.org/comments.pl?sid=7880359&amp;cid=50359309" onclick="return D2.setFocusComment(50359309)" >
                #Re:You still go through HR for jobs?
                #</a>
                if (($last =~ /id="comment_link_\d+/) && 
                    !(/^Re:/)) {
                    #&l00httpd::dbp('wget_follow', "SUBJECT: $para: $_\n");
                    $para--;
                    if ($threads eq '') {
                        $threads = "Slashdot threads (found by 'comment_link_'):<br>\n";
                    }
                    $threads .= "<a href=\"#p$para\">$para: $_</a><br>\n";
                    $para++;
                    $wget .= " <font style=\"color:black;background-color:lime\"> FOUND THREAD </font><br>\n";
                }
            }

            if (/<br>/) {
                s/<br>/<br><a name="p$para"><\/a><small><a href="#__end__">V<\/a> &nbsp; <a href="#p$para">$para<\/a> &nbsp; <a href="\/clip.htm?update=Copy+to+CB&clip=$clip" target="clip"> : <\/a> &nbsp; <\/small> /;
                # increase paragraph count/index
                $para++;
            }
            if (/<p>/) {
                s/<p>/<br><a name="p$para"><\/a><small><a href="#__end__">V<\/a> &nbsp; <a href="#p$para">$para<\/a> &nbsp; <a href="\/clip.htm?update=Copy+to+CB&clip=$clip" target="clip"> : <\/a> &nbsp; <\/small> /;
                # increase paragraph count/index
                $para++;
            }


            $wget .= "$_\n";
            $last = $_;
        }

        # 5) add last navigation link

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


        # semi hide tags
        $wget =~ s/&lt;/<font size="1" style="color:gray;background-color:white">&lt;/gs;
        #$wget =~ s/&lt;/<font size=1">&lt;/gs;
        $wget =~ s/&gt;/&gt;<\/font>/gs;

    $endanchor = '';
    # web page interactive mode, render web page
    $endanchor .= "<hr><a name=\"__end__\"></a>";
    $endanchor .= "<p>Goto sections:\n";
    for (1..$here) {
        $endanchor .= "<a href=\"#__here$_\__\">$_</a> ";
    }
    $endanchor .= "<br><a href=\"#__top__\">Jump to top</a>\n";

    $endanchor .= "<br>Goto paragraph:\n";
    for (1..$para) {
        $endanchor .= "<a href=\"#p$_\">$_</a> ";
    }
    $endanchor .= "<br><a href=\"#__top__\">Jump to top</a>\n";


    $wget = "$title\nOriginal URL: <a href=\"$url\">$url</a><p>\n$threads\n$wget\n$threads$endanchor";
#herehere
    }

    $wget;
}





sub l00http_mobizoom_wget {
    my ($ctrl, $url, $zoom) = @_;
                                my ($bdy, $bdy2, $pre, $gurl, $post, $hdr, $subj, $clip, $last);
                                my ($on_slashdot_org, $threads, $endanchor, $domain, $title, $journal);


                                $bdy = '';
                                $domain = '';
                                $threads = '';
                                $title = "<title>mobizoom $url</title>\n";
    if (length ($url) > 6) {

                                    if ($url =~ /slashdot\.org/i) {
                                        $on_slashdot_org = 1;
                                    } else {
                                        $on_slashdot_org = 0;
                                    }

        # 1) fetch target URL
        ($hdr, $bdy, $domain, $journal) = &wgetfollow2($ctrl, $url);
$wgetorg = $bdy;
if (&l00httpd::l00fwriteOpen($ctrl, 'l00://mobi_wget_org.txt')) {
    &l00httpd::l00fwriteBuf($ctrl, $bdy);
    &l00httpd::l00fwriteClose($ctrl);
}
        if (&l00httpd::l00fwriteOpen($ctrl, 'l00://journal.txt')) {
            &l00httpd::l00fwriteBuf($ctrl, "$journal");
            &l00httpd::l00fwriteClose($ctrl);
        }

if(!$enableNewCode) {
                                    # find title
                                    if ($bdy =~ /(<title>.+?<\/title.*?>)/s) {
                                        $title = "$1\n";
                                    }
                                    # 2) add navigation and content clip link for each paragraph


                                    # 3) drop HTML tags and add font-size as specified:
                                    ## <html>
                                    ## <body>
                                    ## <span>
                                    ## <div>

                                    # remote various HTML tags
                                    $bdy =~ s/<\/*html.*?>//gs;
                                    $bdy =~ s/<head.*?>.*?<\/head.*?>//gs;
                                    $bdy =~ s/<\/*body.*?>//gs;

                            $bdy =~ s/<(\w+)/&lt;$1&gt; <$1/gs;
                            $bdy =~ s/<\/(\w+)(.*?)>/<\/$1$2> &lt;\/$1&gt;/gs;

                                    $bdy =~ s/<\/*span.*?>//gs;
                                    $bdy =~ s/<\/*div.*?>//gs;
                                    $bdy =~ s/<\/*aside.*?>//gs;
                                    $bdy =~ s/<\/*figure.*?>//gs;
                                    $bdy =~ s/<\/*article.*?>//gs;
                                    $bdy =~ s/<\/*section.*?>//gs;

                                    $bdy =~ s/<!.+?>//gs;
                                    $bdy =~ s/<script.+?<\/script *\n*\r*>//sg;
                                    $bdy =~ s/<iframe.+?<\/iframe>//sg;
                                    $bdy =~ s/<style.+?<\/style>//sg;
                                    $bdy =~ s/<figcaption.+?<\/figcaption>//sg;

                                    if ($on_slashdot_org) {
                                        # slashdot special: eliminate list
                                        $bdy =~ s/<li.*?>/<br>/sg;
                                        $bdy =~ s/<\/li.*?>//sg;
                                        $bdy =~ s/<\/*ul.*?>//sg;
                                    }
                                    $bdy =~ s/<p.*?>/<br>/sg;
                                    $bdy =~ s/<\/p>/<\/br>/sg;

                            #        $bdy =~ s/\r//g;
                            #        $bdy =~ s/\n//g;
                            #        $bdy =~ s/^.+<body.*?>\n//g;
                            #        $bdy =~ s/<\/body.*$>\n//g;
                            #        $bdy =~ s/^.+>(This page adapted for your browser comes from )/$1/g;  # cut off before This page adapted
                            #        $bdy =~ s/<\/wml.*$>\n//g;

                                    $bdy =~ s/<img src="(.+?)".*?>/ <a href="$1"><img src=\"$1\" width=\"200\" height=\"200\"><\/a>/sg;

                                    #$bdy =~ s/(<a.+?href=")(\/.+?)(".+?>)/$1http:\/\/$domain$2$3/gs;  # not working

                                    $bdy = "<span style=\"font-size : $zoom%;\">$bdy</span>";
                                    $bdy =~ s/<h(\d).*?>/<\/span><h$1>/sg;
                                    $bdy =~ s/<\/h(\d).*?>/<\/h$1><span style="font-size : $zoom%;">/sg;

                                    # make sure there is at most one <tag> per new line
                                    $bdy2 = $bdy;
                                    $bdy2 =~ s/</\n</g;
                                    $bdy2 =~ s/>/>\n/g;

                                    $bdy = '';
                                    $last = '';
                                    foreach $_ (split ("\n", $bdy2)) {
                                        chomp;
                                        if (/^ *$/) {
                                            next;
                                        }

                                        $clip = $_;
                                        $clip =~ s/<.+?>//g;    # drop all HTML tags
                                        $clip = &l00httpd::urlencode ($clip);

                                        # insert navigation and clip links 
                                        ## change this:
                                        ## <br/><br/>
                                        ## to:
                                        ## <br/><br/>
                                        ##  <a name="p$para"></a>
                                        ##  <small>
                                        ##    <a href="#__end__">V</a> &nbsp; 
                                        ##    <a href="#p$para">$para</a> &nbsp; 
                                        ##    <a href="/clip.htm?update=Copy+to+CB&clip=$clip" target="clip"> : </a> &nbsp; 
                                        ##  </small> /;

                                        if ($on_slashdot_org) {
                                            #<a id="comment_link_50359309" name="comment_link_50359309" href="//developers.slashdot.org/comments.pl?sid=7880359&amp;cid=50359309" onclick="return D2.setFocusComment(50359309)" >
                                            #Re:You still go through HR for jobs?
                                            #</a>
                                            if (($last =~ /id="comment_link_\d+/) && 
                                                !(/^Re:/)) {
                                                #&l00httpd::dbp('wget_follow', "SUBJECT: $para: $_\n");
                                                $para--;
                                                if ($threads eq '') {
                                                    $threads = "Slashdot threads (found by 'comment_link_'):<br>\n";
                                                }
                                                $threads .= "<a href=\"#p$para\">$para: $_</a><br>\n";
                                                $para++;
                                                $bdy .= " <font style=\"color:black;background-color:lime\"> FOUND THREAD </font><br>\n";
                                            }
                                        }

                                        if (/<br>/) {
                                            s/<br>/<br><a name="p$para"><\/a><small><a href="#__end__">V<\/a> &nbsp; <a href="#p$para">$para<\/a> &nbsp; <a href="\/clip.htm?update=Copy+to+CB&clip=$clip" target="clip"> : <\/a> &nbsp; <\/small> /;
                                            # increase paragraph count/index
                                            $para++;
                                        }
                                        if (/<p>/) {
                                            s/<p>/<br><a name="p$para"><\/a><small><a href="#__end__">V<\/a> &nbsp; <a href="#p$para">$para<\/a> &nbsp; <a href="\/clip.htm?update=Copy+to+CB&clip=$clip" target="clip"> : <\/a> &nbsp; <\/small> /;
                                            # increase paragraph count/index
                                            $para++;
                                        }


                                        $bdy .= "$_\n";
                                        $last = $_;
                                    }

                                    # 5) add last navigation link

                                    $bdy .= "<br>\n";
                                    $bdy .= "<font style=\"color:black;background-color:lime\">\n";
                                    $bdy .= "<a href=\"#__top__\">TOP</a>";
                                    $bdy .= "</font>\n";
                                    $bdy .= "<font style=\"color:black;background-color:lime\">\n";
                                    $bdy .= "<a href=\"#__here".($here -1 ) ."__\">last</a>";
                                    $bdy .= "</font>\n";
                                    $bdy .= "<font style=\"color:black;background-color:lime\">\n";
                                    $bdy .= "<a href=\"#__here$here\__\">here$here</a>";
                                    $bdy .= "</font>\n";
                                    $bdy .= "<font style=\"color:black;background-color:lime\">\n";
                                    $bdy .= "<a href=\"#__here". ($here + 1) ."__\">next</a>";
                                    $bdy .= "<a name=\"__here$here\__\"></a>\n";
                                    $here++;
                                    $bdy .= "</font>\n";
                                    $bdy .= "<font style=\"color:black;background-color:lime\">\n";
                                    $bdy .= "<a href=\"#__end__\">END</a>";
                                    $bdy .= "</font>\n";
                                    $bdy .= "<br>\n";


                                    # semi hide tags
                                    $bdy =~ s/&lt;/<font size="1" style="color:gray;background-color:white">&lt;/gs;
                                    #$bdy =~ s/&lt;/<font size=1">&lt;/gs;
                                    $bdy =~ s/&gt;/&gt;<\/font>/gs;
}#herehere
    }

if(!$enableNewCode) {
                                $endanchor = '';
                                # web page interactive mode, render web page
                                $endanchor .= "<hr><a name=\"__end__\"></a>";
                                $endanchor .= "<p>Goto sections:\n";
                                for (1..$here){
                                    $endanchor .= "<a href=\"#__here$_\__\">$_</a> ";
                                }
                                $endanchor .= "<br><a href=\"#__top__\">Jump to top</a>\n";

                                $endanchor .= "<br>Goto paragraph:\n";
                                for (1..$para){
                                    $endanchor .= "<a href=\"#p$_\">$_</a> ";
                                }
                                $endanchor .= "<br><a href=\"#__top__\">Jump to top</a>\n";
}#herehere


                                "$title\nOriginal URL: <a href=\"$url\">$url</a><p>\n$threads\n$bdy\n$threads$endanchor";
}



sub l00http_mobizoom_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition

    # Descriptions to be displayed in the list of modules table
    " A: mobizoom: Allowing font zoom on Google Mobilizer results";
}


sub l00http_mobizoom_part1 {
    my ($ctrl, $sock, $title, $url, $zoom) = @_;
    my ($tmp, $orgurl);

    # web page interactive mode, render web page
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>$title</title>" . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"__top__\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
    print $sock "<a href=\"#__end__\">Jump to end</a><hr>\n";

    # web page interactive mode, render web page
    print $sock "<form action=\"/mobizoom.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"fetch\" value=\"Fetch\">\n";
    $tmp = &l00httpd::urlencode ($url);
    print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">URL</a>";
    print $sock ":<input type=\"text\" size=\"16\" name=\"url\" value=\"$url\"></td>\n";
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

    # web page interactive mode, render web page
    print $sock "<hr>\n";
    $orgurl = $url;
    $orgurl =~ s/&ei=.*$//; # drop &ei=...
    $tmp = $orgurl;
    $tmp =~ s/ /+/g;
    $tmp =~ s/:/%3A/g;
    $tmp =~ s/&/%26/g;
    $tmp =~ s/=/%3D/g;
    $tmp =~ s/"/%22/g;
    $tmp =~ s/\//%2F/g;
    $tmp =~ s/\|/%7C/g;
    print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">URL:</a>\n";
    print $sock "<a href=\"$orgurl\">original</a> \n";
    print $sock "<font style=\"color:black;background-color:lime\"><a href=\"#__here1__\">next</a></font>\n";
    print $sock "View: <a href=\"/view.htm?path=l00://mobizoom.htm\">l00://mobizoom.htm</a> -\n";
    print $sock "<a href=\"/wget.htm?url=$url&submit=\" target=\"newwget\">wget</a> --\n";
    $tmp = &l00httpd::urlencode ("http://googleweblight.com/?lite_url=$url");
    print $sock "<a href=\"/mobizoom.htm?fetch=Fetch&url=$tmp\" target=\"newgwl\">Google web light</a>\n";
    print $sock " -- <a href=\"/ls.htm?path=l00://journal.txt\" target=\"newwin\">l00://journal.txt</a>\n";
    print $sock "<hr>\n";
}

sub l00http_mobizoom_part2 {
    my ($ctrl, $sock, $here, $para) = @_;

    # web page interactive mode, render web page
    print $sock "<hr><a name=\"__end__\"></a>";
    print $sock "<p>Goto sections:\n";
    for (1..$here){
        print $sock "<a href=\"#__here$_\__\">$_</a> ";
    }
    print $sock "<p><a href=\"#__top__\">Jump to top</a>\n";

    print $sock "<p>Goto paragraph:\n";
    for (1..$para){
        print $sock "<a href=\"#p$_\">$_</a> ";
    }
    print $sock "<p><a href=\"#__top__\">Jump to top</a>\n";
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
    my ($wget, $mode1online2offline4download);
    my ($skip, $tmp, $orgurl, $title, $foundthreads, $foundthreadphase, $foundthreadcnt);


if(!defined($ctrl->{'l00file'}{'l00://mobinewcode'})) {
    $ctrl->{'l00file'}{'l00://mobinewcode'} = '0';
}
$enableNewCode = ($ctrl->{'l00file'}{'l00://mobinewcode'} =~ /1/) ? 1 : 0;


    $url = '';
    if (defined ($form->{'url'})) {
        $url = $form->{'url'};
    }

    $mode1online2offline4download = 0;

    if (defined ($form->{'paste'})) {
        $url = &l00httpd::l00getCB($ctrl);
        if ((-f $url) || ($url =~ /^l00:\/\//)) {
            # must be reading locally cached file
            $form->{'paste'} = undef;
            $form->{'fetch'} = 1;
        } else {
            # extract URL if it doesn't look like a local file
            if ($url =~ /(https*:\/\/[^ \n\r\t]+)/) {
                $url = $1;
            }
            if (!($url =~ /https*:\/\//)) {
                # Opera Mini does not include http://
                $url = "http://$url";
            }
            # News++ adds ?rss=1, drop it
            $url =~ s|\?rss=1$||;
        }
        &l00httpd::dbp($config{'desc'}, "URL from clipboard: $url\n"), 
            if ($ctrl->{'debug'} >= 3);
    }


    if ((defined ($form->{'zoom'})) && ($form->{'zoom'} =~ /(\d+)/)) {
        # is a number (zoom %)
        $zoom = $1;
    }
    if (defined ($form->{'zoomradio'})) {
        $zoom = $form->{'zoomradio'};
    }


    # determining mode of operation: $mode1online2offline4download
    ## 1: online: do a live fetch (user interacts through web page)
    ## 2: offline: fetch from a cached file (user interacts through web page)
    ## 4: download: do a live fetch and save as a cached file (no web UI automation)
    # for mode 1 and 2 the web page must be rendered
    # for mode 4 the web page must not be rendered

    # if $form->{'path'} is provided, then download (unless on RHC)
    # else if $form->{'url'} points to a local cached file, do offline
    # else do live fetch


    $title = "Mobizoom $url";

    if (defined ($form->{'path'}) && !defined ($form->{'fetch'})) {
        # from launcher, convert to interactive fetch
        $url = $form->{'path'};
        undef $form->{'path'};
    }
    $orgurl = $url;
    if ((defined ($form->{'path'})) && ($ctrl->{'os'} ne 'rhc')) {
        # only when not on RHC
        $mode1online2offline4download = 4;
    } elsif ((-f $url) || ($url =~ /^l00:\/\//)) {
        $mode1online2offline4download = 2;
        if (&l00httpd::l00freadOpen($ctrl, $url)) {
            $wget = &l00httpd::l00freadAll($ctrl);
            # find embedded page title
            if ($wget =~ /<title>(.+?)<\/title.*?>/s) {
                $title = "$1\n";
            }
            # find original url prepended
            if ($wget =~ /<!-- ::mobizoom::orgurl::(.+?) -->/s) {
                $orgurl = $1;
            }
        } else {
            $wget = "Failed top load '$url'\n";
        }
$wgetorg = $wget;
    } else {
        $mode1online2offline4download = 1;
    }


    if ($mode1online2offline4download & 3) {
        &l00http_mobizoom_part1($ctrl, $sock, $title, $orgurl, $zoom);
    }

    $here = 1;
    if (defined ($form->{'paste'}) || defined ($form->{'fetch'})) {
        $para = 1;
        if ($mode1online2offline4download == 2) {
            # reading from cached file

            # <head> and <form> mess with my <span font-size> so drop them
            $tmp = '';
            $skip = 0;
            $foundthreads = '<br>Jump to Slashdot threads:<br>';
            $foundthreadphase = 0;
            $foundthreadcnt = 1;
            foreach $_ (split("\n", $wget)) {
                if (($foundthreadphase == 1) && (/<a name="(.+?)">/)) {
                    $foundthreadphase = 0;
                    $foundthreads .= "<a href=\"#$1\">$foundthreadcnt FOUND THREAD #$1</a><br>";
                    $foundthreadcnt++;
                }
                if (/FOUND THREAD/) {
                    $foundthreadphase = 1;
                }
                if (/<\/form.*>/) {
                    $skip = 0;
                    next;
                }
                if (/<form.*>/) {
                    $skip = 1;
                    next;
                }
                if (/<\/head.*>/) {
                    $skip = 0;
                    next;
                }
                if (/<head.*>/) {
                    $skip = 1;
                    next;
                }
                if ($skip) {
                    next;
                }
                if (/<\?xml.*>/ || /<!DOCTYPE.*>/) {
                    next;
                }
                $tmp .= "$_\n";
            }
            $wget = $tmp;
            # <span style="font-size : 144%;">
            $wget =~ s/(<span style="font-size : )\d+(%;)">/$1$zoom$2/sg;
            if ($foundthreadcnt > 1) {
                print $sock $foundthreads;
            }
# mobilize page
if($enableNewCode) {
$wget = $wgetorg;
$wget = &l00http_mobizoom_mobilize ($ctrl, $url, $zoom, $wget);
}
if($enableNewCode) {
    print $sock "PROCESSED BY NEW CODE<p>\n";
}
            print $sock $wget;
            if ($foundthreadcnt > 1) {
                print $sock $foundthreads;
            }
        } else {
            # $mode1online2offline4download != 2
            # fetch for active reading or caching automation

            # fetch repeatedly as necessary as Google mobilizer break page
            # into multiple mobilized pages
            $wget = &l00http_mobizoom_wget ($ctrl, $url, $zoom);
if($enableNewCode) {
$wget = $wgetorg;
}

            # save file
            if ($mode1online2offline4download == 4) {
                &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
                # download too small, delete it by not writing
                if (length ($wget) > 2000) {
                    &l00httpd::l00fwriteBuf($ctrl, "<!-- ::mobizoom::orgurl::$url -->\n$wget");
                }
                &l00httpd::l00fwriteClose($ctrl);
            }
# mobilize page
if($enableNewCode) {
            $wget = &l00http_mobizoom_mobilize ($ctrl, $url, $zoom, $wget);
}

            if ($mode1online2offline4download & 3) {
                # web page interactive mode, render web page
if($enableNewCode) {
    print $sock "PROCESSED BY NEW CODE<p>\n";
}
                print $sock $wget;
            }
            if ($mode1online2offline4download != 4) {
                &l00httpd::l00fwriteOpen($ctrl, 'l00://mobizoom.htm');
            }
            &l00httpd::l00fwriteBuf($ctrl, $wget);
            &l00httpd::l00fwriteClose($ctrl);
        }
    }

    if ($mode1online2offline4download & 3) {
        # Add jump links if missing
        if (!($wget =~ /<a href="#__here0__">last<\/a>/s)) {
            &l00http_mobizoom_part2($ctrl, $sock, $here, $para);
        }

        print $sock $ctrl->{'htmlfoot'};
    }
}


\%config;
