
param([switch]$gist)

(Get-Content .\MvcMoviewSaturn-unit-tested-tutorial.ps1 -Raw) -replace '(?s)# IGNORE-START.*?# IGNORE-END', '' | Set-Content pass-1.ps1

(Get-Content .\pass-1.ps1 -Raw) -replace "\`$file = '(.*?)'", ("`n---`n" + 'File: `$1`')  | Set-Content pass-1.ps1

(Get-Content .\pass-1.ps1 -Raw) -replace '(?s)\$original_text = @"(.*?)"@', ("Original text: `n" + '```$1```') | Set-Content pass-1.ps1

(Get-Content .\pass-1.ps1 -Raw) -replace '(?s)\$replacement_text = @"(.*?)"@', ("Replacement text: `n" + '```$1```') | Set-Content pass-1.ps1

# (Get-Content .\pass-1.ps1 -Raw) -replace ('(?s)^@"(.*?)"@ \| ' + "Set-Content '(.*?)'"), ('File: `$2`' + "`n`n" + '```$1```')  | Set-Content pass-1.ps1

# (Get-Content .\pass-1.ps1 -Raw) -replace ('(?s)@"(.*?)"@ \| ' + "Set-Content '(.*?)'"), ('File: `$2`' + "`n`n" + '```$1```')  | Set-Content pass-1.ps1

(Get-Content .\pass-1.ps1 -Raw) -replace ('(?sm)^@"(.*?)"@ \| ' + "Set-Content '(.*?)'"), ('File: `$2`' + "`n`n" + '```$1```')  | Set-Content pass-1.ps1

(Get-Content .\pass-1.ps1) | ForEach-Object {

    if     ($_ -match '^# ') { $_ -replace '^# ', '' }
    elseif ($_ -match '^#')  { $_ -replace '^#',  '' }
    elseif ($_ -match "^cmt '") { $_ -replace "^cmt '(.*)'", '$1' }
    elseif ($_ -match '^cmt "') { $_ -replace '^cmt "(.*)"', '$1' }
    elseif ($_ -match '^Edit \$file -Replacing')  { }
    elseif ($_ -match 'IGNORE-LINE-FOR-MARKDOWN') { }
    else { $_ }

} | Set-Content MvcMovieTutorial.md

if ($gist)
{
    $result = gh gist create MvcMovieTutorial.md
    
    Start-Process $result
}

Remove-Item .\pass-1.ps1