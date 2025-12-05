package main

import (
	"flag"
	"fmt"
	"log/slog"
	"os"

	"github.com/juancortelezzi/scripts-go/cmd/wifi"
	"github.com/juancortelezzi/scripts-go/cmd/workspaces_niri"
)

func main() {
	logger := slog.New(slog.NewTextHandler(os.Stderr, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))

	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, "Usage: %s <command>\n\n", os.Args[0])
		fmt.Fprintf(os.Stderr, "Available commands:\n")
		fmt.Fprintf(os.Stderr, "  wifi            - Display WiFi connection status\n")
		fmt.Fprintf(os.Stderr, "  workspaces_niri - Monitor Niri workspaces\n")
	}

	flag.Parse()

	if flag.NArg() < 1 {
		flag.Usage()
		os.Exit(1)
	}

	command := flag.Arg(0)

	switch command {
	case "wifi":
		wifi.Get()
	case "workspaces_niri":
		workspaces_niri.Run(logger)
		logger.Info("successfuly finished executing workspaces_niri.")
	default:
		fmt.Fprintf(os.Stderr, "Unknown command: %s\n\n", command)
		flag.Usage()
		os.Exit(1)
	}
}
