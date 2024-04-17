function InserisciDati {
    $email_destinatario = Read-Host "Inserisci l'indirizzo email al quale notificare"
    $comune = Read-Host "Inserisci il comune di riferimento"
    $comando = Read-Host "Inserisci il comando rsync"
    return $email_destinatario, $comune, $comando
}
#Funzione per inviare l'email, in caso di errore riprova finche' non va
function InviaEmail {
    param (
        [string]$email_destinatario,
        [string]$comune,
        [string]$oggetto_email,
        [string]$corpo_email
    )

    try {
        Send-MailMessage -From $EmailFrom -To $email_destinatario -Subject $oggetto_email -Body $corpo_email -SmtpServer "smtp.office365.com" -Port 587 -UseSsl -Credential $Credential -ErrorAction Stop
        Write-Host "Email inviata con successo."
    } catch {
        Write-Host "Si e' verificato un errore durante l'invio dell'email: $($_.Exception.Message)"
        Write-Host "Riprovero' l'invio dell'email tra un minuto..."
        Start-Sleep -Seconds 60 
        InviaEmail -email_destinatario $email_destinatario -comune $comune -oggetto_email $oggetto_email -corpo_email $corpo_email
    }
}

# Path di Cygwin
$cygwinPath = "C:\cygwin64" 
$cygwinExe = "$cygwinPath\bin\bash.exe"
$file_esito = "/tmp/esito.txt"

# Inserimento dei dati
$email_destinatario, $comune, $comando = InserisciDati


# Credenziali per l'invio di e-mail
$EmailFrom = "MA_rsync_notify@outlook.com"
$Password = ConvertTo-SecureString "R0cky2022!" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($EmailFrom, $Password)

$comando_completo = "$comando 2>> $file_esito"

# Avvia il processo e attendi che sia terminato
Start-Process -FilePath $cygwinExe -ArgumentList "-l", "-i", "-c", "`"$comando_completo`"" -Wait -NoNewWindow

# Leggi l'esito dal file
$stato_uscita = Get-Content -Path "$cygwinPath$file_esito"

# Controlla lo stato di uscita del comando
if ($null -eq $stato_uscita) {
    Write-Host "Rsync della cartella completato con successo."
    $oggetto_email = "RSYNC TERMINATO CON SUCCESSO"
    $corpo_email = "Ti comunico che l'rsync del repository, avviato per il comune di $comune, e' stato completato con successo!"
    # Invia un'email di notifica di successo
    InviaEmail -email_destinatario $email_destinatario -comune $comune -oggetto_email $oggetto_email -corpo_email $corpo_email
} else {
    Write-Host "Rsync della cartella interrotto con errore."
    $oggetto_email = "RSYNC INTERROTTO - ERRORE"
    $corpo_email = "Ti comunico che l'rsync del repository, avviato per il comune di $comune, si e' interrotto non portando a termine il trasferimento. Questo e' il log dell'errore: `n$stato_uscita"
    # Invia un'email di notifica di errore
    InviaEmail -email_destinatario $email_destinatario -comune $comune -oggetto_email $oggetto_email -corpo_email $corpo_email
}

# Rimuove il file di esito dalla cartella temp
Remove-Item -Path "$cygwinPath$file_esito"
