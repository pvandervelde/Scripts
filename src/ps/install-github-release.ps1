param(
    [string]$installPath = "c:\tools\githubrelease"
)

Add-Type -As System.IO.Compression.FileSystem

# Download the file. Currently there seems to be no way to determine what the latest release is so let just pick one
$url = "https://github.com/aktau/github-release/releases/download/v0.5/windows-amd64-github-release.zip"


$tempDirName = [system.guid]::newguid().tostring()

$tempDir = Join-Path $env:TEMP $tempDirName
new-item -type directory -name $tempDir
set-location $tempDir

$zipFile = Join-Path $tempDir 'github-release.zip'

Try
{
    $webclient = New-Object System.Net.WebClient
    $webclient.DownloadFile($url,$zipFile)

    # Extract the files
    [IO.Compression.ZipFile]::ExtractToDirectory( $zipFile, $tempDir )
    
    if(!(Test-Path -Path $installPath )){
        New-Item -ItemType directory -Path $installPath
    }
    
    Copy-Item (Join-Path $tempDir "bin\windows\amd64") (Join-Path $installPath "github-release.exe")

    # Add to PATH
    # Get the current search path from the environment keys in the registry.
    $OldPath=[environment]::GetEnvironmentVariable("PATH", "User")

    # See if the new Folder is already in the path.
    IF ($ENV:PATH | Select-String -SimpleMatch $installPath)
    { 
        Return 
    }

    # Set the New Path
    $NewPath=$OldPath + ";" + $installPath
    [Environment]::SetEnvironmentVariable("PATH", $NewPath, "User")
}
Finally
{
    If (Test-Path $tempDir){
        Remove-Item $tempDir -Force
    }
}