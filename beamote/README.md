# Beamote - Beamer Remote

This little project provides the ability to control a Panasonic Projector (Beamer)
using their publicly documented Serial Control Protocol.

As it is a simple command line utility, one can execute it from
a webserver script and thus control your projector from basically anywhere.

 * Projector On
 * Screen Down
 * Watch!

Of course all without getting up except for getting drinks and popcorn :)

## Connector Cable (ET-ADSER)

The serial cable is typically called ET-ADSER and has a normal 9-pin serial port
on one side and a 8-pin Mini DIN connector on the other side.

Note that this is *NOT* TTL level serial, just plain old RS-232C.

Specifications can be found in Panasonic's documentation available at:

* ftp://ftp.panasonic.com/pub/Panasonic/Drivers/PBTS/manuals/adser.pdf [Panasonic ET-ADSER.pdf]
* https://eww.pavc.panasonic.co.jp/projector/extranet/main/rs232c/AX200_RS232C.pdf [AX200_RS232C.pdf]

This ET-ADSER serial cable is a bit non-standard and retails, if you can get it, for about 80 USD.
As availability of the cable is limited where I live and paying import taxes for a simple cable like
this is a bit much, I resorted to building my own, which also adds a bit of fun.

As serial ports are not so widely available and longer lengths are not always good,
I resorted to integrating a USB-Serial converter into the cable. If I then need
additional length to reach a host I can just use a standard USB serial cable to
extend the cable and it makes it easy to plug it into almost any Linux box.

Alternatively to the USB-Serial converter used one could be use an Arduino or
a Raspberry Pi's serial port capabilities for driving this on the "computer side" of things.
Do watch out that Raspberry & Arduino's are TTL level, thus you need to convert them.

## Computer Side (USB-Serial)

We use a standard USB-Serial RS232-C connector.

+-----+----------+
| Pin | Function |
+-----+----------+
| 1   | GND      |
| 2   | TXD      |
| 3   | RXD      |
+-----+----------+

## Projector Side

Lindy Mini DIN-Kabel, ST-ST (2m, Grey)
http://www.lindy-usa.com/8-pin-Mini-DIN-cable-connector-connector-5m-31539.html

```
 1     2
3  4    5
 6  7  8
    ^
```

+-----+--------+----------+
| Pin | Color  | Function |
+-----+--------+----------+
| 1   | brown  |          |
| 2   | black  |          |
| 3   | yellow | RXD      |
| 4   | orange | GND      |
| 5   | red    | TXD      |
| 6   | purple |          |
| 7   | blue   |          |
| 8   | green  |          |
+-----+--------+----------+

## Hook it up

Hook up GND with GND, RXD with TXD and TXD with RXD, thus cross the RXD/TXD pairs.

I simply used three Female-Female jumper wires, thus avoiding the need to open up
or otherwise break/solder the 3 pins from the serial connector to the wires.

Bit of tape and they are all nice and tight for the time being.

Now connect the Mini DIN cable to your projector and the USB goes into your computer.
A serial device will appear.

For the below commands you will need 'root' privileges.

On Linux:
```
# dmesg | grep tty
```
or
```
# grep ttyUSB /var/log/syslog
```
This should show for instance ttyUSB3, meaning your device is ```/dev/ttyUSB3```

On OSX in a terminal:
```
#  ls -la /dev/tty* |grep -E 'tty\.'
crw-rw-rw-  1 root    wheel   17,   2 Oct 14 10:28 /dev/tty.Bluetooth-Incoming-Port
crw-rw-rw-  1 root    wheel   17,   4 Oct 14 22:43 /dev/tty.usbserial
```

The bluetooth one is what it says, thus that is not it, but ```/dev/tty.usbserial``` is.
Note that depending on driver it might appear under another name.

Execute a PowerQuery command:
```
# ./beamote.go --device /dev/ttyUSB3 --cmd powerquery
000
```

The ```000``` indicates that the power is off.

To see what beamote sends/receives, use:
```
# ./beamote.go --device /dev/ttyUSB3 -v --cmd powerquery
~~~ Opening /dev/ttyUSB3 at 9600
~~~ Sending Command: "QPW" with params ""
~~~ Serial Bytes: 02 51 50 57 03 / [STX] 'Q' 'P' 'W' [ETX] (len 5)
~~~ Written 5 bytes
~~~ Received 02 30 30 30 03 / [STX] '0' '0' '0' [ETX] (len 5)
000
```

To turn a projector on:
```
# ./beamote.go --device /dev/ttyUSB3 -v --cmd poweron
~~~ Opening /dev/ttyUSB3 at 9600
~~~ Sending Command: "PON" with params ""
~~~ Serial Bytes: 02 50 4f 4e 03 / [STX] 'P' 'O' 'N' [ETX] (len 5)
~~~ Written 5 bytes
~~~ Received 02 50 4f 4e 03 / [STX] 'P' 'O' 'N' [ETX] (len 5)
PON
```

To turn a projector off:
```
# ./beamote.go --device /dev/ttyUSB3 --cmd poweroff
POFF
```

I use my amplifier as an input selector, hence selection of inputs etc is not implemented (yet at least), but the code allow for it to be added easily.

