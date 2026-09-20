param([Parameter(Mandatory = $true)][string]$EvidenceRoot)
$ErrorActionPreference = 'Stop'
$rows = @{}
$unsupported = [Collections.Generic.List[object]]::new()
function Add-Samples([string]$Label, [string]$Case, [int]$Sweep, [double[]]$Samples, [double]$Operations) {
  $key = "$Label/$Case"
  if (!$rows.ContainsKey($key)) {
    $rows[$key] = [ordered]@{ label = $Label; case = $Case; operations = $Operations; sweeps = @{} }
  }
  $rows[$key].sweeps[$Sweep] = $Samples
}
foreach ($label in @('baseline', 'candidate')) {
  foreach ($file in Get-ChildItem (Join-Path $EvidenceRoot $label) -Filter 'sweep-*.stdout.log') {
    if ($file.Name -notmatch '^sweep-(\d+)-(.+)\.stdout\.log$') { continue }
    $sweep = [int]$Matches[1]
    $benchmark = $Matches[2]
    $iterations = 1.0
    foreach ($line in Get-Content $file.FullName) {
      if ($line -match '(?:base_)?iterations=(\d+)') { $iterations = [double]$Matches[1] }
      if ($line -match '^(.+?) unsupported=(.*)$') {
        $unsupported.Add([ordered]@{ label = $label; case = "$benchmark/$($Matches[1])"; sweep = $sweep; reason = $Matches[2] })
      }
      if ($line -notmatch '^(.+?)\s+(?:compile_us|median_ms|calls)=') { continue }
      $name = $Matches[1]
      $operations = $iterations
      if ($line -match '\bcalls=(\d+)') { $operations = [double]$Matches[1] }
      if ($line -match 'raw_(ms|us)=([\d.,]+)') {
        $divisor = if ($Matches[1] -eq 'us') { 1000.0 } else { 1.0 }
        $values = [double[]]@($Matches[2].Split(',') | ForEach-Object { [double]$_ / $divisor })
        Add-Samples $label "$benchmark/$name" $sweep $values $operations
      }
    }
  }
  foreach ($file in Get-ChildItem (Join-Path $EvidenceRoot "$label/auxiliary") -Filter 'sweep-*.stdout.jsonl') {
    if ($file.Name -notmatch '^sweep-(\d+)-(.+)\.stdout\.jsonl$') { continue }
    $sweep = [int]$Matches[1]
    $benchmark = $Matches[2]
    foreach ($line in Get-Content $file.FullName) {
      if (!$line.StartsWith('{')) { continue }
      $data = $line | ConvertFrom-Json
      if (!$data.samples_ms) { continue }
      $name = if ($data.workload) { $data.workload } else { $data.case }
      $operations = if ($data.iterations) { $data.iterations } elseif ($data.n) { $data.n } else { 1 }
      Add-Samples $label "$benchmark/$name/$($data.mode)" $sweep $data.samples_ms $operations
    }
  }
}
function Get-Stats($Row) {
  $values = @($Row.sweeps.Values | ForEach-Object { $_ } | Sort-Object)
  $median = $values[[int][Math]::Floor($values.Count / 2)]
  return [ordered]@{
    samples = $values.Count
    median_ms = $median
    p10_ms = $values[[int][Math]::Floor($values.Count * 0.1)]
    p90_ms = $values[[int][Math]::Floor($values.Count * 0.9)]
    ns_per_operation = $median * 1000000 / $Row.operations
    sweep_medians_ms = @($Row.sweeps.Keys | Sort-Object | ForEach-Object {
      $sorted = @($Row.sweeps[$_] | Sort-Object)
      $sorted[[int][Math]::Floor($sorted.Count / 2)]
    })
  }
}
$summary = foreach ($case in @($rows.Values.case | Sort-Object -Unique)) {
  $before = $rows["baseline/$case"]
  $after = $rows["candidate/$case"]
  $baselineStats = if ($before) { Get-Stats $before } else { $null }
  $candidateStats = if ($after) { Get-Stats $after } else { $null }
  [ordered]@{
    case = $case
    baseline = $baselineStats
    candidate = $candidateStats
    change_percent = if ($before -and $after) {
      100 * ($candidateStats.median_ms / $baselineStats.median_ms - 1)
    } else { $null }
  }
}
[ordered]@{ comparisons = @($summary); unsupported = @($unsupported.ToArray()) } |
  ConvertTo-Json -Depth 10 | Set-Content -Encoding utf8 (Join-Path $EvidenceRoot 'summary.json')
$summary | ForEach-Object {
  if ($_.baseline -and $_.candidate) {
    '{0}: {1:N3} -> {2:N3} ms ({3:+0.0;-0.0;0.0}%)' -f $_.case, $_.baseline.median_ms, $_.candidate.median_ms, $_.change_percent
  } else { '{0}: candidate-only' -f $_.case }
}
