use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

my %config = (proc => "l00http_podplay_proc",
              desc => "l00http_podplay_desc");


my ($rate, $jumpstep, $lib, %played, @playlist);
my ($seq, $AndPlayerState, $lstate, $track, $playlist_cnt, $podplayLast);

$lib = '/sdcard/podcasts/';
$rate = 3;  # secs, refresh rate
$jumpstep = 30; # seconds
$AndPlayerState = 'off';
$lstate = '';
$track = 0;
$seq = 0;
$playlist_cnt = 0;


sub l00http_podplay_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "podplay: Make toast (popup message) on the phone, a demo of controlling phone";
}

sub l00http_podplay_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($info, $podplayElapse, $refreshtag, $timems, $seqnxt, $out);
    my ($tmp, $url, $hdr, $bdy, $domain, $tail, $podname, $fname);

    # read in files that have been marked played
    undef %played;
    if (open (IN, "<${lib}played.txt")) {
        while (<IN>) {
            s/\n//;
            s/\r//;
            if (/^#(.+)$/) {
                # to ignore tracks/files marked with # in colume 0
                $played{$1} = 1;
            }
        }
        close (IN);
    }

    # scan directory $lib to make playlist
    undef @playlist;
    if (opendir (DIR, $lib)) {
        foreach $_ (readdir (DIR)) {
            if (/\.mp3$/) {
                if (!defined ($played{$_})) {
                    push (@playlist, $_);
                }
            }
        }
    }


    # Query Android player state
    $lstate = $AndPlayerState;
    $AndPlayerState = 'off';
    $info = $ctrl->{'droid'}->mediaPlayInfo('l00pod');
    if (defined ($info->{'result'})) {
        $info = $info->{'result'};
        if (defined ($info->{'loaded'})) {
            if ($info->{'loaded'} eq 'true') {
                if ($info->{'isplaying'} eq 'true') {
                    $AndPlayerState = 'playing';
                } else {
                    $AndPlayerState = 'pause';
                }
            }
        }
    }

    $refreshtag = '';

    # execute command
    # no command, 'playing' state polling
    if ((defined ($ctrl->{'FORM'}->{'play'})) &&
        defined ($ctrl->{'FORM'}->{'seq'}) &&
        ($ctrl->{'FORM'}->{'seq'} != $seq)) {
        $refreshtag = "<meta http-equiv=\"refresh\" content=\"$rate\"> ";
        $seq++;
        $track = 0;
        $ctrl->{'droid'}->mediaPlay("$lib$playlist[$track]", 'l00pod');
        $AndPlayerState = 'playing';
    } elsif (defined ($ctrl->{'FORM'}->{'stop'})) {
        $ctrl->{'droid'}->mediaPlayClose('l00pod');
        $AndPlayerState = 'off';
    } elsif ((defined ($ctrl->{'FORM'}->{'lasttrk'})) &&
        defined ($ctrl->{'FORM'}->{'seq'}) &&
        ($ctrl->{'FORM'}->{'seq'} != $seq)) {
        $refreshtag = "<meta http-equiv=\"refresh\" content=\"$rate\"> ";
        $seq++;
        $track--;
        if ($track < 0) {
            $track = 0;
        }
        $ctrl->{'droid'}->mediaPlay("$lib$playlist[$track]", 'l00pod');
        $AndPlayerState = 'playing';
    } elsif ((defined ($ctrl->{'FORM'}->{'nexttrk'})) &&
        defined ($ctrl->{'FORM'}->{'seq'}) &&
        ($ctrl->{'FORM'}->{'seq'} != $seq)) {
        $refreshtag = "<meta http-equiv=\"refresh\" content=\"$rate\"> ";
        $seq++;
        $track++;
        if ($track > $#playlist) {
            $track = $#playlist;
        }
        $ctrl->{'droid'}->mediaPlay("$lib$playlist[$track]", 'l00pod');
        $AndPlayerState = 'playing';
    } elsif (defined ($ctrl->{'FORM'}->{'pause'})) {
        $ctrl->{'droid'}->mediaPlayPause('l00pod');
        $AndPlayerState = 'pause';
    } elsif (defined ($ctrl->{'FORM'}->{'cont'})) {
        $refreshtag = "<meta http-equiv=\"refresh\" content=\"$rate\"> ";
        $ctrl->{'droid'}->mediaPlayStart('l00pod');
        $AndPlayerState = 'playing';
    } elsif ((defined ($ctrl->{'FORM'}->{'back'})) &&
        defined ($ctrl->{'FORM'}->{'seq'}) &&
        ($ctrl->{'FORM'}->{'seq'} != $seq)) {
        $refreshtag = "<meta http-equiv=\"refresh\" content=\"$rate\"> ";
        $seq++;
        $timems = $info->{'position'} - $jumpstep * 1000;
        if ($timems < 0) {
            $timems = 0;
        }
#       printf $sock ("Rewind $jumpstep secs from %d to %d secs.<br>\n", 
#           $info->{'position'} / 1000, $timems / 1000);
        $ctrl->{'droid'}->mediaPlaySeek($timems, 'l00pod');
        $AndPlayerState = 'playing';
    } elsif ((defined ($ctrl->{'FORM'}->{'forward'})) &&
        defined ($ctrl->{'FORM'}->{'seq'}) &&
        ($ctrl->{'FORM'}->{'seq'} != $seq)) {
        $refreshtag = "<meta http-equiv=\"refresh\" content=\"$rate\"> ";
        $seq++;
        $timems = $info->{'position'} + $jumpstep * 1000;
        if ($timems > $info->{'duration'}) {
            $timems = $info->{'duration'} - $jumpstep * 1000;;
        }
#       printf $sock ("Forward $jumpstep secs from %d to %d secs.<br>\n", 
#           $info->{'position'} / 1000, $timems / 1000);
        $ctrl->{'droid'}->mediaPlaySeek($timems, 'l00pod');
        $AndPlayerState = 'playing';
    } elsif (($lstate eq 'playing') && ($AndPlayerState eq 'pause') &&
        defined ($ctrl->{'FORM'}->{'seq'}) &&
        ($ctrl->{'FORM'}->{'seq'} == $seq)) {
        if ($track + 1 <= $#playlist) {
#           printf $sock ("Track #%d endded. Start #%d<br>\n",
#               $track + 1, $track + 2);
            if (open (OU, ">>${lib}played.txt")) {
                # record played tracks
                print OU "$playlist[$track]\n";
                close (OU);
            }
            $track++;
            $ctrl->{'droid'}->mediaPlay("$lib$playlist[$track]", 'l00pod');
            $AndPlayerState = 'playing';
        }
    } elsif (defined ($ctrl->{'FORM'}->{'refresh'})) {
        $refreshtag = "<meta http-equiv=\"refresh\" content=\"$rate\"> ";
    }




$out = '';
    if (defined($ctrl->{'FORM'}->{'clip'})) {
        $tmp = &l00httpd::l00getCB($ctrl);
#       $refreshtag = "<meta http-equiv=\"refresh\" content=\"$rate\"> ";
#       $seq++;
#       $track = 0;
#       $ctrl->{'droid'}->mediaPlay($tmp, 'l00pod');
        $AndPlayerState = 'playing';
        $AndPlayerState = '';

# Extract URL from clipboard
$url = &l00httpd::l00getCB($ctrl);
$out .= "<hr>Clipboard content:<br>$url<p><hr>\n";
$tail = '';
if ($url =~ /(https*:\/\/[^ \n\r\t]+)/) {
    $url = $1;
    if ($url =~ /\/([^ \/]+)$/) {
        $tail = $1;
    }
}
$out .= "Found URL:<br><a href=\"$url\">$url</a><p><hr>Fetch it:<br>\n";

# Fetch first URL
($hdr, $bdy) = &l00wget::wget ($url);
&l00httpd::l00fwriteOpen($ctrl, 'l00://pod1');
&l00httpd::l00fwriteBuf($ctrl, "$hdr\n\n$bdy");
&l00httpd::l00fwriteClose($ctrl);

if (defined($bdy)) {
    $out .= "header bytes " . length($hdr) . " body bytes " . length($bdy) . ". \n";
    $out .= "Fetch result: <a href=\"/view.htm?path=l00://pod1\">view l00://pod1</a><p>\n";
    $url = '';
    if ($bdy =~ /<audio +src="(http:.+?\.mp3)"/) {
        # <audio src="http://cdn.pri.org/sites/default/files/pris-world/segment-audio/121020146.mp3" class="mediaelement-formatter-identifier-1418279453-0" controls="controls" style="max-width: 100%;" preload="none" >
        $url = $1;
        $out .= "audio src URL:<br><a href=\"$url\">$url</a><p><hr>\n";
    } else {
        # no <audio src= tag, search for *.mp3
        $bdy =~ s/</&lt;/g;
        $bdy =~ s/>/&gt;\n/g;
        $out .= "Potential .mp3 URLs:<br>\n";
        foreach $_ (split ("\n", $bdy)) {
            $out .= "$_<p>\n", if (/http.*\.mp3/);
            if (/(http.*\.mp3)/) {
                if ($url eq '') { 
                    $url = $1;
                    $out .= ".mp3 URL:<br><a href=\"$url\">$url</a><p><hr>\n";
                    last;
                }
            }
        }
    }

    if ($url ne '') {
        if ($url =~ /http:\/\/.+?\.(.+?\..+?)\//) {
            $domain = $1;
            $out .= "domain -- tail:<br>$domain -- $tail<p>\n";
        }
        if ($url =~ /\/([^\/]+\.mp3)/) {
            $podname = $1;
            $out .= "podname: $1<p>\n";
        }
        ($hdr, $bdy) = &l00wget::wget ($url);
        &l00httpd::l00fwriteOpen($ctrl, 'l00://pod2');
        &l00httpd::l00fwriteBuf($ctrl, "$hdr\n\n$bdy");
        &l00httpd::l00fwriteClose($ctrl);
        if (defined($hdr)) {
            $out .= "header bytes " . length($hdr) . " body bytes " . length($bdy) . "<p>\n";
            $out .= "<a href=\"/view.htm?path=l00://pod2\">l00://pod2</a><p>\n";
            $hdr =~ s/</&lt;/g;
            $hdr =~ s/>/&gt;\n/g;
            $out .= "$hdr\n";

            $fname = "/sdcard/podcasts/${domain}_${tail}_$podname";
            $fname =~ s/ /_/g;
            if (($url) = $hdr =~ /(http:\/\/.+\.mp3.+?)\n/) {
                $out .= "<p>fname $fname<p>\n";
                $out .= "mp3: $url<p>\n";
                $out .= "mp3:<br><a href=\"$url\">$url</a><p>\n";
                ($hdr, $bdy) = &l00wget::wget ($url);
                if (defined($bdy)) {
                    $out .= "hdr " . length($hdr) . " bdy " . length($bdy) . " $fname<p>\n";
                    if (open (OU, ">$fname")) {
                        binmode (OU);
                        print OU $bdy;
                        close (OU);
                    }
                    $out .= "<a href=\"/ls.htm?path=/sdcard/podcasts/\">/sdcard/podcasts/</a>\n";
                }
            }
        }
    }
}
    }





    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>podplay</title>" . $refreshtag . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}\n";


print $sock $out;
    print $sock "<br><form action=\"/podplay.htm\" method=\"get\">\n";


    # make bit 'buttons'
    #$podsame = "<a href=\"/do.htm?path=/sdcard/l00httpd/l00_play_podcast.pl";
    $seqnxt = $seq + 1;
    if ($AndPlayerState eq 'off') {
        print $sock "<input type=\"submit\" name=\"play\" value=\"Play\">\n";
    }
    if ($AndPlayerState eq 'playing') {
        print $sock "<input type=\"submit\" name=\"lasttrk\" value=\"<<<\">\n";
        print $sock "<input type=\"submit\" name=\"back\" value=\"<-\">\n";
        print $sock "<input type=\"submit\" name=\"pause\" value=\"Pause\">\n";
        print $sock "<input type=\"submit\" name=\"forward\" value=\"->\">\n";
        print $sock "<input type=\"submit\" name=\"nexttrk\" value=\">>>\">\n";
    }
    if ($AndPlayerState eq 'pause') {
        print $sock "<input type=\"submit\" name=\"lasttrk\" value=\"<<<\">\n";
        print $sock "<input type=\"submit\" name=\"back\" value=\"<-\">\n";
        print $sock "<input type=\"submit\" name=\"cont\" value=\"Cont\">\n";
        print $sock "<input type=\"submit\" name=\"forward\" value=\"->\">\n";
        print $sock "<input type=\"submit\" name=\"nexttrk\" value=\">>>\">\n";
    }
    if ($AndPlayerState ne 'off') {
        print $sock "<input type=\"submit\" name=\"stop\" value=\"Stop\">\n";
    }
    print $sock "<br>\n";
    print $sock "<input type=\"submit\" name=\"refresh\" value=\"...\">\n";
    print $sock "<br>\n";

print $sock "<br>\n";
print $sock "<input type=\"submit\" name=\"clip\" value=\"Fetch .mp3 URL\">\n";
    $seqnxt = $seq + 1;
    print $sock "<INPUT TYPE=\"hidden\" NAME=\"seq\" VALUE=\"$seqnxt\">\n";
    print $sock "</form>\n";


    print $sock "<a href=\"/play.htm\" target=\"newwin\">volume</a><p>\n";
    print $sock "<hr>\n";


    # progress
    if (defined ($info->{'position'})) {
        printf $sock ("Playing %d/%d secs. \n", 
            $info->{'position'} / 1000,
            $info->{'duration'} / 1000);
        printf $sock ("Track %d/%d.\n", 
            $track + 1, $#playlist + 1);
    }
    print $sock "<a href=\"/ls.htm?path=$lib\">list tracks</a>.\n";
    print $sock "Mark played in <a href=\"/recedit.htm?record1=.&path=${lib}played.txt\">played.txt</a>.\n";
    print $sock "<br>\n";

    # last call when?
    $playlist_cnt += 1;
    print $sock "call #$playlist_cnt. seq: $seq. ";
    if (defined ($podplayLast)) {
        $podplayElapse = time - $podplayLast;
        print $sock "Last invoked $podplayElapse secs ago<p> \n";
    }

    print $sock "<pre>\n";
    print $sock l00httpd::dumphashbuf("playInfo", $ctrl->{'droid'}->mediaPlayInfo('l00pod')) . "\n";
    print $sock l00httpd::dumphashbuf("playList", $ctrl->{'droid'}->mediaPlayList()) . "\n";
    print $sock "</pre>\n";

    $podplayLast = time;
    print $sock "Audio found in <a href=\"/ls.htm?path=$lib\">$lib</a>\n";
    print $sock "<pre>\n";
    $tmp = 1;
    foreach $_ (@playlist) {
        print $sock "$tmp: $_\n";
        $tmp++;
    }
    print $sock "</pre>\n";

    print $sock "Played in <a href=\"/ls.htm?path=$lib\">$lib</a>\n";
    print $sock "<pre>\n";
    $tmp = 1;
    foreach $_ (keys %played) {
        print $sock "$tmp: $_\n";
        $tmp++;
    }
    print $sock "</pre>\n";


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
