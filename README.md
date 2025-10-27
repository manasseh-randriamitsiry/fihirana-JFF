# fihirana jesosy famonjena fahamarinantsika

## dev: manassehrandriamitsiry@gmail.com

- generate the 
- copy the json google-services.json from firebase 
    - then convert to base64 : python -c "import base64; print(base64.b64encode(open('android/app/google-services.json','rb').read()).decode())"
    - then add GOOGLE_JSON_BASE64  to → Settings → Secrets and Variables → Actions → New repository secret and copy the file content
- do the same thing for jks file , use KEYSTORE_BASE64
    - it can be found by # Debug keystore (default)
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
    - 
## release point
# every tag push 
- git tag v1.0.4
- git push origin v1.0.4