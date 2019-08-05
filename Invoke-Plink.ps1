Function Invoke-Plink {
    param(
        [Parameter(Mandatory = $true)]
        #https://stackoverflow.com/questions/26100674/powershell-custom-error-from-parameters
        [ValidateScript(
            {
                if (Test-Path $_ -PathType leaf) {$true}
                else {Throw "The $_ is not found, Please check the plinkpath"}
            }
        )]
        [string]$PlinkPath,
        [Parameter(Mandatory = $true)]
        [PSCredential]$Credential,
        [Parameter(Mandatory = $true)]
        [string]$commands
        )

    $ssh = $Credential.UserName
    $pw  = $Credential.GetNetworkCredential().Password
    #$PlinkPath = '"' + $PlinkPath + '"'
    .$PlinkPath -ssh $ssh -pw $pw $commands
    #for plink0.71, add -no-antispoof 
}
