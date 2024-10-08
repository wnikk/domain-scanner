# Domain Scanner Script

This is a Bash script that scans a directory structure to identify domain names and subdomains based on the presence of `www` folders and a custom `.noautodomain` file. The script outputs a JSON file that lists the domain names as keys and their corresponding paths as values.

## Features

- Recursively scans directories starting from `/var/sites/`.
- Identifies domain names by the presence of `www` folders.
- Supports subdomains by analyzing sibling directories.
- Reads from `.noautodomain` file, if present, to customize domain and folder mapping.
- Outputs results in a JSON format.
- Shows progress by printing the domains found during the scan.

## Example Directory Structure
```
/var/sites
├── test1.dev
│   ├── www (main domain)
│   └── sub (sub domain)
├── test2.com
│   └── dev (ignored - no www folder)
├── test3.com
│   ├── www (main domain)
│   └── second
│       ├── www (first sub domain)
│       └── secondsub (second sub domain)
├── test4.www
│   └── dev (ignored - no www folder)
└── test5.com
        ├── .noautodomain (file)
        ├── public_html (main domain by custom config)
        └── protected
            └── share (second domain by custom config)
```

## Example Output

For the directory structure above, the resulting JSON file will contain:
```json
{
  "test1.com": "/var/sites/test1.com/www",
  "sub.test1.com": "/var/sites/test1.com/sub",
  "test3.com": "/var/sites/test3.com/www",
  "second.test3.com": "/var/sites/test3.com/second/www",
  "secondsub.second.test3.com": "/var/sites/test3.com/second/secondsub",
  "test5.com": "/var/sites/test5.com/public_html",
  "subdomain.test5.com": "/var/sites/test5.com/protected/share"
}
```

## How It Works
- The script starts scanning from /var/sites/ (this can be modified).
- If a directory contains a www folder, it treats the parent directory as the domain.
- Sibling directories are treated as subdomains.
- If a .noautodomain file is found in a directory, the script reads it and uses the domain and folder mapping specified in the file instead of scanning for the www folder.

## Example .noautodomain file
```makefile
www = public_html
subdomain = protected/share
```
For the above .noautodomain file located at /var/sites/test5.com/, the JSON output will include:
```json
{
  "test5.com": "/var/sites/test5.com/public_html",
  "subdomain.test5.com": "/var/sites/test5.com/protected/share"
}
```
## Progress Display
As the script scans each domain, it prints out the found domains for real-time feedback.

## Requirements
- Bash version 3.2 or higher.
- Ensure the directory /var/sites/ exists and has the appropriate structure.

## Usage
1. Clone the repository:
```bash
git clone https://github.com/wnikk/domain-scanner.git
cd domain-scanner
```
2. Make the script executable:
```bash
chmod +x domain-scanner.sh
```
3. Run the script:
```bash
./domain-scanner.sh
```
4. The results will be saved in a file called **result.json**.

## Customization
- Modify the starting directory by changing the line scan_directories "/var/sites" to scan another location.
- Add a .noautodomain file in any directory to customize domain and folder mappings for that directory.


## Like What You See? :thumbsup:

[![Stars](https://img.shields.io/github/stars/wnikk/domain-scanner)](https://github.com/wnikk/domain-scanner)

### Give Stars :star:

Make the maintainer happy by hitting the star icon for this repository!

### Ready to be a sponsor? :coffee:

You can now [buy me a latte](https://www.buymeacoffee.com/wnik) =)

## License
This project is licensed under the MIT License - see the LICENSE file for details.
