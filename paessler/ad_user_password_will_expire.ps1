Import-Module ActiveDirectory

#you could add - filters, a OU limitation or a server against whom this would be executed.. see Get-ADUser options for more details

#all locked users that aren't disabled or expired
$PasswordWillExpirein7Days=Get-ADUser -filter {Enabled -eq $True -and PasswordNeverExpires -eq $False} –Properties "DisplayName", "mail", "msDS-UserPasswordExpiryTimeComputed" | where { 
$diff = New-TimeSpan ([datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")) (Get-Date)
$diff.Days -le 7 -and $diff.Days -ge 0
} | select "DisplayName","mail",@{Name="ExpiryDate";Expression={[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}



If ($PasswordWillExpirein7Days.count -eq $null -and $PasswordWillExpirein7Days -eq $null){
    $cntPasswordWillExpirein7Days=0
}Elseif ($PasswordWillExpirein7Days.count -eq $null -and $PasswordWillExpirein7Days -ne $null){
    $cntPasswordWillExpirein7Days=1
}Else{
    $cntPasswordWillExpirein7Days=@($PasswordWillExpirein7Days.count)
}

$userlistnames=(($PasswordWillExpirein7Days | select "DisplayName" | ConvertTo-Csv -NoTypeInformation | select -skip 1 ) -join ", ").replace("""","") 
#echo $userlistnames
$XML += "<prtg>"
$XML += "<result>" 
$XML += "<channel>Passwort will expire in 7 days</channel>" 
$XML += "<value>$cntPasswordWillExpirein7Days</value>" 
$XML += "</result>"
$XML += "<text>$userlistnames</text>" 
$XML += "</prtg>"

Function WriteXmlToScreen ([xml]$xml)
{
    $StringWriter = New-Object System.IO.StringWriter;
    $XmlWriter = New-Object System.Xml.XmlTextWriter $StringWriter;
    $XmlWriter.Formatting = "indented";
    $xml.WriteTo($XmlWriter);
    $XmlWriter.Flush();
    $StringWriter.Flush();
    Write-Output $StringWriter.ToString();
}

WriteXmlToScreen $XML