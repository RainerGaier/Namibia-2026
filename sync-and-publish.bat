@echo off
REM ==================================================================
REM Namibia 2026 Quartz Publishing Script
REM ==================================================================
REM
REM This script automates the entire publishing workflow:
REM 1. Syncs content from Obsidian vault to Quartz content folder
REM 2. Builds the Quartz site
REM 3. Commits changes to v4 (development branch)
REM 4. Optionally deploys to gh-pages (production)
REM ==================================================================

setlocal enabledelayedexpansion

echo.
echo ===============================================
echo  Namibia 2026 - Quartz Publishing
echo ===============================================
echo.

REM Configuration
set "VAULT_SOURCE=C:\Users\gaierr\OneDrive - Ovations Technologies\Documents\Obsidian Vault\My Stuff\Namibia\Index"
set "QUARTZ_DIR=C:\Users\gaierr\Documents\quartz"
set "CONTENT_DIR=%QUARTZ_DIR%\content"

REM Check if we're in the right directory
cd /d "%QUARTZ_DIR%"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Could not navigate to Quartz directory
    pause
    exit /b 1
)

REM Check current branch
for /f "tokens=*" %%i in ('git branch --show-current') do set CURRENT_BRANCH=%%i
echo Current branch: %CURRENT_BRANCH%
echo.

REM ==================================================================
REM STEP 1: Sync content from Obsidian vault
REM ==================================================================
echo [1/5] Syncing content from Obsidian vault...
echo.
echo From: %VAULT_SOURCE%
echo To:   %CONTENT_DIR%
echo.

REM Create content directory if it doesn't exist
if not exist "%CONTENT_DIR%" (
    echo Creating content directory...
    mkdir "%CONTENT_DIR%"
)

REM Sync files using xcopy
xcopy "%VAULT_SOURCE%" "%CONTENT_DIR%" /S /E /Y /I

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to sync content from vault
    pause
    exit /b 1
)

echo ✓ Content synced successfully
echo.

REM ==================================================================
REM STEP 2: Build Quartz site
REM ==================================================================
echo [2/5] Building Quartz site...
echo.

REM Check if npx is available
where npx >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: npx not found. Please install Node.js
    pause
    exit /b 1
)

REM Build the site
call npx quartz build

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Quartz build failed
    pause
    exit /b 1
)

echo ✓ Build completed successfully
echo.

REM ==================================================================
REM STEP 3: Check for changes
REM ==================================================================
echo [3/5] Checking for changes...
echo.

git add -A
git diff --cached --quiet
if %ERRORLEVEL% EQU 0 (
    echo No changes detected - site is up to date
    echo.
    pause
    exit /b 0
)

echo Changes detected:
git status --short
echo.

REM ==================================================================
REM STEP 4: Commit changes to v4 branch
REM ==================================================================
echo [4/5] Committing changes to v4 branch...
echo.

REM Switch to v4 if not already there
if not "%CURRENT_BRANCH%"=="v4" (
    echo Switching to v4 branch...
    git checkout v4
    if %ERRORLEVEL% NEQ 0 (
        echo ERROR: Failed to switch to v4 branch
        pause
        exit /b 1
    )
)

REM Create commit with timestamp
for /f "tokens=2-4 delims=/ " %%a in ('date /t') do (set mydate=%%c-%%a-%%b)
for /f "tokens=1-2 delims=/: " %%a in ('time /t') do (set mytime=%%a:%%b)
set COMMIT_MSG=Update Namibia site - %mydate% %mytime%

git commit -m "%COMMIT_MSG%"

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to commit changes
    pause
    exit /b 1
)

echo ✓ Changes committed to v4
echo.

REM ==================================================================
REM STEP 5: Ask about deployment
REM ==================================================================
echo [5/5] Deployment options...
echo.
echo What would you like to do?
echo.
echo 1. Push v4 to GitHub (development branch)
echo 2. Deploy to gh-pages (publish live site)
echo 3. Push v4 AND deploy to gh-pages
echo 4. Exit (keep changes local only)
echo.
choice /C 1234 /N /M "Enter your choice (1-4): "

set CHOICE=%ERRORLEVEL%

if %CHOICE%==4 (
    echo.
    echo Changes committed locally but not pushed
    echo Run this script again when ready to publish
    echo.
    pause
    exit /b 0
)

if %CHOICE%==1 goto PUSH_V4
if %CHOICE%==2 goto DEPLOY_GHPAGES
if %CHOICE%==3 goto PUSH_AND_DEPLOY

:PUSH_V4
echo.
echo Pushing v4 to GitHub...
git push origin v4
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to push to v4
    pause
    exit /b 1
)
echo ✓ v4 pushed successfully
if %CHOICE%==1 goto END
goto DEPLOY_GHPAGES

:DEPLOY_GHPAGES
echo.
echo Deploying to gh-pages...
echo.

REM Copy public folder contents to gh-pages branch
git checkout gh-pages
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to switch to gh-pages branch
    pause
    exit /b 1
)

REM Clear gh-pages content (except .git)
echo Clearing gh-pages content...
for /d %%D in (*) do (
    if not "%%D"==".git" (
        rmdir /s /q "%%D" 2>nul
    )
)
del /q * 2>nul

REM Copy from public folder on v4
echo Copying built site from v4/public...
git checkout v4 -- public
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to checkout public folder from v4
    pause
    exit /b 1
)

REM Move contents of public to root
xcopy public\* . /S /E /Y /I
rmdir /s /q public

REM Commit to gh-pages
git add -A
git commit -m "Deploy site - %mydate% %mytime%"
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: No changes to deploy or commit failed
)

REM Push to gh-pages
git push origin gh-pages
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to push to gh-pages
    pause
    exit /b 1
)

echo ✓ Site deployed to gh-pages
echo.

REM Return to v4
git checkout v4
goto END

:PUSH_AND_DEPLOY
goto PUSH_V4

:END
echo.
echo ===============================================
echo  Publishing Complete!
echo ===============================================
echo.
echo Your Namibia 2026 site has been updated.
echo View it at: https://rainergaier.github.io/Namibia-2026/
echo.
pause
