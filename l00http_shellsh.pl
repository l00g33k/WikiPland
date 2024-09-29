use strict;
use warnings;
use l00wikihtml;
use l00backup;
use l00httpd;
use l00crc32;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14



my %config = (proc => "l00http_shellsh_proc",
              desc => "l00http_shellsh_desc");

my ($shcmd, $remotepath, $localpath);

$shcmd = 'bash -c';
#$remotepath = '/dev/shm/myrcommand.bash';
#$localpath = '/dev/shm/mylcommand.bash';
$remotepath = '/sdcard/z/myrmcmds.bash';
$localpath = '/sdcard/z/mylocmds.bash';

sub l00http_shellsh_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition


    " B: sh: Sends commands to be sourced in the shell";
}


sub l00http_shellsh_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};
    my $form = $ctrl->{'FORM'};
    my ($nofiles, $nodirs);
    my ($lnno, $fname, $catout, $up1lvl, $plpath, $datewidth, $usepath,
        $item, $cnt, $isdir, @items, $ramfname, $cmds, $scrpath);

    $cmds = '';
    if (defined ($form->{'submit'})) {
        if (defined ($form->{'shcmd'}) && (length ($form->{'shcmd'}) >= 1) && ($form->{'shcmd'} !~ /^ *$/)) {
            $shcmd = $form->{'shcmd'};
        }
        if (defined ($form->{'cmds'}) && (length ($form->{'cmds'}) >= 1) && ($form->{'cmds'} !~ /^ *$/)) {
            $cmds = $form->{'cmds'};
        }
        if (defined ($form->{'localpath'}) && (length ($form->{'localpath'}) >= 1)) {
            $localpath = $form->{'localpath'};
        }
        if (defined ($form->{'remotepath'}) && (length ($form->{'remotepath'}) >= 1)) {
            $remotepath = $form->{'remotepath'};
        }
    }
    $scrpath = '';
    if (defined ($form->{'path'}) && (-f $form->{'path'})) {
        # script file exist
        $scrpath = $form->{'path'};
        $usepath = $scrpath;
    } elsif (length($cmds) > 0) {
        # no script file but has commands, make a file
        if (open(OU, ">$localpath")) {
            print OU "$cmds";
            close(OU);
        }
        $usepath = $localpath;
    } else {
        $usepath = '';
    }

    l00httpd::dbp($config{'desc'}, "\n"), if ($ctrl->{'debug'} >= 3);


    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>shellsh</title>" .$ctrl->{'htmlhead2'};
    # clip.pl with \ on Windows
    print $sock "<a name=\"top\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
    print $sock "<a href=\"#end\">Jump to end</a> \n";
    print $sock "<hr>\n";


    print $sock "<pre>\n";
    # TOO1: command to access remote sysetm
    print $sock "Remote: $shcmd\n";

    if (defined ($form->{'submit'}) && ($usepath ne '')) {
        # TOO3: send commands to the remote system
        $catout = `cat $usepath | $shcmd 'cat > $remotepath'`;
        print $sock "\nPushing to remote: $catout\n";

        # TOO2: commands to be sourced at the remote system
        print $sock "\nCommands:\n";
        $catout = `$shcmd 'cat $remotepath'`;
        $lnno = 0;
        foreach $_ (split("\n", $catout)) {
            if ($lnno++ > 1000) {
                last;
            }
            s/</&lt;/g;
            s/>/&gt;/g;
            printf $sock ("%4d: %s\n", $lnno, $_);
        }

        # TOO: execute remote commands
        $catout = `$shcmd 'source $remotepath'`;

        # save output to ram
        $ramfname = "l00://shellsh_".&l00crc32::crc32($shcmd).".txt";
        &l00httpd::l00fwriteOpen($ctrl, "$ramfname");
        &l00httpd::l00fwriteBuf($ctrl, $catout);
        &l00httpd::l00fwriteClose($ctrl);
        print $sock "\n<a href=\"/view.htm?path=$ramfname\" target=\"_blank\">Outputs:</a>\n";
        # TOO
        $lnno = 0;
        foreach $_ (split("\n", $catout)) {
            if ($lnno++ > 1000) {
                last;
            }
            s/</&lt;/g;
            s/>/&gt;/g;
            printf $sock ("%4d: %s\n", $lnno, $_);
        }
    }

    print $sock "</pre>\n";


    print $sock "<a name=\"end\"></a>\n";
    print $sock "<a href=\"#top\">Jump to top</a><p>\n";
    print $sock "<form action=\"/shellsh.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";
    print $sock "<tr>\n";
    print $sock "  <td><input type=\"submit\" name=\"submit\" value=\"S&#818;ubmit\" accesskey=\"s\"></td>\n";
    print $sock "  <td>shcmd: <input type=\"text\" size=\"90\" name=\"shcmd\" value=\"$shcmd\"></td>\n";
    print $sock "</tr>\n";
    print $sock "<tr>\n";
    print $sock "  <td><a href=\"/view.htm?path=$scrpath\" target=\"_blank\">Read-only path</a></td>\n";
    print $sock "  <td><input type=\"text\" size=\"100\" name=\"path\" value=\"$scrpath\"></td>\n";
    print $sock "</tr>\n";
    if ($scrpath eq '') {
        print $sock "<tr>\n";
        print $sock "  <td>Commands:</td>\n";
        print $sock "  <td><textarea name=\"cmds\" cols=\"100\" rows=\"10\" accesskey=\"e\">$cmds</textarea></td>\n";
        print $sock "</tr>\n";
        print $sock "<tr>\n";
        print $sock "  <td><a href=\"/view.htm?path=$localpath\" target=\"_blank\">Local path</a></td>\n";
        print $sock "  <td><input type=\"text\" size=\"100\" name=\"localpath\" value=\"$localpath\"></td>\n";
        print $sock "</tr>\n";
    }
    print $sock "<tr>\n";
    print $sock "  <td>Remote path</td>\n";
    print $sock "  <td><input type=\"text\" size=\"100\" name=\"remotepath\" value=\"$remotepath\"></td>\n";
    print $sock "</tr>\n";
    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "<p>shcmd: $shcmd<p>\n";

    print $sock "<hr>\n";

    if (defined ($ctrl->{'FOOT'})) {
        print $sock "$ctrl->{'FOOT'}\n";
    }

    print $sock $ctrl->{'htmlfoot'};

}


\%config;
