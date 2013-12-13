use strict;
use warnings;
use l00backup;

# Release under GPLv2 or later version by l00g33k@gmail.com, 2010/02/14

# deletes files for now, rename, move and copy possible

my %config = (proc => "l00http_tree_proc",
              desc => "l00http_tree_desc");

my (@list, $lvl);

sub l00http_tree_list {
    my ($sock, $path) = @_;
	my ($file);

    $lvl++;

    if ($lvl < 20) {
        if (opendir (DIR, $path)) {
            foreach $file (readdir (DIR)) {
      	        if ($file =~ /^\.+$/) {
			        next;
                }
      	    if (-d $path.$file) {
                    &l00http_tree_list ($sock, "$path$file/");
                } else {
                    push (@list, $path.$file);
                }
            }
        }
    }
    $lvl--;
}



sub l00http_tree_desc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    # Descriptions to be displayed in the list of modules table
    # at http://localhost:20337/
    "tree: list all files in sub-directories as a tree";
}

sub l00http_tree_proc {
    my ($main, $ctrl) = @_;      #$ctrl is a hash, see l00httpd.pl for content definition
    my $sock = $ctrl->{'sock'};     # dereference network socket
    my $form = $ctrl->{'FORM'};     # dereference FORM data
    my ($buffer, $path2, $path, $file, $cnt);

    # Send HTTP and HTML headers
    print $sock $ctrl->{'httphead'} . $ctrl->{'htmlhead'} . $ctrl->{'htmlttl'} . $ctrl->{'htmlhead2'};
    print $sock "<a name=\"__top__\"></a>\n";
    print $sock "$ctrl->{'home'} <a href=\"$ctrl->{'quick'}\">Quick</a> - ";
    if ((defined ($form->{'path'}) && 
        (length ($form->{'path'}) > 0))) {
        $_ = $form->{'path'};
        # keep path only
        s/\/[^\/]+$/\//;
        print $sock " Path: <a href=\"/ls.htm?path=$_\">$_</a>\n";
        $form->{'path'} =~ s/\r//g;
        $form->{'path'} =~ s/\n//g;
    }
    print $sock " <a href=\"#__end__\">jump to end</a><br>\n";
    print $sock "Links: line#=clip path, path=ls.pl, filename=view.pl<p>\n";

    if (!defined ($form->{'path'})) {
        $form->{'path'} = '';
    }

    if (!defined ($form->{'filter'})) {
        $form->{'filter'} = '';
    }

    undef @list;
	$lvl = 0;
    &l00http_tree_list ($sock, $form->{'path'});
    print $sock "<pre>";
	$cnt = 0;
    foreach $file (sort @list) {
        if (!($file =~ /\.bak$/)) {
		    $cnt++;
		    $_ = $file;
			s/ /%20/g;
            print $sock "<a href=\"/clip.htm?update=Copy+to+clipboard&clip=$_\">".
                sprintf("%3d",$cnt)."</a> ";
		    $_ = $file;
			($path, $file) = /^(.+\/)([^\/]+)$/;
            # show path from base down only
			$path2 = $path;
			$path2 =~ s/^$form->{'path'}//;
            print $sock "<a href=\"/ls.htm?path=$path\">$path2</a>";
            print $sock "<a href=\"/view.htm?path=$path$file\">$file</a>\n";
        }
    }
    print $sock "</pre>";


    print $sock "<hr><form action=\"/tree.htm\" method=\"post\">\n";
    print $sock "<input type=\"submit\" name=\"submit\" value=\"Path\">\n";
    print $sock "<input type=\"text\" size=\"16\" name=\"path\" value=\"$form->{'path'}\">\n";
    print $sock "Filter: <input type=\"text\" size=\"16\" name=\"filter\" value=\"$form->{'filter'}\">\n";
    print $sock "</form>\n";

    print $sock "<a name=\"__end__\"></a>\n";
    print $sock "<a href=\"#__top__\">jump to top</a>\n";

    # send HTML footer and ends
    print $sock $ctrl->{'htmlfoot'};
}


\%config;
