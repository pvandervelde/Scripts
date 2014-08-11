param(
	[string]$jenkinsDir = $env:JENKINS_HOME,
    [string]$backupDir = $env:WORKSPACE,
    [string]$gitExe = "git"
 )

$ErrorActionPreference = 'Stop'

# copy the files from the jenkins dir
& robocopy $jenkinsDir $backupDir /s /mir /xf "*.log" "*.war" "*.bak" "*.old" /xd "workspace" "builds" "plugins" "updates" "userContent" "war" "jenkins.diagnostics*" ".git" /xj /xjd /xjf

$now = [System.DateTimeOffset]::Now

Set-Location $backupDir

# Don't change the line endings
$currentAutocrlf = & $gitExe config core.autocrlf
try
{
    & $gitExe config core.autocrlf false

    # Stage all the new / updated / deleted files
    $output = & $gitExe add -A 2>&1
    Write-Output $output

    Write-Output "Verifying if any changes were made to the configuration ..."

    $status = & $gitExe status --porcelain 2>&1
    if ($status -ne "")
    {
        Write-Output "Some changes were made to the configuration. Committing changes and pushing to remote ... "

        # Commit the changes
        $output = & $gitExe commit -m "Configuration changes from $now" 2>&1
        Write-Output $output

        # and push to the origin
        $output = & $gitExe push origin master --porcelain
        Write-Output $output
    }
}
finally
{
    & $gitExe config core.autocrlf $currentAutocrlf
}

