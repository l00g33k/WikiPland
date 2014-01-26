use l00httpd;
use l00wikihtml;

$hash = $ctrl->{'droid'}->getLaunchableApplications();
$apps = &l00httpd::dumphashbuf ("apps", $hash);
$table = "||seq||Name||comp||\n";
$cnt = 1;
foreach $_ (sort split("\n", $apps)) {
    if (($name, $comp) = /apps->result->(.+) => (.+)/) {
        $table .= "||$cnt ||$name || $comp||\n";
		$cnt++;
    }
}
print $sock &l00wikihtml::wikihtml ($ctrl, "", $table, 0);
print $sock "<p><pre>\n$apps\n</pre>\n";

