
# computing dirtree tree size using du -h
# perl du.pl < du.dir
# perl c:\x\du.pl < c:\x\du.dir

my ($root, $depth, @outs, $cnt, $size, $kilomil, $path, @outs2, $base, $base2);

$depth = 1;
undef @outs;
push (@outs, "bytes\n");

$base = '\/sdcard\/Android\/data\/';
$base = '\/sdcard\/';

$base2 = $base;
$base2 =~ s/\\//g;
print $sock "Create du.dir:<br>\n";
print $sock "du -h $bases > /sdcard/du.dir<br>\n";

if (open (IN, "</sdcard/du.dir")) {
    $cnt = 0;
    while (<IN>) {
#print $sock "$_<br>\n";
        if (!/^\d/) {
            next;
        }
        if (($size, $kilomil, $path) = /([.0-9]+)([KM])[ \t]*$base(.+)/) {
            @dirs = split ("/", $path);
            if ($#dirs < $depth) {
                if ($kilomil eq 'M') {
                    $size *= 1000000;
                } elsif ($kilomil eq 'K') {
                    $size *= 1000;
                }
                push (@outs, sprintf ("%10d,$path\n", $size));
            }
        }
        $cnt++;
    }

    @outs2 = sort {$b cmp $a} (@outs);
    print $sock "<pre>";
    print $sock "@outs2\n";
    print $sock "</pre>\n";
    print $sock "Parse $cnt lines\n";
}
