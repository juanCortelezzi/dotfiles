package wifi

import (
	"fmt"
	"os/exec"
	"strings"
)

func Get() {
	cmd := exec.Command("nmcli", "-t", "-f", "active,ssid", "dev", "wifi", "list")
	output, err := cmd.Output()

	if err != nil {
		fmt.Println("unable to read wifi")
		return
	}

	searchFor := "yes:"
	lines := strings.Split(string(output), "\n")

	var connectedSSIDs []string
	for _, line := range lines {
		if ssid, ok := strings.CutPrefix(line, searchFor); ok {
			connectedSSIDs = append(connectedSSIDs, ssid)
		}
	}

	if len(connectedSSIDs) < 1 {
		fmt.Println("󰤯 No wifi?")
		return
	}

	ssid := connectedSSIDs[0]
	fmt.Printf("󰤥 %s\n", ssid)
}
