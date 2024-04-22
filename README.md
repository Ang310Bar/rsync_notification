INTRODUZIONE

Entrambi gli script notificano con una mail (che inserite dopo averlo avviato) della fine dell'rsync. Entrambi hanno bisogno di privilegi di amministratore per poter funzionare quindi per OS WINDOWS è necessario avviare la PowerShell come amministratore.

IMPORTANTE PER SCRIPT WINDOWS

Prima di lanciare lo script assicurarsi che il Path di installazione di Cygwin sia C:\cygwin64, nel caso fosse diverso, va inserito il path corretto nella riga 73 dello script (inseriscilo senza \ finale). Quando viene chiesto di digitare il comando evitare l'uso di doppi apici ("") ed utilizzare i singoli apici ('').
Consiglio di verificate la presenza del cmdlet Send-MailMessage digitando dalla PowerShell:

Get-Command Send-MailMessage -ErrorAction SilentlyContinue

Se Send-MailMessage è disponibile, vedrai i dettagli del cmdlet stampati nella console. Se non è disponibile, non verrà visualizzato nulla.
# rsync_notification
