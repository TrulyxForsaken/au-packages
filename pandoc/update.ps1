import-module au

$releases = 'https://github.com/jgm/pandoc/releases'

function global:au_SearchReplace() {
    @{
        ".\tools\chocolateyInstall.ps1" = @{
            "(^[$]url\s*=\s*)('.*')"      = "`$1'$($Latest.URL)'"
            "(^[$]checksum\s*=\s*)('.*')" = "`$1'$($Latest.Checksum32)'"
        }
    }
}

function global:au_GetLatest() {
    $download_page = Invoke-WebRequest -Uri $releases

    $re  = '/pandoc-(.+?)-windows.msi'
    $url = $download_page.links | ? href -match $re | select -First 1 -expand href
    $url = 'https://github.com' + $url

    $version = $Matches[1] -replace '-.+$'

    return @{ URL = $url; Version = $version }
}


Update-Package -ChecksumFor 32
