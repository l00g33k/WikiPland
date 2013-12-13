# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14
use warnings;
use strict;

package l00backup;

#use l00backup;      # used for backing up wiki before edit
#&l00backup::backupfile ($fname);

sub backupfile {
    my ($ctrl, $fname, $roll, $norev) = @_;
    my ($buffer, $ii, $ii_1);

    local $/ = undef;
    if (open (IN, "<$fname")) {
        $buffer = <IN>;
        close (IN);

        if ($roll) {
            for ($ii = $norev - 1; $ii >= 2; $ii--) {
                $ii_1 = $ii + 1;
                rename ("$fname.$ii.bak", "$fname.$ii_1.bak");
            }
            rename ("$fname.bak", "$fname.2.bak");

            # the next line doesn't work on PC?
            #rename ("$fname", "$fname.bak");

            open (OU, ">$fname.bak");
            print OU $buffer;
            close (OU);
        } else {
            open (OU, ">$fname.-.bak");
            print OU $buffer;
            close (OU);
        }
    }

    1;
}


1;

