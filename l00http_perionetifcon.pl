use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14


my ($lastcalled, $netiflog, $netifcnt, $netifnoln, $perltime, %ifrxtx, %ifbase, $totalifcon);
my %config = (proc => "l00http_perionetifcon_proc",
              desc => "l00http_perionetifcon_desc",
              perio => "l00http_perionetifcon_perio");
my (%netstatout, %allsocksever, $savedpath, $marks);
my (%ifsrx, %ifstx, $isp, %alwayson, %seennow, $lasttotalifcon, $lastisp, $lasttime);
my $interval = 0, $lastcalled = 0;
$netifcnt = 0;
$perltime = 0;
$savedpath = '';
$totalifcon = 0;
$netiflog = '';
$netifnoln = 0;
$isp = 0;
$marks = '';
$lasttotalifcon = -1;
$lastisp = -1;
$lasttime = -1;

sub l00http_perionetifcon_suspend {
    my ($ctrl) = @_;
    my $sock = $ctrl->{'sock'};     # dereference network socket

    # suspend to sdcard so it can be resumed after restart
    &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_vals.saved");
    &l00httpd::l00fwriteBuf($ctrl, "interval=$interval\n");
    &l00httpd::l00fwriteBuf($ctrl, "netifcnt=$netifcnt\n");
    &l00httpd::l00fwriteBuf($ctrl, "totalifcon=$totalifcon\n");
    &l00httpd::l00fwriteBuf($ctrl, "netifnoln=$netifnoln\n");
    &l00httpd::l00fwriteBuf($ctrl, "savedpath=$savedpath\n");
    &l00httpd::l00fwriteBuf($ctrl, "perltime=$perltime\n");
    &l00httpd::l00fwriteBuf($ctrl, "isp=$isp\n");
    &l00httpd::l00fwriteBuf($ctrl, "lastisp=$lastisp\n");
    &l00httpd::l00fwriteBuf($ctrl, "lasttotalifcon=$lasttotalifcon\n");
    &l00httpd::l00fwriteBuf($ctrl, "lasttime=$lasttime\n");
    if (&l00httpd::l00fwriteClose($ctrl)) {
        print $sock "Unable to write '$ctrl->{'workdir'}tmp/l00_perionetifcon_vals.saved'<p>\n";
    }

    &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_netiflog.saved");
    &l00httpd::l00fwriteBuf($ctrl, $netiflog);
    if (&l00httpd::l00fwriteClose($ctrl)) {
        print $sock "Unable to write '$ctrl->{'workdir'}tmp/l00_perionetifcon_netiflog.saved'<p>\n";
    }
    &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_marks.saved");
    &l00httpd::l00fwriteBuf($ctrl, $marks);
    if (&l00httpd::l00fwriteClose($ctrl)) {
        print $sock "Unable to write '$ctrl->{'workdir'}tmp/l00_perionetifcon_marks.saved'<p>\n";
    }

    &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_allsocksever.saved");
    foreach $_ (sort keys %allsocksever) {
        &l00httpd::l00fwriteBuf($ctrl, "$_ => $allsocksever{$_}\n");
    }
    if (&l00httpd::l00fwriteClose($ctrl)) {
        print $sock "Unable to write '$ctrl->{'workdir'}tmp/l00_perionetifcon_allsocksever.saved'<p>\n";
    }

    &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_alwayson.saved");
    foreach $_ (sort keys %alwayson) {
        &l00httpd::l00fwriteBuf($ctrl, "$_ => $alwayson{$_}\n");
    }
    if (&l00httpd::l00fwriteClose($ctrl)) {
        print $sock "Unable to write '$ctrl->{'workdir'}tmp/l00_perionetifcon_alwayson.saved'<p>\n";
    }

    l00httpd::dbp($config{'desc'}, "Suspend to sdcard:\n");
    l00httpd::dbp($config{'desc'}, "interval=$interval\n");
    l00httpd::dbp($config{'desc'}, "netifcnt=$netifcnt\n");
    l00httpd::dbp($config{'desc'}, "totalifcon=$totalifcon\n");
    l00httpd::dbp($config{'desc'}, "netifnoln=$netifnoln\n");
    l00httpd::dbp($config{'desc'}, "savedpath=$savedpath\n");
    l00httpd::dbp($config{'desc'}, "perltime=$perltime\n");
    l00httpd::dbp($config{'desc'}, "isp=$isp\n");
    l00httpd::dbp($config{'desc'}, "netiflog:\n");
    l00httpd::dbp($config{'desc'}, $netiflog);
    l00httpd::dbp($config{'desc'}, "allsocksever:\n");
    foreach $_ (sort keys %allsocksever) {
        l00httpd::dbp($config{'desc'}, "$_ => $allsocksever{$_}\n");
    }
    l00httpd::dbp($config{'desc'}, "allsocksever:\n");
    foreach $_ (sort keys %alwayson) {
        l00httpd::dbp($config{'desc'}, "$_ => $alwayson{$_}\n");
    }
}

sub l00http_perionetifcon_resume {
    my ($ctrl) = @_;
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my ($key, $val);

    # resume from sdcard after restart
    if (&l00httpd::l00freadOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_vals.saved")) {
        $interval = 0;
        $netifcnt = 0;
        $netiflog = '';
        $totalifcon = 0;
        $netifnoln = 0;
        $savedpath = '';
        $isp = 0;
        undef %allsocksever;
        undef %alwayson;

        $_ = &l00httpd::l00freadLine($ctrl);
        ($interval) = /interval=(\d+)/;
        $_ = &l00httpd::l00freadLine($ctrl);
        ($netifcnt) = /netifcnt=(\d+)/;
        $_ = &l00httpd::l00freadLine($ctrl);
        ($totalifcon) = /totalifcon=(\d+)/;
        $_ = &l00httpd::l00freadLine($ctrl);
        ($netifnoln) = /netifnoln=(\d+)/;
        $_ = &l00httpd::l00freadLine($ctrl);
        if (!(($savedpath) = /savedpath=(.+)/)) {
            $savedpath = '';
        }
        $_ = &l00httpd::l00freadLine($ctrl);
        ($perltime) = /perltime=(\d+)/;
        $_ = &l00httpd::l00freadLine($ctrl);
        ($isp) = /isp=([0-9\.]+)/;

        $_ = &l00httpd::l00freadLine($ctrl);
        if ((!defined($_)) || (!(($lastisp) = /lastisp=(\d+)/))) {
            $lastisp = 0;
        }
        $_ = &l00httpd::l00freadLine($ctrl);
        if ((!defined($_)) || (!(($lasttotalifcon) = /lasttotalifcon=(\d+)/))) {
            $lasttotalifcon = 0;
        }
        $_ = &l00httpd::l00freadLine($ctrl);
        if ((!defined($_)) || (!(($lasttime) = /lasttime=(\d+)/))) {
            $lasttime = 0;
        }

        &l00httpd::l00freadOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_netiflog.saved");
        $netiflog = &l00httpd::l00freadAll($ctrl);
        if (!defined($netiflog)) {
            $netiflog = '';
        }
        &l00httpd::l00freadOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_marks.saved");
        $marks = &l00httpd::l00freadAll($ctrl);
        if (!defined($marks)) {
            $marks = '';
        }

        &l00httpd::l00freadOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_allsocksever.saved");
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            if (($key, $val) = /(.+) => (.+)/) {
                $allsocksever{$key} = $val;
            }
        }
        &l00httpd::l00freadOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_alwayson.saved");
        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            if (($key, $val) = /(.+) => (.+)/) {
                $alwayson{$key} = $val;
            }
        }


        l00httpd::dbp($config{'desc'}, "Resumed from sdcard:\n");
        l00httpd::dbp($config{'desc'}, "interval=$interval\n");
        l00httpd::dbp($config{'desc'}, "netifcnt=$netifcnt\n");
        l00httpd::dbp($config{'desc'}, "totalifcon=$totalifcon\n");
        l00httpd::dbp($config{'desc'}, "netifnoln=$netifnoln\n");
        l00httpd::dbp($config{'desc'}, "savedpath=$savedpath\n");
        l00httpd::dbp($config{'desc'}, "perltime=$perltime\n");
        l00httpd::dbp($config{'desc'}, "isp=$isp\n");
        l00httpd::dbp($config{'desc'}, "netiflog:\n");
        l00httpd::dbp($config{'desc'}, $netiflog);
        l00httpd::dbp($config{'desc'}, "allsocksever:\n");
        foreach $_ (sort keys %allsocksever) {
            l00httpd::dbp($config{'desc'}, "$_ => $allsocksever{$_}\n");
        }
        l00httpd::dbp($config{'desc'}, "alwayson:\n");
        foreach $_ (sort keys %alwayson) {
            l00httpd::dbp($config{'desc'}, "$_ => $alwayson{$_}\n");
        }

        # delete .saved once resumed
        &l00backup::backupfile  ($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_vals.saved", 0, 0);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_vals.saved");
        &l00httpd::l00fwriteClose($ctrl);
        &l00backup::backupfile  ($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_netiflog.saved", 0, 0);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_netiflog.saved");
        &l00httpd::l00fwriteClose($ctrl);
        &l00backup::backupfile  ($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_marks.saved", 0, 0);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_marks.saved");
        &l00httpd::l00fwriteClose($ctrl);
        &l00backup::backupfile  ($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_allsocksever.saved", 0, 0);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_allsocksever.saved");
        &l00httpd::l00fwriteClose($ctrl);
        &l00backup::backupfile  ($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_alwayson.saved", 0, 0);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_alwayson.saved");
        &l00httpd::l00fwriteClose($ctrl);
    }
}

sub l00http_perionetifcon_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition

    # auto resume
    &l00http_perionetifcon_resume($ctrl);

    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    " C: perionetifcon: Periodic logging of netstat";
}


sub l00http_perionetifcon_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($tmp, $buf, $key, $val, $poorwhois);
 
    # get submitted name and print greeting
    if (defined ($form->{"interval"}) && ($form->{"interval"} >= 0)) {
        $interval = $form->{"interval"};
    }
    if ((defined ($form->{"ispadj"})) && ($form->{"ispadj"} >= 0)) {
        $isp = $form->{"ispadj"};
    }
    if (defined ($form->{"restore"})) {
        &l00httpd::l00freadOpen($ctrl,  "$ctrl->{'workdir'}tmp/l00_perionetifcon_vals.saved.-.bak");
        $tmp = &l00httpd::l00freadAll($ctrl);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_vals.saved");
        &l00httpd::l00fwriteBuf($ctrl, $tmp);
        &l00httpd::l00fwriteClose($ctrl);

        &l00httpd::l00freadOpen($ctrl,  "$ctrl->{'workdir'}tmp/l00_perionetifcon_netiflog.saved.-.bak");
        $tmp = &l00httpd::l00freadAll($ctrl);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_netiflog.saved");
        &l00httpd::l00fwriteBuf($ctrl, $tmp);
        &l00httpd::l00fwriteClose($ctrl);

        &l00httpd::l00freadOpen($ctrl,  "$ctrl->{'workdir'}tmp/l00_perionetifcon_marks.saved.-.bak");
        $tmp = &l00httpd::l00freadAll($ctrl);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_marks.saved");
        &l00httpd::l00fwriteBuf($ctrl, $tmp);
        &l00httpd::l00fwriteClose($ctrl);

        &l00httpd::l00freadOpen($ctrl,  "$ctrl->{'workdir'}tmp/l00_perionetifcon_allsocksever.saved.-.bak");
        $tmp = &l00httpd::l00freadAll($ctrl);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_allsocksever.saved");
        &l00httpd::l00fwriteBuf($ctrl, $tmp);
        &l00httpd::l00fwriteClose($ctrl);

        &l00httpd::l00freadOpen($ctrl,  "$ctrl->{'workdir'}tmp/l00_perionetifcon_alwayson.saved.-.bak");
        $tmp = &l00httpd::l00freadAll($ctrl);
        &l00httpd::l00fwriteOpen($ctrl, "$ctrl->{'workdir'}tmp/l00_perionetifcon_alwayson.saved");
        &l00httpd::l00fwriteBuf($ctrl, $tmp);
        &l00httpd::l00fwriteClose($ctrl);
    }
    if (defined ($form->{"stop"})) {
        $interval = 0;
    }
    if (defined ($form->{"suspend"})) {
        &l00http_perionetifcon_suspend($ctrl);
    }
    if (defined ($form->{"resume"})) {
        &l00http_perionetifcon_resume($ctrl);
    }
    if (defined ($form->{"clear"})) {
        $interval = 0;
        $netifcnt = 0;
        $isp = 0;
        $netiflog = '';
        $totalifcon = 0;
        $netifnoln = 0;
        $savedpath = '';
        undef %allsocksever;
        undef %alwayson;
    }
    # save path
    if (defined ($form->{"save"}) && defined ($form->{'savepath'}) && (length ($form->{'savepath'}) > 0)) {
#       if (open (OU, ">$form->{'savepath'}")) 
        if (&l00httpd::l00fwriteOpen($ctrl, "$form->{'savepath'}")) {
            foreach $_ (keys %alwayson) {
                if ($alwayson{$_} ne '') {
#                   print OU "$alwayson{$_}\n";
                    &l00httpd::l00fwriteBuf($ctrl, "$alwayson{$_}\n");
                }
            }
#           print OU $marks.$netiflog;
            &l00httpd::l00fwriteBuf($ctrl, $marks.$netiflog);
#           close (OU);
            &l00httpd::l00fwriteClose($ctrl);
            $savedpath = $form->{'savepath'};
        }
    }
    if (defined ($form->{"overwrite"}) && defined ($form->{'owpath'}) && (length ($form->{'owpath'}) > 0)) {
#       if (open (OU, ">$form->{'owpath'}"))
        if (&l00httpd::l00fwriteOpen($ctrl, "$form->{'owpath'}")) {
            foreach $_ (keys %alwayson) {
                if ($alwayson{$_} ne '') {
#                   print OU "$alwayson{$_}\n";
                    &l00httpd::l00fwriteBuf($ctrl, "$alwayson{$_}\n");
                }
            }
#           print OU $marks.$netiflog;
            &l00httpd::l00fwriteBuf($ctrl, $marks.$netiflog);
#           close (OU);
            &l00httpd::l00fwriteClose($ctrl);
            $savedpath = $form->{'owpath'};
        }
    }


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"top\"></a>\n";
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">HOME</a> <a href=\"/perionetifcon.htm\">Refresh</a><br>\n";

    $tmp = $totalifcon;
    $tmp =~ s/(\d)(\d\d\d)$/$1,$2/;
    $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
    $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
    print $sock "Rx/Tx: $tmp bytes. ";
    $tmp = $isp + int($totalifcon / 100000) / 10;
    print $sock "ISP: $tmp MB ($netifnoln) <a href=\"#end\">end</a>\n";

    if (defined($form->{"mark"})) {
        # allow annotation with marking of current readings and delta from last
        $tmp = $totalifcon;
        $tmp =~ s/(\d)(\d\d\d)$/$1,$2/;
        $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
        $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
        $buf .= "Rx/Tx: $tmp bytes.";

        $tmp = $isp + int($totalifcon / 100000) / 10;
        $buf .= " ISP: $tmp MB ($netifnoln)";

        if ($lasttime > 0) {
            $tmp = $totalifcon - $lasttotalifcon;
            $tmp =~ s/(\d)(\d\d\d)$/$1,$2/;
            $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
            $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
            $buf .= ". Delta: $tmp bytes.";

            $tmp = $isp + int(($totalifcon - $lastisp) / 100000) / 10;
            $buf .= " $tmp MB";

            $tmp = time - $lasttime;
            $buf .= " (${tmp}s):: ";
        } else {
            $buf .= ":: ";
        }
        $buf .= " $form->{'remark'}\n";

        # newest at top
        $marks = $buf . $marks;

        $lastisp = $isp + int($totalifcon / 100000) / 10;
        $lasttotalifcon = $totalifcon;
        $lasttime = time;
    }
    if ($marks ne '') {
        $tmp = $totalifcon - $lasttotalifcon;
        $tmp =~ s/(\d)(\d\d\d)$/$1,$2/;
        $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
        $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
        print $sock "<br>Delta: $tmp bytes.";

        $tmp = $isp + int(($totalifcon - $lastisp * 1000000) / 100000) / 10;
        $tmp = sprintf("%.1f", $tmp);
        print $sock " ISP: $tmp MB";

        $tmp = time - $lasttime;
        print $sock " (${tmp}s)\n";
    }

    print $sock "<form action=\"/perionetifcon.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"0\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td>Run interval (sec, e.g. 2):</td>\n";
    print $sock "        <td><input type=\"text\" size=\"6\" name=\"interval\" value=\"$interval\"></td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Submit\"> \n";
    print $sock "         <input type=\"submit\" name=\"stop\" value=\"Stop\"></td>\n";
    print $sock "        <td><input type=\"submit\" name=\"clear\" value=\"Clear\"></td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "<form action=\"/perionetifcon.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"0\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"save\" value=\"Save new\"></td>\n";
#   $tmp = "$ctrl->{'workdir'}tmp/$ctrl->{'now_string'}_netifcon.csv";
    $tmp = "l00://$ctrl->{'now_string'}_netifcon.csv.txt";
    $tmp =~ s/ /_/g;
    print $sock "        <td><input type=\"text\" size=\"16\" name=\"savepath\" value=\"$tmp\"></td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"overwrite\" value=\"Overwrite\"></td>\n";
    print $sock "        <td><input type=\"text\" size=\"16\" name=\"owpath\" value=\"$savedpath\"></td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"suspend\" value=\"Save\"></td>\n";
    if (-e "$ctrl->{'workdir'}tmp/l00_perionetifcon_vals.saved") {
        print $sock "        <td><input type=\"submit\" name=\"resume\" value=\"Resume\"> from sdcard</td>\n";
    } else {
        print $sock "        <td>Not Saved</td>\n";
    }
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    if (length ($savedpath) > 5) {
        print $sock "View: <a href=\"/view.htm?path=$savedpath\" target=\"_blank\">$savedpath</a><br>\n";
    } else {
        print $sock "View: <a href=\"/view.htm?path=$tmp\" target=\"_blank\">$tmp</a><br>\n";
    }

    print $sock "<form action=\"/perionetifcon.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"0\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"isp\" value=\"Set ISP\"></td>\n";
    print $sock "        <td>offset to match ISP meter: <input type=\"text\" size=\"4\" name=\"ispadj\" value=\"$isp\"></td>\n";
    print $sock "    </tr>\n";
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"mark\" value=\"Mark\"></td>\n";
    print $sock "        <td>Remark: <input type=\"text\" size=\"12\" name=\"remark\" value=\"\">\n";
    print $sock "        <input type=\"submit\" name=\"clrmark\" value=\"Clear\"></td>\n";
    print $sock "    </tr>\n";
                                                
    print $sock "</table>\n";
    print $sock "</form>\n";

    if (length ($savedpath) > 5) {
        #print $sock "Report generator: <a href=\"/rptnetifcon.htm?path=$savedpath\">$savedpath</a><p>\n";
        $savedpath =~ /^(.+\/)([^\/]+)$/;
        print $sock "Report generator: <a href=\"/ls.htm?path=$1\">$1</a><a href=\"/rptnetifcon.htm?path=$savedpath\">$2</a><p>\n";
    }

    if (defined($form->{"clrmark"})) {
        $marks = '';
        $lasttotalifcon = 0;
        $lastisp = 0;
        $lasttime = 0;
    }

    if ($marks ne '') {
        print $sock "Marks:<pre>\n";
        print $sock "$marks</pre>\n";
    }

    print $sock "Currently ESTABLISHED connections (exclude hot spot connections):<pre>\n";
    &l00httpd::l00npoormanrdns($ctrl, $config{'desc'}, "$ctrl->{'workdir'}rptnetifcon.cfg");
    $poorwhois = &l00httpd::l00npoormanrdnshash($ctrl);
    foreach $_ (sort keys %seennow) {
        if ($seennow{$_} eq 'ESTABLISHED') {
		    s/::ffff://g;
            foreach $tmp (sort keys %$poorwhois) {
                s/($tmp)/$poorwhois->{$tmp}($1)/g;
            }
            print $sock "$_\n";
        }
    }
    print $sock "</pre>Lines: $netifnoln : <a href=\"#end\">end</a>\n";
    print $sock "<pre>\n";

    foreach $_ (keys %alwayson) {
        if ($alwayson{$_} ne '') {
            print $sock "     $alwayson{$_}\n";
        }
    }

    $tmp = 0;
    foreach $_ (split("\n", $netiflog)) {
        $tmp++;
        if ($tmp < 60) {
            printf $sock ("%3d: $_\n", $tmp);
        } elsif ($tmp == 60) {
            printf $sock ("%3d: $_\n", $tmp);
            print $sock "\nskipping ".($netifnoln - 60 * 2)." lines\n\n";
        } elsif ($tmp > ($netifnoln - 60)) {
            printf $sock ("%3d: $_\n", $tmp);
        }
    }
    print $sock "</pre>\n";
    print $sock "<p><a href=\"#top\">Jump to top</a><p>\n";

    print $sock "<form action=\"/perionetifcon.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"0\">\n";

    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"restore\" value=\"Restore\"></td>\n";
    print $sock "        <td>Restore *.saved from *.saved.-.bak</td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "</form>\n";

    $tmp = $totalifcon;
    $tmp =~ s/(\d)(\d\d\d)$/$1,$2/;
    $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
    $tmp =~ s/(\d)(\d\d\d,)/$1,$2/;
    print $sock "<p>Total ifconfig $tmp bytes. Lines: $netifnoln\n";
    print $sock "<a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}

sub l00http_perionetifcon_perio {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my ($buf, $tempe, $proto, $RxQ, $TxQ, $local, $remote, $sta, $key);
    my ($tmp, $thisif, $rxb, $txb, $if, $vals, @val, $total, $ifoutput, $retval);

    if (($interval > 0) && 
        (($lastcalled == 0) || (time >= ($lastcalled + $interval)))) {
        $lastcalled = time;
        $retval = $interval;

        if (($ctrl->{'os'} eq 'and') ||
            ($ctrl->{'os'} eq 'lin') ||
            ($ctrl->{'os'} eq 'tmx')) {
            # netstat

            $tempe = '';
            undef %netstatout;
            undef %seennow;
#netstat
#Proto Recv-Q Send-Q Local Address          Foreign Address        State
# tcp       0      0 127.0.0.1:55555        0.0.0.0:*              LISTEN
# tcp       0      0 0.0.0.0:20337          0.0.0.0:*              LISTEN
# tcp       0      0 10.10.10.18:46869      64.4.61.208:443        ESTABLISHED
# tcp       0      0 127.0.0.1:53033        127.0.0.1:53171        ESTABLISHED
#tcp6       0      0 :::20339               :::*                   LISTEN
#tcp6       0      0 ::ffff:127.0.0.1:8182  :::*                   LISTEN
#tcp6       0      0 ::ffff:127.0.0.1:53171 ::ffff:127.0.0.1:53033 ESTABLISHED
            foreach $_ (split ("\n", `netstat`)) {
                if (/UNIX domain sockets/) {
                    # Active UNIX domain sockets (w/o servers)
                    # ignore UNIX sockets
                    last;
                }
                if (/Active Internet/ || /Proto /) {
                    # ignore header
                    next;
                }
                if (($proto, $RxQ, $TxQ, $local, $remote, $sta) = split (' ', $_)) {
                    #LISTEN
                    #SYN_SENT
                    #ESTABLISHED
                    #TIME_WAIT
                    #FIN_WAIT1
                    #CLOSE_WAIT
                    # process only these connections...
                    if ((!($local =~ /127\.0\.0\.1/) || !($remote =~ /127\.0\.0\.1/)) &&        # either side not localhost
                        (!(($local =~ /192\.168\.96\./) && ($remote =~ /192\.168\.96\./))) &&   # not hot spot connection
                        (!($remote =~ /0\.0\.0\.0/)) &&     # not without remote IP
                        (!($sta =~ /LISTEN/)) &&            # not listening
                        (!($sta =~ /CLOSE_WAIT/)) &&        # not CLOSE_WAIT (what is it?)
                        ($proto ne 'Proto')) {              # where does this come from?
                        $local =~ s/:(\d+)$/,$1/;
                        $remote =~ s/:(\d+)$/,$1/;
                        $seennow{"$local->$remote"} = $sta;    # remember socket pair reported in this loop

                        # a socket is listed because it was connected, is connected, or just disconnected
                        # for us just consider it being connected
                        # socket is currently connected
                        if (defined ($allsocksever{"$local->$remote"})) {
                            # we have seen it before
                            if ($allsocksever{"$local->$remote"} eq '') {
                                # it was disconnected, and now connected
                                $allsocksever{"$local->$remote"} = $_;    # connected state
                                # record as just connected
                                $buf = "$ctrl->{'now_string'},net,$proto,local,remote,$local,$remote,conn";
                                $netstatout{$buf} = 1;
                            } else {
                                # it was connected, and still connected
                                # nothing changed, do nothing
                            }
                        } else {
                            # never seen connected
                            $allsocksever{"$local->$remote"} = $_;    # connected state
                            # record as just connected
                            $buf = "$ctrl->{'now_string'},net,$proto,local,remote,$local,$remote,conn";
                            $netstatout{$buf} = 1;
                        }
                        # We want to identify socket pair that are always ESTABLISHED
                        # and convey to rptnetifcon.pl so they can be removed from summary
                        if ($netifcnt == 0) {
                            # the very first time
                            if ($sta =~ /ESTABLISHED/) {
                                $alwayson{"$local->$remote"} = "$ctrl->{'now_string'},net,$proto,local,remote,$local,$remote,alwaysESTAB";
                            }
                        }
                    }
                } else {
                    $tempe .= "LOCAL: $_\n";
                    $netifnoln++;
                }
            }
            if ($netifcnt > 0) {
                # now we remove from %alwayson if seennow != ESTABLISHED
                foreach $tmp (keys %alwayson) {
                    if (!defined($seennow{$tmp})) {
                        # don't see it this time
                        $alwayson{$tmp} = '';    # remove
                    } elsif (!($seennow{$tmp} =~ /ESTABLISHED/)) {
                        # not in ESTABLISHED state
                        $alwayson{$tmp} = '';    # remove
                    }
                }
            }
            foreach $key (keys %allsocksever) {
                # %allsocksever remembers all socket pairs ever seen. "$_" denotes connected; '' otherwise
                # key of the form {"$local->$remote"}
                if (!defined($seennow{$key})) {
                    # socket pair $key not seen now, connection no longer exist
                    if (($proto, $RxQ, $TxQ, $local, $remote, $sta) = split (' ', $allsocksever{"$key"})) {
                        $buf = "$ctrl->{'now_string'},net,$proto,local,remote,$local,$remote,disc";
                        $netstatout{$buf} = 0;
                    }
                    $allsocksever{"$key"} = '';    # disconnected state
                }
            }
            foreach $key (sort keys %netstatout) {
                $tempe .= "$key\n";
                $netifnoln++;
            }


            # ifconfig

            $thisif = '';
            if (open (IN, "</proc/net/dev")) {
#Inter-|   Receive                                                |  Transmit
#    if        0       1    2    3    4     5          6         7        8       9   10   11   12    13      14         15
# face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
#    lo:51918626  105904    0    0    0     0          0         0 51918626  105904    0    0    0     0       0          0
#dummy0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet0:  983996     826    0    0    0     0          0         0    54607     563    0    0    0     0       0          0
#rmnet1:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet2:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet3:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet4:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet5:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet6:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#rmnet7:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#  usb0:  762160    2508    0    0    0     0          0         0   752385    1835    0    0    0     0       0          0
#  sit0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#ip6tnl0:      0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#gannet0:      0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#   tun:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
#  eth0:32919217  366817    0    0    0     0          0         0 49776541  544949    0    0    0     0       0          0
                $ifoutput = "$ctrl->{'now_string'},if,rx,tx";
#               $tempe .= "$ctrl->{'now_string'},if,rx,tx";
                $total = 0;
                while (<IN>) {
                    if (($if, $vals) = /^ *(\w+): *(.+)$/) {
                        if ($if eq 'lo') {
                            next;
                        }
                        @val = split (' ', $vals);
                        if (($val[0] > 0) && ($val[8] > 0)) {
                            # non-zero rx and tx count

                            # save starting values
                            if (!defined($ifbase{"rx_$if"})) {
                                $ifbase{"rx_$if"} = $val[0];
                            }
                            if (!defined($ifbase{"tx_$if"})) {
                                $ifbase{"tx_$if"} = $val[8];
                            }

                            # accumulate rx bytes
                            if (!defined($ifrxtx{"rx_$if"})) {
                                $ifrxtx{"rx_$if"} = 0;
                            }
                            $tmp = ($val[0] - $ifbase{"rx_$if"}) - $ifrxtx{"rx_$if"};
                            $total += $tmp;
                            $ifoutput .= ",$if,$tmp";
                            $ifrxtx{"rx_$if"} = $val[0] - $ifbase{"rx_$if"};

                            # accumulate tx bytes
                            if (!defined($ifrxtx{"tx_$if"})) {
                                $ifrxtx{"tx_$if"} = 0;
                            }
                            $tmp = ($val[8] - $ifbase{"tx_$if"}) - $ifrxtx{"tx_$if"};
                            $total += $tmp;
                            $ifoutput .= ",$tmp";
                            $ifrxtx{"tx_$if"} = $val[8] - $ifbase{"tx_$if"};
                        }
                    }
                }
                if ($total > 0) {
                    $tempe .= "$ifoutput\n";
                    $totalifcon += $total;
                    $netifnoln++;
                }
                close (IN);
            }
        }
        if ($perltime != 0) {
            # subsequently
            $netiflog .= $tempe;
        } else {
            # first time
            $netiflog = $tempe;
        }
        $perltime = time;
        $netifcnt++;
    } elsif ($interval > 0) {
        # remaining time to firing
        $retval = ($lastcalled + $interval) - time;
    } else {
        $retval = 0x7fffffff;
    }

    $retval;
}


\%config;
