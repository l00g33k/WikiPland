# This is an example of what's possible with HTML processing
# I am following a web forum and I want to bookmark my last read message 
# in a really long discussion thread. There must be other options 
# but backyard invention is more fun.
#
# Problem satement:
# Each post has a unique URL of the form:
# http://www.pprune.org/rumours-news/535538-malaysian-airlines-mh370-contact-lost-463.html#post8419340
# The anchor (post8419340) uniquely identifies the post. However,
# there are two problems:
# 1) The post may be deleted by the modulator so the URL is no longer valid
# 2) Irrelavent posts are frequently deleted. However, each page (463) continues 
# to hold 20 posts. Thus if enough posts were deleted, the new valid URL would 
# be:
# http://www.pprune.org/rumours-news/535538-malaysian-airlines-mh370-contact-lost-461.html#post8419340
# So my problem is to automatically find the closest URL to my bookmarked post.
#
# Solution:
# 1) Use other means to put the URL in the clipboard
# 2) Retrieve URL into $url
# 3) Split URL into page number and post number and remaining parts.
# 4) Retrive the page using 
#           ($hdr, $bdy) = &l00wget::wget ($a.$b.$c.$d);
# 5) Scan the HTML for the post anchor and display them
# 6) If we don't find post numbers both greater and smaller that the bookmarked post number, we decrement the page number and try again.



print $sock "pprune processor<p>\n";

if ($ctrl->{'os'} eq 'and') {
    $url = $ctrl->{'droid'}->getClipboard();
    $url = $url->{'result'};

    print $sock "URL:<br><a href=\"$url\">$url</a>\n";
    if (($a,$b,$c,$d) = $url =~ /^(.+-)(\d+)(\.html#post)(\d+)$/) {
        print $sock "($a,$b,$c,$d)<br>\n";
        print $sock "Target post: $d<br>\n";
        print $sock "Target page: $b<br>\n";
		$loop = 10;
		while ($loop > 0) {
			$loop--;
			$gt = 0;
			$lt = 1;
            ($hdr, $bdy) = &l00wget::wget ($a.$b.$c.$d);
            if (length($bdy) == 0) {
				$b--;
			    next;
           	}
            #print $sock "header:<p><pre>\n$hdr\n</pre><p>";
            #print $sock "body:<p><pre>\n$bdy\n</pre><p>";
            print $sock "<pre>\n";
            foreach $_ (split("\n", $bdy)) {
                if (/name="post(\d+)"/) {
                    if ($1 > $d) {
					    $gt = 1;
                	}
                    if ($1 > $d) {
					    $lt = 0;
                	}
                    print $sock "$lt $gt: ";
                    print $sock "<a target=\"pprune\" href=\"$a$b$c$1\">page $b post $1</a>\n";
            	}
           	}
            print $sock "</pre>\n";
			if (($lt > 0) || ($gt == 0)) {
			    $loop = 0;
			} else {
				$b--;
			}
		}
	}

}
