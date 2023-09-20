#!/usr/bin/env python

import sys
def reverse_file(input_file):
	with open(input_file, "r") as infile:
		lines = infile.readlines()

	reversed_lines = reversed(lines)
	
	return list(reversed_lines)

def find_running_after_keyword(log_lines, keyword):
	found_keyword = False

	for line in log_lines:
		if keyword in line:
			found_keyword = True

		if found_keyword and line.strip().startswith("Running"):
			return line.strip()

	return None

def main():
	if len(sys.argv) != 3:
		print("Usage: python script_name.py log_file keyword")
		sys.exit(1)

	log_file = sys.argv[1]
	keyword = sys.argv[2]

	reversed_log_lines = reverse_file(log_file)

	result = find_running_after_keyword(reversed_log_lines, keyword)
	
	if result:
		print("Found: ",result)
	else:
		print("Keyword or 'Running' line not found.")

if __name__ == "__main__":
	main()
