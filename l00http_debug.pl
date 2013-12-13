use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my ($name, $key, $val);
my %config = (proc => "l00http_debug_proc",
              desc => "l00http_debug_desc");


sub l00http_debug_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "debug: view debug log";
}

sub l00http_debug_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    if (defined ($form->{'helloname'})) {
        $name = $form->{'helloname'};
    } else {
        $name = "";
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>debug</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} \n";

    print $sock "<form action=\"/debug.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Your name:</td>\n";
    print $sock "            <td><input type=\"text\" size=\"16\" name=\"helloname\" value=\"$name\"></td>\n";
    print $sock "        </tr>\n";
                                                
    print $sock "    <tr>\n";
    print $sock "        <td><input type=\"submit\" name=\"submit\" value=\"Submit\"></td>\n";
    print $sock "        <td>&nbsp;</td>\n";
    print $sock "    </tr>\n";

    print $sock "</table>\n";
    print $sock "<INPUT TYPE=\"hidden\" NAME=\"ip\" VALUE=\"$ctrl->{'client_ip'}\">\n";
    print $sock "</form>\n";

    # get submitted name and print greeting
    print $sock "Hello, $name, here are all the form data:<p>\n";

    # dump all form data\
    print $sock "<table border=\"1\" cellpadding=\"3\" cellspacing=\"1\">\n";
    for $key (keys %$form) {
        $val = $form->{$key};
        print $sock "<tr><td>$key</td><td>$val</td>\n";
    }
    print $sock "</table>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
