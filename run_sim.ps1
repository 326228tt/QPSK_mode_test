# =============================================================================
#  run_sim.ps1 --- 一键运行 xsim 仿真 (无需打开 Vivado GUI)
#  用法: 在工程根目录执行  .\run_sim.ps1
#        .\run_sim.ps1 -Vcd        同时导出 tb_wave.vcd
#        .\run_sim.ps1 -Wave       产生波形数据并生成波形图片
# =============================================================================
param(
    [switch]$Vcd,
    [switch]$Wave
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $root

# 自动探测 Vivado (可用环境变量 VIVADO_BIN 指定)
$bin = $env:VIVADO_BIN
if (-not $bin) {
    $cand = @(
        "E:\AMD\2025.2\Vivado\bin",
        "C:\Xilinx\Vivado\2025.2\bin",
        "D:\Xilinx\Vivado\2025.2\bin"
    )
    foreach ($c in $cand) { if (Test-Path (Join-Path $c "xvlog.bat")) { $bin = $c; break } }
}
if (-not $bin) { Write-Host "未找到 Vivado，请设置环境变量 VIVADO_BIN" -ForegroundColor Red; exit 1 }
Write-Host "使用 Vivado: $bin" -ForegroundColor Cyan

# 清理旧的编译结果
if (Test-Path xsim.dir) { Remove-Item -Recurse -Force xsim.dir }

$files = Get-Content (Join-Path $root "scripts\files.f") |
         Where-Object { $_ -and ($_ -notmatch '^\s*//') } |
         ForEach-Object { $_ -replace '/', '\' }

if ($Wave) {
    $files = $files | Where-Object { $_ -notmatch 'Top_qpsk_tb\.v' }
    $files += "sim\Top_qpsk_wave_tb.v"
    $top = "Top_qpsk_wave_tb"
    $snap = "wave"
} else {
    $top = "Top_qpsk_tb"
    $snap = "sim_top"
}

$defs = @()
if ($Vcd) { $defs = @("-d", "VCD_DUMP") }

& (Join-Path $bin "xvlog.bat") -i rtl @defs @files
if ($LASTEXITCODE -ne 0) { exit 1 }

& (Join-Path $bin "xelab.bat") -debug typical $top -s $snap
if ($LASTEXITCODE -ne 0) { exit 1 }

& (Join-Path $bin "xsim.bat") $snap -runall

if ($Wave) {
    Write-Host "生成波形图片..." -ForegroundColor Cyan
    $py = $env:DSH_PYTHON
    if (-not $py) { $py = "python" }
    & $py scripts\plot_wave.py
}
