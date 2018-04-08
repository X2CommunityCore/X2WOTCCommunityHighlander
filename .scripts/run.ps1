Param(
    [string]$gamePath # the path to your XCOM 2 installation ending in "XCOM 2"
)

Start-Process -FilePath "$gamePath/Binaries/Win64/XCom2.exe" -ArgumentList "-fromlauncher -log -nostartupmovies -allowconsole" -Wait -WorkingDirectory "$gamePath/Binaries/Win64"