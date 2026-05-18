@echo off
REM Convenience launcher — runs the repo script from the models folder.
call "%~dp0..\cmds\build_models_manifest.bat" %*
