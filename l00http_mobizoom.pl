use strict;
use warnings;

use l00httpd;
use l00crc32;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# a trivial web page mobilizer

# Dropping the defunct Google mobilizer and start a local 
# implementation. Last Google version in commit 1ea84e6


my %config = (proc => "l00http_mobizoom_proc",
              desc => "l00http_mobizoom_desc");
my ($url, $zoom, $para, $here, $prolog);
$url = '';
$zoom = 120;
$para = 1;

sub l00http_mobizoom_wget_follow {
    my ($ctrl, $url) = @_;
    my ($hdr, $bdy, $followmoves, $domain, $moved);

    $hdr = '';
    $bdy = '';


    for ($followmoves = 0; $followmoves < 10; $followmoves++) {
        $domain = '';
        if ($url =~ /http:\/\/([^\/]+?)\//) {
            $domain = $1;
        }
        $url =~ s/\r//g;
        $url =~ s/\n//g;
        ($hdr, $bdy) = &l00wget::wget ($url);
        &l00httpd::dbp('wget_follow', sprintf("#%d: HDR (%d B), BDY (%d B), URL:>%s<\n", 
            $followmoves, length($hdr), length($bdy), $url)) , if ($ctrl->{'debug'} >= 3);
        if ($ctrl->{'debug'} >= 4) {
            &l00httpd::dbp($config{'desc'}, sprintf (
                "URL is %3d bytes long and CRC32 is 0x%08x\n",
                length($url), 
                &l00crc32::crc32($url)));
        }
        &l00httpd::dbp($config{'desc'}, "Header:\n$hdr"), if ($ctrl->{'debug'} >= 4);

        # Find HTTP return code
        $moved = '';
        foreach $_ (split("\n", $hdr)) {
            if (($moved eq '') && (/^HTTP.* 301 /)) {
                $moved = 'moved';
            }
            if (($moved eq 'moved') && (/^location: +(.+)/i)) {
                $url = $1;
                if (!($url =~ /^http:\/\//)) {
                    $url = "http://$domain$url";
                }
                $moved = 'found';
            }
        }
        if ($moved ne 'found') {
            # didn't move, last fetch
            $followmoves = 100;
        }
    }

    ($domain, $hdr, $bdy);
}


sub l00http_mobizoom_wget {
    my ($ctrl, $url, $zoom) = @_;
    my ($wget, $wget2, $pre, $gurl, $post, $hdr, $subj, $clip, $last);
    my ($on_slashdot_org, $threads, $endanchor, $domain, $title);


    $wget = '';
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
        ($domain, $hdr, $wget) = &l00http_mobizoom_wget_follow($ctrl, $url);

        # find title
        if ($wget =~ /(<title>.+?<\/title.*?>)/s) {
            $title = "$1\n";
        }
        # 2) add navigation and content clip link for each paragraph

        $wget2 = '';
        # modify by each new line
        foreach $_ (split("\n", $wget)) {
#            # make link to send text to clipboard
#            $clip = $_;
#            $clip =~ s/<.+?>//g;    # drop all HTML tags
#            $clip = &l00httpd::urlencode ($clip);
#
#            # insert navigation and clip links 
#            ## change this:
#            ## <br/><br/>
#            ## to:
#            ## <br/><br/>
#            ##  <a name="p$para"></a>
#            ##  <small>
#            ##    <a href="#__end__">V</a> &nbsp; 
#            ##    <a href="#p$para">$para</a> &nbsp; 
#            ##    <a href="/clip.htm?update=Copy+to+CB&clip=$clip" target="clip"> : </a> &nbsp; 
#            ##  </small> /;
#            s/<br\/><br\/>/<br\/><br\/><a name="p$para"><\/a><small><a href="#__end__">V<\/a> &nbsp; <a href="#p$para">$para<\/a> &nbsp; <a href="\/clip.htm?update=Copy+to+CB&clip=$clip" target="clip"> : <\/a> &nbsp; <\/small> /;
#            s/span><span/span> <span/g;
            $wget2 .= "$_\n";
#
## 2.1) and some site specific special handling:
### slashdot: find thread head
### latimes: find article start
#
## Search for Slashdot thread SUBJECT and make a list to jump to start of thread
## <b>SUBJECT</b></a><b> (</b><a href=...><b>Score:
#if(($subj) = /<b>(.+?)<\/b><\/a><b> \(<\/b><a href=.+?><b>Score:/) {
#  &l00httpd::dbp($config{'desc'}, "    >>>$subj<<<\n");
#  if(!($subj =~ /^Re:/)) {
#    # This is a new subject line
#    $threads .= "<a href=\"#p$para\">$para: $subj</a><br>\n";
#    $wget2 .= " <font style=\"color:black;background-color:lime\"> FOUND THREAD </font> \n";
#  }
#}


## Make a link to the start of article on LA Times articles
#if(/Create a custom date range/) {
#  $wget2 .= "<a name=\"__latimes__\"></a>FOUDN FOUND Create a custom date range ";
#  $prolog = '<br><a href="#__latimes__">Jump to LA Times article start.</a><p>';
#}
#
## send processed line to dbp
##s/</&lt;/g;
##s/>/&gt;/g;
##&l00httpd::dbp($config{'desc'}, "$_\n");
#
###<br/><br/><a name="__para41__"></a><small><a href="#__top__">^</a>:<a href="#__para41__">41</a></small> <a href='/gwt/x?wsc=pb&u=http://it.slashdot.org/comments.pl%3Fsid%3D4793473%26cid%3D46250423&ei=-QT_UrKyMIa3kAKD4oCIDw'><b>Posting anonymously for obvious reasons...</b></a><b> (</b><a href='/gwt/x?wsc=pb&u=http://rss.slashdot.org/~r/Slashdot/slashdot/~3/ZLaYpqISs0Y/story01.htm&ei=-QT_UrKyMIa3kAKD4oCIDw'><b>Score:</b></a><a href='/gwt/x?wsc=pb&u=http://rss.slashdot.org/~r/Slashdot/slashdot/~3/ZLaYpqISs0Y/story01.htm&ei=-QT_UrKyMIa3kAKD4oCIDw'><b>5</b></a><b>, Interesting)</b>
###
###<b>Posting anonymously for obvious reasons...</b></a><b> (</b>
###<a href='/gwt/x?wsc=pb&u=http://rss.slashdot.org/~r/Slashdot/slashdot/~3/ZLaYpqISs0Y/story01.htm&ei=-QT_UrKyMIa3kAKD4oCIDw'>
###<b>Score:</b></a><a href='/gwt/x?wsc=pb&u=http://rss.slashdot.org/~r/Slashdot/slashdot/~3/ZLaYpqISs0Y/story01.htm&ei=-QT_UrKyMIa3kAKD4oCIDw'><b>5</b></a><b>, Interesting)</b>

            $last = $_;
        }
#        $wget = $wget2;

        # 3) drop HTML tags and add font-size as specified:
        ## <html>
        ## <body>
        ## <span>
        ## <div>

        # remote various HTML tags
        $wget =~ s/<\/*html.*?>//gs;
        $wget =~ s/<head.*?>.*?<\/head.*?>//gs;
        $wget =~ s/<\/*body.*?>//gs;

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

        #$wget =~ s/(<a.+?href=")(\/.+?)(".+?>)/$1http:\/\/$domain$2$3/gs;  # not working

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
    }

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


    "$title\nOriginal URL: <a href=\"$url\">$url</a><p>\n$threads\n$wget\n$threads$endanchor";
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
    my ($wget, $mode1online2offline4download);
    my ($skip, $tmp, $urlorg, $title, $foundthreads, $foundthreadphase, $foundthreadcnt);

    $url = '';
    if (defined ($form->{'url'})) {
        $url = $form->{'url'};
    }

    if (defined ($form->{'paste'})) {
        $url = &l00httpd::l00getCB($ctrl);
        if (!($url =~ /^\//)) {
            # extract URL only if it doesn't look like a local file
            if ($url =~ /(https*:\/\/[^ \n\r\t]+)/) {
                $url = $1;
            }
            if (!($url =~ /https*:\/\//)) {
                # Opera Mini does not include http://
                $url = "http://$url";
            }
            # News++ adds ?rss=1, drop it
            $url =~ s|\?rss=1$||;
        } else {
            # must be reading locally cached file
            $form->{'paste'} = undef;
            $form->{'fetch'} = 1;
            if (&l00httpd::l00freadOpen($ctrl, $url)) {
                $mode1online2offline4download = 2;
                $wget = &l00httpd::l00freadAll($ctrl);
            }
        }
        #print "From clipboard:\n$url\n", if ($ctrl->{'debug'} >= 3);
    }

    if ($url =~ /google\.com\/url\?.*&q=(http.+)[^&]/) {
        $url = $1;
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


    $title = "Mobizoom $url";

    # determining mode of operation: $mode1online2offline4download
    ## 1: online: do a live fetch (user interacts through web page)
    ## 2: offline: fetch from a cached file (user interacts through web page)
    ## 4: download: do a live fetch and save as a cached file (no web UI automation)
    # for mode 1 and 2 the web page must be rendered
    # for mode 4 the web page must not be rendered

    # if $form->{'path'} is provided, then download (unless on RHC)
    # else if $form->{'url'} points to a local cached file, do offline
    # else do live fetch

    if ((defined ($form->{'path'})) && ($ctrl->{'os'} ne 'rhc')) {
        # only when not on RHC
        $mode1online2offline4download = 4;
    } elsif (&l00httpd::l00freadOpen($ctrl, $url)) {
        $mode1online2offline4download = 2;
        $wget = &l00httpd::l00freadAll($ctrl);
        # find embedded page title
        if ($wget =~ /<title>(.+?)<\/title.*?>/s) {
            $title = "$1\n";
        }
#        foreach $_ (split("\n", $wget)) {
#            if ($title eq 'NEXTLINEISTITLE') {
#                l00httpd::dbp($config{'desc'}, "Next line is [$_]\n"), if ($ctrl->{'debug'} >= 0);
#                if (length ($_) < 10) {
#                    # title less than 10 char, can't be
#                    $title = 'Mobilizer Zoom';
#                } else {
#                    $title = $_;
#                }
#                last;
#            }
#            if (/<title>/) {
#                # next line should be page title
#                $title = 'NEXTLINEISTITLE';
#                l00httpd::dbp($config{'desc'}, "Next line should be page title\n"), if ($ctrl->{'debug'} >= 0);
#            }
#        }
    } else {
        $mode1online2offline4download = 1;
    }



    if ($mode1online2offline4download & 3) {
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
        $urlorg = $url;
        $urlorg =~ s/&ei=.*$//; # drop &ei=...
        $tmp = $urlorg;
        $tmp =~ s/ /+/g;
        $tmp =~ s/:/%3A/g;
        $tmp =~ s/&/%26/g;
        $tmp =~ s/=/%3D/g;
        $tmp =~ s/"/%22/g;
        $tmp =~ s/\//%2F/g;
        $tmp =~ s/\|/%7C/g;
        print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$tmp\">URL:</a>\n";
        print $sock "<a href=\"$urlorg\">original</a> \n";
        print $sock "<font style=\"color:black;background-color:lime\"><a href=\"#__here1__\">next</a></font>\n";
        print $sock "View: <a href=\"/view.htm?path=l00://mobizoom.htm\">l00://mobizoom.htm</a> -\n";
        print $sock "<a href=\"/wget.htm?url=$url&submit=\" target=\"newwget\">wget</a> --\n";
        $tmp = &l00httpd::urlencode ("http://googleweblight.com/?lite_url=$url");
        print $sock "<a href=\"/mobizoom.htm?fetch=Fetch&url=$tmp\" target=\"newgwl\">Google web light</a>\n";
        print $sock "<hr>\n";
    }

    $here = 1;
    if (defined ($form->{'paste'}) || defined ($form->{'fetch'})) {
        $para = 1;
        if ($mode1online2offline4download == 4) {
            &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
        } else {
            &l00httpd::l00fwriteOpen($ctrl, 'l00://mobizoom.htm');
        }
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
            print $sock $wget;
            if ($foundthreadcnt > 1) {
                print $sock $foundthreads;
            }
        } else {
            # $mode1online2offline4download != 2
            # fetch for active reading or caching automation

#           &l00httpd::l00fwriteBuf($ctrl, "Original URL: <a href=\"$url\">$url</a><p>\n");
            # fetch repeatedly as necessary as Google mobilizer break page
            # into multiple mobilized pages
            $wget = &l00http_mobizoom_wget ($ctrl, $url, $zoom);

            if ($mode1online2offline4download & 3) {
                # web page interactive mode, render web page
                print $sock $wget;
            }
            &l00httpd::l00fwriteBuf($ctrl, $wget);
            &l00httpd::l00fwriteClose($ctrl);
            if (($mode1online2offline4download == 4) && (length ($wget) < 5000)) {
                # download too small, delete it
                &l00httpd::l00fwriteOpen($ctrl, $form->{'path'});
                &l00httpd::l00fwriteClose($ctrl);
            }
        }
    }

    if ($mode1online2offline4download & 3) {
        # Add jump links if missing
        if (!($wget =~ /<a href="#__here0__">last<\/a>/s)) {
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

        print $sock $ctrl->{'htmlfoot'};
    }
}


\%config;
