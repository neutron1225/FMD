@ECHO OFF
REM lazbuild must be in environment variable LAZ or set it here
REM SET LAZ=C:\lazarus
TITLE=FMD Release
SET cdir=%CD%
CD /D "%cdir%"
SET update_file=latest_version.json
SET repodl=https://github.com/dazedcat19/FMD2/releases/download/
SET changelog_url=https://raw.githubusercontent.com/dazedcat19/FMD2/master/changelog.txt
SET luaver=lua54

ECHO ^{>%update_file%
ECHO   "_comment": "automatically build with make_release_win.bat",>>%update_file%

REM CALL :makerelease i386-win32 Win32 "Win32 Debug" --no-write-project
CALL :makerelease i386-win32 Win32 Win32 --no-write-project
ECHO   ,>>%update_file%
REM CALL :makerelease x86_64-win64 Win64 "Win64 Debug" --no-write-project
CALL :makerelease x86_64-win64 Win64 Win64 --no-write-project

ECHO ^}>>%update_file%

PAUSE
GOTO :EOF

:makerelease
TITLE make %~1
SET tdir=%cdir%\bin\%~1
SET rdir=%cdir%\Release
SET odir=%rdir%\%~1

DEL /F "%tdir%\updater.exe"
DEL /F "%tdir%\updater.dbg"
SET lbuild=%LAZ%\lazbuild --build-mode="%~2" %~4
echo %lbuild% "%cdir%\updaterslim\updater.lpi"
%lbuild% "%cdir%\updaterslim\updater.lpi"

DEL /F "%tdir%\fmd.exe"
DEL /F "%tdir%\fmd.dbg"
SET lbuild=%LAZ%\lazbuild --build-mode="%~3" %~4
echo %lbuild% "%cdir%\mangadownloader\md.lpi"
%lbuild% "%cdir%\mangadownloader\md.lpi"

CALL :getfileversion "%tdir%\fmd.exe"
SET oname=fmd_%fverb%_%~1.7z
RMDIR /S /Q "%odir%"
MKDIR "%odir%"
call :copycdir config
call :copycdir images
call :copycdir licenses
XCOPY /C /F /Y "%cdir%\languages\*.po" "%odir%\languages\"
XCOPY /E /C /F /Y "%cdir%\dist\%~1" "%odir%\"
IF "%luaver%" == "lua54" (
  DEL /F "%odir%\lua53.dll"
  DEL /F "%odir%\lua51.dll"
)
IF "%luaver%" == "lua53" (
  DEL /F "%odir%\lua54.dll"
  DEL /F "%odir%\lua51.dll"
)
IF "%luaver%" == "luajit" (
  DEL /F "%odir%\lua54.dll"
  DEL /F "%odir%\lua53.dll"
)
XCOPY /F /Y "%cdir%\dist\config.json" "%odir%\"
XCOPY /F /Y "%cdir%\changelog.txt" "%odir%\"
XCOPY /F /Y "%cdir%\readme.rtf" "%odir%\"
XCOPY /F /Y "%tdir%\fmd.exe" "%odir%\"
XCOPY /F /Y "%tdir%\fmd.dbg" "%odir%\"
XCOPY /F /Y "%tdir%\updater.exe" "%odir%\"
DEL /F "%rdir%\%oname%"
"%cdir%\dist\%~1\7za" a "%rdir%\%oname%" "%odir%\*" -mx9 -ssw -stl -t7z -y
RMDIR /S /Q "%odir%"
REM -----------------------------------------------------------
ECHO   "%~1": {>>%update_file%
ECHO     "version": "%fverb%",>>%update_file%
ECHO     "download_url": "%repodl%%fverb%/%oname%",>>%update_file%
ECHO     "changelog_url": "%changelog_url%">>%update_file%
ECHO   }>>%update_file%
ECHO ----------------------------------------------------------
GOTO :EOF

:copycdir
XCOPY /E /C /F "%cdir%\%~1" "%odir%\%~1\"
GOTO :EOF

:getfileversion
SET fname=%~1
SET fname=%fname:\=\\%
SET fver=0.0.0
SET fverb=0.0.0.0
FOR /F "Tokens=1* Delims==" %%A IN (
    'WMIC DATAFILE WHERE "NAME='%fname%'" GET VERSION /VALUE 2^>Nul'
) DO FOR /F "Tokens=*" %%C IN ("%%B") DO SET "fverb=%%C"
FOR /F "delims=. tokens=1-3" %%i IN ("%fverb%") DO SET fver=%%i.%%j.%%k
GOTO :EOF
