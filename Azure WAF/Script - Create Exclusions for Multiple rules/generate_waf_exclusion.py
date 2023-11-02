import csv
import re

def main(argv):
    p = re.compile('ARGS:([^:]*)')
    entries = []
    with open(argv[1]) as f:
        rows = csv.reader(f)
        headers = next(rows)
        for row in rows:
            ruleID = row[headers.index('ruleId_s')]
            if ruleID != 949110:
                details = row[headers.index('details_data_s')]
                m = p.findall(details)
                try:
                     entries.append((m[0], ruleID))
                except:
                    pass
    unique_entries = sorted(set(entries))
    for argument, rule  in unique_entries:
        print(f'{argument:<30s} {rule:>20s}')

if __name__ == "__main__":
    import sys
    if len(sys.argv) == 2:
        main(sys.argv)
    else:
        print(f'  Usage:  Script <csv_log_file.csv>')
