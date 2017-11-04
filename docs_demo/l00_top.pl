print $sock "<pre>\n";
print $sock "/proc/stat";

if (defined($procstatlastcalltime)) {
    print $sock "; since last call: ", time - $procstatlastcalltime, " seconds ago";
}
$procstatlastcalltime = time;
print $sock "\n\n";

open(STAT, '/proc/stat') or die "WTF: $!";
print $sock "     user nice sytm idle  ttl  %% iowt  irq sirq stea gues gtnice\n\n";
$row = 0;
while (<STAT>) {
    next unless /^cpu[0-9]*/;
    ($cpu, @cpu) = split(' ', $_);
    if ($cpu =~ /cpu(\d)/) {
        printf $sock ("cpu%d", $1 + 1);
    } else {
        printf $sock ("%-4s", $cpu);
    }
    for ($ii = 0; $ii < 10; $ii++) {
        printf $sock ("%5d", $cpu[$ii] - $cpulst[$row * 10 + $ii]);
        if ($ii == 3) {
             $ttl = ($cpu[0] - $cpulst[$row * 10 + 0]) + 
                    ($cpu[1] - $cpulst[$row * 10 + 1]) + 
                    ($cpu[2] - $cpulst[$row * 10 + 2]) +
                    ($cpu[3] - $cpulst[$row * 10 + 3]);
             printf $sock ("%5d", $ttl);
             printf $sock ("%3.0f%", ($ttl - ($cpu[3] - $cpulst[$row * 10 + 3])) / $ttl * 100);
        }
    }
    for ($ii = 0; $ii < 10; $ii++) {
        $cpulst[$row * 10 + $ii] = $cpu[$ii];
    }
    print $sock "\n";
    $row++;
}
close STAT;
