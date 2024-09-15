#use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2020/02/04

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_calc_proc",
              desc => "l00http_calc_desc");


sub l00http_calc_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    " calc: A trivial spreadsheet";
}

sub l00http_calc_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($ii, $pname, $fname, $html, $output, @format, $compute, $name, $fmt, $tmp);
    my (@formulea, @head, $findhead, $findinit, $cnt, $repeats, $repeat, $rowcnt, $header);


    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>calc</title>" . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"__top__\"></a>\n";
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} <a href=\"#__end__\">jump to end</a> - \n";
    if (defined($form->{'path'})) {
        ($pname, $fname) = $form->{'path'} =~ /^(.+\/)([^\/]+)$/;
        print $sock "Path: <a href=\"/ls.htm?path=$pname\">$pname</a>";
        print $sock "<a href=\"/ls.htm?path=$form->{'path'}\" target=\"_blank\">$fname</a> - \n";
        print $sock "<a href=\"/calc.htm?path=$form->{'path'}\">Calculate</a><p>\n";
    }
    print $sock "<p>\n";

    $html = '';

    undef @formulea;
    undef @head;
    $findhead = 1;
    $findinit = 1;
    $cnt = 0;
    $repeats = 1;
    $rowcnt = 0;
    $header = '';
    $output = '';
    if (&l00httpd::l00freadOpen($ctrl, $form->{'path'})) {

        while ($_ = &l00httpd::l00freadLine($ctrl)) {
            $cnt++;
            s/[\n\r]//g;
            l00httpd::dbp($config{'desc'}, "INPUT $cnt >$_<\n"), if ($ctrl->{'debug'} >= 3);
            if ($findhead) {
                if (/^\|\|.*\|\|$/) {
                    $findhead = 0;
                    $output .= "* [[/view.htm?path=l00://calc_$fname||Calculated table]]\n\n";
                    @_ = split('\|\|', $_);
                    l00httpd::dbp($config{'desc'}, "HEAD  #col $#_ : >$_<\n"), if ($ctrl->{'debug'} >= 3);
                    $output .= "|| $rowcnt ";
                    $rowcnt++;
                    for ($ii = 1; $ii <= $#_; $ii++) {
                        $format[$ii] = '%.2f';
                        if (($name, $fmt) = $_[$ii] =~ /^ *([a-zA-Z0-9_]+?)(%[.0-9]*[gfd]) *$/) {
                            $head[$ii] = $name;
                            $format[$ii] = $fmt;
                        } elsif (($name) = $_[$ii] =~ /^ *([a-zA-Z0-9_]+?) *$/) {
                            $head[$ii] = $name;
                        } else {
                            $head[$ii] = "UKN$ii";
                        }
                        $header .= "|| $head[$ii]";
                        eval "\$$head[$ii] = 0";
                        eval "\$$head[$ii]_ = 0";
                        eval "\$tmp = \$$head[$ii]";
                        $output .= "|| $head[$ii] ";
                        l00httpd::dbp($config{'desc'}, "COL   $ii : >$_[$ii]< -> head >$head[$ii]< := >$tmp<\n"), if ($ctrl->{'debug'} >= 3);
                    }
                    $output .= "||\n";
                    $header .= "||\n";
                } elsif (($name, $tmp) = /^\$([a-zA-Z0-9_]+) *= *(.+);$/) {
                    eval "\$$name=$tmp;";
                    $output .= "\$$name=$tmp;<br>\n";
                    l00httpd::dbp($config{'desc'}, "\$$name=$tmp;\n"), if ($ctrl->{'debug'} >= 3);
                } else {
                    $output .= "$_\n";
                }
            } else {
                if (/^\|\|.*\|\|$/) {
                    @_ = split('\|\|', $_);
                    if ($_[1] =~ /:x(\d+)/) {
                        $repeats = $1;
                        l00httpd::dbp($config{'desc'}, "REPEAT $repeats : >$_<\n"), if ($ctrl->{'debug'} >= 3);
                        next;
                    }
                    if ($findinit) {
                        $findinit = 0;
                        $output .= "|| $rowcnt ";
                        $rowcnt++;
                        for ($ii = 1; $ii <= $#_; $ii++) {
                            if (($compute) = $_[$ii] =~ /^ *(.+?) *$/) {
                                eval "\$$head[$ii] = $compute";
                                eval "\$tmp = \$$head[$ii]";
                                $tmp = sprintf($format[$ii], $tmp);
                                $output .= "|| $tmp ";
                                l00httpd::dbp($config{'desc'}, "INIT  $ii : >$_[$ii]< -> >$head[$ii] $format[$ii] = $compute< := >$tmp<\n"), if ($ctrl->{'debug'} >= 3);
                            }
                        }
                        $output .= "||\n";
                    } else {
                        for ($repeat = 0; $repeat < $repeats; $repeat++) {
                            if (($rowcnt % 20) == 0) {
                                $output .= "|| $header";
                            }
                            $output .= "|| $rowcnt ";
                            $rowcnt++;
                            for ($ii = 1; $ii <= $#_; $ii++) {
                                if (($compute) = $_[$ii] =~ /^ *(.+?) *$/) {
                                    eval "\$$head[$ii]_ = \$$head[$ii]";
                                }
                            }
                            for ($ii = 1; $ii <= $#_; $ii++) {
                                if (($compute) = $_[$ii] =~ /^ *(.+?) *$/) {
                                    if ($compute =~ /"([^"]+)"/) {
                                        $tmp = $1;
                                    } else {
                                        eval "\$$head[$ii] = $compute";
                                        eval "\$tmp = \$$head[$ii]";
                                        $tmp = sprintf($format[$ii], $tmp);
                                    }
                                    $output .= "|| $tmp ";
                                    l00httpd::dbp($config{'desc'}, "EVAL  $rowcnt.$repeat.$ii: >$_[$ii]< => >$head[$ii] = $compute< == >$tmp<\n"), if ($ctrl->{'debug'} >= 3);
                                }
                            }
                            $output .= "||\n";
                        }
                        $repeats = 1;
                    }
                } else {
                    # # between table are comments
                    if (/^[^#]/ || /^$/) {
                        # line not starting with # comment, reset
                        undef @formulea;
                        undef @head;
                        $findhead = 1;
                        $findinit = 1;
                        $repeats = 1;
                        $rowcnt = 0;
                        $header = '';
                    }
                    $output .= "$_\n";
                }
            }



        }

        $html .= "$output\n";

        &l00httpd::l00fwriteOpen($ctrl, "l00://calc_$fname");
        &l00httpd::l00fwriteBuf($ctrl, $output);
        &l00httpd::l00fwriteClose($ctrl);

    } else {
        print $sock "Unable to open '$form->{'path'}'<p>\n";
    }

    $html .= "=___=\n\n";

    print $sock &l00wikihtml::wikihtml ($ctrl, $pname, $html, 0, $fname);

    # send HTML footer and ends
    if (defined ($ctrl->{'FOOT'})) {
        print $sock "<p><a name=\"__end__\"></a><a href=\"#__top__\">Jump to top</a><br>$ctrl->{'FOOT'}\n";
    }
    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
