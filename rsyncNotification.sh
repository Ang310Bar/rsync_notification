#!/bin/bash

# Funzione per configurare sendmail con un server SMTP esterno e un indirizzo email come mittente
configura_sendmail() {
    cp /etc/mail/sendmail.mc /etc/mail/sendmail.mc.old
    touch /etc/mail/client-info
    echo "AuthInfo: \"U:root\" \"I:MA_rsync_notify@outlook.com\" \"P:R0cky2022!\"" >> /etc/mail/client-info        #account di invio
    makemap hash /etc/mail/client-info < /etc/mail/client-info
    mailer_line=$(grep -n "MAILER(smtp)" /etc/mail/sendmail.mc | head -n 1 | cut -d: -f1)
    sed -i "${mailer_line}i \
dnl Configurazioni di sendmail \\
define(\`SMART_HOST',\`smtp.office365.com')dnl \\
define(\`RELAY_MAILER_ARGS', \`TCP \$h 587')dnl \\
define(\`ESMTP_MAILER_ARGS', \`TCP \$h 587')dnl \\
define(\`confAUTH_OPTIONS', \`A p')dnl \\
FEATURE(\`authinfo',\`hash -o /etc/mail/client-info.db')dnl  \\
define(\`confAUTH_MECHANISMS', \`EXTERNAL GSSAPI DIGEST-MD5 CRAM-MD5 LOGIN PLAIN')dnl \\
TRUST_AUTH_MECH(\`EXTERNAL DIGEST-MD5 CRAM-MD5 LOGIN PLAIN')dnl \
" /etc/mail/sendmail.mc
    m4 /etc/mail/sendmail.mc > /etc/mail/sendmail.cf
    systemctl restart sendmail
}

#resetta le impostazioni sendmail
reset_config() {
    rm errore.log
    rm /etc/mail/client-info
    rm /etc/mail/client-info.db
    rm /etc/mail/sendmail.mc
    cp /etc/mail/sendmail.mc.old /etc/mail/sendmail.mc
    m4 /etc/mail/sendmail.mc > /etc/mail/sendmail.cf
    systemctl restart sendmail
}

# Funzione per controllare se sendmail è installato e installarlo se necessario
installa_sendmail() {
    if ! command -v sendmail &> /dev/null; then
        echo "sendmail non è installato. Installazione in corso..."
        if [[ -n $(command -v apt-get) ]]; then
            sudo apt-get update
            sudo apt-get install -y sendmail
            sudo apt-get install -y sendmail-cf
            # Configura sendmail dopo l'installazione
        elif [[ -n $(command -v yum) ]]; then
            sudo yum install -y sendmail
            sudo yum install -y sendmail-cf
            # Configura sendmail dopo l'installazione
        else
            echo "Non è stato possibile trovare un gestore di pacchetti supportato. Assicurati di aver installato sendmail manualmente."
            exit 1
        fi
    fi
}
inserisci_dati () {
    echo "Inserisci l'indirizzo email al quale notificare:"
    read email_destinatario  #inserisci qui la tua email
    echo "Inserisci il comune di riferimento:"
    read comune
    echo "Inserisci il comando rsync:"
    read comando
}

# Esegui il controllo dei pacchetti necessari e la configurazione
installa_sendmail
configura_sendmail

# Inserisce i dati
echo "****************************************************************"
echo "Ok, ho configurato tutto, ora dovrai inserire i dati necessari."
inserisci_dati

echo "Sto per iniziare l'rsync..."
echo "3"
sleep 1
echo "2"
sleep 1
echo "1"
sleep 1

# Esegui il comando e controlla il suo stato di uscita
eval "$comando" 2>> errore.log
stato_uscita=$?

# Controlla lo stato di uscita del comando
if [ $stato_uscita -eq 0 ]; then
    echo "Rsync della cartella completata con successo."
    oggetto_email="RSYNC TERMINATO CON SUCCESSO"
    corpo_email="Ti comunico che l'rsync del repository, avviato per il comune di $comune , è stato completato con successo!"
    # Invia un'email di notifica di successo
else
    echo "Rsync della cartella interrotto con errore."
    errore=$(cat errore.log)
    oggetto_email="RSYNC INTERROTTO - ERRORE"
    corpo_email="Ti comunico che l'rsync del repository, avviato per il comune di $comune , si è interrotto non portando a termine il trasferimento. Questo è il log dell'errore: \n$errore"
    # Invia un'email di notifica di errore
fi

echo -e "From: MA_rsync_notify@outlook.com\nTo: $email_destinatario\nSubject: $oggetto_email\n\n$corpo_email" | /usr/sbin/sendmail -t
#aspetta che l'email sia inviata prima di fare il reset delle impostazioni
sleep 5
while ! tail -n 1 /var/log/maillog | grep -q "stat=Sent (OK"; do
    if ! mailq | grep -q -v "^[A-Za-z0-9]"; then
        echo "Invio non riuscito...Riprovo!"
        echo -e "From: MA_rsync_notify@outlook.com\nTo: $email_destinatario\nSubject: $oggetto_email\n\n$corpo_email" | /usr/sbin/sendmail -t
        echo "**************************"
    fi
    echo "Sto inviando l'email..."
    sleep 15  # Attendi 15 secondi prima di controllare di nuovo
done
echo "Email inviata"
echo "Chiusura e ripristino delle impostazioni"
reset_config
