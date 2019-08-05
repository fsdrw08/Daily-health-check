
Function Parse-webForms {
    param(
        [Parameter(Mandatory = $true)]
        [string]$webFormsUri,
        [Parameter(Mandatory = $true)]
        [PSCredential]$Credential
    )
    
    $WebRequest = Invoke-WebRequest $webFormsUri -SessionVariable Session #| Select -ExcludeProperty content

    $LoginForm = $WebRequest.Forms
    $LoginForm.Fields.login_username = $Credential.UserName
    $LoginForm.Fields.login_password = $Credential.GetNetworkCredential().Password
    $WebRequest = Invoke-WebRequest -Uri $webFormsUri -Method $LoginForm.Method -Body $LoginForm.Fields -WebSession $Session

    $BaseUri = $webFormsUri.Substring(0,$webFormsUri.LastIndexOf("/keyword")+1)

    Function Get-webFormsWebRequest {
        Param(
            $BaseWebRequest,
            [string]$OuterText,
            [string]$BaseWebUri,
            $WebSession
        )
        $link = $BaseWebRequest.links | Where-Object {$_.outerText -match $OuterText} | Select-Object href -Unique
        $uri = ($BaseWebUri + $link.href)
        $WebRequest = Invoke-WebRequest -Uri $uri -WebSession $WebSession
        Return $WebRequest
    }

    Function Get-webFormsTable {
        Param(
            $OuterText,
            $WebRequest
        )
        
        Write-Host "$OuterText"
        $Table = ($WebRequest.ParsedHtml.getElementsByTagName("tbody") | Select-Object -Last 1).children |
            ForEach-Object {
                ($_.children | Where-Object { $_.tagName -eq "td" } | Select-Object -ExpandProperty innerText)  -join ","
            } | ConvertFrom-Csv 
        Return $Table
    }
    
    Get-webFormsTable -WebRequest (Get-webFormsWebRequest -BaseWebRequest $WebRequest -OuterText "keyword1"  -BaseWebUri $BaseUri -WebSession $Session) -OuterText "keyword1" | Format-Table -AutoSize -Property * -Wrap

    Get-webFormsTable -WebRequest (Get-webFormsWebRequest -BaseWebRequest $WebRequest -OuterText "keyword2" -BaseWebUri $BaseUri -WebSession $Session) -OuterText "keyword2"| Format-Table -AutoSize -Property * -Wrap
    
    
    $nestedWebRequest = Get-webFormsWebRequest -BaseWebRequest $WebRequest -OuterText "keyword3" -BaseWebUri $BaseUri -WebSession $Session
    
    $nestedTable = Get-webFormsTable  -WebRequest $errorRowWebRequest -OuterText "keyword4"

    $nestedTable | Format-Table -AutoSize -Property * -Wrap

    Function Get-webFormsError {
        param(
        $WebRequest,
        $WebSession,
        $BaseUri,
        $Table
        )
        $errorRows = $Table | Where-Object {$_."No. Errors" -gt 0}
        $errorTable = $Table | Where-Object {$_.status -eq "error"}
        if ($errorRows) {
            foreach ($errorRow in $errorRows) {
                $errorRowLinks = $WebRequest.links | Where-Object {$_.innerText -match $errorRow.Name.trim()} | Select-Object href -Unique
                foreach ($errorRowLink in $errorRowLinks) {
                    $errorRowUri = ($BaseUri + $errorRowLink.href)
                    $errorRowWebRequest = Invoke-WebRequest -Uri $errorRowUri -WebSession $WebSession
                    $errorRowNextTable = ($errorRowWebRequest.ParsedHtml.getElementsByTagName("tbody") | Select-Object -Last 1).children |
                        ForEach-Object {
                            ($_.children | Where-Object { $_.tagName -eq "td" } | Select-Object -ExpandProperty innerText)  -join ","
                        } | ConvertFrom-Csv
                    Get-webFormsError -WebRequest $errorRowWebRequest -WebSession $WebSession -BaseUri $BaseUri -Table $errorRowNextTable
                }
            }
        }
        elseif ($errorTable) {
        <#
            foreach ($errorItem in $errorTable) {
                $errorItemLinks = $WebRequest.links | Where-Object {$_.innerText -match $errorItem.Name.trim()} | Select-Object href -Unique
                foreach ($errorItemLink in $errorItemLinks){
                    $errorItemUri = ($BaseUri + $errorItemLink.href)
                    $errorItemWebRequest = Invoke-WebRequest -Uri $errorItemUri -WebSession $WebSession
                    $errorItemInfo = $errorItemWebRequest.ParsedHtml.getElementsByTagName("td") |`
                        Select-Object -ExpandProperty innerText | Where-Object {$_ -like "*object*"}
                    Write-Host "--------------`r`n$errorItemUri"
                    $errorItemInfo | Select-Object -Index 3 #($errorItemInfo.length - 8)
                    Write-Host "`r`n"
                }
            }
            #>
            Return $errorTable
        }
    }

    Get-webFormsError -WebRequest $nestedWebRequest -WebSession $Session -BaseUri $BaseUri -Table $nestedTable  | OGV
    
    
    $settingsLink = $WebRequest.links | Where-Object {$_.outerText -match "Settings"}
    $settingsUri = ($BaseUri + $settingsLink.href)
    $settingsWebRequest = Invoke-WebRequest -Uri $settingsUri -WebSession $Session

    Get-webFormsTable -WebRequest (Get-webFormsWebRequest -BaseWebRequest $settingsWebRequest -OuterText "keyword5" -BaseWebUri $BaseUri -WebSession $Session) -OuterText "keyword5"| Format-Table -AutoSize -Property * -Wrap
    
            
}
