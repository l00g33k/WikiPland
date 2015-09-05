use strict;
use warnings;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# this is a simple template, a good starting point to make your own modules

my ($name, $key, $val);
my %config = (proc => "l00http_toast_proc",
              desc => "l00http_toast_desc");


sub l00http_toast_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "toast: Make toast (popup message) on the phone, a demo of controlling phone";
}

sub l00http_toast_proc (\%) {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    if (defined ($form->{'helloname'})) {
        $name = $form->{'helloname'};
    } else {
        $name = "";
    }

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . "<title>toast</title>" . $ctrl->{'htmlhead2'};
    print $sock "$ctrl->{'home'} \n";

    print $sock "<form action=\"/toast.htm\" method=\"get\">\n";
    print $sock "<table border=\"1\" cellpadding=\"5\" cellspacing=\"3\">\n";

    print $sock "        <tr>\n";
    print $sock "            <td>Make a toast:</td>\n";
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
    print $sock "<p>Someone says this to the phone: $name<p>\n";

    if ($ctrl->{'os'} eq 'and') {
        $ctrl->{'droid'}->makeToast($name);
    } elsif ($ctrl->{'os'} eq 'win') {
        `msg %USERNAME% /TIME:1 $name`;
    }


    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
