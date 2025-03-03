;; VaultCore
;; Secure platform for managing crypto keys

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-unauthorized (err u101)) 
(define-constant err-invalid-vault (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-key-expired (err u104))
(define-constant err-invalid-rotation (err u105))
(define-constant err-invalid-period (err u106))
(define-constant min-rotation-period u24) ;; Minimum 24 blocks for rotation

;; Initialize vault with rotation settings
(define-public (initialize-vault (require-rotation bool) (rotation-period uint))
    (let
        ((caller tx-sender))
        (asserts! (is-none (map-get? vaults caller)) err-already-exists)
        (asserts! (>= rotation-period min-rotation-period) err-invalid-period)
        (ok (map-set vaults caller {
            active: true,
            created-at: block-height,
            last-accessed: block-height,
            require-rotation: require-rotation,
            rotation-period: rotation-period
        }))
    )
)

;; Get key rotation history
(define-public (get-key-history (key-id (string-ascii 64)))
    (let
        ((caller tx-sender)
         (vault (map-get? vaults caller)))
        ;; Check if vault exists first
        (asserts! (is-some vault) err-invalid-vault)
        (ok (map-get? key-history { vault-owner: caller, key-id: key-id }))
    )
)
