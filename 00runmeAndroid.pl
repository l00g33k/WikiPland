# Release under GPLv2 or later version by l00g33k@gmail.com

use Cwd;
use strict;
use warnings;

my ($plpath);
$plpath = cwd();
$plpath =~ s/\r//g;
$plpath =~ s/\n//g;
$plpath .= '/';
$plpath =~ s\/cygdrive/(.)\$1:\;
if ($0 =~ /^(.+[\\\/])[^\\\/]+$/) {
    $plpath = $1;
}

# SL4A on Android doesn't include script directory. Add it
push (@INC, $plpath);

# Run real script
do 'l00httpd.pl';

