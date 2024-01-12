use strict;
use warnings;
use l00wikihtml;
use l00backup;
use l00httpd;
use l00crc32;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14



my %config = (proc => "l00http_shellls_proc",
              desc => "l00http_shellls_desc");

my ($shcmd, $shpath, $lscmd);

$shcmd = 'bash -c';
$shpath = '/';
$lscmd = 'ls -la';

sub l00http_shellls_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition


    " B: ls: Files and directories browser";
}


sub l00http_shellls_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};
    my $form = $ctrl->{'FORM'};
    my ($nofiles, $nodirs);
    my ($lnno, $fname, $catout, $up1lvl, $plpath, $datewidth, 
        $item, $cnt, $isdir, $shcmd2, @items, $ramfname);


    if (defined ($form->{'submit'})) {
        if (defined ($form->{'shcmd'}) && (length ($form->{'shcmd'}) >= 1)) {
            $shcmd = $form->{'shcmd'};
        }
        if (defined ($form->{'shpath'}) && (length ($form->{'shpath'}) >= 1)) {
            $shpath = $form->{'shpath'};
        }
    }
    $shcmd2 = $shcmd;
    $shcmd2 =~ s/ /\+/g;
    $shcmd2 =~ s/#/%%23/g; # escape # in URL
    $shcmd2 =~ s/=/%%3D/g; # escape % in printf

    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>shellls</title>" .$ctrl->{'htmlhead2'};
    # clip.pl with \ on Windows
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";
    print $sock "<a href=\"#end\">Jump to end</a> \n";
    print $sock "<hr>\n";


    print $sock "<pre>\n";

    $nofiles = 0;
    $nodirs = 0;
    if ($shpath =~ /\/$/) {
        @items = split("\n", `$shcmd '$lscmd \"$shpath\"'`);
        $cnt = 0;
        # print current directory
        printf $sock ("current directory: <a href=\"/shellls.htm?submit=submit&shcmd=$shcmd2&shpath=$shpath\">$shpath</a><br>\n");
        $up1lvl = $shpath;
        if ($up1lvl =~ /\/$/) {
            $up1lvl =~ s/[^\/]+\/$//;
            $up1lvl =~ s/ /\+/g;
            printf $sock ("  up: <a href=\"/shellls.htm?submit=submit&shcmd=$shcmd2&shpath=$up1lvl\">$up1lvl</a>\n");
        }
        $datewidth = 0;
        foreach $item (@items) {
            if ($item =~ / \.$/) {
                $datewidth = length($item) - 1;
                last;
            }
        }
        foreach $item (@items) {
            if ($item =~ /^total \d+$/) {
                next;
            }
            $fname = substr($item, $datewidth);
            if ($fname =~ /^\.+$/) {
                next;
            }

            $cnt++;
            if ($item =~ /^d/) {
                # directory
                $isdir = '/';
                $nofiles++;
            } else {
                # file
                $isdir = '';
                $nodirs++;
            }
            if ($cnt < 5000) {
                printf $sock ("%4d: %s<a href=\"/shellls.htm?submit=submit&shcmd=$shcmd2&shpath=$shpath$fname$isdir\">$fname$isdir</a>\n", 
                    $cnt, substr($item, 0, $datewidth));
            }
        }
    } else {
        # it's a file

        $up1lvl = $shpath;
        $up1lvl =~ s/[^\/]+$//;
        $up1lvl =~ s/ /\+/g;

        printf $sock ("Up: <a href=\"/shellls.htm?submit=submit&shcmd=$shcmd2&shpath=$up1lvl\">$up1lvl</a>");

        $fname = $shpath;
        $fname =~ s/^.+\/([^\/]+)$/$1/;
        printf $sock ("$fname\n\n");

        $ramfname = "l00://shellls_$fname.". &l00crc32::crc32($shpath.$shcmd) . ".txt";

        print $sock "View: <a href=\"/view.htm?path=$ramfname\" target=\"_blank\">$ramfname</a> -- ";
        print $sock "<a href=\"/launcher.htm?path=$ramfname\" target=\"_blank\">launcher</a>\n\n";

        $catout = `$shcmd 'cat \"$shpath\"'`;

        &l00httpd::l00fwriteOpen($ctrl, "$ramfname");
        &l00httpd::l00fwriteBuf($ctrl, $catout);
        &l00httpd::l00fwriteClose($ctrl);

        $lnno = 0;
        foreach $_ (split("\n", $catout)) {
            if ($lnno++ > 1000) {
                last;
            }
            s/</&lt;/g;
            s/>/&gt;/g;
            printf $sock ("%4d: %s\n", $lnno, $_);
        }
        print $sock "\nView: <a href=\"/view.htm?path=$ramfname\" target=\"_blank\">$ramfname</a>\n\n";
    }


    print $sock "</pre>\n";


    print $sock "<p>There are $nodirs director(ies) and $nofiles file(s)<br>\n";

    print $sock "<form action=\"/shellls.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "<tr>\n";
    print $sock "  <td>shcmd:</td>\n";
    print $sock "  <td><input type=\"text\" size=\"10\" name=\"shcmd\" value=\"$shcmd\"></td>\n";
    print $sock "</tr>\n";
    print $sock "<tr>\n";
    print $sock "  <td>Path:</td>\n";
    print $sock "  <td><input type=\"text\" size=\"10\" name=\"shpath\" value=\"$shpath\"></td>\n";
    print $sock "</tr>\n";
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"S&#818;ubmit\" accesskey=\"s\"></td>\n";
    print $sock "        <td>&nbsp;</td>\n";
    print $sock "    </tr>\n";
    print $sock "</table>\n";
    print $sock "</form>\n";

    print $sock "<hr><a name=\"end\"></a>\n";

    if (defined ($ctrl->{'FOOT'})) {
        print $sock "$ctrl->{'FOOT'}\n";
    }

    print $sock $ctrl->{'htmlfoot'};

}


\%config;
