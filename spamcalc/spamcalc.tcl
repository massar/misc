#
# spamcalc.tcl - sc.pl (http://spamcalc.garion.org) interface for eggdrop
# by Jeroen Massar / Fuzzel <jeroen@unfix.org>
# 01 April 2001 - 00:56 - First Edition
#

set spamcalc_threshold_ban 120
set spamcalc_threshold_warn 35

proc spamcalc_aan {} {
	bind msg - "!spam" spamcalc_msg
	#bind pub - "!spam" spamcalc_pub
	bind msg -o&+o "!spamcheck" spamcheck_msg
	bind join - * spamcalc_join
	putlog "SpamCalc ACTIVATED"
}

proc spamcalc_uit {} {
	unbind msg - "!spam" spamcalc_msg
	#unbind pub - "!spam" spamcalc_pub
	unbind msg -o&+o "!spamcheck" spamcheck_msg
	unbind join - * spamcalc_join
	putlog "SpamCalc DISABLED"
}

###############################################################

proc spamcalc_msg {who host handle txt} {
	spamcalc_egg "$who" "$txt" "$who!$host"
}

proc spamcalc_pub {who host handle chan txt} {
	spamcalc_egg "$chan" "$txt" "$who!$host$chan"
}

proc spamcalc_egg {to txt who} {
	putlog "SPAMCALC: $who - '$txt'"
	set res [spamcalc $txt]
	if { $res == "X" } {
		puthelp "PRIVMSG $to :stop fooling around you idiot"
	} else {
		puthelp "PRIVMSG $to :$txt rates as $res"
	}
}

proc spamcalc_join {nick host handle channel} {
	global spamcalc_threshold_ban
	global spamcalc_threshold_warn
	#putlog "SPAMCALC: $nick - '$host' (onjoin $channel)"

	set beg [expr [string first "@" $host] + 1]
	set dns [string range $host $beg [string length $host]]
	set res [spamcalc $dns]
	if { $res == "X" }  {
		putlog "Spamcalc error"
	} else {
		if { $res > $spamcalc_threshold_ban } {
			newban "*!*@$dns" "Spamcalc" "Your host rates as $res, see www.dnsspam.nl"
		} else {
			if { $res > $spamcalc_threshold_warn } {
				puthelp "PRIVMSG $channel :Spamcalc rates $dns as $res"
			} else {
				putlog "Spamcalc was below threshold ($res/$spamcalc_threshold_warn) for $dns"
			}
		}
	}
}

proc spamcheck_msg {who host handle chan} {
	if { $chan == "" } { set chan "#linux.nl" }
	global spamcalc_threshold_ban
	global spamcalc_threshold_warn
	set nusers 0
	set nban 0
	set nok 0
	set nwarn 0
        foreach p [chanlist $chan] {
		set host [getchanhost $p $chan]
		if { $host != "" } {
			set beg [expr [string first "@" $host] + 1]
			set dns [string range $host $beg [string length $host]]
			set res [spamcalc $dns]
			#putlog "SC: $res $dns"
			if { $res > $spamcalc_threshold_ban } {
				#newban "*!*@$dns" "Spamcalc" "Your host rates as $res, see www.dnsspam.nl"
				puthelp "PRIVMSG $who :SC: $p $dns as $res BANNABLE"
				incr nban
			} else {
				if { $res > $spamcalc_threshold_warn } {
					puthelp "PRIVMSG $who :SC: $p $dns as $res WARN"
					incr nwarn
				} else {
					#putlog "PRIVMSG $who :SC was below threshold ($res/$spamcalc_threshold_warn) for $dns"
					incr nok
				}
			}
		}
                incr nusers
        }
        puthelp "PRIVMSG $who :SpamCheck: Total: $nusers, Ok: $nok, Warn: $nwarn, Ban: $nban"
}

## The real interface to the script
proc spamcalc {txt} {
	regsub -all {([^[:alpha:]])} "$txt" {\1} txt
	set wrd $txt
	if { $wrd == "" } {
		return "X"
	} else {
		set res ""
		catch {set res [exec -- /home/vmlinuz/vmlinuz/bin/sc-0.5/sc.pl -c /home/vmlinuz/vmlinuz/bin/sc-0.5/sc.conf -b $txt]}
		set lines 0
		set empties 0
		return $res
		foreach line [split $res \n] {
			if {$lines >= 10} break
			if {$line == ""} {
				incr empties
				if {$empties >=2} break
				continue
			}
			set ret "$ret $line"
			incr lines
		}
		return $ret
	}
}

