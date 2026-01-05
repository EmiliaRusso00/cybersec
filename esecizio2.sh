#!/bin/bash

# per aggiungere un utente al gruppo sudoers
# sudo adduser <username> sudo

# 1.
# Configura sudo affinchè un utente possa eseguire solo un comando specifico (e.s: nmap)
# sudo apt install nmap
# sudo visudo
# usr ALL = NOPASSWD: /usr/bin/nmap

# tee -a:  leggi l'input e scrivilo in append su un file
# senza '-a' sovrascrittura
# >>: append
# >: redirect 
echo 'usr ALL = NOPASSWD: /usr/bin/nmap' | sudo EDITOR='tee -a' visudo

# 2.
# Configura sudo affinchè un utente possa eseguire solo un comando specifico ma senza un parametro (e.s: si puo eseguire nmap ma non nmap -p)
# sudo visudo
# usr ALL=/usr/bin/nmap, !/usr/bin/nmap ^.*-p.*$

echo 'usr ALL=/usr/bin/nmap, !/usr/bin/nmap ^.*-p.*$' | sudo EDITOR='tee -a' visudo

# 3.
# Cercare tutti gli eseguibili con SUID
# Cercare tutti gli eseguibili con GUID
# find / -user root -perm -4000; >/tmp/files_with_suid.txt
#
# -exec ls -ldb {} \ memorizes data in ldb format (used to provide a detailed listing)

find / -user root -perm -4000 -exec ls -ldb {} \; >/tmp/files_with_suid.txt
find / -user root -perm -2000 -exec ls -ldb {} \; >/tmp/files_with_guid.txt

# 4.
# Creare uno unit file di Systemd per permettere una shell aperta a tutti sulla rete (netcat in modalità listen con il processo /bin/bash) e provare a connettersi dalla propria macchina usando netcat

# inside the vm:
# vi /usr/sbin/openshell.sh : #!/bin/bash
#                             nc -l -p 1234 -e /bin/bash 
# chmod +x openshell.sh
#
# from the host:  
# nc localhost 1234 

echo -e '#!/bin/bash \nnc -l -p 1234 -e /bin/bash' >  /usr/sbin/openshell.sh
chmod +x openshell.sh


tee /etc/systemd/system/openshell.service << EOF 
[Unit]
Description=<a shell is available from now on, connect from the host using the command 'nc localhost source-port'>

[Service]
User=root
ExecStart=/usr/sbin/openshell.sh
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target"
EOF

sudo systemctl daemon-reload
sudo systemctl start openshell.service
sudo systemctl enable openshell.service

# 6. 
# Installare e configurare un modulo PAM per richiedere caratteristiche minime alla password (min 8 caratteri, maiuscole, minuscole e simboli)

# sudo apt install libpam-pwquality
#
# sudo nano /etc/pam.d/passwd
# password    required    pam_pwquality.so retry=3q
# sudo nano /etc/security/pwquality.conf
# minlen = 8
# ucredit = -1
# lcredit = -1


echo 'password    required    pam_pwquality.so retry=3' | tee -a sudo /etc/pam.d/passwd:

echo -e 'minlen = 8 \nucredit = -1 \nlcredit = -1' | tee -a sudo /etc/security/pwquality.conf:

# 7.1
# Imposta una password a GRUB così da non permettere l'avvio del sistema operativo con parametri del kernel non standard

# sudo nano /etc/grub.d/00_header

# cat << EOF
# set superusers="usr"
# password usr 5351
# EOF

# sudo update-grub


# sudo tee -a /etc/grub.d/00_header << REALEND 
# cat << EOF
# set superusers="usr"
# password usr 5351 
# EOF
# REALEND 



# 7.2 NON SCRIPTATO
# grub-mkpasswd-pbkdf2
# ctrl+shift+C per copiare l'hash
# sudo nano /etc/grub.d/40_custom  
# write: set superusers="username"  
#       password_pbkdf2 username hash  
# sudo update-grub  


# 8.
# Rendi la cartella /var/log leggibile solo da root
sudo chmod 700 /var/log


# 9.
# Configura un utente per poter fare cat dei logs ma non essere amministratore (va configurato sudoers in modo opportuno)
# query: How to allow a user to view a particular file via sudoers?

# sudo visudo
# usr ALL = /bin/cat /var/log
#
# now usr can read a log
 using the command: sudo cat /var/log/filename

echo 'usr ALL = /bin/cat /var/log' | sudo EDITOR='tee -a' visudo 

# 10.
# Trova tutti i processi che hanno un file descriptor aperto dentro la cartella /var/log 
sudo lsof /var/log

# 11.
# Cercare se esiste un qualche file/ cartella all'interno della home di un utente che sia scrivibile da tutti gli utenti

# find . -perm -o=w 

# 12. 
#
# sudo su
# crontab -e 
# */1 * * * *  passwd --expire usr

sudo su << REALEND
crontab -e << EOF
*/1 * * * *  passwd --expire usr
EOF
REALEND

# 13.
# Imposta Iptables affinchè sia permesso l'accesso alla macchina solo via SSH (TCP port 22)
sudo apt-get install iptables
sudo iptables -nvL # check the status
sudo iptables -A INPUT -m state --state ESTABLISHED, RELATED -j ACCEPT 
sudo iptables -P DROP
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT 

# Imposta Iptables affinchè sia permesso l'accesso alla macchina solo via SSH (TCP port 22) dall'IP 1.2.3.4 e ad un webserver da qualunque IP (TCP port 80 e 443)
sudo iptables -A INPUT -p tcp -s 1.2.3.4 --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT 
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT 

# Imposta Iptables affinchè sia bloccato tutto il traffico Internet sulla macchina (gli utenti non possono navigare) ma sia funzionante il webserver (TCP port 80 e 443)
sudo iptables -A OUTPUT -p tcp --sport 80 -j ACCEPT 
sudo iptables -A OUTPUT -p tcp --sport 443 -j ACCEPT 

