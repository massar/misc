///usr/bin/env go run $0 "$@"; exit

/*
 * Beamote - Jeroen Massar <jeroen@massar.ch>
 *
 * https://github.com/massar/misc/tree/master/beamote/
 */

package main

import (
	"bufio"
	"flag"
	"fmt"
	"github.com/tarm/serial"
	"time"
)

var g_verbose bool

const (
	/* Start / end indicators */
	PProto_STX  = '\x02'
	PProto_ETX  = '\x03'
	PProto_STXs = "\x02"
	PProto_ETXs = "\x03"

	/* Power commands */
	PCmd_Power_On    = "PON"
	PCmd_Power_Off   = "POF"
	PCmd_Power_Query = "QPW"
)

func perr(format string, str ...interface{}) {
	fmt.Print("--> ")
	fmt.Printf(format+"\n", str...)
}

func verb(format string, str ...interface{}) {
	if g_verbose {
		fmt.Print("~~~ ")
		fmt.Printf(format+"\n", str...)
	}
}

func msg(format string, str ...interface{}) {
	fmt.Printf(format+"\n", str...)
}

func vcmd(bytes []byte) (txt string) {
	hex := ""
	str := ""

	for _, b := range bytes {
		if hex != "" {
			hex += " "
			str += " "
		}

		hex += fmt.Sprintf("%02x", b)

		switch b {
		case PProto_STX:
			str += "[STX]"
			break

		case PProto_ETX:
			str += "[ETX]"
			break

		default:
			str += fmt.Sprintf("'%c'", b)
			break
		}
	}

	return fmt.Sprintf("%s / %s (len %d)", hex, str, len(bytes))
}

func PCmd(s *serial.Port, cmd string, params string) (reply string, err error) {
	var ret []byte
	var n int

	slow := true

	reply = ""

	verb("Sending Command: \"%s\" with params \"%s\"", cmd, params)

	if params != "" {
		cmd += ":" + params
	}

	bytes := []byte(PProto_STXs + cmd + PProto_ETXs)

	if g_verbose {
		verb("Sending %s", vcmd(bytes))
	}

	n, err = s.Write(bytes)

	verb("Written %d bytes", n)

	if err != nil {
		perr("Writing to serial device failed: %s", err)
		return
	}

	if slow {
		time.Sleep(time.Second / 2)
		reader := bufio.NewReader(s)
		ret, err = reader.ReadBytes(PProto_ETX)
	} else {
		buf := make([]byte, 256)
		n, err = s.Read(buf)
		ret = buf[:n]
	}
	if err != nil {
		perr("Reading from serial device timed out: %s", err)
		// return
	}

	if g_verbose {
		verb("Received %s", vcmd(ret))
	}

	reply = string(ret)
	return
}

func main() {
	var device string
	var baud int
	var timeout int
	var cmd string
	var ret string
	var pcmd string
	var parg string

	flag.StringVar(&device, "device", "/dev/tty.usbserial", "Serial Device (/dev/tty.usbserial, /dev/ttyUSB0, etc)")
	flag.IntVar(&baud, "baud", 9600, "Baud rate")
	flag.IntVar(&timeout, "timeout", 5, "Timeout in seconds")
	flag.BoolVar(&g_verbose, "v", false, "Enable verbosity?")
	flag.StringVar(&cmd, "cmd", "help", "The Command")
	flag.Parse()

	switch cmd {
	case "poweron":
		pcmd = PCmd_Power_On
		parg = ""
		break

	case "poweroff":
		pcmd = PCmd_Power_Off
		parg = ""
		break

	case "powerquery":
		pcmd = PCmd_Power_Query
		parg = ""
		break

	default:
		perr("No command specified, please see --help")
		return
	}

	verb("Opening %s at %d", device, baud)

	c := &serial.Config{Name: device, Baud: baud, ReadTimeout: time.Second * time.Duration(timeout)}
	s, err := serial.OpenPort(c)

	if err != nil {
		perr("Opening Serial Port Failed: %s", err)
		return
	}

	ret, err = PCmd(s, pcmd, parg)
	if err != nil {
		perr("Sending command Failed: %s", err)
		return
	}

	msg(ret)

	s.Close()
}
