param(
    [string]$accountName = $(throw "An account name should be specified."),
    [string]$projectToDeploy = $(throw "The project name should be specified."),
    [string]$branchToDeploy = "master",
    [string]$downloadPath = $(throw "The download path should be specified"),
    [string[]]$filesToDownload = @()
)

$token = $env:AppVeyorApiToken
$headers = @{ "Authorization" = "Bearer $token" }

# Search the project history to find the last successful build of the given project and the given branch
$projectSlug = $projectToDeploy

"Getting build history for $projectToDeploy ..."
$historyUrl = "https://ci.appveyor.com/api/projects/$accountName/$projectSlug/history?recordsNumber=25"
$historyResponse = Invoke-RestMethod -Uri $historyUrl -Headers $headers -Method Get
$projectId = $historyResponse.project.projectId
$builds = $historyResponse.builds

$buildId = 0
$buildVersion = ""
$commitId = ""
foreach($build in $builds)
{
    if (($build.branch -eq $branchToDeploy) -and ($build.status -eq "success"))
    {
        $buildId = $build.buildId
        $buildVersion = $build.version
        $commitId = $build.commitId
        break;
    }
}


"Getting extended information for build $buildVersion (Id: $buildId) ..."
$buildUrl = "https://ci.appveyor.com/api/projects/$accountName/$projectSlug/build/$buildVersion"
$buildResponse = Invoke-RestMethod -Uri $buildUrl -Headers $headers -Method Get

$jobs = $buildResponse.build.jobs
$jobId = ""
foreach($job in $jobs)
{
    if ($job.artifactsCount -gt 0)
    {
        $jobId = $job.jobId
        break;
    }
}

"Downloading artifacts from build $buildVersion (Id: $buildId, job: $jobId) which was executed for commit revision: $commitId ..."
foreach($downloadFile in $filesToDownload)
{
    "Downloading $downloadFile"
    $installPath = Join-Path $downloadPath $downloadFile
    $installDirectory = [IO.Path]::GetDirectoryName($installPath)
    if (!(Test-Path -Path $installDirectory ))
    {
        New-Item -ItemType directory -Path $installDirectory | Out-Null
    }
    
    $downloadUrl = "https://ci.appveyor.com/api/buildjobs/$jobId/artifacts/$downloadFile"
    $downloadResponse = Invoke-RestMethod -Uri $downloadUrl -Headers $headers -Method Get -OutFile $installPath

    "Written data to $installPath"
}

"Script complete"