Di seguito è riportata una lista di alcuni esercizi di preparazione alla prova pratica nella parte di hardening. 

Prerequisito per svolgere gli esercizi è creare una virtual machine con Debian 13 (così da potervi esercitare sulla stessa piattaforma che troverete all'esame).

- Configura sudo affinchè un utente possa eseguire solo un comando specifico (e.s: nmap)
- Configura sudo affinchè un utente possa eseguire solo un comando specifico ma senza un parametro (e.s: si puo eseguire nmap ma non nmap -p) Nota: si possono mettere espressioni regolari nel file sudoers
- Cercare tutti gli eseguibili con SUID
- Cercare tutti gli eseguibili con SGID
- Creare uno unit file di Systemd per permettere una shell aperta a tutti sulla rete (netcat in modalità listen con il processo /bin/bash) e provare a connettersi dalla propria macchina usando netcat
- Installare e configurare un modulo PAM per richiedere caratteristiche minime alla password (min 8 caratteri, maiuscole, minuscole e simboli)
- Imposta una password a GRUB così da non permettere l'avvio del sistema operativo con parametri del kernel non standard
- Rendi la cartella /var/log leggibile solo da root
- Configura un utente per poter fare cat dei logs ma non essere amministratore (va configurato sudoers in modo opportuno)
- Trova tutti i processi che hanno un file descriptor aperto dentro la cartella /var/log (il comando lsof tornerà comodo)
- Usa docker per effettuare un privilege escalation
- Cercare se esiste un qualche file all'interno della home di un utente che sia scrivibile da tutti gli utenti
- Cercare se esiste una cartella all'interno della home di un utente che sia scrivibile da tutti gli utenti
- Creare un utente con la password che scade ogni giorno
- Imposta Iptables affinchè sia permesso l'accesso alla macchina solo via SSH (TCP port 22)
- Imposta Iptables affinchè sia permesso l'accesso alla macchina solo via SSH (TCP port 22) dall'IP 1.2.3.4 e ad un webserver da qualunque IP (TCP port 80 e 443)
- Imposta Iptables affinchè sia bloccato tutto il traffico Internet sulla macchina (gli utenti non possono navigare) ma sia funzionante il webserver (TCP port 80 e 443)
- Imposta Iptables affinchè sia permesso l'accesso alla macchina solo via SSH (TCP port 22) e ad un webserver (TCP port 80 e 443)
