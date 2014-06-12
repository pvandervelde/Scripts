param(
    [string]$installPath = "c:\tools\githubrelease"
)

Add-Type -As System.IO.Compression.FileSystem

# Store the current directory so that we can get back there
$currentDir = $pwd

# Create a temp directory to download the file into and then to unzip it
$tempDirName = [system.guid]::newguid().tostring()
$tempDir = Join-Path $env:TEMP $tempDirName

"Creating temp directory at: $tempDir ..."
New-Item -ItemType directory -Path $tempDir | Out-Null

Try
{
    $zipFile = Join-Path $tempDir 'github-release.zip'

    # Download the file. Currently there seems to be no way to determine what the latest release is so let just pick one
    $url = "https://github.com/aktau/github-release/releases/download/v0.5/windows-amd64-github-release.zip"
    
    "Downloading file from: $url"
    "Saving to: $zipFile"
    "..."
    $webclient = New-Object System.Net.WebClient
    $webclient.DownloadFile($url,$zipFile)

    # Extract the files
    "Extracting $zipFile ..."
    [IO.Compression.ZipFile]::ExtractToDirectory( $zipFile, $tempDir )
    
    # Copy only the executable and put it in a known path
    "Copying github-release.exe to $installPath ..."
    if (!(Test-Path -Path $installPath ))
    {
        New-Item -ItemType directory -Path $installPath | Out-Null
    }
    
    Copy-Item (Join-Path $tempDir "bin\windows\amd64\github-release.exe") (Join-Path $installPath "github-release.exe")

    # Add to user PATH
    "Adding $installDir to the user PATH environment variable ..."
    
    # Get the current search path from the environment keys in the registry.
    $oldPath=[environment]::GetEnvironmentVariable("PATH", "User")

    # See if the new Folder is already in the path.
    if ($oldPath | Select-String -SimpleMatch $installPath)
    { 
        return 
    }

    # Set the New Path
    $newPath=$oldPath + ";" + $installPath
    [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
}
Finally
{
    sl $currentDir
    
    "Removing $tempDir ..."
    if (Test-Path $tempDir)
    {
        Remove-Item $tempDir -Force -Recurse | Out-Null
    }
}

"Script completed"