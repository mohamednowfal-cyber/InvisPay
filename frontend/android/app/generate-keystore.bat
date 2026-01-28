@echo off
"d:\Invispay\tools\jdk-17.0.17+10\bin\keytool.exe" -genkeypair -v -keystore "d:\Invispay\frontend\android\app\upload-keystore.jks" -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storepass invispay123 -keypass invispay123 -dname "CN=InvisPay, OU=Dev, O=InvisPay, L=Unknown, ST=Unknown, C=US"
