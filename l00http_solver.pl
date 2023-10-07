#use strict;
#use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my %config = (proc => "l00http_solver_proc",
              desc => "l00http_solver_desc");
my ($buffer, %formulae, %vars, %varsuni);
my ($name, $formula, $formulaname, $sock, $evald, %formuladesc, @results);

$evald = 1e-6;

sub l00http_solver_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "solver: the HP200LX equation solver";
}

sub evalfn {
    my ($val) = pop;
    my ($ind) = pop;
    my ($res, $buf);

    $buf = "$ind = $val;";
    eval $buf;
    $res = eval $formula;
    $buf = "\"$formula\";";
    $buf = eval $buf;
    $res;
}
sub evaldydx {
    my ($val) = pop;
    my ($ind) = pop;
    my ($y0, $y1, $x1, $m);
    $x0 = $val;
    if ($val == 0) {
        $x1 = $evald;
    } else {
        $x1 = $val * (1 + $evald);
    }
    $y0 = &evalfn ($ind, $x0);
    $y1 = &evalfn ($ind, $x1);
    $m = ($y1 - $y0) / ($x1 - $x0);
#$htmlout .= sprintf ("% .1e(% .1e % .1e/% .1e % .1e) ", 
#$m, $y1, $y1 - $y0, $x1, $x1 - $x0);
#printf ("m% .3e(y% .3e dy% .2e/x% .2e dx% .2e)\n", 
#$m, $y1, $y1 - $y0, $x1, $x1 - $x0);
    ($y0, $m);
}

sub dispExtraVal {
    my ($extraname, $extraformu) = @_;
    my ($buf);

$buf = 'val';
    $buf = eval $extranformu;
    $htmlout .= "FOR3 $extraname, $extraformu\n\n";
    $htmlout .= "Extra value formula: $extraformu\n";
    $htmlout .= "$extraname == dispExtraVal $buf\n\n";
}

sub l00http_solver_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my (@alllines, $line, $lineno, $name, $desc, $extraname, $extraformu, $buf, $result);

    $sock = $ctrl->{'sock'};     # dereference network socket

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} $ctrl->{'HOME'} - ";
    print $sock "<a href=\"#end\">Jump to end</a><hr>\n";
    
    if ((defined ($form->{'path'})) && (length ($form->{'path'}) > 0)) {
        print $sock "Path: <a href=\"/ls.htm?path=$form->{'path'}\">$form->{'path'}</a><br>\n";
    } else {
        print $sock "Path: <a href=\"/ls.htm?path=$ctrl->{'workdir'}\">Select solver equation file</a> and 'Set' to 'solver'<br>\n";
        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
        return;
    }
    $form->{'path'} =~ s/\r//g;
    $form->{'path'} =~ s/\n//g;

    # read the equation file
    $buffer = "";
    if (open (IN, "<$form->{'path'}")) {
        $buffer = '';
        while (<IN>) {
            if (!/^#/) {
                $buffer .= $_;
            }
        }
        close (IN);
    } else {
        print $sock "Failed to open '$form->{'path'}'\n";
        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
        return;
    }
    if ($buffer eq "") {
        print $sock "Enpty '$form->{'path'}'\n";
        # send HTML footer and ends
        print $sock $ctrl->{'htmlfoot'};
        return;
    }
    # read successfully
    undef %formulae;
    undef @formulaename;
    undef %formuladesc;
    undef %extraValueName;
    undef %extraValueFormu;
    @alllines = split ("}", $buffer);
    foreach $line (@alllines) {
        $line =~ s/\r/ /g;
        $line =~ s/\n/ /g;
        # {name"desc|formula|disp_value=formula}
        if (($name, $desc, $formula, $extraname, $extraformu) = $line =~ /{(.+)"(.+)\|(.+)\|(.+)=(.+)/) {
            $formulae {$name} = $formula;
            $formuladesc {$name} = $desc;
            $extraValueName {$name} = $extraname;
            $extraValueFormu {$name} = $extraformu;
    $htmlout .= "FOR2 $extraname, $extraformu\n\n";
            push (@formulaename, $name);
        # {name|formula|disp_value=formula}
        } elsif (($name, $formula, $extraname, $extraformu) = $line =~ /{(.+)\|(.+)\|(.+)=(.+)/) {
            $formulae {$name} = $formula;
            $formuladesc {$name} = '';
            $extraValueName {$name} = $extraname;
            $extraValueFormu {$name} = $extraformu;
    $htmlout .= "FOR1 $extraname, $extraformu\n\n";
            push (@formulaename, $name);
        # {name"desc|formula}
        } elsif (($name, $desc, $formula) = $line =~ /{(.+)"(.+)\|(.+)/) {
            $formulae {$name} = $formula;
            $formuladesc {$name} = $desc;
            push (@formulaename, $name);
        # {name|formula}
        } elsif (($name, $formula) = $line =~ /{(.+)\|(.+)/) {
            $formulae {$name} = $formula;
            $formuladesc {$name} = '';
            push (@formulaename, $name);
        }
        #
    }

#print $sock "<pre>Dumping FORM data:\n";
#foreach $name (keys %$form) {
#    print $sock $name ." =&gt; ". $form->{$name}."\n";
#}
#print $sock "\nDumping formulae data:\n";
#foreach $name (@formulaename) {
#    print $sock "'$name' : $formulae{$name}\n";
#}
#print $sock "</pre>\n";



    if (((defined ($form->{'select'})) ||
        (defined ($form->{'solve'}))) &&
        (defined ($form->{'formulaname'}))) {
        $formula = $formulae{$form->{'formulaname'}};
        if (($lhs, $rhs) = ($formula =~ /(.+)=(.+)/)) {
            $formula = "($lhs) - ($rhs)";
            # find variable names
            undef %vars;
            undef @varsnames;
            while ($formula =~ /(\$[^ +\-*\/()\$]+)[ +\-*\/()\$]/g) {
                $name = $1;
                if (!defined ($vars {$name})) {
                    $vars {$name} = 1;
                    push (@varsnames, $name);
                }
                if (!defined ($varsuni {$name})) {
                    $varsuni {$name} = 0;
                }
            }
            foreach $var (keys %vars) {
                $var2 = $var;
                $var2 =~ s/\$/%24/;
                if (defined ($form->{$var2})) {
                    if ($form->{$var2} =~ /^(.+)f *$/) {
                        $form->{$var2} = $1 * 1e-15;
                    } elsif ($form->{$var2} =~ /^(.+)p *$/) {
                        $form->{$var2} = $1 * 1e-12;
                    } elsif ($form->{$var2} =~ /^(.+)n *$/) {
                        $form->{$var2} = $1 * 1e-9;
                    } elsif ($form->{$var2} =~ /^(.+)u *$/) {
                        $form->{$var2} = $1 * 1e-6;
                    } elsif ($form->{$var2} =~ /^(.+)m *$/) {
                        $form->{$var2} = $1 * 1e-3;
                    } elsif ($form->{$var2} =~ /^(.+)k *$/) {
                        $form->{$var2} = $1 * 1e3;
                    } elsif ($form->{$var2} =~ /^(.+)M *$/) {
                        $form->{$var2} = $1 * 1e6;
                    } elsif ($form->{$var2} =~ /^(.+)G *$/) {
                        $form->{$var2} = $1 * 1e9;
                    } elsif ($form->{$var2} =~ /^(.+)T *$/) {
                        $form->{$var2} = $1 * 1e12;
                    }
                    $varsuni {$var} = $form->{$var2};
#print "var $var === $form->{$var2}\n";
                }
            }
#print $sock "<pre>Dumping varsuni:\n";
#foreach $name (keys %varsuni) {
#    print $sock $name ." =&gt; ". $varsuni{$name}."\n";
#}
#print $sock "</pre>\n";
            if ((defined ($form->{'solve'})) &&
                 (defined ($form->{'var'}))) {
                $htmlout = '';
                $l00g_name = $form->{'var'};
                $l00g_xx = $varsuni {$l00g_name};
                $l00g_m = 0;
                $htmlout .= "<pre>\n";
                # display extra value
                if (defined($extraValueName{$form->{'formulaname'}})) {
                    $htmlout .= "Extra value formula: $extraValueFormu{$form->{'formulaname'}}\n";
                    $buf = eval $extraValueFormu{$form->{'formulaname'}};
                    $htmlout .= $extraValueName {$form->{'formulaname'}}."= $buf\n\n";
                }
                # load variables
                foreach $var (keys %vars) {
                    $buf = "$var = $varsuni{$var}";
                    eval $buf;
                }
                $htmlout .= "Formula:\nerror == $formula\n\n";
                for ($l00g_ii = 0; $l00g_ii < 20; $l00g_ii++) {
                    ($l00g_yy, $l00g_m) = &evaldydx ($l00g_name, $l00g_xx);
                    if ($l00g_m != 0) {
                        $l00g_xx -= $l00g_yy / $l00g_m;
                        #$htmlout .= sprintf ("%.3e -= ", $l00g_xx);
                        #$htmlout .= sprintf ("%.3e / ", $l00g_yy);
                        #$htmlout .= sprintf ("%.3e :: ", $l00g_m);
                    } else {
                        $l00g_xx -= $evald;
                        $htmlout .='m == 0; '; 
                    }
                    $buf = eval $formula;
                    $result = sprintf ("% .3e ", $buf);
                    $htmlout .= $result;
                    $buf = eval "\"$formula\";";
                    $result .= " == $buf";
                    $htmlout .= "== $buf\n";
                }
                if ($#results >= 20) {
                    shift(@results);
                }
                $htmlout .= "\nLast 20 results:\n\n";
                unshift(@results, $ctrl->{'now_string'} . " -- $form->{'formulaname'} : $result");
                foreach $result (@results) {
                    $htmlout .= "$result\n";
                }
                foreach $var (keys %vars) {
                    $buf = "$varsuni{$var} = $var";
                    eval $buf;
                }
                $l00g_name = $form->{'var'};
                $varsuni {$l00g_name} = $l00g_xx;
                $htmlout .= "</pre><hr>\n";
            }
#print $sock "<pre>Dumping varsuni:\n";
#foreach $name (keys %varsuni) {
#    print $sock $name ." =&gt; ". $varsuni{$name}."\n";
#}
#print $sock "</pre>\n";


            print $sock "<a href=\"/solver.htm?launchit=solver&path=$form->{'path'}\">Select another equation</a><br>\n";
            print $sock "<form action=\"/solver.htm\" method=\"get\">\n";
            #print $sock "<input type=\"submit\" name=\"solve\" value=\"Solve\">\n";
            print $sock "<input type=\"hidden\" name=\"solve\" value=\"Solve\">\n";
            print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
            print $sock "<input type=\"hidden\" name=\"formulaname\" value=\"$form->{'formulaname'}\">\n";
            print $sock "Select variable to solve.\n";
            print $sock $formuladesc{$form->{'formulaname'}} . "<br>\n";
            print $sock $formulae{$form->{'formulaname'}} . "<br>\n";
            print $sock "<table border=\"1\" cellpadding=\"1\" cellspacing=\"1\">\n";
            foreach $var (@varsnames) {
                print $sock "<tr><td>\n";
                if ($var eq $form->{'var'}) {
                    $checked = 'checked';
                } else {
                    $checked = '';
                }
                #print $sock "<input type=\"radio\" name=\"var\" value=\"$var\" $checked>$var\n";
                print $sock "<input type=\"submit\" name=\"var\" value=\"$var\">\n";
                print $sock "</td><td>\n";
#                $buf = $vars {$var};
#                $buf = "$var = $vars{$var};";
#                print $sock "$buf\n";
                print $sock "= <input type=\"text\" name=\"$var\" size=20 value=\"$varsuni{$var}\">\n";
                print $sock "</td></tr>\n";
                eval $buf;
            }
            print $sock "</table>\n";
            print $sock "</form><p>\n";

            if ((defined ($form->{'solve'})) &&
                 (defined ($form->{'var'}))) {
                print $sock $htmlout;
            }
        } else {
            print $sock "Unable to parse formula '$formula'<p>\n";
        }
    } else {
        # The select button
        print $sock "<br><form action=\"/solver.htm\" method=\"get\">\n";
        #print $sock "<input type=\"submit\" name=\"select\" value=\"Select\">\n";
        print $sock "<input type=\"hidden\" name=\"select\" value=\"Select\">\n";
        print $sock "<input type=\"hidden\" name=\"path\" value=\"$form->{'path'}\">\n";
        print $sock "<br><table border=\"1\" cellpadding=\"1\" cellspacing=\"1\">\n";
        foreach $name (@formulaename) {
            print $sock "<tr><td>\n";
            #print $sock "<input type=\"radio\" name=\"formulaname\" value=\"$name\">$name\n";
            print $sock "<input type=\"submit\" name=\"formulaname\" value=\"$name\">\n";
            print $sock "$formuladesc{$name}\n";
            print $sock "</td><td>\n";
            print $sock "$formulae{$name}\n";
            print $sock "</td></tr>\n";
        }
        print $sock "</table>\n";
        print $sock "</form><p>\n";
    }


    # dump equations
    print $sock "<pre>\n";
    $lineno = 1;
    if (open (IN, "<$form->{'path'}")) {
        # http://www.perlmonks.org/?node_id=1952
        local $/ = undef;
        $buffer = <IN>;
        close (IN);
    }
    $buffer =~ s/\r//g;
    @alllines = split ("\n", $buffer);
    foreach $line (@alllines) {
        $line =~ s/\r//g;
        $line =~ s/\n//g;
        $line =~ s/</&lt;/g;
        $line =~ s/>/&gt;/g;
        print $sock sprintf ("%04d: ", $lineno++) . "$line\n";
    }
    print $sock "</pre>\n";
    print $sock "<hr><a name=\"end\"></a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
