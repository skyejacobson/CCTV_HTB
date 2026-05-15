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

