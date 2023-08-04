#!/usr/bin/env python3
import sys
from bs4 import BeautifulSoup

# Check if enough arguments are provided
if len(sys.argv) != 4:
    print("Usage: python update_input_value.py <id> <value> <html_file>")
    sys.exit(1)

id_to_replace = sys.argv[1]
new_value = sys.argv[2]
html_file_path = sys.argv[3]

try:
    with open(html_file_path, 'r') as file:
        content = file.read()

    
    soup = BeautifulSoup(content, 'html.parser')


    input_element = soup.find('input', {'id': id_to_replace})

    if input_element:

        input_element['value'] = new_value
        with open(html_file_path, 'w') as file:
            file.write(soup.prettify())
        print(f"Successfully updated the value for id '{id_to_replace}' in '{html_file_path}'.")

    else:
        print(f"Input element with id '{id_to_replace}' not found in '{html_file_path}'. No changes were made.")

except FileNotFoundError:
    print(f"File '{html_file_path}' not found.")
    sys.exit(1)
