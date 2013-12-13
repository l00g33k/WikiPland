# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

    print $sock $cnt++, " In do.pl: print content of environment variable INC (Perl's include directories)<br>\n";

    print $sock "<pre>\n";
    for ($ii = 0; $ii < 8; $ii++) {
        printf $sock ("%02x ", $ii);
    }
    print $sock "\n";
    for ($ii = 49; $ii < 58; $ii++) {
        printf $sock (" %c ", $ii);
    }
    print $sock "\n";
    print $sock "</pre>\n";

1;
