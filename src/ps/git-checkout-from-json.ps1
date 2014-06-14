param(
    [string]$gitInfo = "c:\temp\git.info.json",
    [string]$workspace = "c:\temp\"
)

$currentDir = $pwd
try
{
    # Read the JSON file. 
    # It is assumed that the JSON file looks like:
    #
    # {
    #     "revision": "<REVISION_SHA>",
    #     "branch": "<BRANCH_NAME>"
    # }
    $text = [IO.File]::ReadAllText($gitInfo)
    $text = $text.Replace([Environment]::NewLine, [String]::Empty)

    $revisionKey = '"revision":'
    $revisionStartIndex = $text.IndexOf($revisionKey)
    
    $count = $text.SubString($revisionStartIndex + $revisionKey.Length).IndexOf(",")
    if ($count -eq -1)
    {
        $revision = $text.SubString($revisionStartIndex + $revisionKey.Length).Trim(' ', ',', '"', '{', '}')
    }
    else
    {
        $revision = $text.SubString($revisionStartIndex + $revisionKey.Length, $count).Trim(' ', ',', '"', '{', '}')
    }

    $branchKey = '"branch":'
    $branchStartIndex = $text.IndexOf($branchKey)
    
    $count = $text.SubString($branchStartIndex + $branchKey.Length).IndexOf(",")
    if ($count -eq -1)
    {
        $branch = $text.SubString($branchStartIndex + $branchKey.Length).Trim(' ', ',', '"', '{', '}')
    }
    else
    {
        $branch = $text.SubString($branchStartIndex + $branchKey.Length, $count).Trim(' ', ',', '"', '{', '}')
    }

    "Switching to branch: $branch at revision: $revision"

    sl $workspace
    & git checkout -q $revision
}
finally
{
    $pwd = $currentDir
}