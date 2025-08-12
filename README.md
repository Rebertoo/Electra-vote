 Electra-Vote Smart Contract

Electra-Vote is a Clarity smart contract for decentralized academic certificate issuance and management on the Stacks blockchain.

 Features

- **Institution Management:**  
  - Approve or revoke authorized certificate-issuing institutions.
- **Certificate Issuance:**  
  - Institutions can issue certificates to students, storing metadata and IPFS hashes.
- **Certificate Revocation:**  
  - Certificates can be revoked by the issuer or contract owner, with reason and timestamp.
- **Verification:**  
  - Anyone can verify certificate validity and view revocation details.

 Contract Structure

- **Maps:**  
  - `institutions`: Tracks approved issuers.
  - `certificates`: Stores certificate records.
- **Functions:**  
  - `set-owner`: Set contract owner (once).
  - `approve-institution`: Approve an institution.
  - `revoke-institution`: Revoke an institution.
  - `issue-certificate`: Issue a new certificate.
  - `revoke-certificate`: Revoke a certificate.
  - `get-certificate`: Read certificate details.
  - `verify-certificate`: Check certificate validity.
  - `total-certificates`: Get total certificates issued.

 Usage

1. **Set Contract Owner:**  
   Call `set-owner` once after deployment.

2. **Approve Institution:**  
   Owner calls `approve-institution` with institution principal.

3. **Issue Certificate:**  
   Approved institution calls `issue-certificate` with student principal, IPFS hash, metadata, and timestamp.

4. **Revoke Certificate:**  
   Issuer or owner calls `revoke-certificate` with certificate ID and reason.

5. **Verify Certificate:**  
   Anyone calls `verify-certificate` with certificate ID.

 Example

```clarity
(approve-institution 'SP123...)
(issue-certificate 'SP456... "Qm..." "Diploma" u123456)
(revoke-certificate u1 "Fraudulent")
(verify-certificate u1)
```

 Requirements

- [Stacks Blockchain](https://www.stacks.co/)
- [Clarity Language](https://docs.stacks.co/docs/clarity-language/)
- [Clarinet](https://github.com/clarinet/clarinet) for local testing
