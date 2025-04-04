package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"
)

func fatal(format string, v ...any) {
	fmt.Printf(format, v...)
	os.Exit(1)
}

func printCommand(cmd *exec.Cmd) {
	fmt.Printf("%s[*] %s%s%s\n", color(Gray), color(Green), joinArguments(cmd.Args), reset)
}

func joinArguments(args []string) string {
	formattedArgs := make([]string, len(args))
	for i, arg := range args {
		if strings.Contains(arg, " ") {
			formattedArgs[i] = fmt.Sprintf("\"%s\"", arg)
		} else {
			formattedArgs[i] = arg
		}
	}

	return strings.Join(formattedArgs, " ")
}

type Color int

var (
	Red     Color = 31
	Green   Color = 32
	Yellow  Color = 33
	Blue    Color = 34
	Magenta Color = 35
	Gray    Color = 90
)

const reset = "\x1b[0m"

func color(color Color) string {
	return fmt.Sprintf("\x1b[%dm", color)
}
