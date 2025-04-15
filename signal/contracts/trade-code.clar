;; Crypto Trading Strategy Smart Contract
;; A simple blockchain-based trading strategy system

;; Constants
(define-constant ERR-NOT-STRATEGY-OWNER (err u1))
(define-constant ERR-STRATEGY-NOT-LIVE (err u2))
(define-constant ERR-INVALID-SIGNAL (err u3))
(define-constant ERR-ALREADY-EXECUTED (err u4))
(define-constant ERR-WRONG-EXECUTION-HASH (err u5))

;; Data Variables
(define-data-var strategy-owner principal tx-sender)
(define-data-var strategy-live bool false)
(define-data-var subscription-fee uint u1000000) ;; 1 STX
(define-data-var total-capital uint u0)

;; Signal Structure
(define-map trading-signals
    uint
    {
        description: (string-utf8 256),
        execution-hash: (buff 32),
        executed: bool
    }
)

;; Trader Performance Tracking
(define-map trader-performance
    principal
    {
        current-signal: uint,
        total-executed: uint
    }
)

;; Authorization
(define-private (is-owner)
    (is-eq tx-sender (var-get strategy-owner)))

;; Strategy Management Functions
(define-public (activate-strategy)
    (begin
        (asserts! (is-owner) ERR-NOT-STRATEGY-OWNER)
        (var-set strategy-live true)
        (var-set total-capital u0)
        (ok true)))

(define-public (add-signal
    (signal-id uint)
    (description (string-utf8 256))
    (execution-hash (buff 32)))
    (begin
        (asserts! (is-owner) ERR-NOT-STRATEGY-OWNER)
        
        ;; Validate execution hash is not empty
        (asserts! (> (len execution-hash) u0) ERR-NOT-STRATEGY-OWNER)
        
        ;; Validate description is not empty
        (asserts! (> (len description) u0) ERR-NOT-STRATEGY-OWNER)
        
        ;; Set the signal data
        (map-set trading-signals signal-id
            {
                description: description,
                execution-hash: execution-hash,
                executed: false
            })
            
        (ok true)))

;; Trader Onboarding
(define-public (subscribe-to-signals)
    (begin
        (asserts! (var-get strategy-live) ERR-STRATEGY-NOT-LIVE)
        ;; Require subscription fee
        (try! (stx-transfer? (var-get subscription-fee) tx-sender (var-get strategy-owner)))
        
        (map-set trader-performance tx-sender
            {
                current-signal: u0,
                total-executed: u0
            })
        (ok true)))

;; Signal Execution Functions
(define-public (execute-signal
    (signal-id uint)
    (execution-proof (buff 32)))
    (let (
        (signal (unwrap! (map-get? trading-signals signal-id) ERR-INVALID-SIGNAL))
        (trader (unwrap! (map-get? trader-performance tx-sender) ERR-INVALID-SIGNAL))
        )
        ;; Check signal availability
        (asserts! (var-get strategy-live) ERR-STRATEGY-NOT-LIVE)
        (asserts! (not (get executed signal)) ERR-ALREADY-EXECUTED)
        
        ;; Verify execution proof - directly compare the hashes
        (if (is-eq execution-proof (get execution-hash signal))
            (begin
                ;; Update signal status
                (map-set trading-signals signal-id
                    (merge signal {executed: true}))
                
                ;; Update trader performance
                (map-set trader-performance tx-sender
                    (merge trader {
                        current-signal: (+ signal-id u1),
                        total-executed: (+ (get total-executed trader) u1)
                    }))
                
                (ok true))
            ERR-WRONG-EXECUTION-HASH)))

;; Read-only functions
(define-read-only (get-signal-description (signal-id uint))
    (match (map-get? trading-signals signal-id)
        signal (ok (get description signal))
        ERR-INVALID-SIGNAL))

(define-read-only (get-trader-status (trader principal))
    (map-get? trader-performance trader))

(define-read-only (get-strategy-stats)
    {
        live: (var-get strategy-live),
        total-capital: (var-get total-capital),
        subscription-fee: (var-get subscription-fee)
    })