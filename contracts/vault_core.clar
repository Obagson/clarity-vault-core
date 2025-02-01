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

;; Data vars
(define-data-var recovery-delay uint u144) ;; ~24 hours in blocks
(define-data-var key-expiration uint u4320) ;; ~30 days in blocks

;; Data maps
(define-map vaults
    principal
    {
        active: bool,
        created-at: uint,
        last-accessed: uint,
        require-rotation: bool,
        rotation-period: uint
    }
)

(define-map vault-keys
    { vault-owner: principal, key-id: (string-ascii 64) }
    {
        encrypted-key: (string-ascii 1024),
        added-at: uint,
        last-used: uint,
        expires-at: uint,
        rotation-count: uint
    }
)

(define-map recovery-requests
    principal  
    {
        requested-at: uint,
        backup-principal: principal
    }
)

(define-map key-history
    { vault-owner: principal, key-id: (string-ascii 64) }
    {
        previous-keys: (list 5 (string-ascii 1024)),
        rotation-timestamps: (list 5 uint)
    }
)

;; Initialize vault with rotation settings
(define-public (initialize-vault (require-rotation bool) (rotation-period uint))
    (let
        ((caller tx-sender))
        (asserts! (is-none (map-get? vaults caller)) err-already-exists)
        (ok (map-set vaults caller {
            active: true,
            created-at: block-height,
            last-accessed: block-height,
            require-rotation: require-rotation,
            rotation-period: rotation-period
        }))
    )
)

;; Add key to vault with expiration
(define-public (add-key (key-id (string-ascii 64)) (encrypted-key (string-ascii 1024)))
    (let
        ((caller tx-sender)
         (vault (unwrap! (map-get? vaults caller) err-invalid-vault)))
        (ok (map-set vault-keys 
            { vault-owner: caller, key-id: key-id }
            {
                encrypted-key: encrypted-key,
                added-at: block-height,
                last-used: block-height,
                expires-at: (+ block-height (var-get key-expiration)),
                rotation-count: u0
            }
        ))
    )
)

;; Get key from vault with expiration check
(define-public (get-key (key-id (string-ascii 64)))
    (let
        ((caller tx-sender)
         (key-data (unwrap! (map-get? vault-keys { vault-owner: caller, key-id: key-id }) err-invalid-vault))
         (vault (unwrap! (map-get? vaults caller) err-invalid-vault)))
        (asserts! (< block-height (get expires-at key-data)) err-key-expired)
        (map-set vault-keys
            { vault-owner: caller, key-id: key-id }
            (merge key-data
                  { last-used: block-height }))
        (ok (get encrypted-key key-data))
    )
)

;; Rotate key with history tracking
(define-public (rotate-key (key-id (string-ascii 64)) (new-encrypted-key (string-ascii 1024)))
    (let
        ((caller tx-sender)
         (key-data (unwrap! (map-get? vault-keys { vault-owner: caller, key-id: key-id }) err-invalid-vault))
         (vault (unwrap! (map-get? vaults caller) err-invalid-vault))
         (history (default-to 
            { previous-keys: (list), rotation-timestamps: (list) }
            (map-get? key-history { vault-owner: caller, key-id: key-id })))
         (old-key (get encrypted-key key-data)))
        
        (asserts! (or 
            (get require-rotation vault)
            (>= block-height (+ (get last-used key-data) (get rotation-period vault)))
        ) err-invalid-rotation)
        
        (map-set vault-keys
            { vault-owner: caller, key-id: key-id }
            {
                encrypted-key: new-encrypted-key,
                added-at: block-height,
                last-used: block-height,
                expires-at: (+ block-height (var-get key-expiration)),
                rotation-count: (+ (get rotation-count key-data) u1)
            })
        
        (map-set key-history
            { vault-owner: caller, key-id: key-id }
            {
                previous-keys: (unwrap! (as-max-len? (append (get previous-keys history) old-key) u5) err-invalid-rotation),
                rotation-timestamps: (unwrap! (as-max-len? (append (get rotation-timestamps history) block-height) u5) err-invalid-rotation)
            })
        
        (ok true)
    )
)

;; Get key rotation history
(define-read-only (get-key-history (key-id (string-ascii 64)))
    (ok (map-get? key-history { vault-owner: tx-sender, key-id: key-id }))
)

[previous functions remain unchanged...]
