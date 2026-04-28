param(
    [Parameter(Mandatory = $true)]
    [string]$InputFile,

    [Parameter(Mandatory = $true)]
    [string]$OutputFile,

    [string]$HttpUrl = $env:NEO4J_HTTP_URL,
    [string]$Database = $env:NEO4J_DATABASE,
    [string]$Username = $env:NEO4J_USERNAME,
    [string]$Password = $env:NEO4J_PASSWORD
)

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$LocalConfig = Join-Path $RepoRoot ".neo4j.local.ps1"
$ExplicitParameters = @{}

foreach ($key in $PSBoundParameters.Keys) {
    $ExplicitParameters[$key] = $PSBoundParameters[$key]
}

if (Test-Path $LocalConfig) {
    . $LocalConfig
}

foreach ($key in $ExplicitParameters.Keys) {
    Set-Variable -Name $key -Value $ExplicitParameters[$key]
}

if ([string]::IsNullOrWhiteSpace($HttpUrl)) {
    $HttpUrl = "http://localhost:7474"
}

if ([string]::IsNullOrWhiteSpace($Database)) {
    $Database = "neo4j"
}

if ([string]::IsNullOrWhiteSpace($Username)) {
    $Username = "neo4j"
}

if ([string]::IsNullOrWhiteSpace($Password)) {
    throw "Neo4j password is missing. Set NEO4J_PASSWORD or create .neo4j.local.ps1 from .neo4j.local.example.ps1."
}

$InputPath = Resolve-Path $InputFile
$OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputFile)
$OutputDir = Split-Path $OutputPath -Parent

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
}

$pair = "$Username`:$Password"
$encodedAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($pair))

$headers = @{
    Authorization = "Basic $encodedAuth"
    "Content-Type" = "application/json; charset=utf-8"
    Accept = "application/json; charset=utf-8"
}

function Remove-CypherComments {
    param([string]$Text)

    return (($Text -split "`r?`n" | Where-Object {
        $_.Trim() -notmatch '^\s*//'
    }) -join "`n").Trim()
}

function Convert-ResultCell {
    param([object]$Cell)

    if ($null -eq $Cell) {
        return ""
    }

    if ($Cell -is [string]) {
        return $Cell
    }

    return ConvertTo-Json -InputObject $Cell -Compress -Depth 30
}

$content = Get-Content $InputPath -Raw -Encoding UTF8

$queries = $content -split ";" |
    ForEach-Object { $_.Trim() } |
    Where-Object {
        (Remove-CypherComments $_) -ne ""
    }

Set-Content -Path $OutputPath -Value "// Neo4j query + result report`n" -Encoding UTF8

$i = 0
foreach ($raw in $queries) {
    $i++
    $q = Remove-CypherComments $raw

    Add-Content $OutputPath "" -Encoding UTF8
    Add-Content $OutputPath "// ==================================================" -Encoding UTF8
    Add-Content $OutputPath "// QUERY $i" -Encoding UTF8
    Add-Content $OutputPath "// ==================================================" -Encoding UTF8
    Add-Content $OutputPath "$raw;" -Encoding UTF8
    Add-Content $OutputPath "" -Encoding UTF8
    Add-Content $OutputPath "// RESULT $i" -Encoding UTF8
    Add-Content $OutputPath "// --------------------------------------------------" -Encoding UTF8

    $body = @{
        statements = @(
            @{
                statement = $q
                resultDataContents = @("row")
            }
        )
    } | ConvertTo-Json -Depth 30 -Compress

    try {
        $response = Invoke-RestMethod `
            -Uri "$HttpUrl/db/$Database/tx/commit" `
            -Method Post `
            -Headers $headers `
            -Body ([Text.Encoding]::UTF8.GetBytes($body))

        if ($response.errors.Count -gt 0) {
            foreach ($err in $response.errors) {
                Add-Content $OutputPath ("// ERROR: " + $err.message) -Encoding UTF8
            }
            continue
        }

        $result = $response.results[0]
        $columns = $result.columns
        Add-Content $OutputPath ("// " + ($columns -join " | ")) -Encoding UTF8

        foreach ($rowObj in $result.data) {
            $rendered = New-Object System.Collections.Generic.List[string]

            foreach ($cell in $rowObj.row) {
                $rendered.Add((Convert-ResultCell $cell))
            }

            Add-Content $OutputPath ("// " + ($rendered -join " | ")) -Encoding UTF8
        }

        if ($result.data.Count -eq 0) {
            Add-Content $OutputPath "// No rows returned" -Encoding UTF8
        }
    }
    catch {
        Add-Content $OutputPath ("// FAILED: " + $_.Exception.Message) -Encoding UTF8
    }
}

Write-Host "Done. Created $OutputPath"
