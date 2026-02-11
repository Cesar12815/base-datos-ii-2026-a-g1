# ====================================================================
# SCRIPT AUTOMATICO PARA CONSTRUCCION DE OVA - CLASES
# Version: 1.0
# Autor: GitHub Copilot
# Descripcion: Automatiza la creacion de builds minificados y SCORM
# ====================================================================

param(
    [string]$ProjectName = "OVA-MGBD-S01-Sesion01",
    [switch]$SkipInstall = $false
)

Write-Host "[BUILD] INICIANDO CONSTRUCCION DE OVA..." -ForegroundColor Green
Write-Host "Proyecto: $ProjectName" -ForegroundColor Yellow

# Verificar que estamos en un proyecto OVA valido
Write-Host "[CHECK] Verificando archivos necesarios..." -ForegroundColor Gray

$indexExists = Test-Path "index.html"
$cssExists = Test-Path "css" -PathType Container
$jsExists = Test-Path "js" -PathType Container
$manifestExists = Test-Path "imsmanifest.xml"

Write-Host "  - index.html: $(if($indexExists){'OK'}else{'FALTA'})" -ForegroundColor Gray
Write-Host "  - css/: $(if($cssExists){'OK'}else{'FALTA'})" -ForegroundColor Gray
Write-Host "  - js/: $(if($jsExists){'OK'}else{'FALTA'})" -ForegroundColor Gray
Write-Host "  - imsmanifest.xml: $(if($manifestExists){'OK'}else{'FALTA'})" -ForegroundColor Gray

if (-not $indexExists -or -not $cssExists -or -not $jsExists -or -not $manifestExists) {
    Write-Host "[ERROR] Faltan archivos necesarios para el proyecto OVA" -ForegroundColor Red
    Write-Host "Ubicacion actual: $(Get-Location)" -ForegroundColor Yellow
    Write-Host "Asegurate de ejecutar este script en la raiz de tu proyecto OVA" -ForegroundColor Yellow
    exit 1
}

Write-Host "[OK] Todos los archivos necesarios encontrados" -ForegroundColor Green

# 1. CREAR ESTRUCTURA DE CARPETAS
Write-Host "[1/6] Creando estructura de carpetas..." -ForegroundColor Cyan
if (Test-Path "builds") {
    Remove-Item -Path "builds" -Recurse -Force
}
New-Item -ItemType Directory -Path "builds\minified\css" -Force | Out-Null
New-Item -ItemType Directory -Path "builds\minified\js" -Force | Out-Null

# 2. INSTALAR DEPENDENCIAS (si no se especifica -SkipInstall)
if (-not $SkipInstall) {
    Write-Host "[2/6] Instalando herramientas de minificacion y ofuscacion..." -ForegroundColor Cyan
    if (-not (Test-Path "package.json")) {
        npm init -y | Out-Null
    }
    npm install javascript-obfuscator clean-css-cli html-minifier --save-dev --silent
    Write-Host "  [OK] Herramientas instaladas" -ForegroundColor Green
}

# 3. COPIAR ARCHIVOS ORIGINALES
Write-Host "[3/6] Copiando archivos base..." -ForegroundColor Cyan
Copy-Item -Path "index.html" -Destination "builds\minified\index.html" -Force
Copy-Item -Path "css\*" -Destination "builds\minified\css\" -Force
Copy-Item -Path "js\*" -Destination "builds\minified\js\" -Force
Copy-Item -Path "imsmanifest.xml" -Destination "builds\minified\imsmanifest.xml" -Force

# 4. MINIFICAR Y OFUSCAR ARCHIVOS
Write-Host "[4/6] Ofuscando archivos JavaScript con proteccion agresiva..." -ForegroundColor Cyan

# Procesar script.js
Write-Host "  - Ofuscando: script.js" -ForegroundColor Gray
$scriptJs = Join-Path $PWD "builds\minified\js\script.js"
$scriptJsObf = Join-Path $PWD "builds\minified\js\script.obf.js"

npx javascript-obfuscator $scriptJs --output $scriptJsObf --compact true --control-flow-flattening true --control-flow-flattening-threshold 0.75 --dead-code-injection true --dead-code-injection-threshold 0.4 --disable-console-output true --identifier-names-generator hexadecimal --rename-globals true --self-defending true --string-array true --string-array-threshold 0.75 --string-array-encoding rc4 --split-strings true --split-strings-chunk-length 10 2>&1 | Out-Null

if (Test-Path $scriptJsObf) {
    Remove-Item $scriptJs -Force -Recurse -ErrorAction SilentlyContinue
    Move-Item $scriptJsObf $scriptJs -Force
    Write-Host "    [OK] script.js PROTEGIDO (ilegible)" -ForegroundColor Green
} else {
    Write-Host "    [WARN] script.js sin cambios" -ForegroundColor Yellow
}

Write-Host "[5/6] Minificando archivos CSS..." -ForegroundColor Cyan

# Minificar todos los archivos CSS en css/
Get-ChildItem -Path "builds\minified\css" -Filter "*.css" -Recurse | ForEach-Object {
    $cssFile = $_.FullName
    $tempFile = "$cssFile.min"
    Write-Host "  - Procesando: $($_.Name)" -ForegroundColor Gray
    try {
        npx cleancss -O2 --compatibility ie8 $cssFile -o $tempFile 2>&1 | Out-Null
        if (Test-Path $tempFile) {
            Move-Item -Path $tempFile -Destination $cssFile -Force
            Write-Host "    [OK] $($_.Name) minificado" -ForegroundColor Green
        } else {
            Write-Host "    [WARN] $($_.Name) sin cambios" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "    [ERROR] $($_.Exception.Message)" -ForegroundColor Yellow
        if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
    }
}

Write-Host "[6/6] Minificando HTML..." -ForegroundColor Cyan
try {
    $htmlFile = "builds\minified\index.html"
    $tempFile = "$htmlFile.min"
    npx html-minifier --collapse-whitespace --remove-comments --remove-optional-tags --remove-redundant-attributes --remove-script-type-attributes --remove-tag-whitespace --use-short-doctype --minify-css true --minify-js true $htmlFile -o $tempFile 2>&1 | Out-Null
    if (Test-Path $tempFile) {
        Move-Item -Path $tempFile -Destination $htmlFile -Force
        Write-Host "  [OK] index.html minificado" -ForegroundColor Green
    } else {
        Write-Host "  [WARN] HTML sin cambios" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Yellow
    if (Test-Path $tempFile) { Remove-Item $tempFile -Force }
}

# 5. CREAR ZIP SCORM
Write-Host "[ZIP] Creando paquete SCORM..." -ForegroundColor Cyan
$zipName = "builds\$ProjectName-SCORM.zip"
if (Test-Path $zipName) {
    Remove-Item $zipName -Force
}
Compress-Archive -Path "builds\minified\*" -DestinationPath $zipName -Force

# 6. VERIFICAR RESULTADOS
Write-Host "[VERIFY] Verificando resultados..." -ForegroundColor Cyan
$minifiedFiles = Get-ChildItem -Path "builds\minified" -Recurse -File
$zipExists = Test-Path $zipName
$zipSize = if ($zipExists) { [math]::Round((Get-Item $zipName).Length / 1KB, 2) } else { 0 }

Write-Host ""
Write-Host "=====================================" -ForegroundColor Green
Write-Host "CONSTRUCCION COMPLETADA" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host "Archivos procesados: $($minifiedFiles.Count)" -ForegroundColor White
Write-Host "SCORM generado: $zipName ($zipSize KB)" -ForegroundColor White
Write-Host ""
Write-Host "LISTO PARA USAR:" -ForegroundColor Yellow
Write-Host "   - Para Moodle: Sube $zipName como 'Paquete SCORM'" -ForegroundColor White
Write-Host "   - Para compartir: Usa la carpeta builds\minified\" -ForegroundColor White
Write-Host ""

# 7. MOSTRAR CONTENIDO FINAL
Write-Host "Contenido final en builds\minified\:" -ForegroundColor Cyan
Get-ChildItem -Path "builds\minified" -Name | ForEach-Object {
    Write-Host "   - $_" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Proceso completado exitosamente!" -ForegroundColor Green
