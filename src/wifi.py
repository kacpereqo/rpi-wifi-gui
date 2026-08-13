import re
import subprocess
from dataclasses import dataclass
from enum import Enum


class SecurityType(Enum):
    OPEN = "Open"
    WEP = "WEP"
    WPA = "WPA"
    WPA2 = "WPA2"
    WPA3 = "WPA3"

@dataclass
class AccessPoint:
    ssid: str
    bssid: str
    chan: str
    freq: str
    rate: str
    bandwidth: int
    signal: int
    bars: str
    security: list[SecurityType]
    active: str
    in_use: bool

@dataclass
class CommandResult:
    status_code: int
    output: str

def get_all_access_points_nmcli(interface: str = "wlp0s20f3") -> list[dict]:
    PROPERTIES = ["SSID", "BSSID", "CHAN", "FREQ", "RATE", "SIGNAL", "BANDWIDTH", "BARS", "SECURITY","ACTIVE", "IN-USE" ]
    COMMAND = ["sudo", "nmcli", "-t", "-f", ",".join(PROPERTIES), "device", "wifi", "list",  "--rescan", "yes"]

    result = subprocess.run(COMMAND, capture_output=True, text=True, check=False)

    if result.returncode != 0:
        raise RuntimeError(f"Command failed with exit code {result.returncode}: {result.stderr}")

    ap_output = result.stdout
    ap_lines   = ap_output.strip().split("\n")[1:]

    ap_dict_list: list[dict] = []

    for line in ap_lines:
        access_point_dict = {}
        properties = line.replace("\\:", "#").split(":")

        for prop, key in zip(properties, PROPERTIES):
            key = key.lower().replace("-", "_")
            access_point_dict[key] = prop.replace("#", ":").strip()

        access_point_dict["in_use"]   = access_point_dict["in_use"] == "*"
        access_point_dict["rate"]     = access_point_dict["rate"].split()[0]

        ap_dict_list.append(access_point_dict)

    return ap_dict_list

def get_all_access_points_iw(interface: str = "wlp0s20f3") -> list[dict]:
    # Run iw directly without pipes or grep
    command = ["sudo", "iw", "dev", interface, "scan"]

    result = subprocess.run(command, capture_output=True, text=True, check=False)

    if result.returncode != 0:
        raise RuntimeError(f"Command failed with exit code {result.returncode}: {result.stderr}")

    ap_output = result.stdout

    networks = []
    current_signal = None

    for line in ap_output.splitlines():
        line = line.strip()

        if line.startswith("signal:"):
            match = re.search(r"([-\d\.]+)\s*dBm", line)
            if match:
                current_signal = float(match.group(1))

        elif line.startswith("SSID:"):
            ssid = line.replace("SSID:", "").strip()
            if current_signal is not None:
                networks.append({"ssid": ssid, "rssi": current_signal})
                current_signal = None  

    return networks

def get_all_access_points() -> list[AccessPoint]:
    nmcli_output = get_all_access_points_nmcli()
    access_points = [AccessPoint(**ap_dict) for ap_dict in nmcli_output]

    return access_points


def wifi_connect(ssid: str, password: str, bssid: str | None = None) -> CommandResult:
    COMMAND = ["nmcli", "device", "wifi", "connect", ssid, "password", password]

    result = subprocess.run(COMMAND, capture_output=True, text=True, check=False)

    if result.returncode != 0:
        raise RuntimeError(f"Command failed with exit code {result.returncode}: {result.stderr}")

    return CommandResult(status_code=result.returncode, output=result.stdout)