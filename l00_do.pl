# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

    print $sock $cnt++, " In do.pl: print content of environment variable INC (Perl's include directories)<br>\n";

    print $sock "<pre>\n";
    print $sock join ("\n", @INC);
    print $sock "</pre>\n";

1;
