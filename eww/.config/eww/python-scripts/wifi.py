#!/usr/bin/python

import subprocess
from typing import Any


def print_flush(x: Any):
    print(x, flush=True)


def main():
    wifi_cmd = subprocess.run(
        ["nmcli", "-t", "-f", "active,ssid", "dev", "wifi", "list"],
        capture_output=True,
        text=True,
    )

    if wifi_cmd.returncode != 0:
        print_flush("unable to read wifi")

    search_for = "yes:"

    wifi_cmd_lines = wifi_cmd.stdout.split("\n")
    connected_ssids = list(
        map(
            lambda line: line.lstrip(search_for),
            filter(
                lambda line: line.startswith(search_for),
                wifi_cmd_lines,
            ),
        )
    )

    if len(connected_ssids) < 1:
        return print_flush("󰤯 No wifi?")

    ssid = connected_ssids[0]

    print_flush(f"󰤥 {ssid}")


if __name__ == "__main__":
    main()
