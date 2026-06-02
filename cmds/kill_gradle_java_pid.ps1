# ─────────────────────────────────────────────────────────────────────────────
#  vLearn2 — Kill all Java processes related to Gradle
#
#  Finds every java.exe whose command line contains "gradle" and kills it.
#  This covers:
#    - Gradle daemon        (org.gradle.launcher.daemon.bootstrap.GradleDaemon)
#    - VS Code Gradle ext   (com.github.badsyntax.gradle.GradleServer)
#
#  Usage:
#    .\cmds\kill_gradle_java_pid.ps1
# ─────────────────────────────────────────────────────────────────────────────

$procs = Get-CimInstance Win32_Process -Filter "Name='java.exe'" |
         Where-Object { $_.CommandLine -like '*gradle*' }

if (-not $procs) {
    Write-Host "No Gradle-related Java processes found."
    exit 0
}

foreach ($p in $procs) {
    $preview = $p.CommandLine.Substring(0, [Math]::Min(100, $p.CommandLine.Length))
    Write-Host "Killing PID $($p.ProcessId): $preview..."
    Stop-Process -Id $p.ProcessId -Force
}

Write-Host "Done. Killed $($procs.Count) process(es)."
