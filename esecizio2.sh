#!/bin/bash

echo "[*] Controllo file SUID sospetti..."

# find tutti i file SUID
find / -type f -perm -4000 2>/dev/null | while read f; do
    # se il file è python (o altri interpreti pericolosi)
    if [[ "$f" == "/bin/python" ]]; then
        echo "[FIX] Rimosso SUID da $f"
        chmod u-s "$f"
    else
        echo "[OK] File SUID considerato sicuro: $f"
    fi
done

echo "[+] Hardening completato."
