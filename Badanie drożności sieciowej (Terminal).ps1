#UWAGA!!
#Skrypt działa najlepiej na wersji Powershell 7
#__________________________________________________________________________________________________________________________________________________

# zmienne
# lista zawierająca wyniki wszystkich wykonanych przez użytkownika operacji
$lista = New-Object -Typename "System.Collections.ArrayList"

# słownik zawierający paczki adresów IP/nazw
$ips = New-Object System.Collections.Specialized.OrderedDictionary
$ips.Add('paczkawindowsdefenderazuread',@('eu-v20.events.data.microsoft.com','winatp-gw-neu.microsoft.com','winatp-gw-weu.microsoft.com','winatp-gw-neu3.microsoft.com','winatp-gw-weu3.microsoft.com'))
$ips.Add('paczkakontrolerydomeny',@('ad1','ad2','ad3'))

# Wygląd MENU ---------------------------------------------------

# Menu główne
function Main-Menu {
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host "=== MENU ===" -ForegroundColor cyan
    Write-Host "1. Sprawdzanie portu lokalnie"
    Write-Host "2. Sprawdzanie portu zdalnie"
    Write-Host "3. Lista aktywnych połączeń"
    Write-Host "4. Pomoc"
    Write-Host ""
    Write-Host "0. Zakończ"
    Write-Host ""
}

# Podmenu dla opcji 1 lub 2 w menu głównym (sprawdzenie lokalne/ zdalne)
function Sub-Menu-1 {
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host "=== Wybierz port ===" -ForegroundColor cyan
    Write-Host "1.  Active Directory Web Service/Active Directory Management Gateway Service (9389)"
    Write-Host "2.  Global Catalog (3268, 3269)"
    Write-Host "3.  NetBIOS Session Service (139)"
    Write-Host "4.  RPC (135)"
    Write-Host "5.  SMB (445)"
    Write-Host "6.  Kerberos (88)"
    Write-Host "7.  DNS (53)"
    Write-Host "8.  LDAP (389)"
    Write-Host "9.  Telnet (23)"
    Write-Host "10. PPTP (1723)"
    Write-Host "11. HTTP (80)"
    Write-Host "12. HTTPS (443)"
    Write-Host "13. Paczka 'AD DC Ports'"
    Write-Host "14. Paczka 'AD DC Communication Ports'"
    Write-Host "15. Paczka 'DFSN'"
    Write-Host "16. Paczka 'AD Authentication Ports'"
    Write-Host "17. Paczka Linux"
    Write-Host "18. Inny"
    Write-Host ""
    Write-Host "0.  Wróć"
    Write-Host ""
}

# Podmenu dla opcji Inny w Sub-Menu-1
function Sub-Menu-2 {
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host "=== Wybór portów ===" -ForegroundColor cyan
    Write-Host "1. Wprowadź port/porty"
    Write-Host "2. Zakres portów"
    Write-Host "3. Na podstawie wzorca (np. 12*3)"
    Write-Host ""
    Write-Host "0. Wróć"
    Write-Host ""
}

# Pomoc
function Help-Option {

    Write-Host ""
    Write-Host "Sprawdzanie portu lokalnie: " -ForegroundColor green
    Write-Host "Umożliwia sprawdzenie wybran-ego/-ych port-u/-ów lokalnie"
    Write-Host ""
    Write-Host "Sprawdzanie portu zdalnie:" -ForegroundColor green 
    Write-Host "Umożliwia sprawdzenie wybran-ego/-ych port-u/-ów zdalnie, po wybraniu należy podać nazwę DNS, adres ip lub nazwę paczki adresów. Można również wprowadzić wzór np. 123.123.12*.1**, wówczas zostaną sprawdzone wszystkie adresy podstawiając w miejsce * cyfry 0-9"
    Write-Host ""
    Write-Host "Lista aktwnych połączeń:" -ForegroundColor green
    Write-Host "Umożliwia sprawdzenie wszystkich aktywnych połączeń"
    Write-Host ""
    Write-Host "Wprowadź port/porty:" -ForegroundColor green 
    Write-Host "Pozwala na wprowadzenie dowolnej liczby portów. Porty powinny być oddzielone od siebie przecinkami np. 53,80,88"
    Write-Host ""
    Write-Host "Zakres portów:"-ForegroundColor green 
    Write-Host "Pozwala na wprowadzenie dowolnego zakresu dla portów w postaci np. 80-88"
    Write-Host ""
    Write-Host "Na podstawie wzorca (np. 12*3):"-ForegroundColor green
    Write-Host "Pozwala na wprowadzenie wzoru na port w postaci 12*3. Następnie * jest zastępowana cyframi od 0 do 9."
    Write-Host ""
    Write-Host "Paczki portów:" -ForegroundColor green
    Write-Host "    Paczka 'AD DC Ports' - zawiera następujące porty:"-ForegroundColor yellow
    Write-Host "       • 53 (DNS)`n       • 88 (Kerberos)`n       • 135 (RPC)`n       • 139 (NetBIOS Session Service)`n       • 389 (DC Locator, LDAP)`n       • 445 (SMB)`n       • 464 (Kerberos Password V5)`n       • 636 (LDAP SSL)`n       • 3268 (Global Catalog)`n       • 3269 (Global Catalog)`n"
    Write-Host ""
    Write-Host "    Paczka 'AD DC Communication Ports' - zawiera następujące porty:"-ForegroundColor yellow
    Write-Host "       • 135 (RPC)`n       • 137 (NetBIOS Name Service)`n       • 139 (NetBIOS Session Service)`n       • 389 (LDAP)`n       • 636 (LDAP SSL)`n       • 445 (SMB)`n       • 1512 (WINS Resolution)`n       • 42 (WINS Replication)`n"
    Write-Host ""
    Write-Host "    Paczka 'DFSM' - zawiera następujące porty:"-ForegroundColor yellow
    Write-Host "       • 139 (NetBIOS Session Service)`n       • 389 (LDAP Server)`n       • 445 (SMB)`n       • 135 (RPC)`n"
    Write-Host ""
    Write-Host "    Paczka 'AD Authentication Ports' - zawiera następujące porty:"-ForegroundColor yellow
    Write-Host "       • 389 (LDAP)`n       • 53 (DNS)`n       • 88 (Kerberos)`n       • 445 (SMB)`n"
    Write-Host ""
    Write-Host "    Paczka Linux - zawiera następujące porty:"-ForegroundColor yellow
    Write-Host "       • 22 (SSH)`n       • 80 (HTTP)`n       • 443 (HTTPS)`n       • 25 (SMTP)`n       • 53 (DNS)`n       • 21 (FTP)`n       • 3306 (MySQL)`n       • 5432 (PostgreSQL)`n       • 6379 (Redis)`n       • 27017 (MongoDB)`n"
    Write-Host ""
    Write-Host "Paczki adresów/nazw:" -ForegroundColor green
    Write-Host "    Paczka Windows Defender Azure AD - zawiera następujące adresy:"-ForegroundColor yellow
    Write-Host "       • eu-v20.events.data.microsoft.com`n       • winatp-gw-neu.microsoft.com`n       • winatp-gw-weu.microsoft.com`n       • winatp-gw-neu3.microsoft.com`n       • winatp-gw-weu3.microsoft.com"
    Write-Host ""
    Write-Host "    Paczka Kontrolery Domeny - zawiera następujące adresy:"-ForegroundColor yellow
    Write-Host "       • ad1`n       • ad2`n       • ad3"
    Write-Host ""    
    pause
}


# funkcjonalość -------------------------------------------------------------

function Option1 {
    param (
        [int] $port,
        [string] $computer_name
    )
    <#
    Funkcja generująca wynik procedury Test-NetConnection w formie tekstowej. Wynik wyświetlany jest na ekranie i zapisywany do listy.

    Paramtery:
        [int] $port - numer badanego portu 
        [string] $computer_name - nazwa/adres IP 
    #>
    Write-Host ""
    Write-Host "Sprawdzanie portu" $port -ForegroundColor darkyellow
    $text = ""
    $text += ">> Sprawdzenie portu $port <<" + [Environment]::NewLine
    $output = Test-NetConnection -ComputerName $computer_name -Port $port -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    $text += ("ComputerName = "+$output.ComputerName.ToString() + [Environment]::NewLine)
    $text += ("RemoteAddress = "+$output.RemoteAddress.ToString() + [Environment]::NewLine)
    $text += ("RemotePort = "+$output.RemotePort.ToString() + [Environment]::NewLine)
    $text += ("InterfaceAlias = "+$output.InterfaceAlias.ToString() + [Environment]::NewLine)
    $text += ("SourceAddress = "+$output.SourceAddress.ToString() + [Environment]::NewLine)
    $text += "TcpTestSucceeded = "+$output.TcpTestSucceeded.ToString() + [Environment]::NewLine
    $text += [Environment]::NewLine

    $lista.Add($text) | Out-Null
    $output
}


function Option3 {
    <#
    Funkcja generująca wynik procedury netstat -an (listę wszystkich aktywnych połączeń). Wynik wyświetlany jest na ekranie i zapisywany do listy.
    #>
    $output = & netstat -an | Sort-Object
    $outputString = $output | Select-Object -Skip 1 | Select-Object -SkipLast 1 | Out-String # pominięcie pierwszego i ostatniego weirsza
    $outputString += [Environment]::NewLine
    $outputString

    $lista.Add("Lista aktywnych połączeń:" +[Environment]::NewLine) | Out-Null
    $lista.Add($outputString) | Out-Null
}


function Generuj-Porty{
    param(
        [string]$port, 
        [int]$pozycja
    ) 
    <#
    Funkcja generująca porty na podstawie zadanego przez użytkownika wzorca (np. 12*). W miejsce '*' podstawiane są kolejne cyfry od 0 do 9.

    Parametry:
        [string] $port - "wzór" na port
        [int] $pozycja - aktualna pozycja, przy wywołaniu wstawiamy 0
    #>

    $wyniki = @() #lista wszystkich wygenerowanych portów

    # sprawdzenie czy długość wygenerowanego portu i wzorca jest taka sama, jeśli nie sprawdzane są loejne znaki i w miejsce '*' wstawiane cyfry
    if ($pozycja -ge $port.Length) {
            $wyniki += $port
    }
    elseif ($port[$pozycja] -eq '*') {
        for ($cyfra = 0; $cyfra -le 9; $cyfra++) {
            $nowyPort = $port.Substring(0, $pozycja) + $cyfra.ToString() + $port.Substring($pozycja + 1)
            Generuj-Porty $nowyPort ($pozycja + 1)
        }
    }
    else {
        $wyniki += Generuj-Porty $port ($pozycja + 1)
    }
    return $wyniki
}


function Generuj-IP{
    param(
        [string]$ip, 
        [int]$pozycja
    )
    <#
    Funkcja generująca IP na podstawie zadanego przez użytkownika wzorca (np. 123.123.123.12*). W miejsce '*' podstawiane są kolejne cyfry od 0 do 9.

    Parametry:
        [string] $port - "wzór" na IP
        [int] $pozycja - aktualna pozycja, przy wywołaniu wstawiamy 0
    #>

    $wyniki = @() #lista wszystkich wygenerowanych IP

    if ($pozycja -ge $ip.Length){
            $wyniki += $ip
    }
    elseif ($ip[$pozycja] -eq '*'){
        for($cyfra = 0; $cyfra -lt 10; $cyfra++){
            $noweIp = $ip.Substring(0,$pozycja) + $cyfra.ToString() + $ip.Substring($pozycja + 1)
            Generuj-IP $noweIp ($pozycja + 1)
        }
    }
    else{
        $wyniki += Generuj-IP $ip ($pozycja + 1)
    }
    return $wyniki
}


# Wyświetlanie Menu -----------------------------------------------------------

# główna pętla programu pozwalająca na wybór opcji z Menu głównego
function Show-Main-Menu{

    $choice = -1
    while($choice -ne 0){ # Wyświetlane dopóki użytkownik nie wybierze 0

        Clear-Host
        Main-Menu # Wyświetlenie Menu głównego

        $choice = Read-Host "Wybierz opcję (0-4)"

        switch ($choice) {
            "1" {Show-Menu2}    # Sprawdzenie lokalne
            "2" {Show-Menu3}    # Sprawdzenie zdalne
            "3" {Option3        # Wszystkie aktywne połączenia
                 pause}
            "4" {Help-Option}   # Pomoc
            "0" {Write-Host ""} # Wyjście
            default{Write-Host "Nieprawidłowy wybór. Wybierz ponownie." -ForegroundColor red
                    pause}
        }}
    
    # Zapisanie wyniku działania programu do plik na pulpice o nazwie plik_wynikowy, każde otwarcie programu oddzielone jest datą i godziną wykonywania operacji
    if ($choice -eq 0) {
        # nagłówek z datą i godziną
        $data = Get-Date -Format "dd/MM/yyyy  HH:mm " 
        $data_3 = "-------------------------------------------" + [Environment]::NewLine
        $data_2 = $data_3 + $data.ToString() + [Environment]::NewLine + $data_3

        # ścieżka do pliku z wynikami
        $desktopPath = [Environment]::GetFolderPath("Desktop")
        $path = Join-Path $desktopPath "plik_wynikowy.txt"


        Write-Host ""
        Write-Host "Plik wynikowy zapisano na pulpicie." -ForegroundColor green
        Write-Host "Do widzenia!"
        # wczytanie zawartości pliku jeżeli istnieje
        if (Test-Path $path) {
            $content = (Get-Content -Path $path -Raw) }
        } 
        # zapisanie (nagłówka + zawartości listy + wczytanej zawartości) do pliku
        $data_2 + $lista + $content | Set-Content -Path $path
}




# funkcja dla opcji "Sprawdzanie portu lokalnie" (1) oraz "Sprawdzanie portu zdalnie" (2), jeżeli użytkownik wprost podał adres IP (bez '*')
function Show-Menu2{
    param(
        [string] $comp_name = 'localhost'
    )
    <# 
    Parametr :  
        [string] $comp_name - adres IP/ nazwa, jeżeli nie zostanie podana to przyjmuje wartość localhost
    #>

    $choice2 = -1
    while($choice2 -ne 0){

        Clear-Host
        Sub-Menu-1 # Wyświetlenie pierwszego podmenu
        $choice2 = Read-Host "Wybierz opcję (0-18)"

        # Wywołanie funkcji Option 1
        switch ($choice2) {
            "1" {Option1 -computer_name $comp_name -port 9389 # AD WS/AD MGS
                 pause}
            "2" {Option1 -computer_name $comp_name -port 3268 # Global Catalog
                 Option1 -computer_name $comp_name -port 3269
                 pause}
            "3" {Option1 -computer_name $comp_name -port 139 # NetBIOS Session Service
                 pause}
            "4" {Option1 -computer_name $comp_name -port 135 # RPC
                 pause}
            "5" {Option1 -computer_name $comp_name -port 445 # SMB 
                 pause}
            "6" {Option1 -computer_name $comp_name -port 88 # Kerberos
                 pause}
            "7" {Option1 -computer_name $comp_name -port 53 # DNS
                 pause}
            "8" {Option1 -computer_name $comp_name -port 389 # LDAP
                 pause}
            "9" {Option1 -computer_name $comp_name -port 23 # Telnet
                 pause}
            "10" {Option1 -computer_name $comp_name -port 1723 # PPTP
                 pause}
            "11" {Option1 -computer_name $comp_name -port 80 # HTTP
                 pause}
            "12" {Option1 -computer_name $comp_name -port 443 # HTTPS
                 pause}
            "13" {$paczka1 = @(53,88,135,139,389,445,464,636,3268,3269) # Paczka 'AD DC Ports'        
                 foreach ($port in $paczka1){
                    Option1 -computer_name $comp_name -port $port
                       }
                 pause}
            "14" {$paczka2 = @(135,137,139,389,636,445,1512,42) # Paczka 'AD DC Communication Ports'        
                 foreach ($port in $paczka2){
                    Option1 -computer_name $comp_name -port $port
                       }
                 pause}
            "15" {$paczka3 = @(139,389,445,135) # Paczka 'DFSN'          
                 foreach ($port in $paczka3){
                    Option1 -computer_name $comp_name -port $port
                       }
                 pause}
            "16" {$paczka4 = @(389,53,88,445) # Paczka 'AD Authentication Ports'         
                 foreach ($port in $paczka4){
                    Option1 -computer_name $comp_name -port $port
                       }
                 pause}
            "17" {$paczka5 = @(22,80,443,25,53,21,3306,5432,6379,27017) # Paczka Linux
                 foreach ($port in $paczka5){
                    Option1 -computer_name $comp_name -port $port
                       }
                 pause}
            "18" {Show-Menu4 -computer_name $comp_name} # Opcja Inny
            "0" {break} # Powrót
            default { Write-Host "Nieprawidłowy wybór. Wybierz ponownie." -ForegroundColor red 
                      pause}
                      
    }
}
}

# funkcja dla opcji "Sprawdzanie portu zdalnie" (2) do wprowadzenia ip/nazwy
function Show-Menu3{
    Clear-Host
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host ""
    Write-Host "Dostępne paczki: Paczka Windows Defender Azure AD, Paczka Kontrolery Domeny" -ForegroundColor yellow
    Write-Host ""
    $c_name = Read-Host "Podaj nazwę/adres IP/paczkę "

    $c_name = $c_name.Replace(" ", "") # usunięcie spacji z nazwy

    if([String]::IsNullOrWhiteSpace($c_name)){ # jeżeli użytkownik nic nie wprowadzi to do $c_name zostanie przypisany localhost
        $c_name= "localhost"
        }
    
    if(($c_name.ToLower()).Contains('paczka')){ # wybór paczki
        $ip_name_list = $ips[$c_name.ToLower()] # ip/nazwy w wybranej paczce
        
        Show-Menu5 -ip_list $ip_name_list # menu z wyborem portu
    }       
    elseif($c_name.Contains('*')){ # użytkownik wprowadził wzorzec
        $pom = $false
        $parted = $c_name.Split('.')

        foreach($part in $parted){ # sprawdzenie czy między kropkami są maksymalnie 3 znaki, jeśli nie ponownie prosimy o adres
            if($part.Length -gt 3){
                $pom = $true
                break
            }
        }

        while($pom -eq $true){
        $pom = $false

        $c_name = Read-Host "Podaj nazwę lub adres IP "
        $parted = $c_name.Split('.')

        foreach($part in $parted){
            if($part.Length -gt 3){
                $pom = $true
                break
                }
            }
        }

        $ip_name_list = Generuj-IP $c_name 0 # jeżli wzorzec wprowadzono poprawnie generujemy listę IP
        Show-Menu5 -ip_list $ip_name_list # pokazujemy menu z wyborem portów dla kilku nazw/IP
        
    }
    elseif($c_name.Contains(',')){ # użytkownik wprowadził kilka nazw/IP
        $ip_name_list = $c_name.Split(',') # rozdzielamy nazwy/IP
        Show-Menu5 -ip_list $ip_name_list # pokazujemy menu z wyborem portów dla kilku nazw/IP
    }
    else{
        Show-Menu2 -comp_name $c_name # pokazujemy menu z portami dla jednej nazwy/IP
    }
}

# funkcja dla opcji "Inny" w Sub-Menu-1
function Show-Menu4{
    param(
        [string] $computer_name = 'localhost'
    )
    <#
    Funkcja umożliwia wybór wpisania kilku portów, podania zakresu portów lub wzorca 
    Parametr :  
        [string] $comp_name - adres IP/ nazwa, jeżeli nie zostanie podana to przyjmuje wartość localhost
    #>

    $choice3 = -1
    while($choice3 -ne 0){

    Clear-Host
    Sub-Menu-2 # Wyświetlenie podmenu

    $choice3 = Read-Host "Wybierz opcję (0-3)"

    switch ($choice3) {
        "1" {$ports = Read-Host "Wpisz porty "  # Jeden port lub lista portów

             $ports = $ports.Split(',') # rozdzielenie
             $portList = New-Object -Typename "System.Collections.ArrayList"
             $portList.AddRange($ports) # wpisanie portów do listy

             # wykonanie funkcji Option1 dla każdego portu
             foreach ($port in $portList){ 
                Option1 -computer_name $computer_name -port $port
             }

             pause}
        "2" {$ports = Read-Host "Podaj zakres portów " # Zakres portów

             $ports = $ports.Split('-') # rozdzielenie
             $portList = $ports[0]..$ports[1] # stworzenie listy na podstawie zakresu

             # wykonanie funkcji Option1 dla każdego portu
             foreach ($port in $portList){
                Option1 -computer_name $computer_name -port $port
             }
             pause}
        "3" {$ports = Read-Host "Podaj wzorzec " # Wzorzec

             $portList = Generuj-Porty -port $ports -pozycja 0 # generowanie portów

             # wykonanie funkcji Option1 dla każdego portu
             foreach($port in $portList){
                Option1 -computer_name $computer_name -port $port
             }
             pause}
        "0" {break} # Powrót
        default { Write-Host "Nieprawidłowy wybór. Wybierz ponownie." -ForegroundColor red
                  pause}
    }}
}

# funkcja dla opcji "Sprawdzanie portu zdalnie" (2), jeżeli użytkownik podał adres IP w postaci wzorca lub kilka nazw/IP po przecinku
function Show-Menu5{
    param(
        [array] $ip_list
    )
    <#
    Funkcja sprawdza dla każdej nazyw/IP wybrany port lub kilka portów z dostępnej listy
    Parametr :  
        [array] $ip_list - lista adresów IP/ nazw
    #>

    $choice4 = -1
    while($choice4 -ne 0){

    Clear-Host
    Sub-Menu-1 # Wyświtlenie podmenu z dostępnymi portami, paczkami

    $choice4 = Read-Host "Wybierz opcję (0-18)"
    

    switch ($choice4) {
            "1" {foreach($ip in $ip_list){
                    Write-Host "IP/Nazwa: $ip"
                    Option1 -computer_name $ip -port 9389 # AD WS/AD MGS
                 }
                 pause}
            "2" {foreach($ip in $ip_list){
                    Write-Host "IP/Nazwa: $ip"
                    Option1 -computer_name $ip -port 3268 # Global Catalog
                    Option1 -computer_name $ip -port 3269
                 }
                 pause}
            "3" {foreach($ip in $ip_list){
                    Write-Host "IP/Nazwa: $ip"
                    Option1 -computer_name $ip -port 139 # NetBIOS Session Service
                 }
                 pause}
            "4" {foreach($ip in $ip_list){
                    Write-Host "IP/Nazwa: $ip"
                    Option1 -computer_name $ip -port 135 # RPC 
                 }
                 pause}
            "5" {foreach($ip in $ip_list){
                    Write-Host "IP/Nazwa: $ip"
                    Option1 -computer_name $ip -port 445 # SMB
                 }
                 pause}
            "6" {foreach($ip in $ip_list){
                    Write-Host "IP/Nazwa: $ip"
                    Option1 -computer_name $ip -port 88 # Kerberos
                 }
                 pause}
            "7" {foreach($ip in $ip_list){
                    Write-Host "IP/Nazwa: $ip"
                    Option1 -computer_name $ip -port 53 # DNS
                 }
                 pause}

            "8" {foreach($ip in $ip_list){
                    Write-Host "IP/Nazwa: $ip"
                    Option1 -computer_name $ip -port 389 # LDAP
                 }
                 pause}
            "9" {foreach($ip in $ip_list){
                    Write-Host "IP/Nazwa: $ip"
                    Option1 -computer_name $ip -port 23 # Telnet
                 }
                 pause}
            "10" {foreach($ip in $ip_list){
                    Write-Host "IP/Nazwa: $ip"
                    Option1 -computer_name $ip -port 1723 # PPTP
                 }
                 pause}
            "11" {foreach($ip in $ip_list){
                    Write-Host "IP/Nazwa: $ip" 
                    Option1 -computer_name $ip -port 80 # HTTP
                 }
                 pause}
            "12" {foreach($ip in $ip_list){
                    Write-Host "IP/Nazwa: $ip"
                    Option1 -computer_name $ip -port 443 # HTTPS
                 }
                 pause}
            "13" {foreach($ip in $ip_list){
                     Write-Host "IP/Nazwa: $ip"
                     $paczka1 = @(53,88,135,139,389,445,464,636,3268,3269) # Paczka 'AD DC Ports'         
                     foreach ($port in $paczka1){
                        Option1 -computer_name $comp_name -port $port
                           }}
                 pause}
            "14" {foreach($ip in $ip_list){
                     Write-Host "IP/Nazwa: $ip"
                     $paczka2 = @(135,137,139,389,636,445,1512,42) # Paczka 'AD DC Communication Ports'         
                     foreach ($port in $paczka2){
                        Option1 -computer_name $comp_name -port $port
                           }}
                 pause}
            "15" {foreach($ip in $ip_list){
                     Write-Host "IP/Nazwa: $ip"
                     $paczka3 = @(139,389,445,135) # Paczka 'DFSN'        
                     foreach ($port in $paczka3){
                        Option1 -computer_name $comp_name -port $port
                           }}
                 pause}
            "16" {foreach($ip in $ip_list){
                     Write-Host "IP/Nazwa: $ip"
                     $paczka4 = @(389,53,88,445) # Paczka 'AD Authentication Ports'        
                     foreach ($port in $paczka4){
                        Option1 -computer_name $comp_name -port $port
                       }}
                 pause}
            "17" {foreach($ip in $ip_list){
                     Write-Host "IP/Nazwa: $ip"
                     $paczka5 = @(22,80,443,25,53,21,3306,5432,6379,27017) # Paczka Linux         
                     foreach ($port in $paczka5){
                        Option1 -computer_name $comp_name -port $port
                           }}
                 pause}

            "18" {Show-Menu6 -computer_name $ip_list} # Opcja Inny
            "0" {break}


            default {Write-Host "Nieprawidłowy wybór. Wybierz ponownie." -ForegroundColor red 
                      pause}
    }
}
}

# funkcja dla opcji "Inny" w Sub-Menu-1, jeżeli użytkownik podał adres IP w postaci wzorca lub kilka nazw/IP po przecinku
function Show-Menu6{
    param(
        [array] $computer_name
    )
    <#
    Funkcja sprawdza dla każdej nazwy/IP wpisany przez użytkownika port lub kilka portów
    Parametr :  
        [array] $ip_list - lista adresów IP/ nazw
    #>
    $choice5 = -1
    while($choice5 -ne 0){

    Clear-Host
    Sub-Menu-2 # Wyświetlenie podmenu

    $choice5 = Read-Host "Wybierz opcję (0-3)"

    switch ($choice5) {
        "1" {$ports = Read-Host "Wpisz porty " # Jeden port lub lista portów

             $ports = $ports.Split(',') # rozdzielenie
             $portList = New-Object -Typename "System.Collections.ArrayList"
             $portList.AddRange($ports) # wpisanie portów do listy

             # wykonanie funkcji Option1 dla każdego IP/nazwy i dla każdego portu
             foreach($ip in $computer_name){
                Write-Host "IP/Nazwa: $ip"
                foreach ($port in $portList){
                    Option1 -computer_name $ip -port $port
                 }}

             pause}
        "2" {$ports = Read-Host "Podaj zakres portów " # Zakres portów

             $ports = $ports.Split('-') # rozdzielenie
             $portList = $ports[0]..$ports[1] # stworzenie listy na podstawie zakresu

             # wykonanie funkcji Option1 dla każdego IP/nazwy i dla każdego portu
             foreach($ip in $computer_name){
                Write-Host "IP/Nazwa: $ip"
                foreach ($port in $portList){
                    Option1 -computer_name $ip -port $port
                }}

             pause}
        "3" {$ports = Read-Host "Podaj wzorzec " # Wzorzec

             $portList = Generuj-Porty -port $ports -pozycja 0 # generowanie portów

             # wykonanie funkcji Option1 dla każdego IP/nazwy i dla każdego portu
             foreach($ip in $computer_name){
                Write-Host "IP/Nazwa: $ip"
                 foreach($port in $portList){
                    Option1 -computer_name $ip -port $port
                }}

             pause}
        "0" {break}
        default { Write-Host "Nieprawidłowy wybór. Wybierz ponownie." -ForegroundColor red
                  pause}
    }}
}


Show-Main-Menu
