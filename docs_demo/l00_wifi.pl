# <a href="/schdo.htm?dopl=/sdcard/sl4a/scripts/l00httpd/docs_demo/l00_wifi.pl">schdo l00_wifi.pl</a>
#$ctrl->{'droid'}->makeToast('toast');

print $sock "Append &off= to disable wifi mode<br>\n";

$ret = $ctrl->{'droid'}->checkWifiState();
if ($ret->{'result'}) {
    print $sock "wifi mode was on\n";
} else {
    print $sock "wifi mode was off\n";
}
print $sock "<br>\n";


if (defined($ctrl->{'FORM'}->{'off'})) {
    $ret = $ctrl->{'droid'}->toggleWifiState(false);
} else {
    $ret = $ctrl->{'droid'}->toggleWifiState(true);
}
&l00httpd::dumphash ('ret', $ret);
if ($ret->{'result'}) {
    print $sock "wifi mode is on\n";
} else {
    print $sock "wifi mode is off\n";
}
print $sock "<br>\n";


1;
