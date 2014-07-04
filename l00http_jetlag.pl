use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# Create ASCII graphical representation of sleep time for jetlag planning

my %config = (proc => "l00http_jetleg_proc",
              desc => "l00http_jetleg_desc");
my ($charPerDay, $days, $diff, $citytop, $citybot, $wake, $sleep);
my ($wait, $fly, $special);
$charPerDay = 24;
$days = 2;
$diff = -16;
$citytop = 'CT1';
$citybot = 'CT2';
$wake = 21;
$sleep = 8;
$wait = 19;
$fly = 12;
$special = '';

sub oneday {
    my $offset = pop @_;
    my ($hr, $ii, $idx, $buf, $chr, $hrs1, $hrs10);

    $buf = ' ' x $charPerDay;
    $hrs1 = $buf;
    $hrs10 = $buf;
    for ($ii = 0; $ii < 24; $ii++) {
        $hr = ($ii + $offset) % 24;
        $idx = int ($charPerDay * $ii / 24);
        $chr = '=';
        # --==##
        if ($hr < 8) {
            $chr = '#';
        } elsif ($hr < 18) {
            $chr = '-';
        } elsif ($hr < 23) {
            $chr = '=';
        } else {
            $chr = '#';
        }
        substr ($buf, $idx, 1) = $chr;
        if (($hr % 3) == 0) {
            if ($hr < 10) {
                substr ($hrs1, $idx, 1) = $hr;
            } else {
                substr ($hrs1,  $idx, 1) = $hr % 10;
                substr ($hrs10, $idx, 1) = int ($hr / 10);
            }
        }
    }
 
    ($buf, $hrs1, $hrs10);
}


sub l00http_jetleg_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "jetleg: jet travel sleep planner";
}

sub l00http_jetleg_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($hr, $idx, $buf, $chr, $hrs1, $hrs10);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>jetlag</title>" . $ctrl->{'htmlhead2'};
#   print $sock "$ctrl->{'home'} $ctrl->{'HOME'}<br>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} \n";

    if (defined ($form->{'charPerDay'})) {
        $charPerDay = $form->{'charPerDay'};
    }
    if (defined ($form->{'diff'})) {
        $diff = $form->{'diff'};
    }
    if (defined ($form->{'days'})) {
        $days = $form->{'days'};
    }
    if (defined ($form->{'citytop'})) {
        $citytop = $form->{'citytop'};
    }
    if (defined ($form->{'citybot'})) {
        $citybot = $form->{'citybot'};
    }
    if (defined ($form->{'wakeinc'})) {
        $wake++;
    } elsif (defined ($form->{'wakedec'})) {
        $wake--;
    } elsif (defined ($form->{'wake'})) {
        $wake = $form->{'wake'};
    }
    if (defined ($form->{'sleepinc'})) {
        $sleep++;
    } elsif (defined ($form->{'sleepdec'})) {
        $sleep--;
    } elsif (defined ($form->{'sleep'})) {
        $sleep = $form->{'sleep'};
    }
    # wait and flight
    if (defined ($form->{'waitinc'})) {
        $wait++;
    } elsif (defined ($form->{'waitdec'})) {
        $wait--;
    } elsif (defined ($form->{'wait'})) {
        $wait = $form->{'wait'};
    }
    if (defined ($form->{'flyinc'})) {
        $fly++;
    } elsif (defined ($form->{'flydec'})) {
        $fly--;
    } elsif (defined ($form->{'fly'})) {
        $fly = $form->{'fly'};
    }
    if (defined ($form->{'special'})) {
        $special = $form->{'special'};
    }

    ($buf, $hrs1, $hrs10) = &oneday (0);
    $buf = $buf x $days;
    $hrs1 = $hrs1 x $days;
    $hrs10 = $hrs10 x $days;
    
    print $sock "<pre>\n";
    substr ($hrs10, 0, length ($citytop)) = $citytop;
    print $sock "$hrs10\n";
    print $sock "$hrs1\n";
    print $sock "$buf\n";

    $buf = ' ' x $wake . 'z' x $sleep;
    print $sock "$buf\n";

    $buf = ' ' x $wait . 'f' x $fly;
    print $sock "$buf\n";

    if ($special ne '') {
        print $sock "$special\n";
    }

    ($buf, $hrs1, $hrs10) = &oneday ($diff);
    $buf = $buf x $days;
    $hrs1 = $hrs1 x $days;
    $hrs10 = $hrs10 x $days;

    print $sock "$buf\n";
    print $sock "$hrs10\n";
    substr ($hrs1, 0, length ($citybot)) = $citybot;
    print $sock "$hrs1\n";
    print $sock "</pre>\n";


    print $sock "<form action=\"/jetlag.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "<tr>\n";
    print $sock "    <td><input type=\"submit\" name=\"submit\" value=\"Update\"></td>\n";
    print $sock "    <td>";
    print $sock "    <input type=\"submit\" name=\"wakedec\" value=\"wake-\">\n";
    print $sock "    <input type=\"submit\" name=\"wakeinc\" value=\"+\">\n";
    print $sock "    <input type=\"submit\" name=\"sleepdec\" value=\"z-\">\n";
    print $sock "    <input type=\"submit\" name=\"sleepinc\" value=\"+\">\n";
    print $sock "    </td>\n";
    print $sock "</tr>\n";

    print $sock "<tr>\n";
    print $sock "    <td>Flight</td>\n";
    print $sock "    <td>";
    print $sock "    <input type=\"submit\" name=\"waitdec\" value=\"wait-\">\n";
    print $sock "    <input type=\"submit\" name=\"waitinc\" value=\"+\">\n";
    print $sock "    <input type=\"submit\" name=\"flydec\" value=\"z-\">\n";
    print $sock "    <input type=\"submit\" name=\"flyinc\" value=\"+\">\n";
    print $sock "    </td>\n";
    print $sock "</tr>\n";

    print $sock "<tr>\n";
    print $sock "    <td>diff:</td>\n";
    print $sock "    <td><input type=\"text\" size=\"8\" name=\"diff\" value=\"$diff\"></td>\n";
    print $sock "</tr>\n";

    print $sock "<tr>\n";
    print $sock "    <td>char/Day:</td>\n";
    print $sock "    <td><input type=\"text\" size=\"8\" name=\"charPerDay\" value=\"$charPerDay\"></td>\n";
    print $sock "</tr>\n";

    print $sock "<tr>\n";
    print $sock "    <td>days:</td>\n";
    print $sock "    <td><input type=\"text\" size=\"8\" name=\"days\" value=\"$days\"></td>\n";
    print $sock "</tr>\n";

    print $sock "<tr>\n";
    print $sock "    <td>City 1:</td>\n";
    print $sock "    <td><input type=\"text\" size=\"8\" name=\"citytop\" value=\"$citytop\"></td>\n";
    print $sock "</tr>\n";

    print $sock "<tr>\n";
    print $sock "    <td>City 2:</td>\n";
    print $sock "    <td><input type=\"text\" size=\"8\" name=\"citybot\" value=\"$citybot\"></td>\n";
    print $sock "</tr>\n";

    print $sock "<tr>\n";
    print $sock "    <td>Wake:</td>\n";
    print $sock "    <td><input type=\"text\" size=\"8\" name=\"wake\" value=\"$wake\"></td>\n";
    print $sock "</tr>\n";

    print $sock "<tr>\n";
    print $sock "    <td>Sleep:</td>\n";
    print $sock "    <td><input type=\"text\" size=\"8\" name=\"sleep\" value=\"$sleep\"></td>\n";
    print $sock "</tr>\n";

    print $sock "<tr>\n";
    print $sock "    <td>Wait:</td>\n";
    print $sock "    <td><input type=\"text\" size=\"8\" name=\"wait\" value=\"$wait\"></td>\n";
    print $sock "</tr>\n";

    print $sock "<tr>\n";
    print $sock "    <td>Fly:</td>\n";
    print $sock "    <td><input type=\"text\" size=\"8\" name=\"fly\" value=\"$fly\"></td>\n";
    print $sock "</tr>\n";

    print $sock "<tr>\n";
    print $sock "    <td>Special:</td>\n";
    print $sock "    <td><input type=\"text\" size=\"8\" name=\"special\" value=\"$special\"></td>\n";
    print $sock "</tr>\n";

    print $sock "</form>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};

}


\%config;
