param(
  [string]$Objdump = 'llvm-objdump',
  [string]$Objcopy = 'llvm-objcopy',
  [string]$Output = '.dart_tool/arm64'
)

$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $Output | Out-Null
$snapshotPath = Join-Path $Output 'typed_runtime.aot'
$assemblyPath = Join-Path $Output 'typed_runtime.txt'
$symbolsPath = Join-Path $Output 'symbols.txt'
& dart compile aot-snapshot --target-os=linux --target-arch=arm64 benchmark/runtime_probe.dart -o $snapshotPath
if ($LASTEXITCODE -ne 0) { throw 'ARM64 cross-compilation failed' }
& $Objdump --syms $snapshotPath | Set-Content $symbolsPath
if ($LASTEXITCODE -ne 0) { throw 'Symbol extraction failed' }
$symbol = Select-String -Path $symbolsPath -Pattern '^([0-9a-f]+)\s+.*\.text\s+([0-9a-f]+)\s+TypedMachine\._dispatch$'
if (-not $symbol) { throw 'TypedMachine._dispatch symbol not found' }
$start = [Convert]::ToInt64($symbol.Matches[0].Groups[1].Value, 16)
$size = [Convert]::ToInt64($symbol.Matches[0].Groups[2].Value, 16)
$startOption = '--start-address=0x{0:x}' -f $start
$stopOption = '--stop-address=0x{0:x}' -f ($start + $size)
# AOT mapping symbols can label this range as data even with -D. Strip symbols
# from a separate inspection copy, then decode only the verified function range.
$inspectionPath = Join-Path $Output 'disassembly-only.elf'
& $Objcopy --strip-all $snapshotPath $inspectionPath
if ($LASTEXITCODE -ne 0) { throw 'Creating disassembly copy failed' }
& $Objdump --disassemble-all --triple=aarch64 $startOption $stopOption --no-show-raw-insn $inspectionPath | Set-Content $assemblyPath
if ($LASTEXITCODE -ne 0) { throw 'ARM64 disassembly failed' }
Write-Output $symbol.Line
Write-Output "Disassembly: $assemblyPath"
