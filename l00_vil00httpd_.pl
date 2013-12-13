# This do .pl script prints results suitable for making menu 
# selection in a bash shell script to open any of the script 
# in vi for editing:
# http://localhost:20337/do.htm?path=/sdcard/sl4a/scripts/l00httpd/l00_vil00httpd_.pl


$cnt = 0;
$menu = '';
$edit = '';
$col = 0;

$pl = '';

# scan and store all *.pl and *.pm file in $pl
if (opendir (DIR, '/sdcard/sl4a/scripts/l00httpd/')) {
    foreach $file (sort readdir (DIR)) {
        if ($file =~ /^(l00.+\.p[lm])$/) {
            $_ = $1;
            $cnt++;
            $pl .= "$_\n";
        }
    }
    closedir (DIR);
    print $sock "Found $cnt .p[lm]\n";
}


# use shorthand to shorten file name
# shorthand: = -> l00http_ ; _ -> l00_\n";
# find longest shorten file name length
$len = 0;
foreach $_ (split("\n", $pl)) {
    if (/^l00http_/) {
        s/^l00http_/=/;
        s/^l00_/_/;
    }
    if (length ($_) > $len) {
        $len = length ($_);
    }
}

# start generating shell script
print $sock "<pre>\n";
print $sock "while [ 1 ]; do\n";
print $sock "busybox clear\n";
print $sock "echo shorthand: = is l00http_ , _ is l00_\n";


# print 3 column menu:
$col = 0;
$sel = 'a';
$sels[1] = '2';
$sels[2] = '3';
foreach $_ (split("\n", $pl)) {
    # shorten filename
    s/^l00http_/=/;
    s/^l00_/_/;
    if ($col == 0) {
        print $sock "echo ";
    }
    # pad column with '.' if less than longest filename
    $sels[0] = $sel;
    $me = "$sels[$col]$_" . "." x ($len-1);
    # print menu
    print $sock substr ($me,0,$len);
    $col++;
    # wrap
    if ($col >= 3) {
        print $sock "\n";
        $col = 0;
        $sel++;
    }
}
if ($col > 0) {
    print $sock "\n";
}
print $sock "echo xz exit\n";
print $sock "read sel\n";
print $sock "echo \$sel\n\n";

$col = 0;
$sel = 'a';
$sels[1] = '2';
$sels[2] = '3';
foreach $_ (split("\n", $pl)) {
    $col++;
    print $sock "if [ \$sel = \"".$sel x $col."\" ]; then\n";
    print $sock "busybox vi /sdcard/sl4a/scripts/l00httpd/$_; fi\n";
    if ($col >= 3) {
        $col = 0;
        $sel++;
    }
}

print $sock "\nif [ \$sel = \"xz\" ]; then\n";
print $sock "break; fi\n";

print $sock "\ndone\n";


print $sock "</pre>\n";
