import os
import sys
import subprocess

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Required argument: <path to xorg.conf>")
        sys.exit(1)

    xorg_config = sys.argv[1]

    lspci_p = subprocess.Popen(['lspci'], stdout=subprocess.PIPE)
    lspci_vga_p = subprocess.Popen(['grep', 'VGA'], stdin=lspci_p.stdout, stdout=subprocess.PIPE)
    lspci_p.stdout.close()

    vga_devices = lspci_vga_p.communicate()[0]

    gpus = []

    for line in vga_devices.split('\n'):
        if len(line) == 0:
            continue
        if "Cirrus" in line:
            continue
        if "NVIDIA Corporation" in line:
            bus_id_hex = line.split(' ')[0]
            bus_id0, bus_id12 = bus_id_hex.split(':')[0], bus_id_hex.split(':')[1]
            bus_id1, bus_id2 = bus_id12.split('.')
            bus_id_decimal = "{}:{}:{}".format(int(bus_id0, 16), int(bus_id1, 16), int(bus_id2, 16))
            gpus.append((line, bus_id_hex, bus_id_decimal))

    print("{} GPUs detected:".format(len(gpus)))
    print("  {: <10s} {: <10s} {}".format("BusID hex", "BusID dec", "lspci output"))
    for line, bus_id_hex, bus_id_decimal in gpus:
        print("  {: <10s} {: <10s} {}".format(bus_id_hex, bus_id_decimal, line))

    print("Fixing xorg.conf {}...".format(xorg_config))
    xorg_config_backup = xorg_config + ".backup"
    os.rename(xorg_config, xorg_config_backup)
    print("  Backup saved to {}".format(xorg_config_backup))

    with open(xorg_config_backup, 'r') as config:
        lines = config.readlines()

    # 1. Delete whole section ServerLayout (comment it with # symbol)
    # 2. Delete whole section Screen (comment it with # symbol)
    # 3. Add line with BusID in section Device (taken from output of lspci | grep VGA)
    section_start = "Section \""
    section_end   = "EndSection\n"
    sections_to_delete = ["ServerLayout", "Screen"]

    with open(xorg_config, 'w') as updated:
        current_section = None
        for line in lines:
            removed = False

            if current_section is None and section_start in line:
                current_section = line[len(section_start):-2]
                if current_section in sections_to_delete:
                    print("  Section {} deleted!".format(current_section))

            if current_section in sections_to_delete:
                removed = True

            if current_section is not None and line == section_end:
                if current_section == "Device":
                    _, _, bus_id_decimal = gpus[0]
                    print("  BusID {} added!".format(bus_id_decimal))
                    updated.write("    BusID          \"PCI:{}\"\n".format(bus_id_decimal))
                current_section = None

            if removed:
                updated.write("#{}".format(line))
            else:
                updated.write("{}".format(line))
