# fuzgoogle.tcl v1.1
#
# Standalone:
#  pub:google <queryword1> [<queryword2> <...>]
#  pub:google fuzzel
#
# Eggdrop(tm) support:
# in your bot:
#  .tcl source fuzgoogle.tcl
#  .tcl pub:fuzegginit
#
# and then you can use:
# !google keywords - displays the first related website found from google in the channel
# !image keywords  - displays the first related image found on google in the channel
#
# by Jeroen Massar aka Fuzzel/unfix <jeroen@unfix.org> - http://unfix.org
# for the IRCNet channels: #linux.nl (www.penguin.nl), #carnique (www.carnique.nl and #cu2.nl (www.cu2.nl)
# But of course anybody can use it :)
#

package require http
# We apparently need to fake some stuff to make Google happy
http::config -useragent "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.0; .NET CLR 1.0.3705)"

proc pub:dourl { mode query begin end arg } {
	for { set index 0 } { $index<[llength $arg] } { incr index } {
		set query "$query[lindex $arg $index]"
		if {$index<[llength $arg]-1} then {
			set query "$query+"
		}
	}
	set token [http::geturl $query]
	set html  [http::data $token]

	# Finish http output
	puts stderr ""
	upvar #0 $token state
	set max 0
	set beginnetje [string first $begin $html]
	set beginnetje [expr $beginnetje + [string length $begin]]
	set einde [string first $end $html $beginnetje]
	set einde [expr $einde - 1]
	set result [string range $html $beginnetje $einde]
	if { $mode == "google" } {
		set beginnetje [string first "http" $result]
		if { [string range $result $beginnetje [expr $beginnetje + 3] ] != "http" } {
			set result "'$arg' not found"
		} else {
			if { [string range $result 0 3] == "/url" } {
				set result [string range $result 0 [expr [string length $result] - 7 ] ]
			}
			set result [string range $result $beginnetje [string length $result] ]
		}
	}
	if { $mode == "image" } {
		if { [string range $result 0 6] == "-EQUIV=" } {
			set result "'$arg' not found"
		} else {
			set result "http://$result"
		}
	}
	return $result
}

proc pub:google { arg } {
	set query "http://www.google.nl/search?q="
	set begin "<p class=g><a href="
	set end ">"
	set error "/"
	return [pub:dourl "google" $query $begin $end $arg]
}

proc pub:image { arg } {
	set query "http://images.google.com/images?hl=en&imgsafe=off&q="
	set begin "<a href=/imgres?imgurl="
	set end "&"
	return [pub:dourl "image" $query $begin $end $arg]
}

# Eggdrop(tm) Support
proc pub:fuzegginit {} {
	bind pub - !google pub:fuzegggoogle
	bind pub - !image pub:fuzeggimage
	putlog "FuzGoogle.tcl - TCL Google Queries with Eggdrop support"
	putlog "by Jeroen Massar aka Fuzzel/unfix <jeroen@unfix.org>"
	putlog "Website: http://unfix.org"
	putlog "created for IRCNet channels: #linux.nl (www.penguin.nl), #carnique (www.carnique.nl and #cu2.nl (www.cu2.nl)"
}

proc pub:fuzegggoogle { nick uhost handle channel arg } {
	if {[llength $arg]==0} {
		putserv "KICK $channel $nick :zeg kansloos figuur, doe eens niet"
	} else {
		putlog "GOOGLE: $nick!$uhost - '$arg'"
		set answer [pub:google $arg]
		putserv "PRIVMSG $channel :google says $answer"
	}
}

proc pub:fuzeggimage { nick uhost handle channel arg } {
	if {[llength $arg]==0} {
		putserv "kick $channel $nick :zeg kansloos figuur, opzouten..."
	} else {
		putlog "IMAGE: $nick!$uhost - '$arg'"
		set answer [pub:image $arg]
		putserv "PRIVMSG $channel :imagegoogle says $answer"
	}
}

