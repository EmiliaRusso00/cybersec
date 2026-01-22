#!/bin/bash

# per aggiungere un utente al gruppo sudoers
# sudo adduser <username> sudo

# PRE TUTTO: 
# Per collegarti via SSH:
# sulla VM digita 
# ip a 
# scoperto l'ip della macchina vai sul terminale del PC dell'aula campus e scrivi:
# ssh nome_utente@ip_trovato (controlla che la VM abbia la network a bridge e non NAT)

sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.original
sudo chmod a-w /etc/ssh/sshd_config.original

# 1.
# Configura sudo affinchè un utente possa eseguire solo un comando specifico (e.s: nmap)
# https://heshandharmasena.medium.com/explain-sudoers-file-configuration-in-linux-1fe00f4d6159
# sudo apt install nmap
# sudo visudo
# which nmap
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

echo 'usr ALL=/usr/bin/nmap, !/usr/bin/nmap ""' | sudo EDITOR='tee -a' visudo

# Configurazione sudoers per fare eseguire sudo nmap -p, sudo nmap e bloccare tutto il resto:

# prova ALL=(ALL:ALL) /usr/bin/nmap ^-p$
# prova ALL=(ALL:ALL) /usr/bin/nmap ""

# altro esempio brutto:sudo cat /var/log/auth.log /etc/shadow ovvero si ha in sudoers:
# utente_name ALL = (root) NOPASSWD:/bin/cat /var/log/*
# senza ! l'utente potrebbe cambiare la password di root:
# user   ALL = /usr/bin/passwd [a-zA-Z0-9_]*, !/usr/bin/passwd root


# 3.
# Cercare tutti gli eseguibili con SUID
# Cercare tutti gli eseguibili con GUID
# find / -user root -perm -4000; >/tmp/files_with_suid.txt
#
# -exec ls -ldb {} \ memorizes data in ldb format (used to provide a detailed listing)
# Controlla se sei root altrimenti tocca fare il comando con sudo

sudo find / -user root -perm -4000 2>/dev/null -exec ls -ldb {} \; >/tmp/files_with_suid.txt
sudo find / -user root -perm -2000 -exec ls -ldb {} \; >/tmp/files_with_guid.txt

# Per capire chi ha quali permessi set user id e group id, poi se c'è un utente es: gianni quello che si fa è scrivere id gianni, group gianni per vedere se ha credenziali da root

# Per levare i permessi a file sospetti, di solito i file con suid non sono di utenti, ma di root
# Se un utente ha un file con suid settato può facilmente diventare root
# cat /tmp/files_with_suid.txt
# Controlla prima: ls -l /path_to_file
# chmod u-s /path_to_file 
# chmod g-s /path_to_file_o_directory


# 4.
# Creare uno unit file di Systemd per permettere una shell aperta a tutti sulla rete 
# (netcat in modalità listen con il processo /bin/bash) e provare a connettersi dalla propria macchina usando netcat

# inside the vm:
# vi /usr/sbin/openshell.sh : #!/bin/bash
#                             nc -l -p 1234 -e /bin/bash 
# chmod +x openshell.sh
#
# from the host:  
# nc localhost 1234 
# occhio a sudo (in caso va messo davanti ai comandi. 

echo -e '#!/bin/bash \nnc -l -p 1234 -e /bin/bash' > sudo /usr/sbin/openshell.sh
chmod +x /usr/sbin/openshell.sh

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

#Per far un test di verifica prova a connetterti localmente nc 127.0.0.1 1234 (se riesci a fare whoami e esce root è fatta)

# 6. 
# Installare e configurare un modulo PAM per richiedere caratteristiche minime alla password (min 8 caratteri, maiuscole, minuscole e simboli)

# sudo apt install libpam-pwquality
# prima di far qualunque cosa facciamo un backup dello scritp, altrimenti un errore potrebbe bloccare tutti i login
sudo cp /etc/pam.d/common-password /etc/pam.d/common-password.backup

# sudo nano /etc/pam.d/passwd
# password    required    pam_pwquality.so retry=3q
# sudo nano /etc/security/pwquality.conf
# minlen = 8
# ucredit = -1
# lcredit = -1
# Sed è un domando molto utile permette di inserire prima di pam_unix_so la riga giusta

sudo sed -i '/pam_unix.so/i password      requisite       pam_pwquality.so retry=3 minlen=8 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1' /etc/pam.d/common-password

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

