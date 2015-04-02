# <a href="/schdo.htm?dopl=/sdcard/sl4a/scripts/l00httpd/docs_demo`/l00_airplane.pl">schdo l00_airplane.pl</a>
#$ctrl->{'droid'}->makeToast('toast');

print $sock "Append &off= to disable airplane mode<br>\n";

$ret = $ctrl->{'droid'}->checkAirplaneMode();
if ($ret->{'result'}) {
    print $sock "airplane mode was on\n";
} else {
    print $sock "airplane mode was off\n";
}
print $sock "<br>\n";


if (defined($ctrl->{'FORM'}->{'off'})) {
    $ret = $ctrl->{'droid'}->toggleAirplaneMode(false);
    print $sock "turning airplane mode off\n";
} else {
    $ret = $ctrl->{'droid'}->toggleAirplaneMode(true);
    print $sock "turning airplane mode on\n";
}
print $sock "<br>\n";

&l00httpd::dumphash ('ret', $ret);
if ($ret->{'result'}) {
    print $sock "airplane mode is on\n";
} else {
    print $sock "airplane mode is off\n";
}
print $sock "<br>\n";


1;
