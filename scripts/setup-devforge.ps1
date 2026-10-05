# ==========================================
# DevForge Initializer
# ==========================================
# Atajo histórico: el diagnóstico del entorno lo hace DevForge Doctor.
# Acepta los mismos parámetros (-Json, -Project <ruta>) y devuelve su código de salida.

& (Join-Path $PSScriptRoot "doctor/Invoke-DevForgeDoctor.ps1") @args
exit $LASTEXITCODE
