param(
    [string]$scriptPath = $(throw "The script path should be specified."),
    [string]$projectPath = "c:\projects",
    [string]$accountName = $(throw "An account name should be specified."),
    [string]$projectToDeploy = $(throw "The project name should be specified."),
    [string]$branchToDeploy = "master",
    [string[]]$artifactsToDeploy = @()
)

$currentDir = $pwd

$currentProjectSlug = $env:APPVEYOR_PROJECT_SLUG
$projectDir = Join-Path $projectPath $currentProjectSlug

try
{
    $powershellScriptPath = (Join-Path $scriptPath "src\ps")
    
    # Download the VCS info and version files
    "Downloading the VCS info and version files ..."
    $vcsInfoFile = "build\temp\vcs.info.json"
    $versionFile = "build\temp\semantic_version.json"
    & $powershellScriptPath\appveyor-download-artifacts.ps1 -accountName $accountName -projectToDeploy $projectToDeploy -branchToDeploy $branchToDeploy -downloadPath $projectDir -filesToDownload $vcsInfoFile,$versionFile
    
    # Restore the GIT workspace to the given revision
    "Restoring workspace to the correct revision ..."
    & $powershellScriptPath\git-checkout-from-json.ps1 -gitInfo (Join-Path $projectDir $vcsInfoFile) -workspace $projectDir
    
    # Read the version file and build the paths
    $versionFileContents = $text = [IO.File]::ReadAllText((Join-Path $projectDir $versionFile))
    $versionComplete = ConvertFrom-Json $versionFileContents
    $version = $versionComplete.GitHubFlowVersion_SemVer
    $version
    
    # Mangle the download paths in case they have a ${version} in their path
    "Parsing artifact paths ..."
    $artifactsToDeployExpanded = @()
    foreach($artifact in $artifactsToDeploy)
    {
        $expandedPath = $artifact -replace "_#version#_", $version
        $artifactsToDeployExpanded += $expandedPath
        
        "Added $expandedPath to the artifacts list .."
    }
    
    # Download the remaining files
    "Downloading artifacts ..."
    & $powershellScriptPath\appveyor-download-artifacts.ps1 -accountName $accountName -projectToDeploy $projectToDeploy -branchToDeploy $branchToDeploy -downloadPath $projectDir -filesToDownload $artifactsToDeployExpanded
}
finally
{
    sl $currentDir
}