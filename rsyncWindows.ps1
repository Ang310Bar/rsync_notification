function InserisciDati {
    $email_destinatario = Read-Host "Inserisci l'indirizzo email al quale notificare "
    "Inserisci l'indirizzo email al quale notificare:" | Out-File -FilePath "$script_output" -Append
    $risposta = Read-Host "L'indirizzo email inserito e': $email_destinatario. Confermi? (s/n) "
    "L'indirizzo email inserito e': $email_destinatario. Confermi? (s/n): `n$risposta" | Out-File -FilePath "$script_output" -Append
    while ($risposta -eq "n") {
        $email_destinatario = Read-Host "Inserisci l'indirizzo email al quale notificar: "
        "Inserisci l'indirizzo email al quale notificare:" | Out-File -FilePath "$script_output" -Append
        $risposta = Read-Host "L'indirizzo email inserito e': $email_destinatario. Confermi? (s/n) "
        "L'indirizzo email inserito e': $email_destinatario. Confermi? (s/n): `n$risposta" | Out-File -FilePath "$script_output" -Append
    }
    $risposta = Read-Host "Vuoi mettere qualcuno in copia? (s/n) "
    "Vuoi mettere qualcuno in copia? (s/n):`n$risposta" | Out-File -FilePath "$script_output" -Append
    $email_copia = @()
    while ($risposta -eq "s") {
        $email = Read-Host "Scrivi l'indirizzo email in copia "
        "Scrivi l'indirizzo email in copia:`n$email" | Out-File -FilePath "$script_output" -Append
        $email_copia += $email
        $risposta = Read-Host "Vuoi inserire un altro indirizzo email in copia? (s/n) "
        "Vuoi inserire un altro indirizzo email in copia? (s/n):`n$risposta" | Out-File -FilePath "$script_output" -Append
    }
    $comune = Read-Host "Inserisci il comune di riferimento "
    "Inserisci il comune di riferimento:`n$comune" | Out-File -FilePath "$script_output" -Append
    $comando = Read-Host "Inserisci il comando rsync (evita l'utilizzo dei doppi apici) "
    "Inserisci il comando rsync (evita l'utilizzo dei doppi apici):`n$comando" | Out-File -FilePath "$script_output" -Append
    $risposta = Read-Host "Il comando inserito e': $comando. Confermi? (s/n) "
    "Il comando inserito e': $comando. Confermi? (s/n):`n$risposta" | Out-File -FilePath "$script_output" -Append
    while ($risposta -eq "n") {
        $comando = Read-Host "Inserisci il comando rsync (evita l'utilizzo dei doppi apici) "
        "Inserisci il comando rsync (evita l'utilizzo dei doppi apici):`n$comando" | Out-File -FilePath "$script_output" -Append
        $risposta = Read-Host "Il comando inserito e': $comando. Confermi? (s/n) "
        "Il comando inserito e': $comando. Confermi? (s/n):`n$risposta" | Out-File -FilePath "$script_output" -Append
    }
    
    return $email_destinatario, $comune, $comando, $email_copia
}

#Funzione per inviare l'email, in caso di errore riprova finche' non va
function InviaEmail {
    param (
        [string]$email_destinatario,
        [string]$comune,
        [string]$oggetto_email,
        [string]$corpo_email
    )

    # Verifica se sia l'oggetto che il corpo dell'email sono vuoti
    if ([string]::IsNullOrEmpty($oggetto_email) -or [string]::IsNullOrEmpty($corpo_email)) {
        Write-Host "Oggetto o corpo dell'email vuoti. L'email non verrà inviata." -ForegroundColor Red
        return
    }

    try {
        if (-not [string]::IsNullOrEmpty($email_copia)) {
            $email_copia_stringa = $email_copia -join ","
            Send-MailMessage -From $EmailFrom -To $email_destinatario -Cc $email_copia_stringa -Subject $oggetto_email -Body $corpo_email -SmtpServer "smtp.office365.com" -Port 587 -UseSsl -Credential $Credential -ErrorAction Stop
        } else {
            Send-MailMessage -From $EmailFrom -To $email_destinatario -Subject $oggetto_email -Body $corpo_email -SmtpServer "smtp.office365.com" -Port 587 -UseSsl -Credential $Credential -ErrorAction Stop
        }
        Write-Host "Email inviata con successo." -ForegroundColor Green
        "Email inviata con successo." | Out-File -FilePath "$script_output" -Append
    } catch {
        Write-Host "Si e' verificato un errore durante l'invio dell'email: $($_.Exception.Message)" -ForegroundColor Red
        "Si e' verificato un errore durante l'invio dell'email: $($_.Exception.Message)" | Out-File -FilePath "$script_output" -Append
        Write-Host "Riprovero' l'invio dell'email tra un minuto..." -ForegroundColor Yellow
        "Riprovero' l'invio dell'email tra un minuto..." | Out-File -FilePath "$script_output" -Append
        Start-Sleep -Seconds 60 
        InviaEmail -email_destinatario $email_destinatario -comune $comune -oggetto_email $oggetto_email -corpo_email $corpo_email
    }
}

# Path di Cygwin
$cygwinPath = "C:\cygwin64" 
$cygwinExe = "$cygwinPath\bin\bash.exe"
$file_errore = "/tmp/errore.txt"
$file_output = "/tmp/log.txt"
$script_output = "$cygwinPath/tmp/script.txt"

#Inizializzo log dello script
$null | Out-File -FilePath $script_output

# Inserimento dei dati
$email_destinatario, $comune, $comando, $email_copia = InserisciDati


# Credenziali per l'invio di e-mail
$EmailFrom = "MA_rsync_notify@outlook.com"
$Password = ConvertTo-SecureString "R0cky2022!" -AsPlainText -Force
$Credential = New-Object System.Management.Automation.PSCredential($EmailFrom, $Password)

$comando_completo = "$comando > >(tee $file_output) 2> >(tee $file_errore >&2)"

Write-Host "Sto per iniziare l'rsync..." -ForegroundColor Green
"Sto per iniziare l'rsync..." | Out-File -FilePath "$script_output" -Append
Write-Host "3"
Start-Sleep -Seconds 1
Write-Host "2"
Start-Sleep -Seconds 1
Write-Host "1"
Start-Sleep -Seconds 1

# Avvia il processo e attendi che sia terminato fino a 5 volte in caso di errore
$retryCount = 1
do {
    Start-Process -FilePath $cygwinExe -ArgumentList "-l", "-i", "-c", "`"$comando_completo`"" -Wait -NoNewWindow
   
    if (Select-String -Path "$cygwinPath$file_errore" -Pattern "Warning: Permanently added") {
        $numero_righe=(Get-Content $cygwinPath$file_errore).Count
        if ($numero_righe -eq 1) {
            # Cancella tutto il contenuto del file se il numero di righe e' 1 e l'errore è solo il warning ssh
            Clear-Content $cygwinPath$file_errore
        }
    }
    # Leggi l'esito dal file
    $stato_uscita = Get-Content -Path "$cygwinPath$file_errore"
    # Controlla lo stato di uscita del comando
    if ($null -eq $stato_uscita) {
        Write-Host "Rsync della cartella completato con successo." -ForegroundColor Green
        "Rsync della cartella completato con successo." | Out-File -FilePath "$script_output" -Append
        $oggetto_email = "RSYNC TERMINATO CON SUCCESSO"
        $corpo_email = "Ti comunico che l'rsync del repository, avviato per il comune di $comune, e' stato completato con successo! Se desideri visualizzare il log, lo trovi al percorso '$cygwinPath\tmp\log.txt'."
        # Invia un'email di notifica di successo
        InviaEmail -email_destinatario $email_destinatario -comune $comune -oggetto_email $oggetto_email -corpo_email $corpo_email
        break
    } else {
        Write-Host "Rsync della cartella interrotto con errore. Stato uscita: $stato_uscita . Tentativo n $retryCount" -ForegroundColor Red
        "Rsync della cartella interrotto con errore. Stato uscita: $stato_uscita . Tentativo n $retryCount" | Out-File -FilePath "$script_output" -Append
         $retryCount++
        if ($retryCount -ge 5) {
            Write-Host "Numero massimo di tentativi raggiunto. Interrompo il processo." -ForegroundColor Red
            "Numero massimo di tentativi raggiunto. Interrompo il processo." | Out-File -FilePath "$script_output" -Append
            InviaEmail -email_destinatario $email_destinatario -comune $comune -oggetto_email $oggetto_email -corpo_email $corpo_email
            break
        } else {
            $ip = "8.8.8.8"
            if (!(Test-Connection -ComputerName $ip -Count 1 -Quiet)) {
                Write-Host "Connessione tra le due macchine interrotta! Attendo 60 secondi e riprovo..." -ForegroundColor Red
                "Connessione tra le due macchine interrotta! Attendo 60 secondi e riprovo..." | Out-File -FilePath "$script_output" -Append
                $riconn = 1
                #Attende fino a 15 minuti poi ferma lo script
                while ($riconn -le 30) {
                    Start-Sleep -Seconds 30
                    Write-Host "Tentativo di riconnessione: $riconn" -ForegroundColor Yellow
                    "Tentativo di riconnessione: $riconn" | Out-File -FilePath "$script_output" -Append
                    if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
                        Write-Host "Connessione ristabilita." -ForegroundColor Green
                        "Connessione ristabilita." | Out-File -FilePath "$script_output" -Append
                        break
                    }
                    $riconn++
                }
                if ($riconn -gt 30) {
                    Write-Host "Tentativi di riconnessione esauriti. Fermo lo script." -ForegroundColor Red
                    "Tentativi di riconnessione esauriti. Fermo lo script." | Out-File -FilePath "$script_output" -Append
                    $oggetto_email = "RSYNC INTERROTTO PER DISCONNESSIONE"
                    $corpo_email = "Ti comunico che l'rsync del repository, avviato per il comune di $comune , si è interrotto a causa di una disconnessione. Ho fatto 30 tentativi di riconnessione ma senza successo. Troverai il riepilogo completo ($outputFile) e l'output dello script ($logFile) nella cartella dove hai eseguito il comando. Questo invece è il riepilogo degli errori: `n$errore"
                    InviaEmail -email_destinatario $email_destinatario -comune $comune -oggetto_email $oggetto_email -corpo_email $corpo_email
                    break
                }
            }
            Write-Host "Riprovo il processo. Tentativo n $($retryCount)" -ForegroundColor Yellow
            "Riprovo il processo. Tentativo n $($retryCount)" | Out-File -FilePath "$script_output" -Append
        }
    }
} while ($true)
