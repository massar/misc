#
# rangeban.tcl - subnet banning for eggdrops(tm)
# by Jeroen Massar / Fuzzel <jeroen@unfix.org>
# 15 July 2002 - 15:08 - First Edition
# 13 Sept 2002 - 22:31 - Regexp version with config load + save
# 14 Sept 2002 - 14:38 - Added Country support, now does a whois to get the country
# 05 Oct  2002 - 20:12 - Country bans are now neatly done as "join #linux.$tld"
# 03 Jan  2003 - 21:54 - A host has to have at least 1 A or AAAA otherwise Ban.
#

proc rangeban_aan {} {
	global RangeBans
	source rangeban.conf
	bind join - * rangeban_join
	putlog "Rangeban ACTIVATED"
}

proc rangeban_uit {} {
	unbind join - * rangeban_join
	putlog "Rangeban DISABLED"
}

bind msg -n&+n "!rangeban" rangeban_msg
bind msg -n&+n "!addban" rangeban_add_msg
bind msg -o&+o "!getbans" rangeban_get_msg
bind msg -o&+o "!tstban" rangeban_tst_msg
bind msg -n&+n "!savebans" rangeban_save_msg
bind msg -n&+n "!loadbans" rangeban_load_msg

###############################################################

proc rangeban_join {nick host handle channel} {
	#putlog "RANGEBAN: $nick - '$host' (onjoin $channel)"
	set beg [expr [string first "@" $host] + 1]
	set dns [string range $host $beg [string length $host]]
	set res [rangeban $dns ""]
	if { $res == "BAN" } {
		newban "*!*@$dns" "RangeBan" "Thank you for using The Rangeban Service(tm)"
		#putlog "RANGEBAN: Adding Ban *!*@$dns"
	} elseif { $res == "NOIP" } {
		newban "*!*@$dns" "RangeBan" "No IP, No IRC"
	} elseif { $res != "OK" } {
		newban "*!*@$dns" "RangeBan" "Join #linux.$res, Greets, The Rangeban Service(tm))"
		#putlog "RANGEBAN: Adding Ban *!*@$dns"
	}
}

proc rangeban_msg {who host handle chan} {
	if { $chan == "" } { set chan "#linux.nl" }
	set nusers 0
	set nban 0
	set nok 0
	puthelp "PRIVMSG $who :RangeBanCheck: Scanning #linux.nl"
	foreach p [chanlist $chan] {
		set host [getchanhost $p $chan]
		if { $host != "" } {
			set beg [expr [string first "@" $host] + 1]
			set dns [string range $host $beg [string length $host]]
			puthelp "PRIVMSG $who :==== $p @ $host"
			set res [rangeban $dns $who]
			if { $res == "BAN"} {
				newban "*!*@$dns" "RangeBan" "Thank you for using The Rangeban Service(tm)"
				#putlog "RANGEBAN: Adding Ban *!*@$dns"
				incr nban
			} else {
				incr nok
			}
		}
		incr nusers
	}
	puthelp "PRIVMSG $who :RangeBanCheck: Total: $nusers, Ok: $nok, Ban: $nban"
}

proc rangeban_add_msg {who host handle bans} {
	global RangeBans
	lappend RangeBans $bans
	puthelp "PRIVMSG $who :Added $bans"
}

proc rangeban_get_msg {who host handle bans} {
	global RangeBans
	puthelp "PRIVMSG $who :Current RangeBans: $RangeBans"
}

proc rangeban_tst_msg {who host handle what} {
	set res [rangeban $what $who]
	puthelp "PRIVMSG $who :Verdict: $what : $res"
}

proc rangeban_save_msg {who host handle what} {
	global RangeBans
	set fd [open "rangeban.conf" w]
	puts $fd "set RangeBans { $RangeBans }"
	puthelp "PRIVMSG $who :RangeBans saved"
	putlog "RANGEBAN: Bans saved"
	close $fd
}

proc rangeban_load_msg {who host handle what} {
	global RangeBans
	source rangeban.conf
	puthelp "PRIVMSG $who :RangeBans loaded"
	putlog "RANGEBAN: Bans loaded"
}

###############################################################

## Check a host if it should be banned based on iprange
## It resolves IPv4 and IPv6 :)
## We don't know for sure if a host connects with IPv4 or IPv6
## so we simply go for worst case ;)
## We also rangeban if the host doesn't resolve at all.
proc rangeban {host who} {
	global RangeBans
	set verdict "OK"
	#regsub -all {([^[:alpha:]])} "$host" {\1} host
	if { $host == "" } {
		return ""
	} else {
		set res ""
		catch {set res [exec -- ~vmlinuz/vmlinuz/vmlinuzrangeban $host]}
		set ips 0
		foreach line [split $res \n] {
			if {$line == ""} continue

			# Don't check the whois for a hostname
			if {	[string match "*\[0-9\].*\[0-9\].*\[0-9\].*\[0-9\]" $line] ||
				[string match "*:*" $line] } {
				catch {set country [split [split [exec -- ~vmlinuz/vmlinuz/vmlinuzwhois $line] \n] " "]}
				incr ips
				set country [string tolower $country]
				if {$country == ""} { set country "??" }
				if { $who != "" } {
					puthelp "PRIVMSG $who :$country : $host / $line"
				}
				if { $country != "nl" && $country != "be"  } {
					if {$who != ""} {
						puthelp "PRIVMSG $who :$country : $host / $line"
					}
					if { [regexp -nocase ".*(pl|si|ro|lv|id|hu|cz|cn|sg|jp|it)" $country] } {
						set verdict $country
					} elseif { $who == "" } {
						# putserv "PRIVMSG Fuzzel :COUNTRY $country : $host / $line"
					}
				}
			}

			foreach i $RangeBans {
				if { [regexp -nocase "^$i$" $line ] } {
					# Only set it to BAN if it was still OK
					# This preserves whois bans on country
					if { $verdict == "OK" } { set verdict "BAN" }
					if { $who == "" } {
						putlog "RANGEBAN $line verdicted as BAN because $i matches"
					} else {
						puthelp "PRIVMSG $who :RANGEBAN $line verdicted as BAN because $i matches"
					}
				}
			}
		}
		if {$ips == 0} {
			set verdict "NOIP"
		}
		return $verdict
	}
}

