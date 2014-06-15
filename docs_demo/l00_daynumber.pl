use l00httpd;
use l00wikihtml;

print $sock "Prints day number:<p>\n";

$secsnow = time;

# time starts from 1/1/1970
# date number start from 1/1/1900
# 25569 is 1/1/1970
$daysnow = int ($secsnow / (24 * 3600) + 25569);
print $sock "$daysnow day number since 1/1/1900<p>\n";

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime ($secsnow);
$date = sprintf ("%04d/%02d/%02d %2d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
print $sock "$secsnow seconds since 1/1/1970 ($date)<p>\n";

($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime (0);
$date = sprintf ("%04d/%02d/%02d %2d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
print $sock "0 since 1/1/1970 ($date)<p>\n";

print $sock "Looking for a day number in the clipboard...<p>\n";
if ($ctrl->{'os'} eq 'and') {
    $scratch = $ctrl->{'droid'}->getClipboard();
    $scratch = $scratch->{'result'};
    if ($scratch =~ /(\d+)/) {
        if (($scratch >= 0) && ($scratch < 60000)) {
            print $sock "Found $scratch in the Clipboard<p>\n";
            $secsclip = ($scratch - 25569) * (24 * 3600);
            ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime ($secsclip);
            $date = sprintf ("%04d/%02d/%02d %2d:%02d:%02d", $year+1900, $mon+1, $mday, $hour, $min, $sec);
            print $sock "$secsclip seconds since 1/1/1970 ($date)<p>\n";
        }
	}
}
