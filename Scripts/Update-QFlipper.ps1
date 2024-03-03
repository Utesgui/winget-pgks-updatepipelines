if ($Env:GITHUB_TOKEN) {
    Write-Host 'GITHUB_TOKEN detected'
    $gitToken = ${Env:GITHUB_TOKEN}
}
else {
    Write-Host 'GITHUB_TOKEN not detected'
    exit 1
}

$wingetPackage = "FlipperDevicesInc.qFlipper"
$versionDirectoryUrl = "https://update.flipperzero.one/qFlipper/directory.json"


$versionDirectory = Invoke-RestMethod -Uri $versionDirectoryUrl 
$latestVersionDirectory = ($versionDirectory.channels | Where-Object id -eq "release").versions.version
$latestVersionUrl = (($versionDirectory.channels | Where-Object id -eq "release").versions.files | Where-Object { ($_.target -eq "windows/amd64") -and ($_.type -eq "installer") }).url

$prMessage = "Update version: $wingetPackage version $latestVersionDirectory"

$foundMessage, $textVersion, $separator, $wingetVersions = winget search --id $wingetPackage --source winget --versions

# Check for existing versions in winget
if ($wingetVersions -contains $latestVersionDirectory) {
    Write-Output "Latest version of $wingetPackage $latestVersionDirectory is already present in winget."
}
else {
    # Check for existing PRs
    $ExistingPRs = gh pr list --search "$($wingetPackage) version $($latestVersionDirectory) in:title draft:false" --state 'all' --json 'title,url' --repo 'microsoft/winget-pkgs' | ConvertFrom-Json

    if ($ExistingPRs.Count -gt 0) {
        Write-Output "$foundMessage"
        $ExistingPRs | ForEach-Object {
            Write-Output "Found existing PR: $($_.title)"
            Write-Output "-> $($_.url)"
        }
    }
    elseif ($wingetVersions -and ($wingetVersions -notmatch $latestVersionDirectory)) {
        gh repo sync $Env:WINGET_PKGS_FORK_REPO -b main
        .\wingetcreate.exe update $wingetPackage -s -v $ver -u "$latestVersionUrl" --prtitle $prMessage -t $gitToken
    }
    else { 
        Write-Output "$foundMessage"
        Write-Output "No existing PRs found. Check why wingetcreate has not run."
    }
}
