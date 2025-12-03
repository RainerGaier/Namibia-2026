@echo off
setlocal enabledelayedexpansion

echo.
echo ===============================================
echo  Namibia 2026 - Quartz Publishing
echo ===============================================
echo.

REM CONFIGURATION
set "VAULT_SOURCE=C:\Users\gaierr\OneDrive - Ovations Technologies\Documents\Obsidian Vault\My Stuff\Namibia\Index"
set "QUARTZ_DIR=C:\Users\gaierr\Documents\quartz"
set "CONTENT_DIR=%QUARTZ_DIR%\content"
set "TEMP_PUBLIC=%QUARTZ_DIR%\_public_temp"

REM STEP 0: Ensure Quartz folder
cd /d "%QUARTZ_DIR%" || (
  echo ERROR: Quartz directory not found
  exit /b 1
)

REM Ensure we are on v4
for /f "tokens=*" %%i in ('git branch --show-current') do set CURRENT_BRANCH=%%i
if not "%CURRENT_BRANCH%"=="v4" (
  echo Switching to v4...
  git checkout v4 || (
    echo ERROR: Cannot switch to v4
    exit /b 1
  )
)

echo.
echo [1/5] Syncing Obsidian vault to Quartz
xcopy "%VAULT_SOURCE%\*" "%CONTENT_DIR%\" /S /E /Y /I >nul

echo.
echo [2/5] Building Quartz site
call npx quartz build || (
  echo ERROR: Quartz build failed
  exit /b 1
)

REM Move public to a temp folder to survive branch switch
echo Moving fresh public/ to temp storage...
rmdir /s /q "%TEMP_PUBLIC%" 2>nul
mkdir "%TEMP_PUBLIC%"
xcopy "%QUARTZ_DIR%\public\*" "%TEMP_PUBLIC%\" /S /E /Y /I >nul

echo.
echo [3/5] Committing changes to v4
git add -A
git commit -m "Update Namibia site" || (
  echo No changes to commit on v4.
)

echo.
echo [4/5] Select deployment option:
echo 1. Push v4 to GitHub
echo 2. Deploy to gh-pages
echo 3. Push v4 AND deploy to gh-pages
echo 4. Exit
choice /C 1234 /N /M "Choose (1-4): "
set CH=%ERRORLEVEL%

if %CH%==4 exit /b 0
if %CH%==1 goto PUSH_V4
if %CH%==2 goto DEPLOY
if %CH%==3 goto PUSH_AND_DEPLOY

:PUSH_V4
echo Pushing v4...
git push origin v4
if %CH%==1 goto END

:DEPLOY
echo.
echo [5/5] Deploying to gh-pages...

git checkout gh-pages || (
  echo ERROR: Cannot switch gh-pages
  exit /b 1
)

echo Clearing gh-pages...
for /d %%D in (*) do (
  if not "%%D"==".git" rmdir /s /q "%%D"
)
del /q * >nul 2>&1

echo Copying fresh site from temp public...
xcopy "%TEMP_PUBLIC%\*" ".\" /S /E /Y /I >nul

git add -A
git commit -m "Deploy site" || echo Nothing to commit.

echo Pushing gh-pages...
git push origin gh-pages

git checkout v4
goto END

:PUSH_AND_DEPLOY
call :PUSH_V4
call :DEPLOY

:END
echo.
echo ===============================================
echo  Publishing Complete!
echo ===============================================
pause
exit /b 0
