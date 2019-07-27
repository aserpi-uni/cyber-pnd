#!/bin/bash

for HOST in dns.pndeflab.edu ftp.pndeflab.edu intfw.pndeflab.edu syslog.pndeflab.edu mainfw.pndeflab.edu web.pndeflab.edu; do
    clear
    ssh -o StrictHostKeyChecking=no admin@$HOST
done

clear
sftp demo@ftp.pndeflab.edu
