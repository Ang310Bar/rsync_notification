#!/bin/bash

#####################################################################################################
## Funzione per configurare sendmail con un server SMTP esterno e un indirizzo email come mittente ##
#####################################################################################################
configura_sendmail() {
    echo "COnfiguro sendmail..." | tee -a script.log
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
######################################
## resetta le impostazioni sendmail ##
######################################
reset_config() {
    rm /etc/mail/client-info
    rm /etc/mail/client-info.db
    rm /etc/mail/sendmail.mc
    cp /etc/mail/sendmail.mc.old /etc/mail/sendmail.mc
    m4 /etc/mail/sendmail.mc > /etc/mail/sendmail.cf
    systemctl restart sendmail
}
####################################################################################
## Funzione per controllare se sendmail è installato ed installarlo se necessario ##
####################################################################################
installa_sendmail() {
    if ! command -v sendmail &> /dev/null; then
        echo "sendmail non è installato. Installazione in corso..." | tee -a script.log
        if [[ -n $(command -v apt-get) ]]; then
            sudo apt-get update
            sudo apt-get install -y sendmail
            sudo apt-get install -y sendmail-cf
        elif [[ -n $(command -v yum) ]]; then
            sudo yum install -y sendmail
            sudo yum install -y sendmail-cf
        else
            echo "Non è stato possibile trovare un gestore di pacchetti supportato. Assicurati di aver installato sendmail manualmente." | tee -a script.log
            exit 1
        fi
    fi
}
##################################
## funzione per inserire i dati ##
##################################
inserisci_dati () {
    echo "Inserisci l'indirizzo email al quale notificare:" | tee -a script.log
    read email_destinatario  #inserisci qui la tua email 
    echo "L'indirizzo email inserito è: $email_destinatario" | tee -a script.log
    echo "Confermi? (s/n)" | tee -a script.log
    read risposta_email
    while [ "$risposta_email" == "n" ]; do
        echo "Inserisci l'indirizzo email al quale notificare:" | tee -a script.log
        read email_destinatario
        echo "L'indirizzo email inserito è: $email_destinatario" | tee -a script.log
        echo "Confermi? (s/n)" | tee -a script.log
        read risposta_email
    done
    echo "Vuoi mettere qualcuno in copia? (s/n)" | tee -a script.log
    read risposta_copia
    email_copia=()
    while [ "$risposta_copia" == "s" ]; do
        echo "Scrivi l'indirizzo email in copia:" | tee -a script.log
        read email
        email_copia+=("$email")
        echo "Vuoi inserire un altro indirizzo email in copia? (s/n)" | tee -a script.log
        read risposta_copia
    done
    echo "Inserisci il comune di riferimento:" | tee -a script.log
    read comune
    echo "Inserisci il comando rsync:" | tee -a script.log
    read comando
    echo "Il comando inserito è: $comando" | tee -a script.log
    echo "Confermi? (s/n)" | tee -a script.log
    read risposta_comando
    while [ "$risposta_comando" == "n" ]; do
        echo "Inserisci il comando rsync:" | tee -a script.log
        read comando
        echo "Il comando inserito è: $comando" | tee -a script.log
        echo "Confermi? (s/n)" | tee -a script.log
        read risposta_comando
    done
}


if [ -f "script.log" ]; then
    rm script.log
fi
touch script.log

########################################################################
## Esegue il controllo dei pacchetti necessari e fa la configurazione ##
########################################################################
installa_sendmail
configura_sendmail
echo "****************************************************************" | tee -a script.log
echo "Ok, ho configurato tutto, ora dovrai inserire i dati necessari." | tee -a script.log

######################
## Inserisce i dati ##
######################
inserisci_dati

echo "Sto per iniziare l'rsync..." | tee -a script.log
echo "3" | tee -a script.log
sleep 1
echo "2" | tee -a script.log
sleep 1
echo "1" | tee -a script.log
sleep 1

#######################################
##   rimuovo i vecchi log se ci sono ##
#######################################
if [ -f "./output.log" ]; then
    rm "./output.log"
fi
if [ -f "./errore.log" ]; then
    rm "./errore.log"
fi

#################################################################################################################
## Avvia un ciclo in modo da riprovare il comando quando ha un errore. Il limite di tentativi è impostato a 5. ##
#################################################################################################################
tentativi=1 #tentativo 1 (che poi incremento fino a 5)
echo "rsync avviato..." | tee -a script.log
ip=$(echo "$comando" | sed 's/.*@\([^:]*\):.*/\1/')  #ottiene l'ip del pod dalla stringa
echo "Ip del pod: $ip" | tee -a script.log
while [ $tentativi -le 5 ]; do
    # Esegue il comando e controlla il suo stato di uscita
    eval "$comando" 2>&1 | tee output.log | tee errore.log
    stato_uscita=$?


    ##############################################
    ## Controlla lo stato di uscita del comando ##
    ##############################################
    if [ $stato_uscita -eq 0 ]; then
        echo "Rsync della cartella completato con successo." | tee -a script.log
        if [ "$tentativi" -ne 1 ]; then
            oggetto_email="RSYNC RIUSCITO - ATTENZIONE"
            corpo_email="Ti comunico che l'rsync del repository, avviato per il comune di $comune , è stato completato con successo! TUTTAVIA, ho riscontrato dei problemi, controlla i log! Troverai il riepilogo completo del comando (output.log) e l'output dello script (script.log) nella cartella dove hai eseguito il comando."
        else
            oggetto_email="RSYNC TERMINATO CON SUCCESSO"
            corpo_email="Ti comunico che l'rsync del repository, avviato per il comune di $comune , è stato completato con successo! Troverai il riepilogo completo del comando (output.log) e l'output dello script (script.log) nella cartella dove hai eseguito il comando."
        fi
        break #esce dal ciclo
    else
        echo "Rsync fallito. (Tentativo n $tentativi)" | tee -a script.log
        errore=$(cat errore.log)
        echo "ERRORE RISCONTRATO: $stato_uscita" | tee -a script.log
        if ! ping -c 1 $ip &> /dev/null; then
            echo "Connessione tra le due macchine interrotta!" | tee -a script.log
            riconn=1
            while [ $riconn -le 5 ]; do
                sleep 60
                echo "Tentativo di riconnessione: $riconn" | tee -a script.log
                if  ping -c 1 $ip &> /dev/null; then
                    echo "Connessione ristabilita. Riprovo il comando..." | tee -a script.log
                    break
                fi
                ((riconn++))
            done
            if ! ping -c 1 $ip &> /dev/null; then
                oggetto_email="RSYNC INTERROTTO PER DISCONNESSIONE"
                corpo_email="Ti comunico che l'rsync del repository, avviato per il comune di $comune , si è interrotto a causa di una disconnessione. Ho fatto
                5 tentativi di riconnessione ma senza successo. Troverai il riepilogo completo (output.log) e l'output dello script (script.log) nella cartella dove hai eseguito il comando. Questo invece è il riepilogo degli errori: \n$errore"
                break
            fi
        else
            echo "Riprovo a lanciare il comando..." | tee -a script.log
            oggetto_email="RSYNC INTERROTTO"
            corpo_email="Ti comunico che l'rsync del repository, avviato per il comune di $comune , si è interrotto non portando a termine il trasferimento. Ho fatto
            altri $tentativi tentativi di riavvio del comando ma senza successo. Troverai il riepilogo completo (output.log) e l'output dello script (script.log) nella cartella dove hai eseguito il comando. Questo invece è il riepilogo degli errori: \n$errore"
        fi
       ((tentativi++))
    fi
done

###################
## Invia l'email ##
###################
if [ -n "$oggetto_email" ]; then
    echo -e "From: MA_rsync_notify@outlook.com\nTo: $email_destinatario\nCc: $(IFS=','; echo "${email_copia[*]}")\nSubject: $oggetto_email\n\n$corpo_email" | /usr/sbin/sendmail -t

    ########################################################################################################################################
    ## aspetta 5 secondi e poi verifica se è stata inviata la mail, in caso contrario crea un loop che si interrompe quando la mail parte ##
    ########################################################################################################################################
    sleep 5
    while ! tail -n 1 /var/log/maillog | grep -q "stat=Sent (OK"; do

        if ! mailq | grep -q -v "^[A-Za-z0-9]"; then    #Questo if si assicura che se l'email non è piu in coda ma non è stata ancora inviata, la riaggiunge in coda
            echo "Invio non riuscito...Riprovo!"
            echo -e "From: MA_rsync_notify@outlook.com\nTo: $email_destinatario\nCc: $(IFS=','; echo "${email_copia[*]}")\nSubject: $oggetto_email\n\n$corpo_email" | /usr/sbin/sendmail -t
            echo "**************************"
        fi
        echo "Sto inviando l'email..."
        sleep 15  # Attende 15 secondi prima di controllare di nuovo
    done

    echo "Email inviata" | tee -a script.log
else
    echo "Qualcosa è andato storto. Riprova a lanciare lo script assicurandoti di aver scritto il comando correttamente." | tee -a script.log
fi

echo "Chiusura e ripristino delle impostazioni" | tee -a script.log

#################################################################################################
## Le impostazione di sendmail vanno resettate in caso si voglia utilizzare di nuovo lo script ## 
#################################################################################################
reset_config
