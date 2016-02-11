# Certificate Chain Check

This simple script uses the 'openssl' command to fetch a certificate chain from a live host
and then list each certificate and check for SHA1 signatures.

Note that this only checks the certificates served by the host, this should include all intermediary certificates.
This thus does NOT check if the root certificate is SHA1.

## Usage
```
certchaincheck.sh <hostname> <port>
```

## Exit code

 * 0 = all ok, no SHA1 found
 * 1 = invalid parameters
 * 2 = SHA1 certificate found

## Example
```
certchaincheck.sh www.example.com 443
```

### Output

```
$ ./sha1check.sh www.example.com 443
---------------- Certificate
Signature Algorithm: sha256WithRSAEncryption
 Issuer: C=IL, O=StartCom Ltd., OU=Secure Digital Certificate Signing, CN=StartCom Class 2 Primary Intermediate Server CA
 Subject: C=CH, ST=Zurich, L=Zurich, O=Example AG, CN=www.example.com/emailAddress=postmaster@example.com
 Signature Algorithm: sha256WithRSAEncryption
---------------- Certificate
Signature Algorithm: sha1WithRSAEncryption
 Issuer: C=IL, O=StartCom Ltd., OU=Secure Digital Certificate Signing, CN=StartCom Certification Authority
 Subject: C=IL, O=StartCom Ltd., OU=Secure Digital Certificate Signing, CN=StartCom Class 2 Primary Intermediate Server CA
 Signature Algorithm: sha1WithRSAEncryption
>>>>>>>>>>>>>>>>>>>>>>> CERTIFICATE HAS SHA1 SIGNATURES <<<<<<<<<<<<<<<<<<<<<<
---------------- Done
```

