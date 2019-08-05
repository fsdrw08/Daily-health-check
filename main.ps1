[string]$table = ""

[object]$csv = Import-Csv $table

[string]$plinkPath = ".\PLINK.EXE"

[string]$region = ""

. ".\Invoke-Plink.ps1"
. ".\Parse-WebForms.ps1"

if ($csv) {
    #generate a credential table
    [object]$credentialTable = $csv `
      | Where-Object {($_.Way -match "ssh" -or $_.way -match "HttpRequest") -and $_.Region -eq $region -and $_.Account -ne ""} `
      | Select-Object Account,Hint -Unique `
      | Select-Object Account,Hint,@{n='Credential';e={(Get-Credential -UserName $_.Account -Message ('Hint:' + $_.Hint))}} -Unique

    #execution
    foreach ($task in ($csv | Where-Object {$_.Region -eq $region -and $_.GetAccess -eq "success"})) {
        
        if ((Test-Path $plinkPath) -and $task.Way -eq "ssh" ){
            $credential = ($credentialTable | Where-Object {$_.Account -match $task.Account -and $_.hint -match $task.Hint}).credential
            $sshCredential = New-Object System.Management.Automation.PSCredential (($credential.UserName + '@' + $task.address), $credential.Password)
            #⬇️ need to improve 
            $commands = '"' + [string]$task.command1 + "`n" + [string]$task.command2 + "`n" + [string]$task.command3 + "`n" + [string]$task.command4 + "`n" + [string]$task.command5  + "`n" + [string]$task.command6 + "`n" + [string]$task.command7 + "`n" + [string]$task.command8 +'"'
            
            Invoke-Plink -PlinkPath $plinkPath -Credential $sshCredential -commands $commands
        }
        elseif(!(Test-Path $plinkPath)){
            Write-Host "Please check the plinkpath"
        }
        
        if ($task.Address -like "*address*" -and $task.Way -like "HttpRequest") {
            Parse-webForms -webFormsUri ($task.Address) -Credential (($credentialTable | Where-Object {$_.Account -match $task.Account -and $_.hint -match $task.hint}).Credential)
        }
        #>
        if ($task.Way -like "Browser" -and $task.Address -like "*keywords*") {
            Start-Sleep -Seconds 5
            Start-Process $task.Address
        }
        #>
    }
}
else {Write-Host "The ""$Table"" is not found, Please check the TABLE path"}
