[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") 
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[System.Windows.Forms.Application]::EnableVisualStyles()


# lista zawierająca wyniki wszystkich wykonanych przez użytkownika operacji
$lista = New-Object -Typename "System.Collections.ArrayList"

# lista portów do wyboru - słownik
$ports = New-Object System.Collections.Specialized.OrderedDictionary

# dodanie elementów do słownika
$ports.Add("Active Directory Web Service/Active Directory Management Gateway Service (9389)",@(9389))
$ports.Add("Global Catalog (3268, 3269)",@(3268,3269))
$ports.Add("NetBIOS Session Service (139)", @(139))
$ports.Add("RPC (135)",@(135))
$ports.Add("SMB (445)",@(445))
$ports.Add("Kerberos (88)",@(88))
$ports.Add("DNS (53)",@(53))
$ports.Add("LDAP (389)",@(389))
$ports.Add("Telnet (23)",@(23))
$ports.Add("PPTP (1723)",@(1723))
$ports.Add("HTTP (80)",@(80))
$ports.Add("HTTPS (443)",@(443))
$ports.Add("Paczka 'AD DC Ports'",@(53,88,135,139,389,445,464,636,3268,3269))
$ports.Add("Paczka 'AD DC Communication Ports'",@(135,137,139,389,636,445,1512,42))
$ports.Add("Paczka 'AD Authentication Ports'",@(389,53,88,445))
$ports.Add("Paczka Linux",@(22,80,443,25,53,21,3306,5432,6379,27017,8000,8080))
$ports.Add("Inny",@(-1))



#Paczka adresów
$ips = New-Object System.Collections.Specialized.OrderedDictionary

$ips.Add('paczkawindowsdefenderazuread',@(
'eu-v20.events.data.microsoft.com',
'winatp-gw-neu.microsoft.com',
'winatp-gw-weu.microsoft.com',
'winatp-gw-neu3.microsoft.com',
'winatp-gw-weu3.microsoft.com'))

$ips.Add('paczkakontrolerydomeny',@(
'ad1',
'ad2',
'ad3'))



<# funkcja generująca listę portów na podstawie wprowadzonego przez użytkownika wzorca
[string]$port - sprawdzany port
[int]$pozycja - aktualna pozycja 
[int]$cyfra - podstawia liczby od 1 do 9
[@]$wyniki - lista zawierająca wygenerowane porty #> 
function Generuj-Porty{
    param(
    [string]$port, 
    [int]$pozycja) 

    $wyniki = @()

    if ($pozycja -ge $port.Length) {
            $wyniki += $port
    }
    elseif ($port[$pozycja] -eq '*') {                    # możliwość wprowadzenia znaku * , który sprawdza wszystkie liczby od 1 do 9
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


# funkcja generująca listę adresów IP na podstawie zadanego przez użytkownika wzorca
function Generuj-IP{
    param(
    [string]$ip, 
    [int]$pozycja)

    $wyniki = @()

    if ($pozycja -ge $ip.Length){
            $wyniki += $ip
    }
    elseif ($ip[$pozycja] -eq '*'){                       # możliwość wprowadzenia znaku * , który sprawdza wszystkie liczby od 1 do 9
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


# funkcja rozdzielająca adresy IP
#[string] $port_name - nazwa portu
#[string] $computer_name i nazwa adresu IP (domyślnie jest to 'localhost')
function Option1{
    param (
    [string] $port_name,
    [string] $computer_name = 'localhost'
    )
    $text = ""

    $computer_name = $computer_name.Replace(" ", "")

    $regex = "[a-zA-Z]"    
    $containsLetters = $computer_name -match $regex      #sprawdzanie czy adres zawiera litery
    
    if(($computer_name.ToLower()).Contains('paczka')){
    $comp_name = $ips[$computer_name.ToLower()]
    foreach($c_name in $comp_name){
            $text += Generuj-Output $port_name $c_name
        }
    }
    elseif($computer_name.Contains("*") -and $containsLetters -eq $true){
       $text += "Wprowadzono niepoprawny adres IP"
    }
    elseif($computer_name.Contains("*")){
        $comp_name = Generuj-IP $computer_name 0

        foreach($c_name in $comp_name){
            $text += Generuj-Output $port_name $c_name
        }}
    elseif($computer_name.Contains(",")){
        $comp_name = $computer_name.Split(",")
        foreach($c_name in $comp_name){
            $text += Generuj-Output $port_name $c_name
        }}
    else{
        $text += Generuj-Output $port_name $computer_name
        }
    return $text
}


# funkcja generująca tekst wyniku funkcji Test-NetConnection
function Generuj-Output{
    param (
    [string] $port_name,
    [string] $computer_name = 'localhost'
    )

    $porty = $ports[$port_name]
    $text = ""

    if($porty -eq -1){
            $Form2.Add_Shown({$Form2.Activate()})
            [void] $Form2.ShowDialog()

            $porty = $textBox_2.Text
            $textBox_2.Text = ""

            if($porty.Contains(",")){
                $porty = $porty.Split(",")
            }
            elseif($porty.Contains("-")){
                $ports = $porty.Split("-")
                $porty = $ports[0]..$ports[1]
            }
            elseif($porty.Contains("*")){
                $porty = Generuj-Porty -port $porty -pozycja 0
            }}

    if($porty -ne ""){
        foreach($port in $porty){
            $text += ">> Sprawdzenie portu $port <<" + [Environment]::NewLine
            $oldSyncContext = $null
            try {
                $oldSyncContext = [Threading.SynchronizationContext]::Current
                [Threading.SynchronizationContext]::SetSynchronizationContext($null)
                $output = Test-NetConnection -ComputerName $computer_name -Port $port -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
            }
            finally {
                if ($null -ne $oldSyncContext) {
                [Threading.SynchronizationContext]::SetSynchronizationContext($oldSyncContext)
            }}                                                                                          #wypisanie listy z danymi
            $text += ("ComputerName = "+$output.ComputerName.ToString() + [Environment]::NewLine)
            $text += ("RemoteAddress = "+$output.RemoteAddress.ToString() + [Environment]::NewLine)
            $text += ("RemotePort = "+$output.RemotePort.ToString() + [Environment]::NewLine)
            $text += ("InterfaceAlias = "+$output.InterfaceAlias.ToString() + [Environment]::NewLine)
            $text += ("SourceAddress = "+$output.SourceAddress.ToString() + [Environment]::NewLine)
            $text += ("TcpTestSucceeded = "+$output.TcpTestSucceeded.ToString() + [Environment]::NewLine)
            $text += [Environment]::NewLine
        }}
    else{
        $text += "Nie wybrano żadnego portu"
    }
    $lista.Add($text) | Out-Null
    return $text
}


#Funkcja wypisująca liste aktywnych połączeń do pola wynikowego (Tab3)
function UpdateTextBox2 {
    $output = & netstat -an | Sort-Object
    $outputString = $output | Select-Object -Skip 1 | Select-Object -SkipLast 1 | Out-String 
    $outputString += [Environment]::NewLine
    $TextBox2.Text += $outputString 
    $lista.Add("Lista aktywnych połączeń:" +[Environment]::NewLine) | Out-Null
    $lista.Add($outputString) | Out-Null
}



# Graficzny interfejs
#____________________________________________________________________________________________________

#Panel2 (okienko przy wyborze portu "Inny")
$Form2 = New-Object System.Windows.Forms.Form
$Form2.StartPosition = "CenterScreen"
$Form2.Size = "500,120"
$Form2.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#90E0EF")
$Form2.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$Form2.ControlBox = $False

#Napis "Wpisz port:" (przy wyborze portu "Inny")
$Label_2 = New-Object System.Windows.Forms.Label
$Label_2.Text = "Wpisz port:"
$Label_2.AutoSize = $True
$Label_2.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]::Bold)
$Label_2.Location = New-Object System.Drawing.Point(20,32) 
$Form2.Controls.Add($Label_2)

#Pole do wprowadzenia portu (przy wyborze portu "Inny")
$textBox_2                        = New-Object System.Windows.Forms.TextBox
$textBox_2.Location               = New-Object System.Drawing.Point(120,30)
$textBox_2.Size                   = New-Object System.Drawing.Size(300,50)
$textBox_2.Multiline              = $false
$textBox_2.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$textBox_2.ReadOnly               = $false
$Form2.Controls.Add($textBox_2)

    #Przycisk OK (przy wyborze portu "Inny")
    $okButton = New-Object Windows.Forms.Button
    $okButton.Location = New-Object Drawing.Point(180, 70)
    $okButton.Size = New-Object Drawing.Size(60, 25)
    $okButton.Text = "OK"
    $okButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
    $okButton.Add_Click({
        if($TabPanel.SelectedTab -eq $Tab1){ 
            $TextBox3.Text = "Sprawdzanie portu ..."
            }
        elseif($TabPanel.SelectedTab -eq $Tab2){
            $TextBox4.Text = "Sprawdzanie portu..."
            }
        $Form2.Close() })


    #Przycisk CANCEL (przy wyborze portu "Inny")
    $noButton = New-Object Windows.Forms.Button
    $noButton.Location = New-Object Drawing.Point(260, 70)
    $noButton.Size = New-Object Drawing.Size(60, 25)
    $noButton.Text = "Cancel"
    $noButton.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#FFFFFF")
    $noButton.Add_Click({ 
        $TextBox_2.Text = ""
        $Form2.Close()
    })

    #$Form2.AcceptButton = $okButton
    #$Form2.CancelButton = $noButton

    $Form2.Controls.Add($okButton)
    $Form2.Controls.Add($noButton)



#Panel główny   _____________________________
$Form = New-Object System.Windows.Forms.Form
$Form.StartPosition = "CenterScreen"
$Form.Topmost = $false 
$Form.Size = "900,800"
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$Form.MaximizeBox = $false




#Ikona (na pasku w górnym lewym rogu)
$iconBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAgAAAAIACAYAAAD0eNT6AAAACXBIWXMAAAsTAAALEwEAmpwYAAAgAElEQVR4nO3dCfh9Y7n/8TvDLzOZZ1EhQ5KM6dBBjiFNyhBRnVNJJGQow48UKQdlaJKENDghBwmlSNLJ1EQZU50yZB6T81/3f//WObvd3t/vHtb9fJ611vt1XZ/rOlc5+t73ftbaz17D85gBAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAHK2SJGdinyuyNVF/lDk4Vnx//tHs/67nWb9swDQfd7wc0TveeNq47wBZGv9It8o8lSR/xkyTxf5ZpENBH8vAD0/9v0c4OeCYc8bfo7xc836gr8XQJflipxvwx+8g3JBkeUT/+0ANPxY92N+0vOGn3uWS/y3Ayi81TqX6CY9iMs8UmTHpBUASM2PcT/Wqzpv+DnorUkrAFpuZpHnrLqDuIz/Ow9PVwaAhPzYjjpvzExXBtBOsxU5xao/gHtzRKqCACThx3T0ecPPTbOlKghokxlFvmbxB3GZd6YpC0CwXSzdeeO8InOlKQtoh/mKXGbpDmLP40VelKI4AGH8GPZjOeW547vWOWcBmNCiRa6ztAdwmcsT1Acgjh/DinPHT4w1A4CJ+Os6t5jmAC6zWXiVACJsbtpzx6+N14uBsfilu9+Z9gD2XBpdKIAQfuyqzx93F1kxulCgSV5onQNHffB6/mbM4oG68WPWj131+cNzZ5EVYssFmsFX1rrd9Adtd94XWjGAqu1p+vNGd+6yzg8bAAMsU+Q20x+svTk3smgAlfNjVn3e6M1viiwdWTRQV0sU+ZXpD9J+uSWwbgDVu9X0541+8b9rqcC6gdrJ+cvf80xc6QAC+DGrPm8Myi+LLB5XOlAf/q7sL0x/UE6XeaIaAKBSfqyqzxfT5eYiC0c1AKiDuYv8yPQH4zBhZS+gHvxYVZ8vhslVxrLBaKnZi3zL9AfhMPHXiZ4X0wYAFfNjNZdXAKfLN40NhNBCJ5r+4Bs2dwb1AECMu0x/3hg2p8S0AMjTAaY/6EbJxTFtABDEj1n1eWOU7BvTBiAvO1p9Ls+VOTCkEwCiHGT688Yoec462xYDjfWaIk+b/mAbNWtENANAGD9m1eeNUfNUkU0imgGorVLkIdMfZKPmpxHNABDOj131+WPU/KXISyKaAaj4azl1eNe/X94W0A8A8fySuvr8MU58G+EFAvoBJOev5NTldb/e/Nw6rysCqB8/dv0YVp9HxonvZcCrx6i9Q0x/MI0Tf1Bx44B+AEhn/SLPmv58Mk4ODugHkMxWVr8n/sscEdAPAOn5saw+n4wTn7hsGdAPINyLrfNAi/ogGiffMFbnAprCj2U/ptXnlXHyQJGVqm8JEGde62x2oT54xonfe5uz+pYAEPJj2o9t9fllnNxknXMqUAtnmf6gGSdfMB76A5rKj+0vmv48M06+EtAPoHK7mv5gGSe+NwFP3QLN5sf4TNOfb8bJztW3A6jOikUeNv2BMkp8Cc4PRTQDQLb2tvo9oOwLqb0woBfAxOYoco3pD5JR4k/ZviuiGQCy5wsFPWP689Aoudq4TYkMHWn6g2OUPFFk25BOAKiL7Yo8afrz0Sg5LKQTwJh8wZw6LbbhGxJtE9IJAHXzWqvXJOCvRTYM6QQwogWL3Gn6g2KUL//XhXQCQF39i3V241Ofn4bNHcZ+AcjA2aY/GIaN3+/bLqYNAGrujVavZwLOiGkDMBxf6ld9EAwbv0WxY0wbADTEm6xziV19vho2PMcEifmL/M70B8CwX/5vjWkDgIbZyerzTNOdxiqBEPiM6Qf/sNkzqAcAmundpj9vDZvjgnoA9LWe1WeG/NGgHgBotqNNf/4aJr6gEW8FIAlf8OcG0w/6YeIPKLK8L4Bx+Lnjy6Y/jw0T3zCITcwQ7lDTD/Zh8r0iM4J6AKAd/Ev1u6Y/nw2Tg4J6APx/K1s9FszwrYgXDOoBgHbx9+3rcNXT1zFYNagHgF1m+kE+Xf5YZOmoBgBopWWL/Mn057fpcklUA9BuvoCOenBPF1/E49VRDQDQahtZZyVR9XluumwV1QC0k98Hu9X0A3u6vDeqAQBQ2Mv057np8mvjgUBUaB/TD+rp8pWw6gHg/5xm+vPddGHtE1TiBUXuN/2AnirXF5k7qgEA0GWuIteZ/rw3VR4osnBUA9AeJ5p+ME+VPxdZLqx6APhHyxe51/Tnv6nCCoGYyCqW9+5Yzxlb+wLQ8Ift/BykPg8Oij+wuHJY9Wi8C00/iKfKp+NKrx1fodEnbP62xm7WWcvcNzXZzHgtEqPzMeNjx8eQjyUfUz62fIzNIfy7cnOS6c+DU+W8uNLRZL62tHrwTpVfGPf9vf5dilxQ5BGbul93FflckY2N5ZHxj3xM+NjwMXKXTT2WfKz5mPOx1/Zj0J8H8GV41efDqbJ+WPVorEtNP3AHxVcjfFlc6dmbr8hHrPOgzzj98xPWG5P/1ciVj4Vxv8R8DPpYnC/5X52P1S3vFVIviisdTbSB6QftVGnzKy5bFrnbqunjd6zzMBPayT97HwNVjCUfk1um/fOz8kHTnxenynpxpaNpqjopRMRns228hO01z7TqHzq6r8hr0pWBTPhn7p99lWPJx+ZMa+/xmfNV0/+MKx1NkvOvf7/32MZX/ma32MVH/E2PNySrBmpbW2fjmKjxdJa1cyU6v6LyqOnPk4PCVQBMyzeTUA/UQWnjpX9/yOh8i++tvzLElYDm8884xXr2/vT58xPVlJOcbwVcGFg3GmAdy/e91muLzBZXepbmL/I9S9djvyTMMwHN5Z9t1Zf9p8oV1r6HA/0cdY3pz5eDsm5c6ai7i00/QPvFf7GsHlh3jhYyzXKjbCfaXIqrez5xXzBFcRlZ0/JdQO3bgXWjxtawfH/9HxFYd44WsM6JU9VvngdoHv9MVePJfxHPH19iVj5u+vPmoKwZWDdq6gumH5j9cou1617ivEWuMm3Pb7R2PsndVP5Z+meqHFM/KDJPdKEZ8Wd3fmP682e/fDawbtTQokWeMP3A7JetAuvOja+q5vdN1T33vCq4VqTjK/ypx5PncmvXyoG+dLK65/3yeJFFAutGzfhKXupBOeiE0Ra+vrqvcaDueRl+JTSHf5bq8VTG70HPHltuVnJdG+CAyKJRH/6+7j2mH5C9edY6zyW0xcmm73l37owtFwndYfrx1J3Px5abldWK/NX0Pe/N762dazWgh+/2pR6M/XJyZNGZOcT0/e6XpSKLRhL+GarHUb8cGFl0ZnzCo+53v2wfWTTqQfm0+aA8XGSJyKIzsqvl+/YFCwPVn3+G6nHULz7mdwqsOyeLF3nI9D3vzVWRRSN/vk2kehD2y/6RRWfEH7RLsSrbuNkxrnQk4p+hehwNii9H3Jatag8yfb/7ZZ3IopG3M0w/AHvj96bmiiw6E0sX+aPp+z1V/jWseqTin6F6HE13vLfhap+//fDfpu93b06LLBr58vfNc9y4Yq/IojPhD9/80PS9ni67RDUAyfgtJvU4mi4/KjIjqgEZyXGfAP8OaNtyzSi8w/SDrzf+i7gN7wnn9sT/oGwT1QAk45+hehwNkxOjGpARv7L5B9P3ujdM9FvoStMPvN7sHVlwJnY2fZ+HzUuCeoB0/DNUj6Nhs0NQD3Kyr+n73JvLQitGdlYo8jfTD7zu+P2xpv/6X9HyfBq4X/zvbNOCLU3ln2FdxtyD1vzdKHO8CuDfBU3vO7ocZvpB15sPhFas5yv9XW36Pg+b82LaAAH/LNXjadj4ngFNn3jmeBXgw6EVIxu+Mchtph9w3bnXmv/r/3DT93mUtOUd7Tao022nNnwZ+aZI95m+z925NbRiZOPVph9svTkytGI9f9c5x+VAB8VPTm14FbMt/LPM7QtnqjxT5JUhncjHx0zf595sGFoxspDbtr++EM7SoRVr+aV/9Vaso+agkE5A6WDTj6tRcrM1e636Zawz0VH3uTtsANZwfm8tt18CZ4ZWrHeo6Xs8Su60zhoRaBb/TP2zVY+vUXJwSCfycY7pe9wd/25o+vMXrbap6QdZb9aLLFhsVessd6ru8bDxp4E3D+kEcuCfbW5v/0yVJ6zZr6JuYPoe92bj0IohdbzpB1h3ro4tV8oftrzC9D0eJR8J6QRykuvOk4NypXWOpabKbTO2T8aWC6Xc9gV/S2y5UnVYgrU7p1izT7To8M/YP2v1eBslTX4jJbc3NG6LLRcqa5l+cHXnz9bch3z8NZ97TN/jYfNp48u/Tfyz9s9cPe6Gzd3W3NeEfQ+E3J7LWj20YkgcbvqB1Z3jY8uVmmn6/g6bY2JagBo40PTjb9g0+fbUSabvb1t63VrXm35gdeflseXK+Os9j5m+v9PlOWvH3guY2j7WGQvq8ThdfNe6pYJ6oLau6fvbnetiy0Vqvs5zTgf5z2PLlfqy6fs7XXws7BlUP+rHJ4LqMTlMvhjVgAz4ugfq/nafH5aNLRcp+clePai6s19suTL+ylIdVvw7MKoBqC2/EqAel9Pl2SIrRzVA7ADT97c7740tFyl9y/QDqox/QS4ZW67MV0zf3+lyWFj1qLsjTD8+p8vpYdVr+WqoPsFR97fMN2LLRSqzFbnf9AOqzEWx5cq82PL/9d/kS6iYnL8d8CXTj9Op0uSrAN8xfX/L+AZtvBnUAP6wnXowdWe32HJlcv/1f4l19iUApuKv5ub0RdQvp4dVr/Uu0/e2O2vElosUcrq357P3RWPLlVjJ8rp815tfF1kgrHo0zYLW2R5WPW4Hxa+0rRhWvc7iltd5ZK/YcpHC+aYfSGW+H1yrygmm7+2gPFJktbjS0VCrFHnY9ON3UI6LK13qKtP3tsx/BNeKYH7//y+mH0hl9oktV8J/Wed6ovTXed4YVzoabnvL6/Xh7jxYZL640mX2N31vyzxgne8Q1NQrTD+IutPEy3Y53WLpzWcC60Y7nGr6cTwoTVzL4kWm72t31ootF5H8fXv1ACpzQ3CtCj479s0z1L3tl19ac9dPRzpzWV6L1HTnN9bMX6i+UJq6t2U+EFwrAuV0//+I4FoVtjZ9X/vlqSJrBtaNdlm7yDOmH9f98trAulWOMn1fy3wruFYE+oPpB1CZjYNrVfDFMtR97ZfDI4tGK33M9OO6X86OLFpkU9P3tczdsaUiyhKmHzxlHi/y/Nhyk/NXpZ4wfW97c4t1LtsCVfLj91emH9+98WNwocC6FbzXOZ1bFostFxFyujz93eBaFfYwfV97409sN/FKS1V873VfRW6dIpsXef2sbD7rP/P/bk7ZX5e/TSzPtwL+LbJoke+Zvq9lmnibpfEOMf3AKfPh4FoVrjV9X3vTxMuh4/JVDzeyzt7m37bOA2PDLNXs/4wvgnOBdcbthsYKit1yvO11VWjFGoeavq9lDgquFQF8EQf1wCmzYXCtqfm6/+qe9sYvGS4fWXQN+C98/0V/rnX2j6+qt76Ykn/xvc64QuCv8j5p+vHeneesea8Y+5U8dV/LfD24VgS40/QDx+Mn4qadNHNarKPMx0IrzpvvpPapIvdZfJ99k5RjiyyVpLI8fcL04703TVtkzCezj5m+r57fBteKii1s+dyr+05wrQo/Mn1fu+MrEb4gtOI8+RUPX6jGX3tM3XP/FXxykeXCq8zPIta5KqIe9925MrJgEX92St1Xj3+XLBhcKyrkDzWpB02ZmbGlJudvV/zN9H3tzpGhFefHryj5AiVVXuYfN/6Gy0xr3lsu08nttUDfRKdpT6v7ca3ua5lNY0tFlXJaAXC74FpT8yeO1T3tjv/6Xzi04rz48yS+u6G6773xV+TWC6w7Nz7mctsD4x2hFafn+3ioe1qmabdYGu1zph8wZZYNrjW1C03f0+4cH1tuNp5nnV/9T5u+54PibxDMtGYuT9tPbrtgnhdbbnIrmL6nZU4OrhUVusL0A8bz5+hCE/PXwXL61eOXPV8UWnEe5rXOa3nqfg8b/yKaJ6QTefEn73Pav953CJw9tOL0UjzYOkwujS4U1fHlG9UDxnNJdKGJ+SVedU+704b9uv3hxtweuhwm1xVZNKAfufE1FtS97s4rYstNLpcHAW+PLhTV8IeRcpmVHxVca2oHmr6n3dkytly5ZSzP5WeHjf/tS1felbxsY/o+d2e/2HKTO8b0PfX4d8qM4FpRgVVNP1jKvDm41tT8lUZ1T8v83pp3ubObv3Z0o+n7PGl+Yc1+SNNvi/3R9H0u85+x5Sa3g+l7WuYlwbWiAjnNyFcJrjUlP9Hl8NpZmaNjy5Wa2zrLu6p7XFV82eh5K+1QXj5p+h6X8Wd0mjQxXs30PS2zVXCtqIC/rqEeKJ6mXTJ6mel72p3VY8uVOsf0/a06Z1XaobysZfr+dmeN2HKT8p09c1l35P3BtaICnzH9QPHcEV1oYv6OsbqnZX4TXKvSe03f36g0cde6kj8kpu5vmbcH15ra70zfU09bXjmutYtNP1A8l0UXmlguEyvPMcG1qvhVltw2mqkyvmFTk36ddjvO9P0tc0JwranlsjVw056vaKSbTD9QPKdGF5pYTq+ibRRcq4IvnnON6XsbneusmQsF/ZPpe1vmh8G1pvYF0/fUc310oZhcLk/k7h9daEL+UFEuO3M9ZM16yKn0HtP3NlXeVVHPcuIPyeayQZA/rNukSdZBpu+p557oQjEZXy71GdMPFM8bg2tN6cWm72eZJl6G88V+HjB9b1PFV3dr4u5qvvCXurdlVgquNaXtTd9Pz1PRhWIyC5l+kJRZK7jWlP7F9P0s07SFTtxhpu9r6ny4ks7lJaeFsrYIrjWltU3fzzILBNeKCaxs+gFSZvHgWlPa0/T9LLNBcK2p+fvx95q+r6lzf5H5KuhfTvzZFHVfy+wRXGtKS5m+n2XasPdIbW1s+gHi8fdW5wiuNSV//UXdU4/vNjd3cK2p+Q5/6r6qsncF/cuJb4DkY1TdV8+ngmtNyc+lz5m+p54Ng2vFBHLZP/q+6EITy2XDk5uiCxXI5a0VRW6ooH+58aWP1X31NG1r4L+Yvqee7aILxfjebfoB4vlVdKGJ5XJS+3JwnanltoKcIi+buIt5OdP0PfXcHF1oYreavqeeJr7B0hiHmH6AeH4QXWhiuTyhflB0oYkda/qeqtO0RZ0ONX1PPfdGF5rY1abvqefg6EIxPr/vpR4gnibtU5/T/bftg2tNzX+lqXuqTtNuA+xk+p56/DmkJq2X4bc01D31HBtdKMZ3kukHiKdJqwAuafp+llk7uNaUFrN8JlbKeA8WnbCXOVnX9D0ts1hwrSl93vT99JwYXSjGl8sgadJlzTVN388yLwiuNaW3mL6fueTNE/YyJ4uYvp9lmrRjZi63yz4bXSjGd4bpB4hnZnCdKW1m+n56nrbOSo9N4ZNEdU9zyccm7GVOclqNdNPYUpP6qOn76Tk9ulCM72umHyCeJj0o8ibT99Pz++hCE8vlnmYOOXfCXuYml/1I3hBdaEK5POD91ehCMb5cTqr7RheaUC4PNTVtJy5/VVTd01zy8wl7mZtc1nbYIbrQhD5k+n56mvSAd+NcbPoB4tkzutCEdjd9Pz1XxpaZ3BOm72kueWzCXubGt+NV99SzW3ShCe1l+n56mrgZWWNcYfoB4vnX6EITymWb2kujC01oTtP3M7c0aensy0zfT8+/RReaUC6LvF0eXSjGl8tiEbtGF5qQr9eu7qfn29GFJrSw6fuZWxaaqKN58V+J6n569oouNKHdTN9Pz1XRhWJ815l+gHiadO9tf9P309Oke2/Lm76fuWX5iTqaFx+r6n569o8uNCE/p6r76bkuulCM71rTDxDPTtGFJuQPNKr76WnS5iY5bW+aS5acqKN5Od/0/fR8MLrQhHY2fT89P44uFOPzNfjVA8Sze3CdKb3f9P30XBxdaELzm76fuWXeiTqal0tM30/P+6ILTegdpu+n58rgOjGB75p+gHjeE11oQv4gkbqfniY9fDObddZqV/c0lzxrzVrk6Xum76mnSTvX7WH6fnq+E10oxneh6QeIZ+/oQhN6u+n76flRdKGJ3Wf6nuaSpu1cd43pe+rZJbrQhPYxfT89F0QXivH5imLqAeL5UHShCeXy8M0t0YUmlsuXRA5p2pPVvzV9Tz1N2j3zQNP30/ON6EIxvrNNP0A8H4kuNKHXmb6fngeiC03sdNP3NJd8ccJe5uZB0/fUs010oQkdZvp+es6MLhTj+5LpB4jnyOhCE9rQ9P30+LaxcwbXmtIBpu9pLmnS62ozLJ9tntcLrjUl3zBK3U9P0yarjXKK6QeI51PRhSb0YtP3s8xywbWm9CrT9zOXbDBhL3Oygun7WWal4FpT+nfT99NzcnShGN8Jph8gntOjC01oQdP3s8ymsaUm5UvfPmL6nqrjPWjSlZ1cts/2NOnVSr/0ru6n57joQjG+XC4TXRRdaGJPmb6nnia91uRy2bxKmaZtrpLL3hlPRBeaWC5rKxwVXSjG5ytfqQeIp2nLRd5j+p56jo4uNLFcNjhRpmmTumNN31PP3dGFJvYz0/fU06RXvBvH33tVDxDPndGFJpbLEstN+7Xot1favC3wk9asTYCcLxSj7qunaetm5PIjpEnLvDfOa00/QDyPRxea2Fmm76nnT9GFCvh7xeq+qvK1CvqXGx+j6r56zoguNDGfLKp76tk8ulCMb23TD5Ay8wTXmtJM0/ezzFKxpSa3qel7qsomk7cvK/6WirqnZQ4LrjWlnPbOWCu4VkxgWdMPkDIrBNea0q6m72eZ7YJrVfCV8NR9TZ1rKulcXt5g+r6W2Tm41pT8dUZ1P8s07QdIozzf9AOkzMbBtaa0ken7WaaJr+Fsbfq+ps6WlXQuLyeavq9lmrQI0Cam76enaYuRNdLDph8ont2iC01oUdP3s8z1wbUq+E54V5q+t6lyRSVdy89Npu9tmRcE15qSvymi7qfnwehCMbnbTD9QPE1aDtj9zvQ99fg2ugsH16qwWpFnTN/f6Dxd5KUV9Swni1k+SwDfGVxrah83fU89t0YXisnlssvaOdGFJna+6Xtapkn3N7t9wvS9jU7T1nIo7Wb63pY5N7jW1L5u+p56ro4uFJPzV4vUA8Xzk+hCE8tlNy5PU7fk9GdY/BaHur9R8Uvkc1fWrbycZ/r+lmnSbqQul0WAzoouFJPzpRrVA8Xzl+hCE9vW9D0t82iRuWLLlfHNl3J5jqXqz2yVCvuUE5/UPGb6HpfZKrbc5B4yfU89R0QXism9w/QDpUyTHsTx11/U/ezO62PLlXqLdZ51UPe4qngtb660Q3nx2tQ97s6SseUm5c9WqPtZ5u3BtaICrzb9QCnTpG1O3R2m72mZbwXXqvY+0/e4quxTcW9yc6Hpe1zmt8G1ppbTttkbBdeKCixt+oFSZo/gWlM7zfQ9LeNPky8WW66cPzCn7vOk+XjlXcnL4pbX2xufjy03ub1M39MyiwfXigr4O9W53I9r2sGYy2ZLZZr+y9IdaPo+j5tjAvqRm/1N3+fuNG2zmi+ZvqeeR6MLRXVuNv2A8fxXdKGJ5XR1xeOXO2cLrTgPe1q9ngl41pp39asfH3u3m77f3Vk6tOL0bjR9Tz1NXICssfz+sHrAePwy9YzgWlPzL111X7uzbWy52fA6HzB9v6fLfdZZ2rgNclr73/Or2HKT89dic7m90tRXjxvpk6YfMGXWDq41tZNM39PuXB5bblZ8tzlfjETd80HxtS9WDKs+P98zfc+7c0Jsucm90vQ9LdPUBawaaXfTD5gy74otNTnfD1vd096sH1pxXnwzkgOKPG76vpfxZ272KzJHYN252dD0fe/NppEFC7zb9D0ts2twrajQy0w/YMqcElxrav4F5IscqfvanYtCK87TGqbve5nVgmvN0aWm73t37rfmTcA+a/q+llk9uFZUyA+EJ0w/aDw3B9eqcKbp+9qbNl0FcL7IlLrnZZq04NUwctoeu8yXIwsW+aXp++rxq21Nm1w1nt+PVA8cj+8Q1rT3R7c3fV97c2VkwRliAqDzQ9P3vDdNWxnTz5m57K54TXCtCHCq6QdOme2Da01tPstnrYXuvDGy6MwwAdDwZZrV/e7NI0XmiSxaYAfT97XMScG1IkBOD5A0cQCdYfq+9sbfyX5+ZNEZYQKQnr/Se5vp+92bL0YWLZLT/f+mPcjdCjm9QvLL4FoV/tn0fe2XQyKLzggTgPRmmr7X/fLqwJpVbjV9X8s07VXuVvDZui/Eox48Hr+X1aQdupwvuZzT5kBlniry0sC6c8EEIK1VrTO21L3ujR+DzwusWyGnnUebuJhba9xg+gFUZsfgWhU+avq+9ssPrHknxV5MANLxJX/9QTB1n/vl8MC6Vd5m+r6W+VlwrQiU032krwTXqrCS5btG/QcD684BE4B0fOEldY/7xfdcWCGwbpWzTd/bMk1bx6VV/Fe3egCVedA6i+g0zfmm722/+OXalwfWrcYEII1XWD63EnvzH4F1q/g50s+V6t6WeUtsuYiU07ukns1iy5V4jen7Oij+8GXTXo8qMQGIN2+RX5u+v4OySVzpMluavq9l/LtjidhyEc13yFIPpDKfDq5VJZctO/vl7MC6lZgAxPuy6Xs7KDfElS3ll9zVvS3z8+BakUBOA+pua+bDae80fW+nyt5xpcswAYjlmxup+zpVdg+rXMfPjfeYvrdlmvqDrVVyW7nrFbHlSsxV5A+m7+2g+J7im4RVr8EEII7vePlX0/d1UH5vnWOuadYzfW+786bYcpFCbs8BHFln8Q0AABIcSURBVBlbrswHTN/bqfJQkTXDqk+PCUAM39kwt90ue/P+sOq1Pmb63pbxt5sWjS0XqfzC9AOqzG+tmbcB/BeJ/zJR93eq+OXFZaMakBgTgOr5AjR3mb6fU+WPReYOql/Jz4m+lLe6v2VujC0XKX3G9AOqO6+KLVcm96sAHn94qglfWEwAqrWw5f0wa5k9oxogtonpe9ud42PLRUrbmn5AdefzseXK1OEqgOd6q/+XFhOA6ixY5DrT93G6NPXXv/uS6fvbna1iy0VKvkOcb5mpHlRlHrbmvp/+HtP3d5hcXWT+oB6kwASgGgtYvsv89qapu9L5egs5nZ8ftfbsKtoa55p+YHWniXsDuNmL3GT6/g6Tn1p9H/RhAjA5/7t/bPr+DRO/dTV7TBvkdjV9f7vztdhyoZDbILsktlypXLcK7hdfKKqODwYyAZiM7855s+l7N2w2j2lDFi43fX+7s1NsuVDwh3xyerfXN/JYJrRirQtN3+Nh41uqrhDThjBMAMbnn3WOW1kPynkxbciCfxY5bSjma4YsFFoxZK4w/QDrzlGx5UqtYvluotIvdxZZOqQTMZgAjMc/Y/+s1T0bNr6p1YtDOpGHT5i+x925NLZcKPmSsOoB1p37rLlP9bqZpu/xKLnW6vPwDxOA0fln65+xul+j5JCQTuTBH4S+3/Q97s77QiuG1PKW16qAnneGVqw1wzo78ql7PEqODulE9ZgAjO4Y0/dqlPhmNDNCOpGH3N4Y8u+GOj4PhBH4O+Dqgdadm2LLldvY8rrHN138OZE1QjpRLSYAo/HPNKdngKaLHzMbhHQiD77yX04rtHp+GloxsrC/6Qdab14TWrHeqabv8Sj5ZkwbKsUEYDS5vQY8XU6MaUM2tjB9j3uzT2jFyMISlt8vgfNDK9abr8hvTN/nYeOXAlcK6UR1mAAM74VWr6tQfqzMF9GIjOT2lpB/JywZWjGycZHpB1x3/JXAVUIr1vPLmblNvKbK4TFtqAwTgOH5Z6nu0bDx19DWjWlDNl5q+U3Ivh1aMbKyg+kHXG++ElpxHg41fZ+HzXVBPagKE4Dh+b1ddY+GzcFBPcjJV03f5968KbRiZMU3rcltz+82XAXwpUyvMn2vh4n/Qsl5rwAmAMPxzzC3X5uDcmWR2UK6kI+VrXOuU/e6Ow9YfV7/RUU+a/qB15szQivOwwqW37u/g5LzpVgmAMPxz1Ddn2Fyb5HlgnqQkxx//X8mtGJkaUPTD7zetOEqgPMngHP7FdAv20c1oAJMAIbjn6G6P9PFn43556gGZCTHX/+eV0YWjXz92vSDrzdtuArgDjR9r6dLzos0MQEYjn+G6v5Ml/3Cqs9Ljr/+fxlaMbJ2gOkHYG98hrxyZNGZ8IVAvm76fk+V3aOKrwATgOG8w/T9mSrnxJWeldUsz1//+0YWjbz5iesx0w/C3jR5969u/q6zr4So7veg5PxkMBOA4fhnqO7PoPiqpPPGlZ6V3F699jxunV1i0WKfM/1A7JctIovOiO/Odrfp+90vLw+se1JMAIaztun70y+/t3Y89Of8+QZ1v/vl5MiiUQ9+aSq3DYI8N1rntbk2WLPIQ6bveXd8QZZ5IoueEBOA4fhn6J+lukfdebDI6pFFZ8TPYTebvue98XP+SwPrRo1cZvoB2S/viiw6M5taZ+9zdc/LXBVa7eSYAAwvp7UnfDKyeWy5WdnD9D3vl0sii0a9bGv6Adkvfy6yQGDduXmb5bNoy4eCa50UE4Dh+Wep7pHHH4LbMbjWnPgiTH8yfd/7ZavAulEzvvpWrpvVfDyw7hz5VQ/1LZk6bAzCBGB4/lmq96Hwie3uwXXm5ljTj81+udU6byEB/2tv0w/MfnnaOs8ptIl6EnBafIkTYwIwmi+Zrj8+lveILzEra1jn3KUem/2yZ2DdqCm/XOUP56gHZ7/4PcymrxHey/fmVvT6iSIrJqhvUkwARuOfqX+2iv7slaC+nPi56semH5f94uf4nPf4gNARph+gg/LewLpz9QFLfyUg93v/JSYAo0v9LICP3fcnqSwvuV5N9RweWDdqbkHL9yrAw0WWjSs9W/5gYKr7t5dafV69ZAIwOv9leqGl6Yk/8JfzUtJRli/yiOnHZL/4q8Z1GasQOdL0A3VQLgysO2dvsPhXBG8oslCqgirABGA8/hn7Zx3ZDx+rb0hVUGYuMP14HJTDA+tGQ/jJLLdFabqT8/K0kTazuM/lp0UWSVdKJZgAjM8/a//MI3rhY3SzdKVkZQfTj8VB8Su7dZrgQ+ijph+wg+L7huf+ilqUVYv8yqrt55lF5k5ZREWYAEzGP3P/7Kvsg4/NVVMWkRFf0vs+04/FQZkZVjkax2eKuT4L4PmOtfc91rmsszbCkzZZD39n9b6awgSgGj4GfCxMUr+PRR+TcyX+23Ph56KLTT8OB4V7/xjZUaYfuFNl77jSa8EfiDyhyAM2Wt98/29/D/j56f/kSjEBqI6PBR8TPjZGqdvHno/BNj6c220/04/BqTIzrHI0lm8TmfOzAP6r42Vh1deHn7y3LnJ8ke8X+aP939UBf3Pit9Z5ePLgIuuI/sYITABi+BjxseJjxseOj6HyePOx5WPMx5qPubpPIqvgO2bmtIdHb7j3j7EdYPoBPFX8F0sd719jckwAoOa3PHLc6a87+4ZVj8bzGf7tph/EU4U9rduJCQDUTjX92JsqfgVnRlj1aIXtTT+Qp8vuUcUjW0wAoOQLdKnH3XRp61oMqNgPTD+Yp4rfn2zS/W1MjwkAVPy+/+OmH3dT5fth1aN11rZ89qkflLuKLBpUP/LDBAAK/nD0HaYfc1PFz9X8IEKlzjD9wJ4ulxeZI6oByAoTAKTm+2T4GiTq8TZd6rCdN2pmmSKPmX5wT5dPRDUAWWECgNSOM/1Ymy6PFlkqqgFot0NNP8Cni29B+raoBiAbTACQ0ttNP86GycFRDQD8lZJfmH6QT5dnimwR1APkgQkAUnmN5b3YTxlfk4DX/hBqfcv/gUCPr2C2VlAPoMcEACmsYXnvi1LGz8kbBfUA+Du++I56wA+TPxRZPqgH0GICgGj+3NOkGyWlyglBPQD+wQJF7jH9oB8mfsuCE3TzMAFAJD/H3WT6sTVM7i4yf0wbgP62M/3AHzZXGBuXNA0TAETxNf6vNP24GjZbh3QBmMY3TT/4h80lxiSgSZgAIII/ROc7IarH1LA5O6YNwPSWLPIX0x8Ew+ZiYxLQFEwAULU5i1xg+vE0bO4vsnhIJ4Ah1WFTjO6ca6wW2ARMAFAl//L/lunH0ih5a0gngBGdZfqDYZT4rQsmAfXGBABV8SV+v2r6cTRKTg/pBDAGf2I29w0yenOmdQ581BMTAFShjl/+txlP/SMz61pnBT71wTFKzrfOE7+oHyYAmJQ/D1SnB5k9fy2yYUQzgEkdbvoDZNR83zpXMFAvTAAwifmKfNf0Y2fUfCSiGUAVZrN6vT9b5r+Mp2nrhgkAxrVwkR+bftyMmquM25bI3HJWr1cDy9xe5EUB/UAMJgAYxwpFbjH9mBk1DxV5YfXtAKrnr6f4trzqg2bU+PLGqwX0A9VjAoBR+bFdlyXMu+Pn0u0D+gGEOdb0B844ubfImgH9QLWYAGAULy3y36YfK+Pk4wH9AEL5varLTH/wjBM/USxbfUtQISYAGJYfy3X98r/UuO+PmlqkyJ2mP4jGyU+MxYJyxgQAw/Bj2I9l9RgZJ/5c0sLVtwRIZ60ij5v+YBonBwf0A9VgAoBhfNj042OcPFHkFQH9AJLb2fQH1DjxicsSAf3A5JgAYDqLFXnU9ONjnOwY0A9A5njTH1Tj5JMRzcDEmABgOn7sqscG5xzAOvfi/IEW9cE1anzLTbYQzg8TAEzFj1k/dtVjY9T4luU89IdG8g0sbjD9QTZqXhfRDEyECQCm4seselyMGl+RdL6IZgC5WLrIXaY/2EbJpyMagYkwAcBU/JhVj4tR4rupLhnSCSAzvijHA6Y/6IbNj2PagAkwAcBUrjX9uBg2fqti1Zg2AHn6pyJPmv7gGyYPBvUA42MCgKn4MaseF8PEz4GvCuoBkLW3FPmb6Q/CYTJnUA8wHiYAGMSPVfWYGCZ+7ntzUA+AWtjX9AfiMFkwqgEYCxMADOLHqnpMDJMPRDUAqJMjTX8wTheuAOSFCQAGqcMVgMPDqgdq6GjTH5SD8lBg3RgPEwBMxY9Z9bgYlKMC6wZqK9dJwLWRRWMsTAAwlVw3ADousmig7k4w/UHam5NCK8Y4mABgKn7MqscFX/7AiJ5X5GTTH6zdeX1oxRgHEwBMxY9Z9bjoji9M9LzQioGG8APlFNMftB5fsGiu2HIxBiYAmMqMIveZfmx4vmh8+QMjma3IqaY/eP89ulCMhQkApuPHrnps+NVMvvyBMR1ouoPXV+laJr5EjIEJAKbja+s/brpxcUx8iUDz+YIZz1n6A/jQFMVhLEwAMAw/hlOPB1/hb68UxQFtsUuRZyzdQfwzY/GfnDEBwDD8GPZjOdVY8HPUzkkqA1pma0tzSe/PRVZIVBPGwwQAw/Jj2Y/p6HHg56atEtUEtNJ61tk+M+og9l3EXpmsGoyLCQBGsZbFvhXg542Nk1UDtNjqRW636g/iO4qskbAOjI8JAEblx7Yf41V//n4uWj1hHUDrLVzk61bdQfyNIoskrQCTYAKAcfgx7sd6VZ+9n4MWTloBgP+1TZEbbPwD+MYi2yb/qzEpJgCYhB/zfuyP+5n7OWeb5H81gH/gC21sUeSr1rkXN93B++Csf/a1xiIddcUEAJPyY9/PAaOeN7YwzhtAlmYvsk6R3ayz5/anZuXwWf/ZK2f9M6g3JgCokp8T/Nww6LyxjnHeAIAsMAEAAKCFmAAAANBCTAAAAGghJgAAALQQEwAAAFqICQAAAC3EBAAAgBZiAgAAQAsxAQAAoIWYAAAA0EJMAAAAaCEmAAAAtBATAAAAWogJAAAALcQEAACAFmICAABACzEBAACghZgAAADQQkwAAABoISYAAAC0EBMAAABaiAkAAAAtxAQAAIAWYgIAAEALMQEAAKCFmAAAANBCTAAAAGghJgAAALQQEwAAAFqICQAAAC3EBAAAgBZiAgAAQAsxAQAAoIWYAAAA0EJMAAAAaCEmAAAAtBATAAAAWogJAAAALcQEAACAFmICAABACzEBAACghZgAAADQQkwAAABoISYAAAC0EBMAAABaiAkAAAAtxAQAAIAWYgIAAEALMQEAAKCFmAAAANBCTAAAAGghJgAAALQQEwAAAFqICQAAAC3EBAAAgBZiAgAAQAsxAQAAoIWYAAAA0EJMAAAAaCEmAAAAtBATAAAAWogJAAAALcQEAACAFmICAABACzEBAACghZgAAADQQkwAAABoISYAAAC0EBMAAABaiAkAAAAtxAQAAIAWYgIAAEALMQEAAKCFmAAAANBCTAAAAGghJgAAALQQEwAAAFqICQAAAC3EBAAAgBZiAgAAQAsxAQAAoIWYAAAA0EJMAAAAaCEmAAAAtBATAAAAWogJAAAALcQEAACAFmICAABACy1k+i/+MgsF1woAAGaZYfov/jIzgmsFAABdHjX9l/+j4VUCAIC/c73pJwA/C68SAAD8ndNMPwE4LbxKAADwd3Yy/QRgp/AqAQDA31mgyOOm+/J/wngDAAAAidNNNwE4PUF9AACgj5cU+aul//J/tsiqCeoDAAADnGzpJwAnJ6kMAAAM5M8C3GXpvvzvmvW/CQAAxF5uaR4IfLLIuolqAgAAQ9imyFMW9+X/1Kz/DQAAkJktizxk1X/5PzTr3w0AADLlT+dXuUzw9cYT/wAA1MIcRfYrcp+N/8V/36x/xxyJ/3YAADCh+YvsZaNdEbh+1v/P/IK/FwAAVGyZIrsUObrIOUUumpVzZv1nu8z6ZwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAQMv8P9Il/JHnzerxAAAAAElFTkSuQmCC'
$iconBytes = [Convert]::FromBase64String($iconBase64)
$stream          = [System.IO.MemoryStream]::new($iconBytes, 0, $iconBytes.Length)
$Form.Icon       = [System.Drawing.Icon]::FromHandle(([System.Drawing.Bitmap]::new($stream).GetHIcon()))



#Nagłówek (Tytuł "Badanie drożności sieciowej")   _______________________
$Button_top                         = New-Object system.Windows.Forms.Button
$Button_top.text                    = "Badanie drożności sieciowej"
$Button_top.width                   = 760
$Button_top.height                  = 93
$Button_top.location                = New-Object System.Drawing.Point(50,20)
$Button_top.Font                    = New-Object System.Drawing.Font('Microsoft Sans Serif',20,[System.Drawing.FontStyle]([System.Drawing.FontStyle]::Bold))
$Button_top.ForeColor               = [System.Drawing.ColorTranslator]::FromHtml("#ffffff")
$Button_top.BackColor               = [System.Drawing.ColorTranslator]::FromHtml("#0099df")


#Panel zakładek   _________________________
$TabPanel = New-object System.Windows.Forms.TabControl 
$TabPanel.Size = "830,585" 
$TabPanel.Location = "30,150"
$TabPanel.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",12,[System.Drawing.FontStyle]::Regular) 
$Form.Controls.Add($TabPanel)



#Tab1 (Sprawdzanie portu lokalnie)  __________________________________
$Tab1 = New-object System.Windows.Forms.Tabpage
$Tab1.DataBindings.DefaultDataSourceUpdateMode = 0 
$Tab1.UseVisualStyleBackColor = $True 
$Tab1.Name = "Tab1" 
$Tab1.Text = "Sprawdzanie portu lokalnie”
$Tab1.Font = New-Object System.Drawing.Font("Microsoft Sans Serif",12,[System.Drawing.FontStyle]::Regular)
$TabPanel.Controls.Add($Tab1)


#Napis "Port:"
$Label1 = New-Object System.Windows.Forms.Label
$Label1.Text = "Port:"
$Label1.AutoSize = $True
$Label1.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Bold)
$Label1.Location = New-Object System.Drawing.Point(20,30) 
$Tab1.Controls.Add($Label1)


#Lista rozwijana (Sprawdzanie portu lokalnie)________________
$ComboBox1                       = New-Object system.Windows.Forms.ComboBox
$ComboBox1.text                  = "Wybierz port"
$ComboBox1.width                 = 550
$ComboBox1.height                = 44
$ComboBox1.location              = New-Object System.Drawing.Point(80,29)
$ComboBox1.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$ComboBox1.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList;


# dodanie elementów do listy rozwijanej (Sprawdzanie portu lokalnie)
foreach($port in $ports.Keys){
    $ComboBox1.Items.Add($port) | Out-Null
}

# button "Test" (Sprawdzanie portu lokalnie)
$buttonTest = New-Object Windows.Forms.Button
$buttonTest.Location = New-Object Drawing.Point(660, 29)
$buttonTest.Text = "Test"
$buttonTest.Add_Click({
    if($ComboBox1.SelectedItem -ne "Inny"){
        $TextBox3.Text = "Sprawdzanie portu ..."}
    $TextBox3.Text = Option1 -port_name $ComboBox1.SelectedItem
})

# okienko wynikowe - tekstowe (Sprawdzanie portu lokalnie)
$TextBox3 = New-Object System.Windows.Forms.TextBox
$TextBox3.Multiline = $True
$TextBox3.ScrollBars = "Vertical"
$TextBox3.Location = New-Object System.Drawing.Point(50, 80)
$TextBox3.Size = New-Object System.Drawing.Size(700, 440)
$TextBox3.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]::Regular)
$TextBox3.ReadOnly = $True

$Tab1.Controls.Add($TextBox3)
$Tab1.Controls.Add($comboBox1)
$Tab1.Controls.Add($buttonTest)







#Tab2 (Sprawdzanie portu zdalnie)____________________________________________________________________
$Tab2 = New-object System.Windows.Forms.Tabpage
$Tab2.DataBindings.DefaultDataSourceUpdateMode = 0 
$Tab2.UseVisualStyleBackColor = $True 
$Tab2.Name = "Tab2" 
$Tab2.Text = "Sprawdzanie portu zdalnie” 
$TabPanel.Controls.Add($Tab2)


#Napis "Port" (Sprawdzanie portu zdalnie)
$Label2 = New-Object System.Windows.Forms.Label
$Label2.Text = "Port:"
$Label2.AutoSize = $True
$Label2.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Bold)
$Label2.Location = New-Object System.Drawing.Point(20,30) 
$Tab2.Controls.Add($Label2)


#Lista rozwijana (Sprawdzanie portu zdalnie)________________
$ComboBox2                       = New-Object system.Windows.Forms.ComboBox
$ComboBox2.text                  = "Wybierz port"
$ComboBox2.width                 = 550
$ComboBox2.height                = 44
$ComboBox2.location              = New-Object System.Drawing.Point(80,29)
$ComboBox2.Font                  = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$ComboBox2.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList;


# dodanie elementów do listy rozwijanej (Sprawdzanie portu zdalnie)
foreach($port in $ports.Keys){
    $ComboBox2.Items.Add($port) | Out-Null
}


# button "Test2" (Sprawdzanie portu zdalnie)
$buttonTest2 = New-Object Windows.Forms.Button
$buttonTest2.Location = New-Object Drawing.Point(660, 29)
$buttonTest2.Text = "Test"
$buttonTest2.Add_Click({
    if($ComboBox2.SelectedItem -ne "Inny"){
        $TextBox4.Text = "Sprawdzanie portu ..."}
    if($textBox1.Text -ne "Wprowadź adres"){
        $TextBox4.Text = Option1 -computer_name $textBox1.Text -port_name $ComboBox2.SelectedItem
    }
    else{
        $TextBox4.Text = Option1 -port_name $ComboBox2.SelectedItem
    }
})


# okienko wynikowe - tekstowe (Sprawdzanie portu zdalnie)
$TextBox4 = New-Object System.Windows.Forms.TextBox
$TextBox4.Multiline = $True
$TextBox4.ScrollBars = "Vertical"
$TextBox4.Location = New-Object System.Drawing.Point(25, 110)
$TextBox4.Size = New-Object System.Drawing.Size(460, 410)
$TextBox4.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]::Regular)
$TextBox4.ReadOnly = $True

#Panel adresów
$panel0 = New-Object Windows.Forms.Panel
$panel0.Size = New-Object Drawing.Size(290, 370)
$panel0.Location = New-Object Drawing.Point(510, 130)
$panel0.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#CCCCCC")
$panel0.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

#Spis paczek adesów
$label1_panel0 = New-Object System.Windows.Forms.Label
$label1_panel0.Text = "Lista paczek adresów:"
$label1_panel0.AutoSize = $True
$label1_panel0.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Bold)
#$label1_panel0.ForeColor = [System.Drawing.Color]::White
$label1_panel0.Location = New-Object System.Drawing.Point(20,12) 
$panel0.Controls.Add($label1_panel0)

#Spis paczek adesów
$label2_panel0 = New-Object System.Windows.Forms.Label
$label2_panel0.Text = "Paczka Windows Defender Azure AD`r`n--------------------------------------------------`r`n• eu-v20.events.data.microsoft.com`r`n• winatp-gw-neu.microsoft.com`r`n• winatp-gw-weu.microsoft.com`r`n• winatp-gw-neu3.microsoft.com`r`n•  winatp-gw-weu3.microsoft.com"
$label2_panel0.AutoSize = $True
$label2_panel0.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]::regular)
#$label2_panel0.ForeColor = [System.Drawing.Color]::White
$label2_panel0.Location = New-Object System.Drawing.Point(20,50) 
$panel0.Controls.Add($label2_panel0)

$label3_panel0 = New-Object System.Windows.Forms.Label
$label3_panel0.Text = "Paczka Kontrolery Domeny`r`n--------------------------------------------------`r`n• ad1`r`n• ad2`r`n•  ad3"
$label3_panel0.AutoSize = $True
$label3_panel0.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]::regular)
#$label2_panel0.ForeColor = [System.Drawing.Color]::White
$label3_panel0.Location = New-Object System.Drawing.Point(20,190) 
$panel0.Controls.Add($label3_panel0)


$Tab2.Controls.Add($Panel0)
$Tab2.Controls.Add($TextBox4)
$Tab2.Controls.Add($comboBox2)
$Tab2.Controls.Add($buttonTest2)



#Pole do wprowadzenia adresu IP (Sprawdzanie portu zdalnie)_________________________________________
$textBox1                        = New-Object System.Windows.Forms.TextBox
$textBox1.Location               = New-Object System.Drawing.Point(180,70)
$textBox1.Size                   = New-Object System.Drawing.Size(300,50)
$textBox1.Multiline              = $false
$textBox1.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$textBox1.ReadOnly               = $false
$textBox1.Text = "Wprowadź adres"
$Tab2.Controls.Add($textBox1)


# Obsługa zdarzenia "Enter" dla pola tekstowego $textBox1
$textBox1.Add_Enter({
    if ($textBox1.Text -eq "Wprowadź adres") {
        $textBox1.Text = ""
    }
})


# Obsługa zdarzenia "Leave" dla pola tekstowego $IP_Tab2
$textBox1.Add_Leave({
    if ([string]::IsNullOrWhiteSpace($textBox1.Text)) {
        $textBox1.Text = "Wprowadź adres"
    }
})


#Napis "Adres IP / Nazwa:" (Sprawdzanie portu zdalnie)
$Label3 = New-Object System.Windows.Forms.Label
$Label3.Text = "Adres IP / Nazwa:"
$Label3.AutoSize = $True
$Label3.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Bold)
$Label3.Location = New-Object System.Drawing.Point(20,70) 
$Tab2.Controls.Add($Label3)



#Tab3 (Lista aktywnych połączeń)  __________________________________
$Tab3 = New-object System.Windows.Forms.Tabpage
$Tab3.DataBindings.DefaultDataSourceUpdateMode = 0 
$Tab3.UseVisualStyleBackColor = $True 
$Tab3.Name = "Tab3" 
$Tab3.Text = "Lista aktywnych połączeń” 
$TabPanel.Controls.Add($Tab3)


#Pole wynikowe (Lista aktywnych połączeń)
$TextBox2 = New-Object System.Windows.Forms.TextBox
$TextBox2.Multiline = $True
$TextBox2.ScrollBars = "Vertical"
$TextBox2.Location = New-Object System.Drawing.Point(50, 65)
$TextBox2.Size = New-Object System.Drawing.Size(700, 450)
$TextBox2.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]::Regular)
$TextBox2.ReadOnly = $True
$Tab3.Controls.Add($TextBox2) 




# button "Run netstat" (Lista aktywnych połączeń)
$buttonNetstat = New-Object System.Windows.Forms.Button
$buttonNetstat.Location = New-Object System.Drawing.Point(50, 20)
$buttonNetstat.Size = New-Object System.Drawing.Size(150, 30)
$buttonNetstat.Text = "Run netstat"
$buttonNetstat.Add_Click({ $TextBox2.Text = "Lista aktywnych połączeń:" +[Environment]::NewLine
UpdateTextBox2 })
$Tab3.Controls.Add($buttonNetstat)


#Tab4 (Historia)  __________________________________
$Tab4 = New-object System.Windows.Forms.Tabpage
$Tab4.DataBindings.DefaultDataSourceUpdateMode = 0 
$Tab4.UseVisualStyleBackColor = $True 
$Tab4.Name = "Tab4" 
$Tab4.Text = "Historia” 
$TabPanel.Controls.Add($Tab4)


#Pole do wprowadzenia ścieżki (Historia)
$textBox4_1                        = New-Object System.Windows.Forms.TextBox
$textBox4_1.Location               = New-Object System.Drawing.Point(110,30)
$textBox4_1.Size                   = New-Object System.Drawing.Size(430,50)
$textBox4_1.Multiline              = $false
$textBox4_1.Font                   = New-Object System.Drawing.Font('Microsoft Sans Serif',10)
$textBox4_1.ReadOnly               = $false

#Domyślnie wprowadzana ścieżka na pulpit użytkownika (Historia)
$desktopPath = [Environment]::GetFolderPath("Desktop")
$path = Join-Path $desktopPath "plik_wynikowy.txt"

$textBox4_1.Text = $path
$Tab4.Controls.Add($textBox4_1)


#Napis "Ścieżka:" (Historia)
$Label4_1 = New-Object System.Windows.Forms.Label
$Label4_1.Text = "Ścieżka: "
$Label4_1.AutoSize = $True
$Label4_1.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Bold)
$Label4_1.Location = New-Object System.Drawing.Point(20,30) 
$Tab4.Controls.Add($Label4_1)


#Button "Wczytaj" (Historia)
$buttonWczytaj = New-Object Windows.Forms.Button
$buttonWczytaj.Location = New-Object Drawing.Point(580, 27)
$buttonWczytaj.Size = New-Object System.Drawing.Size(80, 30)
$buttonWczytaj.Text = "Wczytaj"
$buttonWczytaj.Add_Click({
    if (Test-Path $textBox4_1.Text) {
        $lista2 = Get-Content -Path $textBox4_1.Text -Raw | Out-String
    }
    $textBox4_2.Text = $lista2 #| Out-String
})


#Button "Zapisz" (Historia)
$buttonZapisz = New-Object Windows.Forms.Button
$buttonZapisz.Location = New-Object Drawing.Point(680, 27)
$buttonZapisz.Size = New-Object System.Drawing.Size(80, 30)
$buttonZapisz.Text = "Zapisz"
$buttonZapisz.Add_Click({
    $data = Get-Date -Format "dd/MM/yyyy  HH:mm " 
    $data_3 = "-------------------------------------------" + [Environment]::NewLine
    $data_2 = $data_3 + $data.ToString() + [Environment]::NewLine +$data_3
    if (Test-Path $textBox4_1.Text){
    $content = (Get-Content -Path $path -Raw)
    }
    $data_2 + $lista + $content | Set-Content  -Path $textBox4_1.Text
})


#Pole wynikowe (Historia)
$TextBox4_2 = New-Object System.Windows.Forms.TextBox
$TextBox4_2.Multiline = $True
$TextBox4_2.ScrollBars = "Vertical"
$TextBox4_2.Location = New-Object System.Drawing.Point(50, 80)
$TextBox4_2.Size = New-Object System.Drawing.Size(700, 440)
$TextBox4_2.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 10, [System.Drawing.FontStyle]::Regular)
$TextBox4_2.ReadOnly = $True

$Tab4.Controls.Add($TextBox4_2)
$Tab4.Controls.Add($buttonWczytaj)
$Tab4.Controls.Add($buttonZapisz)




#Tab5  (Pomoc)   __________________________________
$Tab5 = New-object System.Windows.Forms.Tabpage
$Tab5.DataBindings.DefaultDataSourceUpdateMode = 0 
$Tab5.UseVisualStyleBackColor = $True 
$Tab5.Name = "Tab5" 
$Tab5.Text = "Pomoc” 
$TabPanel.Controls.Add($Tab5)



#PanelMain - Główny panel (Pomoc) __________________________________________
$PanelMain = New-Object Windows.Forms.Panel
$PanelMain.Size = New-Object Drawing.Size(815, 500)
$PanelMain.Location = New-Object Drawing.Point(4, 20)
$PanelMain.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#f8f8f8")
$PanelMain.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$PanelMain.BorderStyle
$PanelMain.AutoScroll = $true
$Tab5.Controls.Add($PanelMain)




#Panel "Sprawdzanie portu lokalnie" (Pomoc) __________________________________________
$panel1 = New-Object Windows.Forms.Panel
$panel1.Size = New-Object Drawing.Size(750, 210)
$panel1.Location = New-Object Drawing.Point(23, 25)
$panel1.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#e6e6e6")
$panel1.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$panel1.BorderStyle
$PanelMain.Controls.Add($panel1)

#Napis "Sprawdzanie portu lokalnie" (Pomoc)
$label1_panel1 = New-Object System.Windows.Forms.Label
$label1_panel1.Text = "Sprawdzanie portu lokalnie"
$label1_panel1.AutoSize = $True
$label1_panel1.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Bold)
$label1_panel1.Location = New-Object System.Drawing.Point(20,12) 
$panel1.Controls.Add($label1_panel1)

#Definicja "Sprawdzanie portu lokalnie" (Pomoc)
$label2_panel1 = New-Object System.Windows.Forms.Label
$label2_panel1.Text = "(umożliwia sprawdzenie wybranych portów lokalnie)"
$label2_panel1.AutoSize = $true
$label2_panel1.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 11, [System.Drawing.FontStyle]::Regular)
$label2_panel1.Location = New-Object System.Drawing.Point(250,12) 
$panel1.Controls.Add($label2_panel1)

#Opis "Sprawdzanie portu lokalnie" (Pomoc)
 $label3_panel1 = New-Object System.Windows.Forms.Label
 $label3_panel1.Text ="Po wciśnięciu przycisku 'Test' nastąpi wykonanie funkcji oraz wyświetlenie wyników w polu.`r`nUżytkownik może wybrać port z listy lub wprowadzić port ręcznie po wybraniu opcji 'Inny'."
 $label3_panel1.AutoSize = $true
 $label3_panel1.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Regular)
 $label3_panel1.Location = New-Object System.Drawing.Point(20,50) 
 $panel1.Controls.Add($label3_panel1)
  
#Opis2 "Sprawdzanie portu lokalnie" (Pomoc)
$label4_panel1 = New-Object System.Windows.Forms.Label
 $listItems ="Opcja 'Inny' posiada 4 możliwości wprowadzania:", 
 "• Jeden port : Pozwala na wprowadzenie jednego dowolnego portu",
 "• Lista portów : Pozwala na wprowadzenie dowolnej liczby portów. (np. 53,445)",
 "• Zakres portów : Pozwala na wprowadzenie dowolnego zakresu dla portów (np. 80-88) ",
 "• Na podstawie wzorca *: w miejscu gwiazdki wprowadza wszystkie możliwe kombinacje (np. 12*3)"
$label4_panel1.Text = $listItems -join "`r`n"
$label4_panel1.AutoSize = $true
 $label4_panel1.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Regular)
 $label4_panel1.Location = New-Object System.Drawing.Point(20,100) 
 $panel1.Controls.Add($label4_panel1)




#Panel "Sprawdzanie portu zdalnie" (Pomoc) __________________________________________
$panel2 = New-Object Windows.Forms.Panel
$panel2.Size = New-Object Drawing.Size(750, 200)
$panel2.Location = New-Object Drawing.Point(23, 255)
$panel2.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#e6e6e6")
$panel2.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

#Napis "Sprawdzanie portu lokalnie" (Pomoc)
$label1_panel2 = New-Object System.Windows.Forms.Label
$label1_panel2.Text = "Sprawdzanie portu zdalnie"
$label1_panel2.AutoSize = $True
$label1_panel2.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Bold)
$label1_panel2.Location = New-Object System.Drawing.Point(20,12) 
$panel2.Controls.Add($label1_panel2)

#Definicja "Sprawdzanie portu zdalnie" (Pomoc)
$label2_panel2 = New-Object System.Windows.Forms.Label
$label2_panel2.Text = "(umożliwia sprawdzenie wybranych portów zdalnie)"
$label2_panel2.AutoSize = $true
$label2_panel2.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 11, [System.Drawing.FontStyle]::Regular)
$label2_panel2.Location = New-Object System.Drawing.Point(250,12) 
$panel2.Controls.Add($label2_panel2)

#Opis "Sprawdzanie portu zdalnie" (Pomoc)
$label3_panel2 = New-Object System.Windows.Forms.Label
$label3_panel2.Text = "Po wciśnięciu przycisku 'Test' nastąpi wykonanie funkcji oraz wyświetlenie wyników w polu.`r`nW przypadku pozostawienia pola 'Adres IP' pustego, funkcja zadziała dla localhosta.`r`nUżytkownik może wprowadzić adres IP w formie wzorca (np. 192.168.100.12*).`r`nUżytkownik może podać nazwę paczki lub kilka adresów IP/nazw rozdzielając je przecinkami.`r`n`r`nUżytkownik może wybrać port z listy lub wprowadzić port ręcznie po wybraniu opcji 'Inny'.`r`nSposób działania opcji 'Inny' tak, jak wyżej. "
$label3_panel2.AutoSize = $true
$label3_panel2.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Regular)
$label3_panel2.Location = New-Object System.Drawing.Point(20,50) 
$panel2.Controls.Add($label3_panel2)




#Panel "Lista aktywnych połączeń" (Pomoc) __________________________________________
$panel3 = New-Object Windows.Forms.Panel
$panel3.Size = New-Object Drawing.Size(750, 80)
$panel3.Location = New-Object Drawing.Point(23, 475)
$panel3.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#e6e6e6")
$panel3.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

#Napis "Lista aktywnych połączeń" (Pomoc)
$label1_panel3 = New-Object System.Windows.Forms.Label
$label1_panel3.Text = "Lista aktywnych połączeń"
$label1_panel3.AutoSize = $True
$label1_panel3.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Bold)
$label1_panel3.Location = New-Object System.Drawing.Point(20,12) 
$panel3.Controls.Add($label1_panel3)

#Definicja "Lista aktywnych połączeń" (Pomoc)
$label2_panel3 = New-Object System.Windows.Forms.Label
$label2_panel3.Text = "(umożliwia sprawdzenie wszystkich aktywnych połączeń)"
$label2_panel3.AutoSize = $true
$label2_panel3.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 11, [System.Drawing.FontStyle]::Regular)
$label2_panel3.Location = New-Object System.Drawing.Point(250,12) 
$panel3.Controls.Add($label2_panel3)

#Opis "Lista aktywnych połączeń" (Pomoc)
$label3_panel3 = New-Object System.Windows.Forms.Label
$label3_panel3.Text = "Po wciśnięciu przycisku 'Run netstat' nastąpi wykonanie funkcji oraz wyświetlenie wyników w polu."
$label3_panel3.AutoSize = $true
$label3_panel3.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Regular)
$label3_panel3.Location = New-Object System.Drawing.Point(20,45) 
$panel3.Controls.Add($label3_panel3)


#Panel "Historia" (Pomoc) _____________________________________________
$panel4 = New-Object Windows.Forms.Panel
$panel4.Size = New-Object Drawing.Size(750, 160)
$panel4.Location = New-Object Drawing.Point(23, 575)
$panel4.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#e6e6e6")
$panel4.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

#Napis "Historia" (Pomoc)
$label1_panel4 = New-Object System.Windows.Forms.Label
$label1_panel4.Text = "Historia"
$label1_panel4.AutoSize = $True
$label1_panel4.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Bold)
$label1_panel4.Location = New-Object System.Drawing.Point(20,12) 
$panel4.Controls.Add($label1_panel4)

#Definicja "Historia" (Pomoc)
$label2_panel4 = New-Object System.Windows.Forms.Label
$label2_panel4.Text = "(umożliwia zapis oraz wczytanie historii)"
$label2_panel4.AutoSize = $true
$label2_panel4.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 11, [System.Drawing.FontStyle]::Regular)
$label2_panel4.Location = New-Object System.Drawing.Point(100,12) 
$panel4.Controls.Add($label2_panel4)

#Opis "Historia" (Pomoc)
$label3_panel4 = New-Object System.Windows.Forms.Label
$label3_panel4.Text = "W pole 'Ścieżka' - należy wprowadzić ścieżkę miejsca, w którym chcemy zapisać lub wczytać plik.`r`nŚcieżkę należy wprowadzić bez znaków `"...`".`r`n`r`nPrzycisk 'Wczytaj' - wczytuje wpisaną ścieżkę i wypisuje wyniki w polu tekstowym.`r`nPrzycisk 'Zapisz' - zapisuje wyniki do pliku tekstowego. "
$label3_panel4.AutoSize = $true
$label3_panel4.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Regular)
$label3_panel4.Location = New-Object System.Drawing.Point(20,50) 
$panel4.Controls.Add($label3_panel4)

#Panel "Paczki portów" (Pomoc) _____________________________________________
$panel5 = New-Object Windows.Forms.Panel
$panel5.Size = New-Object Drawing.Size(750, 640)
$panel5.Location = New-Object Drawing.Point(23, 755)
$panel5.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#e6e6e6")
$panel5.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle

#Napis "Paczki portów" (Pomoc)
$label1_panel5 = New-Object System.Windows.Forms.Label
$label1_panel5.Text = "Paczki portów"
$label1_panel5.AutoSize = $True
$label1_panel5.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Bold)
$label1_panel5.Location = New-Object System.Drawing.Point(20,12) 
$panel5.Controls.Add($label1_panel5)

#Definicja "Paczki portów" (Pomoc)
$label2_panel5 = New-Object System.Windows.Forms.Label
$label2_panel5.Text = "(spis zawartości paczek)"
$label2_panel5.AutoSize = $true
$label2_panel5.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 11, [System.Drawing.FontStyle]::Regular)
$label2_panel5.Location = New-Object System.Drawing.Point(140,12) 
$panel5.Controls.Add($label2_panel5)


#Opis "Paczki portów" (Pomoc)
#Paczka 'AD DC Ports'
$label3_panel5 = New-Object System.Windows.Forms.Label
$label3_panel5.Text = "Paczka 'AD DC Ports':`n• 53 (DNS)`n• 88 (Kerberos)`n• 135 (RPC)`n• 139 (NetBIOS Session Service)`n• 389 (DC Locator, LDAP)`n• 445 (SMB)`n• 464 (Kerberos Password V5)`n• 636 (LDAP SSL)`n• 3268 (Global Catalog)`n• 3269 (Global Catalog)`n"
$label3_panel5.AutoSize = $true
$label3_panel5.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Regular)
$label3_panel5.Location = New-Object System.Drawing.Point(20,50) 
$panel5.Controls.Add($label3_panel5)

#Paczka 'AD DC Communication Ports'
$label4_panel5 = New-Object System.Windows.Forms.Label
$label4_panel5.Text = "Paczka 'AD DC Communication Ports':`n• 135 (RPC)`n• 137 (NetBIOS Name Service)`n• 139 (NetBIOS Session Service)`n• 389 (LDAP)`n• 636 (LDAP SSL)`n• 445 (SMB)`n• 1512 (WINS Resolution)`n• 42 (WINS Replication)`n"
$label4_panel5.AutoSize = $true
$label4_panel5.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Regular)
$label4_panel5.Location = New-Object System.Drawing.Point(350,50) 
$panel5.Controls.Add($label4_panel5)

#Paczka 'DFSM'
$label5_panel5 = New-Object System.Windows.Forms.Label
$label5_panel5.Text = "Paczka 'DFSM':`n• 139 (NetBIOS Session Service)`n• 389 (LDAP Server)`n• 445 (SMB)`n• 135 (RPC)`n"
$label5_panel5.AutoSize = $true
$label5_panel5.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Regular)
$label5_panel5.Location = New-Object System.Drawing.Point(20,280) 
$panel5.Controls.Add($label5_panel5)

#Paczka 'AD Authentication Ports'
$label6_panel5 = New-Object System.Windows.Forms.Label
$label6_panel5.Text = "Paczka 'AD Authentication Ports':`n• 389 (LDAP)`n• 53 (DNS)`n• 88 (Kerberos)`n• 445 (SMB)`n"
$label6_panel5.AutoSize = $true
$label6_panel5.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Regular)
$label6_panel5.Location = New-Object System.Drawing.Point(350,280) 
$panel5.Controls.Add($label6_panel5)

#Paczka Linux
$label5_panel5 = New-Object System.Windows.Forms.Label
$label5_panel5.Text = "Paczka Linux:`n• 22 (SSH)`n• 80 (HTTP)`n• 443 (HTTPS)`n• 25 (SMTP)`n• 53 (DNS)`n• 21 (FTP)`n• 3306 (MySQL)`n• 5432 (PostgreSQL)`n• 6379 (Redis)`n• 27017 (MongoDB)`n"
$label5_panel5.AutoSize = $true
$label5_panel5.Font = New-Object System.Drawing.Font('Microsoft Sans Serif', 12, [System.Drawing.FontStyle]::Regular)
$label5_panel5.Location = New-Object System.Drawing.Point(20,400) 
$panel5.Controls.Add($label5_panel5)





#Margines_bottom (transparent)____________________________________________
$panel6 = New-Object Windows.Forms.Panel
$panel6.Size = New-Object Drawing.Size(750, 85)
$panel6.Location = New-Object Drawing.Point(20, 1335)
$panel6.BackColor = [System.Drawing.ColorTranslator]::FromHtml("#f8f8f8")
$panel6.BorderStyle = [System.Windows.Forms.BorderStyle]::none

$PanelMain.Controls.Add($panel1)
$PanelMain.Controls.Add($panel2)
$PanelMain.Controls.Add($panel3)
$PanelMain.Controls.Add($panel4)
$PanelMain.Controls.Add($panel5)
$PanelMain.Controls.Add($panel6)


# Initlize the form
$Form.controls.AddRange(@($Button_top))

Clear-Host
$Form.Add_Shown({$Form.Activate()})
[void] $Form.ShowDialog()

$stream.Dispose()
$Form.Dispose()

