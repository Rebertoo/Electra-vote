;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Decertify.clar
;; Decentralized Academic Certificate Registry
;; Version: 1.0
;; Notes: Simple, readable, Clarinet-friendly Clarity contract.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; ----------------------------
;; Constants and Globals
;; ----------------------------

;; Contract owner (set at deploy time)
(define-data-var contract-owner principal 'SP000000000000000000002Q6VF78)

;; Auto-increment counter for certificate IDs
(define-data-var cert-counter uint u0)

;; Registry of authorized issuing institutions
;; map key: {issuer: principal} -> {approved: bool}
(define-map institutions { issuer: principal } { approved: bool })

;; Certificates map
;; key: { id: uint } ->
;; value: {
;;   issuer: principal,
;;   student: principal,
;;   ipfs-hash: (string-ascii 128),
;;   metadata: (string-ascii 256),
;;   issued-at: uint,
;;   revoked: bool,
;;   revoked-by: principal,
;;   revoked-at: uint,
;;   revoke-reason: (string-ascii 256)
;; }
(define-map certificates
  { id: uint }
  {
    issuer: principal,
    student: principal,
    ipfs-hash: (string-ascii 128),
    metadata: (string-ascii 256),
    issued-at: uint,
    revoked: bool,
    revoked-by: principal,
    revoked-at: uint,
    revoke-reason: (string-ascii 256)
  }
)

;; ----------------------------
;; Helpers / Internal checks
;; ----------------------------

;; Helper to check if principal is contract owner
(define-private (is-owner? (p principal))
  (is-eq p (var-get contract-owner))
)

(define-read-only (is-institution (p principal))
  (default-to false (get approved (map-get? institutions (tuple (issuer p)))))
)

;; ----------------------------
;; Admin: Manage Institutions
;; ----------------------------

;; Set contract owner on first call (should be called once after deployment)
;; Set contract owner on first call (should be called once after deployment)
(define-public (set-owner (owner principal))
  (begin
    (asserts! (is-eq (var-get contract-owner) 'SP000000000000000000002Q6VF78) (err "OWNER_ALREADY_SET"))
    (var-set contract-owner owner)
    (ok owner)
  )
)

;; Approve institution
(define-public (approve-institution (issuer principal))
  (begin
    (asserts! (is-owner? tx-sender) (err "ONLY_OWNER"))
    (map-set institutions (tuple (issuer issuer)) (tuple (approved true)))
    (ok issuer)
  )
)

;; Revoke institution
(define-public (revoke-institution (issuer principal))
  (begin
    (asserts! (is-owner? tx-sender) (err "ONLY_OWNER"))
    (map-set institutions (tuple (issuer issuer)) (tuple (approved false)))
    (ok issuer)
  )
)

;; ----------------------------
;; Issuance: Institutions issue certificates
;; ----------------------------

;; Issue certificate, using block-height as issued-at
;; Issue certificate, using issued-at as timestamp
(define-public (issue-certificate (student principal) (ipfs-hash (string-ascii 128)) (metadata (string-ascii 256)) (issued-at uint))
  (let ((new-id (+ (var-get cert-counter) u1)))
    (begin
      (asserts!
        (match (map-get? institutions (tuple (issuer tx-sender)))
          institution
          (get approved institution)
          false
        )
        (err "NOT_AUTHORIZED_ISSUER")
      )
      (map-set certificates (tuple (id new-id))
        (tuple
          (issuer tx-sender)
          (student student)
          (ipfs-hash ipfs-hash)
          (metadata metadata)
          (issued-at issued-at)
          (revoked false)
          (revoked-by 'SP000000000000000000002Q6VF78)
          (revoked-at u0)
          (revoke-reason "")
        )
      )
      (var-set cert-counter new-id)
      (print (tuple (event "certificate-issued") (id new-id)))
      (ok new-id)
    )
  )
)

;; ----------------------------
;; Revocation: issuer or owner can revoke
;; ----------------------------

;; Revoke certificate, using block-height as revoked-at
;; Revoke certificate, using revoked-at as timestamp
(define-public (revoke-certificate (cert-id uint) (reason (string-ascii 256)) (revoked-at uint))
  (begin
    (match (map-get? certificates (tuple (id cert-id)))
      cert
      (let (
             (issuer (get issuer cert))
           )
        (begin
          (asserts! (or (is-eq tx-sender issuer) (is-owner? tx-sender)) (err "NOT_AUTHORIZED_TO_REVOKE"))
          (asserts! (is-eq false (get revoked cert)) (err "ALREADY_REVOKED"))
          (map-set certificates (tuple (id cert-id))
            (tuple
              (issuer issuer)
              (student (get student cert))
              (ipfs-hash (get ipfs-hash cert))
              (metadata (get metadata cert))
              (issued-at (get issued-at cert))
              (revoked true)
              (revoked-by tx-sender)
              (revoked-at revoked-at)
              (revoke-reason reason)
            )
          )
          (print (tuple (event "certificate-revoked") (id cert-id) (revoked-by tx-sender) (revoked-at revoked-at) (reason reason)))
          (ok cert-id)
        )
      )
      (err "CERT_NOT_FOUND")
    )
  )
)

;; ----------------------------
;; Read-only helpers
;; ----------------------------

;; Returns the certificate record or none
(define-read-only (get-certificate (cert-id uint))
  (map-get? certificates { id: cert-id })
)

;; Verify certificate: returns (ok true) if exists and not revoked, else (err ...)
(define-read-only (verify-certificate (cert-id uint))
  (match (map-get? certificates { id: cert-id })
    cert
    (if (is-eq false (get revoked cert))
        (ok true)
        (err (tuple (reason (get revoke-reason cert)) (revoked-by (get revoked-by cert)) (revoked-at (get revoked-at cert))))
    )
    (err (tuple (reason "CERT_NOT_FOUND") (revoked-by 'SP000000000000000000002Q6VF78) (revoked-at u0)))
  )
)

;; Returns total certificates issued so far
(define-read-only (total-certificates)
  (ok (var-get cert-counter))
)
