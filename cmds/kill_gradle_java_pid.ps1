# ─────────────────────────────────────────────────────────────────────────────
#  vLearn2 — Kill all Java processes related to Gradle or OpenJDK
#
#  Finds every java.exe whose command line matches any of the patterns below
#  and kills it. This covers:
#    - Gradle daemon        (org.gradle.launcher.daemon.bootstrap.GradleDaemon)
#    - VS Code Gradle ext   (com.github.badsyntax.gradle.GradleServer)
#    - OpenJDK processes    (path contains "openjdk" or "jdk")
#    - Eclipse JDT LS       (VS Code redhat.java language server, OpenJDK-based)
#    - VS Code Java ext JRE (redhat.java bundled JRE, path contains "jre")
#
#  Usage:
#    .\cmds\kill_gradle_java_pid.ps1
# ─────────────────────────────────────────────────────────────────────────────

$patterns = @('*gradle*', '*openjdk*', '*jdk*', '*jre*')

$procs = Get-CimInstance Win32_Process -Filter "Name='java.exe'" |
         Where-Object {
             $cmd = $_.CommandLine
             $patterns | Where-Object { $cmd -like $_ }
         }

if (-not $procs) {
    Write-Host "No Gradle/OpenJDK-related Java processes found."
    exit 0
}

foreach ($p in $procs) {
    $preview = $p.CommandLine.Substring(0, [Math]::Min(100, $p.CommandLine.Length))
    Write-Host "Killing PID $($p.ProcessId): $preview..."
    Stop-Process -Id $p.ProcessId -Force
}

Write-Host "Done. Killed $($procs.Count) process(es)."
