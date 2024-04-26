$separatore = "`n#####################################################################`n"
# Ottieni il percorso della cartella corrente in cui viene eseguito lo script
$cartellaCorrente = Get-Location
# Definisci il percorso completo per il file report
$reportFile = Join-Path -Path $cartellaCorrente -ChildPath "report.txt"
# Crea il file report
New-Item -Path $reportFile -ItemType File -Force > $null
Write-Host "File del report creato nella cartella dello script." -ForegroundColor Green
$dataAttuale = (Get-Date).ToString("dd/MM/yyyy")
"-_-_-_-_-_-_-_-_-_-_ REPORT DEL $dataAttuale -_-_-_-_-_-_-_-_-_-_`n" | Out-File -FilePath "$reportFile" -Append
$separatore | Out-File -FilePath "$reportFile" -Append
$hostname = HOSTNAME.EXE
"Hostname: $hostname" | Out-File -FilePath "$reportFile" -Append
$separatore | Out-File -FilePath "$reportFile" -Append

$publicIp = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
"IP Pubblico: $publicIp" | Out-File -FilePath "$reportFile" -Append
$separatore | Out-File -FilePath "$reportFile" -Append

# Ottieni tutti i dischi presenti nel sistema
$dischi = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DriveType -eq 3 } | Select-Object -ExpandProperty DeviceID
"I DISCHI SONO: $dischi" | Out-File -FilePath "$reportFile" -Append
$separatore | Out-File -FilePath "$reportFile" -Append

Write-Host "Cerco la cartella Maggioli nei dischi. Questa operazione potrebbe richiedere qualche secondo."
# Itera su ciascun disco
foreach ($disco in $dischi) {
    $maggioliPath = Get-ChildItem -Path "$disco\" -Recurse -Depth 4 -Directory -Filter '*maggioli*' -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*\maggioli" -or $_.FullName -like "*\Maggioli" } | Select-Object -ExpandProperty FullName -First 1
    
    if ($maggioliPath) {
        Write-Host "Path della cartella Maggioli trovato!" -ForegroundColor Green
        break
    }
}
if($maggioliPath){
    Write-Host "Cerco la cartella repository."
    $repositoryPath = Get-ChildItem -Path "$maggioliPath\" -Recurse -Directory -Filter '*repository*' -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*\repository" -or $_.FullName -like "*\Repository" } | Select-Object -ExpandProperty FullName -First 1
    $wildflyPath = Get-ChildItem -Path "$maggioliPath\" -Recurse -Directory -Filter '*wildfly_home*' -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*\wildfly_home" -or $_.FullName -like "*\Wildfly_home" } | Select-Object -ExpandProperty FullName -First 1
    $javaPath = Get-ChildItem -Path "$maggioliPath\" -Recurse -Directory -Filter '*java*' -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*\java" -or $_.FullName -like "*\Java" } | Select-Object -ExpandProperty FullName -First 1
    $cacertsPath = Get-ChildItem -Path "$javaPath\" -Recurse -Directory -Filter '*security*' -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*\lib\security" } | Select-Object -ExpandProperty FullName -First 1
    $dataPath = Get-ChildItem -Path "$maggioliPath\" -Recurse -Directory '*data*' | Where-Object { $_.FullName -like "*\geoserver\data" } | Select-Object -ExpandProperty FullName -First 1
}
else{
    Write-Host "PATH DELLA CARTELLA MAGGIOLI NON TROVATO." -ForegroundColor Red
    Write-Host "Cerco direttamente le cartelle necessarie."
    foreach ($disco in $dischi) {
        $repositoryPath = Get-ChildItem -Path "$disco\" -Directory -Filter '*repository*' -ErrorAction SilentlyContinue -Recurse -Depth 1 | Where-Object { $_.FullName -like "*\repository" -or $_.FullName -like "*\Repository" } | Select-Object -ExpandProperty FullName -First 1
        if ($repositoryPath) {
            $wildflyPath = Get-ChildItem -Path "$disco\" -Recurse -Depth 3 -Directory -Filter '*wildfly_home*' -ErrorAction SilentlyContinue  | Where-Object { $_.FullName -like "*\wildfly_home" -or $_.FullName -like "*\Wildfly_home" } | Select-Object -ExpandProperty FullName -First 1
            $javaPath = Get-ChildItem -Path "$disco\" -Recurse -Depth 3 -Directory -Filter '*java*' -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*\java" -or $_.FullName -like "*\Java" } | Select-Object -ExpandProperty FullName -First 1
            $cacertsPath = Get-ChildItem -Path "$javaPath\" -Recurse -Directory -Filter '*security*' -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*\lib\security" } | Select-Object -ExpandProperty FullName -First 1
            $dataPath = Get-ChildItem -Path "$disco\" -Recurse -Depth 6 -Directory -Filter '*data*' | Where-Object { $_.FullName -like "*\geoserver\data" } | Select-Object -ExpandProperty FullName -First 1
            break
        }
    }
}
if(-not $repositoryPath){
    $risposta = Read-Host "Non sono stato in grado di trovare la cartella 'repository', vuoi aggiungere tu il path? (s/n)"
    while ($risposta -eq "s") {
        $repositoryPath = Read-Host "Inserisci qui il path"
        if (Test-Path $repositoryPath) {
            break
        }
        $risposta = Read-Host "Il path inserito non è corretto, vuoi riprovare? (s/n)"
    }
    if (-not (Test-Path $repositoryPath)) {
        Write-Host "PATH DELLA CARTELLA REPOSITORY NON TROVATO. SCRIPT TERMINATO." -ForegroundColor Red
        "PATH REPOSITORY NON TROVATO" | Out-File -FilePath "$reportFile" -Append
        $separatore | Out-File -FilePath "$reportFile" -Append
        exit 1
    }

}
"PATH DELLA CARTELLA REPOSITORY: $repositoryPath" | Out-File -FilePath "$reportFile" -Append
$contenutoRepository = Get-ChildItem -Path "$repositoryPath" -Directory | Select-Object -ExpandProperty Name
"CONTENUTO:`n   $contenutoRepository" | Out-File -FilePath "$reportFile" -Append
$separatore | Out-File -FilePath "$reportFile" -Append
if(-not $wildflyPath){
    $risposta = Read-Host "Non sono stato in grado di trovare la cartella 'wildfly_home', vuoi aggiungere tu il path? (s/n)"
    while ($risposta -eq "s") {
        $wildflyPath = Read-Host "Inserisci qui il path"
        if (Test-Path $wildflyPath) {
            break
        }
        $risposta = Read-Host "Il path inserito non è corretto, vuoi riprovare? (s/n)"
    }
    if (-not (Test-Path $wildflyPath)) {
        Write-Host "PATH WILDFLY_HOME NON TROVATO. SCRIPT TERMINATO." -ForegroundColor Red
        "PATH WILDFLY_HOME NON TROVATO" | Out-File -FilePath "$reportFile" -Append
        $separatore | Out-File -FilePath "$reportFile" -Append
        exit 1
    }

}
"PATH DELLA CARTELLA wildfly_home: $wildflyPath" | Out-File -FilePath "$reportFile" -Append
$separatore | Out-File -FilePath "$reportFile" -Append
if(-not $javaPath){
    $risposta = Read-Host "Non sono stato in grado di trovare la cartella 'Java', vuoi aggiungere tu il path? (s/n)"
    while ($risposta -eq "s") {
        $javaPath = Read-Host "Inserisci qui il path"
        if (Test-Path $javaPath) {
            $cacertsPath = Get-ChildItem -Path "$javaPath\" -Recurse -File -Filter '*security*' -ErrorAction SilentlyContinue | Where-Object { $_.FullName -like "*\lib\security" } | Select-Object -ExpandProperty FullName
            break
        }
        $risposta = Read-Host "Il path inserito non è corretto, vuoi riprovare? (s/n)"
    }
    if (-not (Test-Path $javaPath)) {
        Write-Host "PATH JAVA NON TROVATO. SCRIPT TERMINATO." -ForegroundColor Red
        "PATH JAVA NON TROVATO" | Out-File -FilePath "$reportFile" -Append
        $separatore | Out-File -FilePath "$reportFile" -Append
        exit 1
    }
}
Write-Host "Tutti i path necessari sono stati trovati." -ForegroundColor Green
"PATH DELLA CARTELLA Java: $javaPath" | Out-File -FilePath "$reportFile" -Append
$separatore | Out-File -FilePath "$reportFile" -Append
Write-Host "Creo la cartella di appoggio."

# Crea la cartella "appoggio" all'interno del percorso della cartella repository
$cartellaAppoggio = Join-Path -Path $repositoryPath -ChildPath "appoggio"
New-Item -Path $cartellaAppoggio -ItemType Directory -Force > $null

if (Test-Path $cartellaAppoggio) {
    Write-Host "La cartella 'appoggio' e' stata creata correttamente." -ForegroundColor Green
    "PATH CARTELLA DI APPOGGIO: $cartellaAppoggio" | Out-File -FilePath "$reportFile" -Append
    $separatore | Out-File -FilePath "$reportFile" -Append

} else {
    Write-Host "Si è verificato un errore durante la creazione della cartella 'appoggio'." -ForegroundColor Red
    "Si è verificato un errore durante la creazione della cartella 'appoggio' in $repositoryPath." | Out-File -FilePath "$reportFile" -Append
    $separatore | Out-File -FilePath "$reportFile" -Append
    exit 1
}
Write-Host "Eseguo la copia dei dati."
try {
    Copy-Item -Path "$wildflyPath/standalone/configuration/standalone-full.xml" -Destination $cartellaAppoggio -Force
    Copy-Item -Path "$wildflyPath/standalone/deploy/sicraweb.ear/server/signed-jars/conf.ig/sicraweb.server.config.xml" -Destination $cartellaAppoggio -Force
    Copy-Item -Path "$wildflyPath/standalone/deploy/sicraweb.ear/server/signed-jars/conf.ig/security_1" -Destination $cartellaAppoggio -Force
    Copy-Item -Path "$wildflyPath/standalone/deploy/sicraweb.ear/server/signed-jars/conf.ig/security_2" -Destination $cartellaAppoggio -Force
    Copy-Item -Path "$cacertsPath/cacerts" -Destination $cartellaAppoggio -Force
    Write-Host "5 file correttamente copiati nella cartella di appoggio" -ForegroundColor Green
    "SONO STATI COPIATI I SEGUENTI FILE:`n   standalone-full.xml`n   sicraweb.server.config.xml`n   security_1`n   security_2`n   cacerts" | Out-File -FilePath "$reportFile" -Append
    $separatore | Out-File -FilePath "$reportFile" -Append
}
catch {
    Write-Host "Errore durante la copia" -ForegroundColor Red
    "ERRORE DURANTE LA COPIA DEI FILE" | Out-File -FilePath "$reportFile" -Append
    $separatore | Out-File -FilePath "$reportFile" -Append
}
Write-Host "Verifico la presenza del Geoserver"

# Verifica se la cartella "geoserver" esiste
if (Test-Path $dataPath) {   
    $dataFiles = Get-ChildItem -Path $dataPath
    if ($dataFiles.Count -gt 0) {
        "GEOSERVER: SI" | Out-File -FilePath "$reportFile" -Append 
        $separatore | Out-File -FilePath "$reportFile" -Append
        Write-Host "Presente: SI" -ForegroundColor Yellow
    } else {
        "GEOSERVER: NO" | Out-File -FilePath "$reportFile" -Append
        $separatore | Out-File -FilePath "$reportFile" -Append
        Write-Host "Presente: NO" -ForegroundColor Yellow
    }   
} 
else {
    Write-Host "Presente: NO" -ForegroundColor Yellow
    "GEOSERVER: NO" | Out-File -FilePath "$reportFile" -Append
    $separatore | Out-File -FilePath "$reportFile" -Append
}
Write-Host "Verifico la presenza del VAADIN"

#verifica del VAADIN
$fileVaadin = "$wildflyPath/standalone/deploy/sicraweb-vaadin.war/WEB-INF/portal.properties"
if (Test-Path $fileVaadin -PathType Leaf) {
    "VAADIN: SI`nFILE COPIATO IN APPOGGIO" | Out-File -FilePath "$reportFile" -Append
    $separatore | Out-File -FilePath "$reportFile" -Append
    Copy-Item -Path $fileVaadin -Destination $cartellaAppoggio -Force
    Write-Host "Presente: SI (Copiato il file nella cartella di appoggio)" -ForegroundColor Yellow

} else {
    "VAADIN: NO" | Out-File -FilePath "$reportFile" -Append
    $separatore | Out-File -FilePath "$reportFile" -Append
    Write-Host "Presente: NO" -ForegroundColor Yellow
}
Write-Host "Cerco gli alias dei ws."
# Leggi il contenuto del file XML
$confXml = Get-Content -Path "$wildflyPath/standalone/deploy/sicraweb.ear/server/signed-jars/conf.ig/sicraweb.server.config.xml"
$alias = $confXml | Where-Object { $_ -match 'alias' }
$nomiWs = $alias | Select-String -Pattern ' name="([^"]+)"' | ForEach-Object { $_.Matches.Groups[1].Value }
$nomiWsOrdinati = $nomiWs | Sort-Object
# Aggiungi i valori al file di report
"ALIAS PER I WS:" | Out-File -FilePath $reportFile -Append
foreach ($nome in $nomiWsOrdinati) {
    "   $nome" | Out-File -FilePath $reportFile -Append
}
$separatore | Out-File -FilePath "$reportFile" -Append
Write-Host "HO TRASCRITTO I NOMI DEGLI ALIAS." -ForegroundColor Green
Write-Host " "
Write-Host "OPERAZIONI TERMINATE" -ForegroundColor Green