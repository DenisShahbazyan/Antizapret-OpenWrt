import os

folder_path = os.getcwd() + '/domains/vpn'
output_file = "all_vpns.txt"

with open(output_file, "w", encoding="utf-8") as outfile:
    for filename in os.listdir(folder_path):
        file_path = os.path.join(folder_path, filename)
        if os.path.isfile(file_path):
            with open(file_path, "r", encoding="utf-8") as infile:
                last_line = ""
                for line in infile:
                    outfile.write(line)
                    last_line = line
                if last_line and not last_line.endswith('\n'):
                    outfile.write('\n')
