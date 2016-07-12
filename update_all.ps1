param($Name = $null)
cd $PSScriptRoot

#import-module ..\au -force
if (Test-Path update_vars.ps1) { . ./update_vars.ps1 }

$options = @{
    Timeout = 100
    Push    = $true
    Threads = 10

    #Do not use mail notification, appvayor build will be broken on errors
    # and we will get notifications on broken builds
    Mail = @{
        To       = $Env:mail_user
        Server   = 'smtp.gmail.com'
        UserName = $Env:mail_user
        Password = $Env:mail_pass
        Port     = 587
        EnableSsl= $true
    }

    Gist_ID = $Env:Gist_ID
    Script = { param($Phase, $Info)
        if ($Phase -ne 'END') { return }

        save-runinfo
        save-gist
        git
    }

}

function save-runinfo {
    "Saving run info"
    $Info | Export-CliXML $PSScriptRoot\update_results.xml
}

function save-gist {
    "Saving to gist"
    if (!(gcm gist.bat -ea 0)) { "  Error: No gist.bat found: gem install gist"; return }

    $icon_err= 'https://cdn0.iconfinder.com/data/icons/shift-free/32/Error-128.png'
    $icon_ok= 'http://www.iconsdb.com/icons/preview/tropical-blue/ok-xxl.png'

    $log = @"
# Update-AUPackages

**Time:** $($info.startTime)  
**Packages:** [majkinetor@chocolatey](https://chocolatey.org/profiles/majkinetor)  
**Git repository:** https://github.com/majkinetor/chocolatey

This file is automatically generated by the [update_all.ps1](https://github.com/majkinetor/chocolatey/blob/master/update_all.ps1) script using the [AU module](https://github.com/majkinetor/au).

$(
  if ($Info.error_count.total) { 
    "<img src='$icon_err' width='48'> **LAST RUN HAD $($info.error_count.total) [ERRORS](#errors) !!!**" }
  else {
    "<img src='$icon_ok' width='48'> Last run was OK" }
)

``````
$($Info.stats -join "`n")
$($Info.result | ft | Out-String)
``````

$(
    if ($info.error_count.total) {
        "## Errors`n`n"
        '```'
            $info.error_info
        '```'
    }
)
"@

    $log | gist.bat --filename 'Update-AUPackages.md' --update $Info.Options.Gist_ID
    if ($LastExitCode) { "ERROR: Gist update failed" }
}

function git() {
    $pushed = $Info.results | ? Pushed
    if (!$pushed) { "Git: no updates, skipping"; return }

    pushd $PSScriptRoot

    "`nExecuting git pull"
    git checkout master
    git pull

    "Commiting updated packages to git repository"
    $pushed | % { git add $_.PackageName }
    git commit -m "UPDATE BOT: $($pushed.length) packages updated"

    "`nPushing git"
    git push "https://$Env:github_user:$Env:github_pass@github.com/majkinetor/chocolatey.git"
    popd
}

updateall -Name $Name -Options $options | ft
$global:updateall = Import-CliXML $PSScriptRoot\update_results.xml
if ($updateall.error_count.total) { throw 'Errors during update' }


