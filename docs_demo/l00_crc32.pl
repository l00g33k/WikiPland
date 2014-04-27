use l00crc32;

$buf = "asdfasdf";
$crc = &l00crc32::crc32($buf);

print $sock "crc32 = " , sprintf("%08x", $crc);
