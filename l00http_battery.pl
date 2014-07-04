use strict;
use warnings;
use l00wikihtml;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_battery_proc",
              desc => "l00http_battery_desc");
my ($allreadings, $lasttimestamp, $battcnt, $dmesgcnt, $hdr);
$allreadings = '';
$lasttimestamp = 0;
$battcnt = 0;
$dmesgcnt = 0;
$hdr = "||#||level||vol||temp||curr||dis curr||chg src||chg en||over vchg||batt state||time stamp||\n";

sub l00http_battery_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    " battery: print battery level";
}

sub l00http_battery_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($bstat, $tmp, $table, $noln);
    my ($level, $vol, $temp, $curr, $dis_curr, $chg_src, $chg_en, $over_vchg, $batt_state, $timestamp);


	# Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>battery</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'}\n";
    print $sock "<a href=\"#end\">Jump to end</a>\n";

    print $sock "<form action=\"/battery.htm\" method=\"get\">\n";
    print $sock "<input type=\"submit\" name=\"submit\" value=\"Submit\">\n";
    print $sock "</form>\n";

    if (defined($form->{'clear'})) {
        $allreadings = '';
        $lasttimestamp = 0;
        $battcnt = 0;
        $dmesgcnt = 0;
    }

    if ($ctrl->{'os'} eq 'and') {
        # This SL4A call doesn't work for my Slide:(
        #$tmp = $ctrl->{'droid'}->batteryGetLevel();
        #print $sock "batteryGetLevel $tmp\n";
        #&l00httpd::dumphash ("tmp", $tmp);
        #$tmp = $ctrl->{'droid'}->batteryGetStatus();
        #print $sock "batteryGetStatus $tmp\n";
        #&l00httpd::dumphash ("tmp", $tmp);

        # On Slide, dmesg contains battery status:
        #<6>[ 7765.397493] [BATT] ID=2, level=89, vol=4209, temp=326, curr=-214, dis_curr=0, chg_src=1, chg_en=1, over_vchg=0, batt_state=1 at 7765326083644 (2013-12-11 12:08:08.239292486 UTC)
        $bstat = 'Only my Slide, dmesg contains a line with battery level: [BATT] ID=2, level=89, vol=4209, temp=326... If you see this line, either dmesg did not work, or the line format is different. Contact me to support it.';
        if (open (IN, "<$ctrl->{'workdir'}del/l00_battery.txt")) {
            $noln = 1;
            $table = '';
            while (<IN>) {
                $table .= $_;
                $noln++;
			}
			close (IN);
		} else {
            $table = $hdr;
		}
        print $sock "Battery level logging reported by 'dmesg' ($noln lines):<p>\n";
        foreach $_ (split("\n", `dmesg`)) {
            if (/\[BATT\] ID=2/) {
                $bstat = $_;
            }
        }
        if (($level, $vol, $temp, $curr, $dis_curr, $chg_src, $chg_en, $over_vchg, $batt_state, $timestamp) 
             = $bstat =~ /level=(\d+), vol=(\d+), temp=(\d+), curr=(-*\d+), dis_curr=(\d+), chg_src=(\d+), chg_en=(\d+), over_vchg=(\d+), batt_state=(\d+) at \d+ \((.+? UTC)\)/) {
            if ($lasttimestamp ne $timestamp) {
                $lasttimestamp = $timestamp;
                $battcnt++;
                $chg_src =~ s/0/0 (off)/;
                $chg_src =~ s/1/1 (usb)/;
                $chg_src =~ s/2/2 (wall)/;
                $chg_en =~ s/0/0 (off)/;
                $chg_en =~ s/1/1 (usb)/;
                $chg_en =~ s/2/2 (wall)/;
                $table = "||$battcnt||$level||$vol||$temp||$curr||$dis_curr||$chg_src||$chg_en||$over_vchg||$batt_state||$timestamp||\n" . $table;
                if (open (OU, ">$ctrl->{'workdir'}del/l00_battery.txt")) {
                    print OU $table;
					close (OU);
				}
            }
        }
        $tmp = $hdr . $table;
        $tmp =~ s/(\.\d)\d+ UTC/ UTC/g;
        print $sock &l00wikihtml::wikihtml ($ctrl, "", $tmp, 0);
        print $sock "<a name=\"end\"></a>";
        print $sock "<p>Saved: <a href=\"/ls.htm?path=$ctrl->{'workdir'}del/l00_battery.txt\">$ctrl->{'workdir'}del/l00_battery.txt</a><p>\n";

        print $sock "<form action=\"/battery.htm\" method=\"get\">\n";
        print $sock "<input type=\"submit\" name=\"clear\" value=\"Clear All Readings\">\n";
        print $sock "</form>\n";

        print $sock "<p>Last reading:<p>\n$bstat<p>\n";
        $dmesgcnt++;
        $allreadings = "$dmesgcnt: $bstat<p>\n$allreadings";
        print $sock "<hr>All Readings:<p>\n$allreadings\n";
    }

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
