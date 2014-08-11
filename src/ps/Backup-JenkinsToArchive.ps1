param(
    [string]$jenkinsDir = $env:JENKINS_HOME,
    [string]$remoteDir = $(throw 'Need a remote directory'),
    [string]$tempDir = [System.IO.Path]::GetTempPath(),
    [string]$7zipDir = "$Env:ProgramW6432\7-Zip"
 )

$ErrorActionPreference = 'Stop'

Write-Output "Copying files from Jenkins directory located at: $jenkinsDir"

# Create a temp dir with a random name
$tempDirName = [System.IO.Path]::GetRandomFileName()
$tempPath = Join-Path $tempDir $tempDirName

$baseDir = New-Item -Path (Split-Path $tempPath) -Name (Split-Path $tempPath -Leaf) -ItemType "directory"
try
{ 
    $jenkinsBackupDir = New-Item -Path $baseDir.FullName -Name 'Jenkins' -ItemType "directory"  

    # copy the files from the jenkins dir
    Write-Output "Copying Jenkins configuration files ..."
    $files = Get-ChildItem $jenkinsDir | Where-Object { ((!($_.Extension -match ".old"))`
            -and (!($_.Extension -match ".log"))`
            -and (!$_.PSIsContainer)) } | Copy-Item -Destination (Join-Path $jenkinsBackupDir.FullName $_.Name) -Verbose

    Write-Output ""
    Write-Output ""
    Write-Output "Copying war directory"
    if (Test-Path (Join-Path $jenkinsDir "war"))
    {
        $files = Get-ChildItem $jenkinsDir | Where-Object { (($_.PSIsContainer)`
            -and ($_.Name -eq "war")) } | Copy-Item -Destination (Join-Path $jenkinsBackupDir.FullName $_.Name) -Container -Recurse -Verbose
    }
    
    Write-Output ""
    Write-Output ""
    Write-Output "Copying userContent directory"
    if (Test-Path (Join-Path $jenkinsDir "userContent"))
    {
        $files = Get-ChildItem $jenkinsDir | Where-Object { (($_.PSIsContainer)`
            -and ($_.Name -eq "userContent")) } | Copy-Item -Destination (Join-Path $jenkinsBackupDir.FullName $_.Name) -Container -Recurse -Verbose
    }
        
    Write-Output ""
    Write-Output ""
    Write-Output "Copying updates directory"
    if (Test-Path (Join-Path $jenkinsDir "updates"))
    {
        $files = Get-ChildItem $jenkinsDir | Where-Object { (($_.PSIsContainer)`
            -and ($_.Name -eq "updates")) } | Copy-Item -Destination (Join-Path $jenkinsBackupDir.FullName $_.Name) -Container -Recurse -Verbose
    }
    
    Write-Output ""
    Write-Output ""
    Write-Output "Copying plugins directory"
    if (Test-Path (Join-Path $jenkinsDir "plugins"))
    {
        $files = Get-ChildItem $jenkinsDir | Where-Object { (($_.PSIsContainer)`
            -and ($_.Name -eq "plugins")) } | Copy-Item -Destination (Join-Path $jenkinsBackupDir.FullName $_.Name) -Container -Recurse -Verbose
    }
    
    Write-Output ""
    Write-Output ""
    Write-Output "Copying fingerprints directory"
    # copy the fingerprints directory
    if (Test-Path (Join-Path $jenkinsDir "fingerprints"))
    {
        $files = Get-ChildItem $jenkinsDir | Where-Object { (($_.PSIsContainer)`
            -and ($_.Name -eq "fingerprints")) } | Copy-Item -Destination (Join-Path $jenkinsBackupDir.FullName $_.Name) -Container -Recurse -Verbose
    }
    
    # foreach project in the jobs directory copy the config file
    $projectDirs = Get-ChildItem (Join-Path $jenkinsDir 'jobs') | Where-Object { ($_.PSIsContainer) }
    foreach($dir in $projectDirs)
    {
        Write-Output ""
        Write-Output ""
        Write-Output "Copying project directory: " + $dir.Name
    
        # Copy the config file, the changes file and the file containing the next build number
        $files = Get-ChildItem $dir.FullName | Where-Object { !($_.Name -match 'workspace') -and !($_.PSIsContainer) }
        foreach($file in $files)
        {
            if ($file -ne $null)
            {
                $fileName = $file.FullName
                $relativePath = $fileName.Substring($fileName.IndexOf($jenkinsDir, [System.StringComparison]::OrdinalIgnoreCase) + $jenkinsDir.Length)
                $newPath = Join-Path $jenkinsBackupDir.FullName $relativePath
                
                if (!(Test-Path (Split-Path $newPath)))
                {
                    New-Item -Path (Split-Path $newPath) -ItemType "directory" | Out-Null
                }

                Copy-Item $file.FullName -Destination $newPath -Verbose
            }
        }
        
        # Copy the Builds directory
        $buildsDir = Get-ChildItem $dir.FullName | Where-Object { (($_.PSIsContainer) -and ($_.Name -eq "builds")) } 
        if (($buildsDir -ne $null) -and (Test-Path $buildsDir))
        {
            $buildsPath = $buildsDir.FullName
            
            $relativePath = $buildsPath.Substring($buildsPath.IndexOf($jenkinsDir, [System.StringComparison]::OrdinalIgnoreCase) + $jenkinsDir.Length)
            $newPath = Join-Path $jenkinsBackupDir.FullName $relativePath
            
            Copy-Item -Path $buildsPath -Destination $newPath -Recurse -Verbose
        }
    }

    Write-Output ""
    Write-Output ""
    Write-Output "Compressing $jenkinsBackupDir to $output"
        
    # Name the zip: JenkinsBackup_<DATE>
    $output = Join-Path $baseDir ("JenkinsBackup_" + [System.DateTime]::Now.ToString("yyyy_MM_dd-HH_mm_ss") + ".7z")
    
    # zip the jenkins temp dir
    $7zipExe = Join-Path $7zipDir "7z.exe"
    & $7zipExe a -t7z $output $jenkinsBackupDir.FullName
    if ($LastExitCode -ne 0)
    {
        throw "Failed to compress the Jenkins backup directory."
    }
    
    # copy the backup to the desired location (fileserver: \Optima\Product\Siren\Development\Jenkins)
    Copy-Item $output -Destination (Join-Path $remoteDir (Split-Path $output -Leaf)) -Verbose -ErrorAction Stop
    
    Write-Output "Backup successful"
}
finally
{
    # Clean up the mess
    if (Test-Path -Path $baseDir.FullName -PathType Container)
    {
        Remove-Item -Path $baseDir -Recurse -Force
    }
}