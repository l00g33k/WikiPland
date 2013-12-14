# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

package l00mktime;

sub weekno  {
	# calculate week number since 1970
    local ($year, $mon, $mday) = @_;
    $mon--;

    # week number from day number since 1970
    $julian = int (&mktime ($year, $mon, $mday, 0, 0, 0) / 3600 / 24);

    # 1970/1/1 is wed; + 2 makes 1970/5 (mon) == 7
    $dayofwk =  ($julian  + 2) % 7;
    $wkno = int (($julian + 2) / 7);
    ($wkno, $julian);
}

# This code is derived from my original work on Perl 4.0 that run on my 
# HP 200LX which does not have mktime.  I didn't research what is available 
# in Perl 5.  Why change working code?
sub mktime  {
##############################################################################
#   $time = &mktime ($year, $mon, $mday, $hour, $min, $sec);
#
#   make time (sec since 1970) from components
##############################################################################

    #   local variables
    local ($gstime, $i);
    local ($gssec,$gsmin,$gshour,$gsmday,$gsmon,$gsyear,$gswday,$gsyday,$gsisdst);

    #   retrieve arguments
    local ($sec)    = pop(@_);
    local ($min)    = pop(@_);
    local ($hour)   = pop(@_);
    local ($mday)   = pop(@_);
    local ($mon)    = pop(@_);
    local ($year)   = pop(@_);

    #print "mktime $year $mon $mday\n";

    #   first guest
    $gstime = ($year - 70) * 365.25;
    $gstime = $gstime      + $mon * 30.5 + $mday;
    $gstime = $gstime * 24 + $hour;
    $gstime = $gstime * 60 + $min;
    $gstime = $gstime * 60 + $sec;

    #   successive approximation
    for ($i = 0; $i < 30; $i++) {
        #   time from 1st guest
        ($gssec,$gsmin,$gshour,$gsmday,$gsmon,$gsyear,$gswday,$gsyday,$gsisdst) =
                                                                gmtime ($gstime);
                                                                #localtime ($gstime);
        # gmtime yields correct results on a Saturday night 8pm at GMT + 8
        # on a Windows set to GMT - 8 time zone
        # on a phone set to GMT + 8 time zone
        #print "$gstime:$gsyear,$gsmon,$gsmday,$gshour,$gsmin,$gssec\n";

        if ($year != $gsyear) {
            #   refine year
            $gstime += ($year - $gsyear) * 365 * 24 * 3600;
            next;
        }

        if ($mon != $gsmon) {
            #   refine month
            $gstime += ($mon - $gsmon) * 30 * 24 * 3600;
            next;
        }

        if ($mday != $gsmday) {
            #   refine date
            $gstime += ($mday - $gsmday) * 24 * 3600;
            next;
        }

        if ($hour != $gshour) {
            #   refine hour
            $gstime += ($hour - $gshour) * 3600;
            next;
        }

        if ($min != $gsmin) {
            #   refine min
            $gstime += ($min - $gsmin) * 60;
            next;
        }

        if ($sec != $gssec) {
            #   refine sec
            $gstime += ($sec - $gssec);
            next;
        }

        #   all equal, done
        last;
    }

    #   return value
    #print "mktime $gstime\n";
    $gstime;

}# mktime



1;

