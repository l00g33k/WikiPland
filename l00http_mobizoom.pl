#<!-- ::mobizoom::orgurl::http... -->

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
my ($url, $zoom, $para, $here, $prolog, $freeimgsize, $imgsrclink, $backurl, $forcetarget);
my ($mobiz_wget, $mobiz_sig);
$mobiz_sig = '';
$url = '';
$zoom = 150;
$para = 1;
$freeimgsize = 'checked';
$imgsrclink = '';
$backurl = '';
$forcetarget = '';

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
        $domain = 'http://';
        $url =~ s/\r//g;
        $url =~ s/\n//g;
        if ($url =~ /https*:\/\/([^\/]+?)\//) {
            $domain = $1;
        }
        $wgetjournal = '';
        ($hdr, $bdy) = &l00wget::wget ($ctrl, $url, $nmpw, $opentimeout, $readtimeout, $debug);
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
    my ($ctrl, $url, $zoom, $wget, $saveinternal) = @_;
    my ($on_slashdot_org, $urlgiven, $wget2, $domain, $wgettmp);
    my ($clip, $tmp, $last, $lnno, $wgetorg, $inhref);
    my ($threads, $endanchor, $title, $freetag, $sectprelog);


    # This trivial mobilizer will process in two different mode:
    # Processed mode: the original cached file has the HTML tags 
    #   already striped, so the only processing is to remove 
    #   the <head>, <body>, and <form> tags
    # Raw mode: the new cache file format is identical to the 
    #   result of wget, i.e. complete HTML file, and in addition 
    #   the original URL is prepended as <!-- ::mobizoom::orgurl::http... -->

    $urlgiven = $url;

    $wgetorg = $wget;
    if ($wget =~ /<!-- ::mobizoom::orgurl::(.+?) -->/s) {
        # recover URL from cached file
        $url = $1;
    }

    $domain = '';
    $url =~ s/\r//g;
    $url =~ s/\n//g;
    if ($url =~ /(https*:\/\/[^\/]+?)\//) {
        $domain = $1;
    }

    # remote various HTML tags
    $wget =~ s/<head.*?>.*?<\/head.*?>//gsi;
    $wget =~ s/<\/*body.*?>//gs;

    # form
    $wget =~ s/<form.+?<\/form *\n*\r*>//gsi;

    # free size image
    if ($freeimgsize eq 'checked') {
        $freetag = '&freeimgsize=on';
    } else {
        $freetag = '';
    }

    # put all tags on a line
    $wget =~ s/[\r\n]/ /gs;
    $wget =~ s/</\n</gs;
    $wget =~ s/>/>\n/gs;



    if ((!($wget =~ /<html/im) || !($wget =~ /<\/html/im)) &&
        (($wget =~ /<font/im))) {
        # this is for backward compatibility
        # content has no <html> or </html> tag
        # and doesn't have <font>, i.e. not plain text
        &l00httpd::dbp($config{'desc'}, "Will not mobilize page\n"), 
                                        if ($ctrl->{'debug'} >= 3);
        # make paragraph jump table
        $tmp = '';
        foreach $_ ($wget =~ /<a name="__para(\d+)__">/gm) {
            $tmp .= "<a href=\"#__para${_}__\">$_</a> ";
        }

        # add domain for local domain url
        $wget =~ s/(<a.+?href=["'])\//$1$domain\//gm;
        $wget =~ s/(<a.+?href=)\//$1$domain\//gm;
        # remote target=
        $wget =~ s/(<a.+?href=["'].+?) target=".+?"(.*?>)/$1$2/g;
        # convert URL to mobizoom, some uses ' instead of "
        $wget =~ s/(<a.+?href=")(https*:\/\/.+?)"/$1\/mobizoom.htm?fetch=mobizoom$freetag&url=$2"/g;
        $wget =~ s/(<a.+?href=')(https*:\/\/.+?)'/$1\/mobizoom.htm?fetch=mobizoom$freetag&url=$2'/g;
        $wget =~ s/(<a.+?href=)(https*:\/\/.+?)>/$1\/mobizoom.htm?fetch=mobizoom$freetag&url=$2>/g;

        $wget = "Paragraph: $tmp<br>$wget<p><hr><a name=\"__end__\"></a>Paragraph: $tmp";
    } else {
        &l00httpd::dbp($config{'desc'}, "Will mobilize page\n"), 
                                        if ($ctrl->{'debug'} >= 3);

        $threads = '';
        $title = "<title>MZ $url</title>\n";

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

        # display tags in debug mode
        if ($ctrl->{'debug'} >= 4) {
            $wget =~ s/<(\w+)/&lt;$1&gt; <$1/gs;
            $wget =~ s/<\/(\w+)(.*?)>/<\/$1$2> &lt;\/$1&gt;/gs;
        }

        $wget =~ s/<\/*span.*?>//gsi;
        $wget =~ s/<\/*div.*?>//gsi;
        $wget =~ s/<\/*aside.*?>//gsi;
        $wget =~ s/<\/*figure.*?>//gsi;
        $wget =~ s/<\/*article.*?>//gsi;
        $wget =~ s/<\/*section.*?>//gsi;
        $wget =~ s/<\/*main.*?>//gsi;
        $wget =~ s/<\/*nav.*?>//gsi;
        $wget =~ s/<hr.*?>//gsi;

        $wget =~ s/<!.+?>//gs;
        $wget =~ s/<script.+?<\/script *\n*\r*>//gsi;
        $wget =~ s/<iframe.+?<\/iframe>//gsi;
        $wget =~ s/<style.+?<\/style>//gsi;
        $wget =~ s/<figcaption.+?<\/figcaption>//gsi;

        # slashdot special: eliminate list
        $wget =~ s/<li.*?>/<br>&sect;&nbsp;&nbsp;&nbsp;/gsi;
        $wget =~ s/<\/li.*?>//gsi;
        $wget =~ s/<\/*ul.*?>//gsi;

        $wget =~ s/<p.*?>/<br>/gsi;
        $wget =~ s/<\/p>//sgi;

        # convert img src="//domain to src="http://
        $wget =~ s/(<img[^>]+src=["'])\/\//$1http:\/\//gsi;
        # display alt text
        $wget =~ s/(<img[^>]+?alt=")([^"]+?)(".*?>)/$1$2$3&lt;$2&gt;/gsi;

        if ($freeimgsize eq 'checked') {
            if ($imgsrclink eq 'checked') {
               #$wget =~ s/<img +src=['"](.+?)['"].*?>/ <a href="$1"><img src="$1"><\/a>/gsi;
                $wget =~ s/(<img[^"]+src=")(.+?)("[^"]*?>)/ <a href="$2">$1$2$3<\/a>/gsi;
            } else {
               #$wget =~ s/<img +src=['"](.+?)['"].*?>/<img src="$1">/gsi;
                $wget =~ s/(<img[^"]+src=")(.+?)("[^"]*?>)/$1$2$3/gsi;
            }
        } else {
            if ($imgsrclink eq 'checked') {
               #$wget =~ s/<img +src=['"](.+?)['"].*?>/ <a href="$1"><img src="$1" width="200" height="200"><\/a>/gsi;
                $wget =~ s/<img +src=['"](.+?)['"].*?>/ <a href="$1"><img src="$1" width="200" height="200"><\/a>/gsi;
            } else {
               #$wget =~ s/<img +src=['"](.+?)['"].*?>/<img src="$1" width="200" height="200">/gsi;
                $wget =~ s/<img +src=['"](.+?)['"].*?>/<img src="$1" width="200" height="200">/gsi;
            }
            if ($imgsrclink eq 'checked') {
               #$wget =~ s/<img +src=['"](.+?)['"].*?>/ <a href="$1"><img src="$1"><\/a>/gsi;
                $wget =~ s/(<img[^"]+src=")(.+?)("[^"]*?)>/ <a href="$2">$1$2$3 width="200" height="200"><\/a>/gsi;
            } else {
               #$wget =~ s/<img +src=['"](.+?)['"].*?>/<img src="$1">/gsi;
                $wget =~ s/(<img[^"]+src=")(.+?)("[^"]*?)>/$1$2$3 width="200" height="200">/gsi;
            }
        }

        $wget = "<span style=\"font-size : $zoom%;\">$wget</span>";
        $wget =~ s/<h(\d).*?>/<\/span><h$1>/gsi;
        $wget =~ s/<\/h(\d).*?>/<\/h$1><span style="font-size : $zoom%;">/gsi;
        $wget =~ s/<blockquote(.*?)>/<\/span><blockquote><span style="font-size : $zoom%;">/gsi;
        $wget =~ s/<\/blockquote>/<\/span><\/blockquote><span style="font-size : $zoom%;">/gsi;
        $wget =~ s/<table.*?>/<\/span><table><span style="font-size : $zoom%;">/gsi;
        $wget =~ s/<\/table.*?>/<\/span><\/table><span style="font-size : $zoom%;">/gsi;
        $wget =~ s/<footer(.*?)>/<\/span><footer><span style="font-size : $zoom%;">/gsi;
        $wget =~ s/<\/footer>/<\/span><\/footer><span style="font-size : $zoom%;">/gsi;


        # make sure there is at most one <tag> per new line
        $wget2 = $wget;
        $wget2 =~ s/</\n</g;
        $wget2 =~ s/>/>\n/g;

        $wgettmp = '';
        foreach $_ (split ("\n", $wget2)) {
            chomp;
            if (/^ *$/) {
                next;
            }
            $wgettmp .= "$_\n";
        }
        $wget2 = $wgettmp;

        if (defined($saveinternal) && ($saveinternal)) {
            &l00httpd::l00fwriteOpen($ctrl, "$urlgiven.internal.txt");
            &l00httpd::l00fwriteBuf($ctrl, $wget2);
            &l00httpd::l00fwriteClose($ctrl);

            open(WGET2, ">$urlgiven.internal.txt");
            print WGET2 $wget2;
            close (WGET2);
        }

        $wget = '';
        $last = '';
        $clip = '';
        $lnno = 0;
        $inhref = 0;
        foreach $_ (split ("\n", $wget2)) {
            chomp;
            if (/^ *$/) {
                next;
            }
            $lnno++;

            $tmp = $_;
            $tmp =~ s/<.+?>//g;    # drop all HTML tags
            $clip .= &l00httpd::urlencode ("$tmp ");

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

            # handle anchor like: <a href="//domain.com">
            s/(<a.+?href=["'])\/\//$1http:\/\/\//gm;
            # add domain for local domain url
            s/(<a.+?href=["'])\//$1$domain\//gm;
            s/(<a.+?href=)\//$1$domain\//gm;
            # remote target=
            s/(<a.+?href=["'].+?) target=".+?"(.*?>)/$1$2/g;
            # convert URL to mobizoom, some uses ' instead of "
            s/(<a.+?href=")(https*:\/\/.+?)"/$1\/mobizoom.htm?fetch=mobizoom$freetag&url=$2"/g;
            s/(<a.+?href=')(https*:\/\/.+?)'/$1\/mobizoom.htm?fetch=mobizoom$freetag&url=$2'/g;
            s/(<a.+?href=)(https*:\/\/.+?)>/$1\/mobizoom.htm?fetch=mobizoom$freetag&url=$2>/g;

            $sectprelog = 
                "<a href=\"\/clip.htm?update=Copy+to+CB&clip=$clip\" target=\"_blank\"> : <\/a> &nbsp; <a name=\"p$para\"><\/a><small>".
                "<a href=\"#__top__\">^<\/a> &nbsp; ".
                "<a href=\"#p$para\">$para<\/a> &nbsp; ";
            if (($urlgiven =~ /l00:\/\//) || (-f $urlgiven)) {
                $sectprelog .= "<a href=\"/edit.htm?path=$urlgiven&editline=on&blklineno=$lnno&context=on&contextln=10\">ed<\/a> &nbsp; ";
            }
            $sectprelog .= "<\/small>";

            # do not insert paragraph break between <a href...> and </a>
            if (/<a[^>]+href=[^>]+>/i) {
                $inhref = 1;
            }
            if (/<\/a[^>]*>/i) {
                $inhref = 0;
            }
            if (!$inhref) {
                # don't put paragraph in the middle of <a href>..</a>
                if (/<br>/i) {
                    #&l00httpd::dbp($config{'desc'}, "BR: >$_<\n");
                    s/<br>/<br>$sectprelog /i;
                    # increase paragraph count/index
                    $para++;
                    $clip = '';
                } elsif (/<h\d.*?>/i) {
                    #&l00httpd::dbp($config{'desc'}, "P: >$_<\n");
                    s/<(h\d.*?)>/$sectprelog<$1>/i;
                    # increase paragraph count/index
                    $para++;
                    $clip = '';
                } elsif (/<p>/i) {
                    #&l00httpd::dbp($config{'desc'}, "P: >$_<\n");
                    s/<p>/<br>$sectprelog /i;
                    # increase paragraph count/index
                    $para++;
                    $clip = '';
                } else {
                    #&l00httpd::dbp($config{'desc'}, "xx: >$_<\n");
                }
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


        # display tags in debug mode
        if ($ctrl->{'debug'} >= 4) {
            # semi hide tags
            $wget =~ s/&lt;/<font size="1" style="color:gray;background-color:white">&lt;/gs;
            #$wget =~ s/&lt;/<font size=1">&lt;/gs;
            $wget =~ s/&gt;/&gt;<\/font>/gs;
        }


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

        if (($url =~ /\.(jpeg)$/i) ||
            ($url =~ /\.(jpg)$/i) ||
            ($url =~ /\.(gif)$/i) ||
            ($url =~ /\.(png)$/i)) {
            $wget = "Target is an image: <a href=\"/ls.htm?path=l00://mobizoom.$1\">l00://mobizoom.$1</a><p>".
                    "<img src=\"/ls.htm?path=l00://mobizoom.$1\">";
            if (length ($wgetorg) > 200) {
                &l00httpd::l00fwriteOpen($ctrl, "l00://mobizoom.$1");
                &l00httpd::l00fwriteBuf($ctrl, $wgetorg);
                &l00httpd::l00fwriteClose($ctrl);
            }
        } elsif (($forcetarget eq 'jpg') ||
                 ($forcetarget eq 'png') ||
                 ($forcetarget eq 'gif')) {
            $wget = "Target forced to $forcetarget: <a href=\"/ls.htm?path=l00://mobizoom.$forcetarget\">l00://mobizoom.$forcetarget</a><p>".
                    "<img src=\"/ls.htm?path=l00://mobizoom.$forcetarget\">";
            if (length ($wgetorg) > 200) {
                &l00httpd::l00fwriteOpen($ctrl, "l00://mobizoom.$forcetarget");
                &l00httpd::l00fwriteBuf($ctrl, $wgetorg);
                &l00httpd::l00fwriteClose($ctrl);
            }
        }

        $_ = $title;
        $wget = "$title\nOriginal URL: <a href=\"$url\">$url</a><p>\n$threads\n$wget\n$threads$endanchor";
    }

    $wget;
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
    $tmp = &l00httpd::urlencode ($url);
    print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">URL</a> ";
    print $sock "<input type=\"text\" size=\"16\" name=\"url\" value=\"$url\" accesskey=\"e\"></td>\n";
    print $sock "<input type=\"submit\" name=\"fetch\" value=\"Fetch\">\n";
    print $sock "zoom:<input type=\"text\" size=\"3\" name=\"zoom\" value=\"$zoom\"></td>\n";
    print $sock "<input type=\"submit\" name=\"paste\" value=\"CB p&#818;aste\" accesskey=\"p\">\n";
    foreach $_ ((100, 110, 121, 133, 146, 160, 176, 194, 240, 300, 400, 500, 600)) {
        print $sock "<input type=\"radio\" name=\"zoomradio\" value=\"$_\"><a href=\"/mobizoom.htm?fetch=mobizoom&zoomradio=$_&url=$url\">$_</a> ";
    }
    print $sock "<input type=\"checkbox\" name=\"freeimgsize\" $freeimgsize>Free image size.\n";
    if (-f $url) {
        # if we have a cached file
        print $sock "(<input type=\"checkbox\" name=\"saveinternal\">Save int.buf. \n";
        print $sock "<a href=\"/view.htm?path=$url.internal.txt\">view</a>).\n";
    }
    print $sock "<input type=\"checkbox\" name=\"imgsrclink\" $imgsrclink>Link img src.\n";
    print $sock "Force ";
    print $sock "<input type=\"radio\" name=\"forcetarget\" value=\"jpg\">.jpg";
    print $sock "<input type=\"radio\" name=\"forcetarget\" value=\"png\">.png";
    print $sock "<input type=\"radio\" name=\"forcetarget\" value=\"gif\">.gif";
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
    print $sock "<a href=\"/launcher.htm?path=$orgurl\" target=\"_blank\">launcher</a> - \n";
    print $sock "<font style=\"color:black;background-color:lime\"><a href=\"#__here1__\">next</a></font>\n";
    print $sock "View: <a href=\"/view.htm?path=l00://mobizoom_wget.htm\">l00://mobizoom_wget.htm</a> -\n";
    print $sock "<a href=\"/view.htm?path=l00://mobizoom_mblz.htm\">l00://mobizoom_mblz.htm</a> -\n";
    print $sock "<a href=\"/wget.htm?url=$url&submit=\" target=\"_blank\">wget</a> --\n";
    $tmp = &l00httpd::urlencode ("http://googleweblight.com/?lite_url=$url");
    print $sock "<a href=\"/mobizoom.htm?fetch=Fetch&url=$tmp\" target=\"_blank\">Google web light</a>\n";
    print $sock " -- <a href=\"/ls.htm?path=l00://journal.txt\" target=\"_blank\">l00://journal.txt</a>\n";
    $title =~ s/<\/*title>//g;
    $tmp = &l00httpd::urlencode ($title);
    print $sock "-- Title: <a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">$title</a>";
    print $sock "-- <a href=\"/mobizoom.htm?fetch=Fetch&url=$backurl\">Back</a>\n";
    if ($backurl ne $url) {
        # remember back url only if different
        $backurl = $url;
    }
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
    my ($wget, $mode1online2offline4download, $path);
    my ($skip, $tmp, $title, $foundthreadphase);
    my ($hdr, $domain, $journal);



    $url = '';
    if (defined ($form->{'url'})) {
        $url = $form->{'url'};
    }
    if (defined ($form->{'fetch'}) && ($form->{'fetch'} eq 'mobizoom')) {
        # URL generated by mobizoom, use special trick to overcome & problem
        # (there's no easy way to globally translate & in URL to %26 to prevent 
        # it from processing by URL parser, so we cheat)
        # since we generate this form, we just copy from after &url=
        # s/(<a.+?href=")(https*:\/\/.+?)"/$1\/mobizoom.htm?fetch=Fetch$freetag&url=$2"/g;
        if ($ctrl->{'FORMORG'} =~ /&url=(.+)/) {
            $url = $1;
        }
    }
    if (defined ($form->{'paste'}) || defined ($form->{'fetch'})) {
        if ((defined ($form->{'freeimgsize'})) && ($form->{'freeimgsize'} eq 'on')) {
            $freeimgsize = 'checked';
        } else {
            $freeimgsize = '';
        }
        # link to img src
        if ((defined ($form->{'imgsrclink'})) && ($form->{'imgsrclink'} eq 'on')) {
            $imgsrclink = 'checked';
        } else {
            $imgsrclink = '';
        }
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
    if (defined ($form->{'forcetarget'})) {
        $forcetarget = $form->{'forcetarget'};
    } else {
        $forcetarget = '';
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
            if (-f $url) {
                # is a file, do path=./ substitution
                $path = $url;
                $path =~ s/([\\\/])[^\\\/]+$/$1/;
                $wget =~ s/path=.\//path=$path/gm;
            }
        } else {
            $wget = "Failed top load '$url'\n";
        }
    } else {
        $mode1online2offline4download = 1;
    }


    if ($mode1online2offline4download & 3) {
        &l00http_mobizoom_part1($ctrl, $sock, $title, $url, $zoom);
    }

    $here = 1;
    if (defined ($form->{'paste'}) || defined ($form->{'fetch'})) {
        $para = 1;


        if ($mode1online2offline4download == 2) {
            # mobilize page
            $wget = &l00http_mobizoom_mobilize ($ctrl, $url, $zoom, $wget,
                ((defined ($form->{'saveinternal'})) && ($form->{'saveinternal'} eq 'on')));
            print $sock $wget;
        } else {
            # $mode1online2offline4download != 2
            # fetch for active reading or caching automation
            if ($mobiz_sig ne "$url:$imgsrclink") {
                ($hdr, $mobiz_wget, $domain, $journal) = &wgetfollow2($ctrl, $url);
            }
            $mobiz_sig = "$url:$imgsrclink";


            # save file
            if ($mode1online2offline4download == 4) {
                &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
                # download too small, delete it by not writing
                if (length ($mobiz_wget) > 2000) {
                    &l00httpd::l00fwriteBuf($ctrl, "<!-- ::mobizoom::orgurl::$url -->\n$mobiz_wget");
                }
                &l00httpd::l00fwriteClose($ctrl);
            } else {
                &l00httpd::l00fwriteOpen($ctrl, 'l00://mobizoom_wget.htm');
                &l00httpd::l00fwriteBuf($ctrl, "<!-- ::mobizoom::orgurl::$url -->\n$mobiz_wget");
                &l00httpd::l00fwriteClose($ctrl);
            }
            $wget = &l00http_mobizoom_mobilize ($ctrl, $url, $zoom, $mobiz_wget,
                ((defined ($form->{'saveinternal'})) && ($form->{'saveinternal'} eq 'on')));

            if ($mode1online2offline4download & 3) {
                # web page interactive mode, render web page
                print $sock $wget;
            }
            if ($mode1online2offline4download != 4) {
                &l00httpd::l00fwriteOpen($ctrl, 'l00://mobizoom_mblz.htm');
                &l00httpd::l00fwriteBuf($ctrl, $wget);
                &l00httpd::l00fwriteClose($ctrl);
            }
        }
    }

    if ($mode1online2offline4download & 3) {
        # Add jump links if missing
        if (defined($wget) && 
            !($wget =~ /<a href="#__here0__">last<\/a>/s)) {
            &l00http_mobizoom_part2($ctrl, $sock, $here, $para);
        }

        print $sock $ctrl->{'htmlfoot'};
    }
}


\%config;
