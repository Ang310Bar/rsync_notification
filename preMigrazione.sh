#!/bin/bash


spazio="###################################################"

# Cerca il percorso della cartella "repository" limitando la ricerca alla profondità massima di 1
repositoryPath=$(find / -type d -path "*/home/jboss/repository" 2> /dev/null)

# Verifica se il percorso della cartella "repository" è stato trovato correttamente
if [ -n "$repositoryPath" ]; then

    echo "Path della cartella repository trovato, eseguo i comandi."
    reportPath="$repositoryPath/report.txt"

    echo "$spazio" >> $reportPath
    # Salva nel report il percorso della cartella "repository" e invia l'output alla console
    echo "PATH DELLA REPOSITORY: $repositoryPath" >> $reportPath

    # Ottieni il percorso della cartella genitore di "repository" che sarebbe /home/jboss/
    parentPath=$(dirname "$repositoryPath") 

    if mkdir "$repositoryPath/appoggio"; then
        echo "$spazio" >> $reportPath
        echo "PATH DELLA CARTELLA DI APPOGGIO: $repositoryPath/appoggio" >> $reportPath
    else
        echo "$spazio" >> $reportPath
        echo "Impossibile creare la cartella 'appoggio'. Interrompo lo script." >> $reportPath
        exit 1
    fi
    cd $repositoryPath/appoggio
    # Esegui i comandi cp con i percorsi relativi rispetto alla cartella genitore di "repository"
    cp -pr "${parentPath}/java/jre/lib/security/cacerts" .
    cp -pr "${parentPath}/wildfly_home/standalone/configuration/standalone-full.xml" .
    cp -pr "${parentPath}/wildfly_home/standalone/deploy/sicraweb.ear/server/signed-jars/conf.ig/sicraweb.server.config.xml" .
    cp -pr "${parentPath}/wildfly_home/standalone/deploy/sicraweb.ear/server/signed-jars/conf.ig/security_1" .
    cp -pr "${parentPath}/wildfly_home/standalone/deploy/sicraweb.ear/server/signed-jars/conf.ig/security_2" .
   
    # Verifica VAADIN
    if [ -f "$parentPath/wildfly_home/standalone/deploy/sicraweb-vaadin.war/WEB-INF/portal.properties" ]; then
        cp -pr "${parentPath}/wildfly_home/standalone/deploy/sicraweb-vaadin.war/WEB-INF/portal.properties" .
        echo "$spazio" >> $reportPath
        echo "LISTA DEI FILE IN APPOGGIO:" >> $reportPath
        ls -1 >> $reportPath
        cd ..
        echo "$spazio" >> $reportPath
        echo "VAADIN: SI" >> $reportPath
        
    else
        echo "$spazio" >> $reportPath
        echo "LISTA DEI FILE IN APPOGGIO:" >> $reportPath
        ls -1 >> $reportPath
        cd ..
        echo "$spazio" >> $reportPath
        echo "VAADIN: NO" >> $reportPath
    fi
    # Verifica GEOSERVER
    if [ -z "$(ls -A "$repositoryPath/geoserver/data")" ]; then
        echo "$spazio" >> $reportPath
        echo "GEOSERVER: NO" >> $reportPath
    else
        echo "$spazio" >> $reportPath
        echo "GEOSERVER: SI" >> $reportPath
    fi
    echo "$spazio" >> $reportPath
    echo "LISTA DEGLI ALIAS DEI WS:" >> $reportPath
    cat $parentPath/wildfly_home/standalone/deploy/sicraweb.ear/server/signed-jars/conf.ig/sicraweb.server.config.xml | grep "alias" | awk '{print $4}' | grep 'name="[^"]*"' | sed 's/name="//; s/"//' >> $reportPath
    
    hostname=$(hostname -s)
    echo "$spazio" >> $reportPath
    echo "HOSTNAME DELLA MACCHINA: $hostname" >> $reportPath

    ipPubblico=$(curl ifconfig.me)
    echo "$spazio" >> $reportPath
    echo "IP PUBBLICO: $ipPubblico" >> $reportPath

    ipLocale=$(hostname -I | awk '{print $1}')
    echo "$spazio" >> $reportPath
    echo "IP LOCALE: $ipLocale" >> $reportPath

    echo "Il report è pronto, consulta il file report.txt ($repositoryPath/report.txt) per tutte le informazioni. "

else
    echo "La cartella 'repository' non è stata trovata. Interrompo lo script."
    exit 1
fi







