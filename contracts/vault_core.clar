;; VaultCore
;; Secure platform for managing crypto keys

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-unauthorized (err u101))
(define-constant err-invalid-vault (err u102))
(define-constant err-already-exists (err u103))

;; Data vars
(define-data-var recovery-delay uint u144) ;; ~24 hours in blocks

;; Data maps
(define-map vaults
    principal
    {
        active: bool,
        created-at: uint,
        last-accessed: uint
    }
)

(define-map vault-keys
    { vault-owner: principal, key-id: (string-ascii 64) }
    {
        encrypted-key: (string-ascii 1024),
        added-at: uint,
        last-used: uint 
    }
)

(define-map recovery-requests
    principal  
    {
        requested-at: uint,
        backup-principal: principal
    }
)

;; Initialize vault
(define-public (initialize-vault)
    (let
        ((caller tx-sender))
        (asserts! (is-none (map-get? vaults caller)) err-already-exists)
        (ok (map-set vaults caller {
            active: true,
            created-at: block-height,
            last-accessed: block-height
        }))
    )
)

;; Add key to vault
(define-public (add-key (key-id (string-ascii 64)) (encrypted-key (string-ascii 1024)))
    (let
        ((caller tx-sender))
        (asserts! (is-some (map-get? vaults caller)) err-invalid-vault)
        (ok (map-set vault-keys 
            { vault-owner: caller, key-id: key-id }
            {
                encrypted-key: encrypted-key,
                added-at: block-height,
                last-used: block-height
            }
        ))
    )
)

;; Get key from vault
(define-public (get-key (key-id (string-ascii 64)))
    (let
        ((caller tx-sender)
         (key-data (map-get? vault-keys { vault-owner: caller, key-id: key-id })))
        (asserts! (is-some key-data) err-invalid-vault)
        (map-set vault-keys
            { vault-owner: caller, key-id: key-id }
            (merge (unwrap-panic key-data)
                  { last-used: block-height }))
        (ok (get encrypted-key (unwrap-panic key-data)))
    )
)

;; Initiate key recovery
(define-public (initiate-recovery (backup-principal principal))
    (let
        ((caller tx-sender))
        (asserts! (is-some (map-get? vaults caller)) err-invalid-vault)
        (ok (map-set recovery-requests caller {
            requested-at: block-height,
            backup-principal: backup-principal
        }))
    )
)

;; Complete recovery after delay period
(define-public (complete-recovery (vault-owner principal))
    (let
        ((caller tx-sender)
         (request (map-get? recovery-requests vault-owner)))
        (asserts! (is-some request) err-invalid-vault)
        (asserts! (is-eq caller (get backup-principal (unwrap-panic request))) err-unauthorized)
        (asserts! (> block-height (+ (get requested-at (unwrap-panic request)) (var-get recovery-delay))) err-unauthorized)
        (map-set vaults vault-owner 
            (merge (unwrap-panic (map-get? vaults vault-owner))
                  { last-accessed: block-height }))
        (map-delete recovery-requests vault-owner)
        (ok true)
    )
)

;; Read only functions
(define-read-only (get-vault-info (vault-owner principal))
    (ok (map-get? vaults vault-owner))
)

(define-read-only (get-recovery-info (vault-owner principal))
    (ok (map-get? recovery-requests vault-owner))
)