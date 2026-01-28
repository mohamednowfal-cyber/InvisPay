$keytoolPath = "d:\Invispay\tools\jdk-17.0.17+10\bin\keytool.exe"
$keystorePath = "d:\Invispay\frontend\android\app\upload-keystore.jks"
$alias = "upload"
$storepass = "invispay123"
$keypass = "invispay123"

# Check if keystore already exists
if (Test-Path $keystorePath) {
    Write-Host "Keystore already exists at $keystorePath"
    exit 0
}

# Create keystore with all parameters
$dname = "CN=InvisPay, OU=Development, O=InvisPay, L=Unknown, ST=Unknown, C=US"

try {
    & $keytoolPath -genkeypair `
        -keystore $keystorePath `
        -alias $alias `
        -keyalg RSA `
        -keysize 2048 `
        -validity 10000 `
        -storepass $storepass `
        -keypass $keypass `
        -dname $dname `
        -noprompt
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Keystore created successfully at $keystorePath"
    } else {
        Write-Host "Keystore creation failed with exit code $LASTEXITCODE"
        exit 1
    }
} catch {
    Write-Host "Error creating keystore: $_"
    exit 1
}
