param(
  [Parameter(Mandatory = $true)]
  [string]$BaselineRoot,
  [Parameter(Mandatory = $true)]
  [string]$CandidateRoot,
  [string]$EvidenceRoot = "$PSScriptRoot/../.dart_tool/dynamic-performance/2026-09-19-ac",
  [int]$Samples = 15,
  [int64]$ProcessorAffinity = 4,
  [string]$ReuseBaselineEvidence
)

$ErrorActionPreference = 'Stop'
$requiredBaselineCommit = '8ad26b3757891abb1381bface225fae6bc763dfa'

$dartCommand = Get-Command dart -ErrorAction Stop
$dartExecutable = $dartCommand.Source
if ([IO.Path]::GetExtension($dartExecutable) -notmatch '^\.exe$') {
  $adjacentDartExecutable = Join-Path (Split-Path $dartExecutable) 'dart.exe'
  if (!(Test-Path -LiteralPath $adjacentDartExecutable -PathType Leaf)) {
    throw "dart resolves to $dartExecutable, and no adjacent dart.exe was found."
  }
  $dartExecutable = $adjacentDartExecutable
}

$benchmarks = [ordered]@{
  dispatch       = 5000000
  calls          = 1000000
  closures       = 1000000
  callbacks      = 100000
  external_calls = 1000000
  globals        = 1000000
  exceptions     = 100001
  async          = 100001
  dynamic        = 100000
}

$power = Get-CimInstance -Namespace root\wmi -Class BatteryStatus |
  Select-Object -First 1
if ($null -ne $power -and !$power.PowerOnline) {
  throw 'Performance runs require AC power.'
}

$evidencePath = [IO.Path]::GetFullPath($EvidenceRoot)
New-Item -ItemType Directory -Force -Path $evidencePath | Out-Null

function ConvertTo-HexString([byte[]]$Bytes) {
  return ([BitConverter]::ToString($Bytes)).Replace('-', '')
}

function Get-CheckoutMetadata([string]$Root) {
  Push-Location $Root
  try {
    $patchHash = git diff --binary | git hash-object --stdin
    $benchmarkHashes = [ordered]@{}
    $normalizedBenchmarkHashes = [ordered]@{}
    foreach ($name in $benchmarks.Keys) {
      $benchmarkPath = "benchmark/$name.dart"
      $benchmarkHashes[$name] =
        (Get-FileHash $benchmarkPath -Algorithm SHA256).Hash
      $normalized = (Get-Content $benchmarkPath -Raw).Replace("`r`n", "`n")
      $hash = [Security.Cryptography.SHA256]::Create()
      try {
        $normalizedBenchmarkHashes[$name] = ConvertTo-HexString(
          $hash.ComputeHash([Text.Encoding]::UTF8.GetBytes($normalized)))
      } finally {
        $hash.Dispose()
      }
    }
    $changedFileHashes = [ordered]@{}
    foreach ($line in @(git status --porcelain=v1 --untracked-files=all)) {
      $relativePath = $line.Substring(3)
      if ($relativePath.Contains(' -> ')) {
        $relativePath = $relativePath.Split(' -> ')[-1]
      }
      $relativePath = $relativePath.Trim('"')
      if (Test-Path -LiteralPath $relativePath -PathType Leaf) {
        $changedFileHashes[$relativePath] =
          (Get-FileHash -LiteralPath $relativePath -Algorithm SHA256).Hash
      }
    }
    return [ordered]@{
      root = [IO.Path]::GetFullPath($Root)
      commit = (git rev-parse HEAD).Trim()
      patchHash = $patchHash.Trim()
      pubspecLock = (Get-FileHash pubspec.lock -Algorithm SHA256).Hash
      benchmarkHashes = $benchmarkHashes
      normalizedBenchmarkHashes = $normalizedBenchmarkHashes
      changedFileHashes = $changedFileHashes
    }
  } finally {
    Pop-Location
  }
}

function Copy-BenchmarkSources([string]$Label, [string]$Root) {
  $sourceRoot = Join-Path (Join-Path $evidencePath 'sources') $Label
  $benchmarkRoot = Join-Path $sourceRoot 'benchmark'
  New-Item -ItemType Directory -Force -Path $benchmarkRoot | Out-Null
  foreach ($name in $benchmarks.Keys) {
    Copy-Item -LiteralPath (Join-Path $Root "benchmark/$name.dart") `
      -Destination (Join-Path $benchmarkRoot "$name.dart") -Force
  }
}

function Invoke-Process(
  [string]$FilePath,
  [string[]]$Arguments,
  [string]$WorkingDirectory,
  [string]$OutputPath,
  [string]$ErrorPath,
  [bool]$Pin
) {
  $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments `
    -WorkingDirectory $WorkingDirectory -WindowStyle Hidden -PassThru `
    -RedirectStandardOutput $OutputPath -RedirectStandardError $ErrorPath
  # Keep the native handle open so Windows PowerShell retains ExitCode after
  # WaitForExit. Otherwise successful short processes can report null.
  $processHandle = $process.Handle
  if ($Pin) {
    try {
      $process.PriorityClass = 'AboveNormal'
      $process.ProcessorAffinity = [IntPtr]$ProcessorAffinity
    } catch {
      $process.Kill()
      throw
    }
  }
  $process.WaitForExit()
  $process.Refresh()
  if ($process.ExitCode -ne 0) {
    throw "$FilePath exited with code $($process.ExitCode); see $ErrorPath"
  }
}

function Invoke-OptionalAuxiliaryProcess(
  [string]$Label,
  [string]$Probe,
  [string]$FilePath,
  [string[]]$Arguments,
  [string]$WorkingDirectory,
  [string]$OutputPath,
  [string]$ErrorPath
) {
  try {
    Invoke-Process $FilePath $Arguments $WorkingDirectory $OutputPath $ErrorPath $true
    return $true
  } catch {
    [ordered]@{
      capturedAt = (Get-Date).ToString('o')
      checkout = $Label
      probe = $Probe
      reason = $_.Exception.Message
    } | ConvertTo-Json -Compress | Add-Content -Encoding utf8 `
      (Join-Path $evidencePath 'auxiliary-skips.jsonl')
    return $false
  }
}

function Build-Checkout([string]$Label, [string]$Root) {
  $output = Join-Path $evidencePath $Label
  New-Item -ItemType Directory -Force -Path $output | Out-Null
  $builds = [ordered]@{}
  if ($Label -eq 'baseline' -and $ReuseBaselineEvidence) {
    $previous = Get-Content (Join-Path $ReuseBaselineEvidence 'metadata.json') -Raw | ConvertFrom-Json
    if ($previous.baseline.commit -ne $requiredBaselineCommit -or
        $previous.dart -ne (& $dartExecutable --version 2>&1 | Out-String).Trim()) {
      throw 'Reused baseline must have the same revision and SDK.'
    }
    foreach ($name in $benchmarks.Keys) {
      if ($previous.baseline.normalizedBenchmarkHashes.$name -ne $baselineMetadata.normalizedBenchmarkHashes[$name]) {
        throw "Reused baseline benchmark differs: $name"
      }
      Copy-Item (Join-Path $ReuseBaselineEvidence "baseline/$name.exe") $output
      $builds[$name] = $previous.builds.baseline.$name
    }
    return $builds
  }
  foreach ($name in $benchmarks.Keys) {
    Write-Host "Building $Label/$name"
    $exe = Join-Path $output "$name.exe"
    $stdout = Join-Path $output "$name-compile.stdout.log"
    $stderr = Join-Path $output "$name-compile.stderr.log"
    $watch = [Diagnostics.Stopwatch]::StartNew()
    Invoke-Process $dartExecutable @('compile', 'exe', "benchmark/$name.dart", '-o', $exe) `
      $Root $stdout $stderr $false
    $watch.Stop()
    $builds[$name] = [ordered]@{
      compileElapsedUs = [int64]($watch.Elapsed.TotalMilliseconds * 1000)
      executableBytes = (Get-Item $exe).Length
    }
  }
  return $builds
}

function Build-Auxiliary([string]$Label, [string]$Root) {
  $output = Join-Path (Join-Path $evidencePath $Label) 'auxiliary'
  $allocator = Join-Path $output 'allocator'
  if ($Label -eq 'baseline' -and $ReuseBaselineEvidence) {
    $previous = Get-Content (Join-Path $ReuseBaselineEvidence 'metadata.json') -Raw | ConvertFrom-Json
    New-Item -ItemType Directory -Force -Path (Split-Path $output) | Out-Null
    Copy-Item (Join-Path $ReuseBaselineEvidence 'baseline/auxiliary') $output -Recurse
    return @{
      audit = @{ available = $previous.builds.baselineAuxiliary.audit.available; executableBytes = $previous.builds.baselineAuxiliary.audit.executableBytes; compileElapsedUs = $previous.builds.baselineAuxiliary.audit.compileElapsedUs }
      affinity = @{ available = $previous.builds.baselineAuxiliary.affinity.available; executableBytes = $previous.builds.baselineAuxiliary.affinity.executableBytes; compileElapsedUs = $previous.builds.baselineAuxiliary.affinity.compileElapsedUs }
    }
  }
  $allocatorSource = Join-Path $PSScriptRoot '../.dart_tool/allocator_swaps_20260916/audit.dart'
  $workloadSource = Join-Path $PSScriptRoot '../.dart_tool/allocator_swaps_20260916/workloads'
  $casesSource = Join-Path $PSScriptRoot '../.dart_tool/allocator_swaps_20260916/after/cases.json'
  $affinitySource = Join-Path $PSScriptRoot '../.dart_tool/register_affinity_20260916/production/probes/affinity.dart'
  $missingInputs = @($allocatorSource, $workloadSource, $casesSource, $affinitySource) |
    Where-Object { !(Test-Path -LiteralPath $_) }
  if ($missingInputs.Count -ne 0) {
    return [ordered]@{
      audit = [ordered]@{ available = $false; reason = "Missing inputs: $($missingInputs -join ', ')" }
      affinity = [ordered]@{ available = $false; reason = "Missing inputs: $($missingInputs -join ', ')" }
    }
  }

  New-Item -ItemType Directory -Force -Path $allocator | Out-Null
  Copy-Item $allocatorSource `
    (Join-Path $allocator 'audit.dart') -Force
  $workloads = Join-Path $allocator 'workloads'
  New-Item -ItemType Directory -Force -Path $workloads | Out-Null
  Copy-Item (Join-Path $workloadSource '*') `
    $workloads -Recurse -Force
  Copy-Item $casesSource `
    (Join-Path $allocator 'cases.json') -Force
  Copy-Item $affinitySource `
    (Join-Path $output 'affinity.dart') -Force

  $yamlRoot = ([IO.Path]::GetFullPath($Root)).Replace('\', '/')
  @"
name: dynamic_performance_$Label
environment:
  sdk: ^3.10.0
dependencies:
  dart_eval:
    path: '$yamlRoot'
"@ | Set-Content -Encoding utf8 (Join-Path $output 'pubspec.yaml')

  try {
    Invoke-Process $dartExecutable @('pub', 'get') $output `
      (Join-Path $output 'pub-get.stdout.log') `
      (Join-Path $output 'pub-get.stderr.log') $false
  } catch {
    return [ordered]@{
      audit = [ordered]@{ available = $false; reason = $_.Exception.Message }
      affinity = [ordered]@{ available = $false; reason = $_.Exception.Message }
    }
  }
  $builds = [ordered]@{}
  foreach ($probe in @('audit', 'affinity')) {
    Write-Host "Building $Label/$probe"
    $source = if ($probe -eq 'audit') { 'allocator/audit.dart' } else { 'affinity.dart' }
    $exe = Join-Path $output "$probe.exe"
    try {
      $watch = [Diagnostics.Stopwatch]::StartNew()
      Invoke-Process $dartExecutable @('compile', 'exe', $source, '-o', $exe) $output `
        (Join-Path $output "$probe-compile.stdout.log") `
        (Join-Path $output "$probe-compile.stderr.log") $false
      $watch.Stop()
      $builds[$probe] = [ordered]@{
        available = $true
        compileElapsedUs = [int64]($watch.Elapsed.TotalMilliseconds * 1000)
        executableBytes = (Get-Item $exe).Length
      }
    } catch {
      $builds[$probe] = [ordered]@{
        available = $false
        reason = $_.Exception.Message
      }
    }
  }

  if ($builds['audit']['available']) {
    try {
      foreach ($mode in @('prepare', 'loadprepare', 'branchprepare')) {
        Invoke-Process (Join-Path $output 'audit.exe') @($allocator, $mode) $output `
          (Join-Path $output "$mode.stdout.log") `
          (Join-Path $output "$mode.stderr.log") $false
      }
      foreach ($line in Get-Content (Join-Path $output 'prepare.stdout.log')) {
        if ($line.StartsWith('{') -and ($line | ConvertFrom-Json).error) {
          throw "Auxiliary correctness failure: $line"
        }
      }
    } catch {
      $builds['audit']['available'] = $false
      $builds['audit']['reason'] = $_.Exception.Message
    }
  }
  if ($builds['affinity']['available']) {
    try {
      Invoke-Process (Join-Path $output 'affinity.exe') @('check', '257') $output `
        (Join-Path $output 'affinity-check.stdout.log') `
        (Join-Path $output 'affinity-check.stderr.log') $false
    } catch {
      $builds['affinity']['available'] = $false
      $builds['affinity']['reason'] = $_.Exception.Message
    }
  }
  return $builds
}

function Run-Sweep([int]$Sweep, [string[]]$Order) {
  foreach ($label in $Order) {
    $output = Join-Path $evidencePath $label
    foreach ($name in $benchmarks.Keys) {
      Write-Host "Sweep $Sweep $label/$name"
      $arguments = @([string]$benchmarks[$name], [string]$Samples)
      if ($label -eq 'baseline' -and $name -eq 'dynamic') {
        $arguments += 'allow-unsupported'
      }
      Invoke-Process (Join-Path $output "$name.exe") $arguments $output `
        (Join-Path $output "sweep-$Sweep-$name.stdout.log") `
        (Join-Path $output "sweep-$Sweep-$name.stderr.log") $true
    }
    $auxiliary = Join-Path $output 'auxiliary'
    $allocator = Join-Path $auxiliary 'allocator'
    $auxiliaryBuilds = $metadata['builds']["${label}Auxiliary"]
    if ($auxiliaryBuilds['audit']['available']) {
      $auditSucceeded = Invoke-OptionalAuxiliaryProcess $label 'audit-execute' `
        (Join-Path $auxiliary 'audit.exe') `
        @($allocator, 'execute', [string]$Samples, [string](($Sweep * 3) % 8)) `
        $auxiliary (Join-Path $auxiliary "sweep-$Sweep-allocator.stdout.jsonl") `
        (Join-Path $auxiliary "sweep-$Sweep-allocator.stderr.log")
      if ($auditSucceeded) {
        [void](Invoke-OptionalAuxiliaryProcess $label 'audit-load' `
          (Join-Path $auxiliary 'audit.exe') @($allocator, 'load') `
          $auxiliary (Join-Path $auxiliary "sweep-$Sweep-load.stdout.jsonl") `
          (Join-Path $auxiliary "sweep-$Sweep-load.stderr.log"))
      }
    }
    if ($auxiliaryBuilds['affinity']['available']) {
      [void](Invoke-OptionalAuxiliaryProcess $label 'affinity' `
        (Join-Path $auxiliary 'affinity.exe') `
        @('benchmark', '100000', [string]$Samples) $auxiliary `
        (Join-Path $auxiliary "sweep-$Sweep-affinity.stdout.jsonl") `
        (Join-Path $auxiliary "sweep-$Sweep-affinity.stderr.log"))
    }
  }
}

$baselineMetadata = Get-CheckoutMetadata $BaselineRoot
$candidateMetadata = Get-CheckoutMetadata $CandidateRoot
if ($baselineMetadata['commit'] -ne $requiredBaselineCommit) {
  throw "Baseline must be $requiredBaselineCommit, found $($baselineMetadata['commit'])."
}
foreach ($name in $benchmarks.Keys) {
  if ($baselineMetadata['normalizedBenchmarkHashes'][$name] -ne `
      $candidateMetadata['normalizedBenchmarkHashes'][$name]) {
    throw "Benchmark source differs between checkouts: benchmark/$name.dart"
  }
}
Copy-BenchmarkSources 'baseline' $BaselineRoot
Copy-BenchmarkSources 'candidate' $CandidateRoot
$toolSource = Join-Path (Join-Path $evidencePath 'sources') 'tool'
New-Item -ItemType Directory -Force -Path $toolSource | Out-Null
Copy-Item -LiteralPath $PSCommandPath `
  -Destination (Join-Path $toolSource 'run_dynamic_performance.ps1') -Force

$llvmObjdumpPath = 'C:\Program Files\AMD\ROCm\6.2\bin\llvm-objdump.exe'
$llvmObjdump = if (Test-Path -LiteralPath $llvmObjdumpPath -PathType Leaf) {
  [ordered]@{
    available = $true
    path = $llvmObjdumpPath
    version = (& $llvmObjdumpPath --version | Select-Object -First 2 | Out-String).Trim()
  }
} else {
  [ordered]@{ available = $false; path = $llvmObjdumpPath }
}
$controlFlowGraphRoot = 'D:\Projects\control_flow_graph'
$controlFlowGraph = if (Test-Path -LiteralPath $controlFlowGraphRoot -PathType Container) {
  [ordered]@{
    available = $true
    root = $controlFlowGraphRoot
    commit = (git -C $controlFlowGraphRoot rev-parse HEAD).Trim()
  }
} else {
  [ordered]@{ available = $false; root = $controlFlowGraphRoot }
}

$metadata = [ordered]@{
  capturedAt = (Get-Date).ToString('o')
  dartExecutable = $dartExecutable
  dart = (& $dartExecutable --version 2>&1 | Out-String).Trim()
  powerScheme = (powercfg /getactivescheme | Out-String).Trim()
  power = $power | Select-Object PowerOnline, Charging, Discharging
  cpu = Get-CimInstance Win32_Processor |
    Select-Object Name, NumberOfCores, NumberOfLogicalProcessors
  os = Get-CimInstance Win32_OperatingSystem |
    Select-Object Caption, Version, BuildNumber
  samplesPerSweep = $Samples
  processorAffinity = $ProcessorAffinity
  priority = 'AboveNormal'
  buildFlags = 'dart compile exe (default release AOT flags)'
  llvmObjdump = $llvmObjdump
  controlFlowGraph = $controlFlowGraph
  baseline = $baselineMetadata
  candidate = $candidateMetadata
}

$metadata['builds'] = [ordered]@{
  baseline = Build-Checkout 'baseline' $BaselineRoot
  candidate = Build-Checkout 'candidate' $CandidateRoot
  baselineAuxiliary = Build-Auxiliary 'baseline' $BaselineRoot
  candidateAuxiliary = Build-Auxiliary 'candidate' $CandidateRoot
}
$metadata | ConvertTo-Json -Depth 8 |
  Set-Content -Encoding utf8 (Join-Path $evidencePath 'metadata.json')

foreach ($label in @('baseline', 'candidate')) {
  foreach ($probe in @('audit', 'affinity')) {
    if (!$metadata.builds["${label}Auxiliary"][$probe].available) {
      throw "Required auxiliary $label/$probe unavailable: $($metadata.builds["${label}Auxiliary"][$probe].reason)"
    }
  }
}

Run-Sweep 1 @('baseline', 'candidate')
Run-Sweep 2 @('candidate', 'baseline')

Write-Output "Performance evidence written to $evidencePath"
