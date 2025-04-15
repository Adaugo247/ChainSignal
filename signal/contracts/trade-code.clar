;; Crypto Trading Strategy Smart Contract - Stage 2
;; A blockchain-based trading strategy system with time-locks and profit distribution

;; Constants
(define-constant ERR-NOT-STRATEGY-OWNER (err u1))
(define-constant ERR-STRATEGY-NOT-LIVE (err u2))
(define-constant ERR-INVALID-SIGNAL (err u3))
(define-constant ERR-ALREADY-EXECUTED (err u4))
(define-constant ERR-WRONG-EXECUTION-HASH (err u5))
(define-constant ERR-LOCKUP-PERIOD-ACTIVE (err u6))
(define-constant ERR-INVALID-PARAMETER (err u7))
(define-constant MAX-SIGNAL-ID u100) ;; Maximum allowed signal ID

;; Data Variables
(define-data-var strategy-owner principal tx-sender)
(define-data-var strategy-live bool false)
(define-data-var current-phase uint u0)
(define-data-var subscription-fee uint u1000000) ;; 1 STX
(define-data-var total-capital uint u0)
(define-data-var current-block-height uint u0) ;; Block height tracking for lockup periods

;; Signal Structure
(define-map trading-signals
    uint
    {
        description: (string-utf8 256),
        execution-hash: (buff 32), ;; SHA256 hash of the expected execution proof
        lockup-end: uint,          ;; Lockup period end block height
        profit-share: uint,
        executed: bool
    }
)

;; Trader Performance Tracking
(define-map trader-performance
    principal
    {
        current-signal: uint,
        executed-signals: (list 20 uint),
        last-trade: uint,
        total-executed: uint
    }
)

;; Signal Executions
(define-map signal-executions
    {signal: uint, trader: principal}
    {
        attempts: uint,
        executed-at: (optional uint)
    }
)

;; Authorization
(define-private (is-owner)
    (is-eq tx-sender (var-get strategy-owner)))

;; Block Height Management
(define-public (update-block-height (new-height uint))
    (begin
        (asserts! (is-owner) ERR-NOT-STRATEGY-OWNER)
        ;; Validate height is not less than current
        (asserts! (>= new-height (var-get current-block-height)) ERR-INVALID-PARAMETER)
        (var-set current-block-height new-height)
        (ok true)))

;; Strategy Management Functions
(define-public (activate-strategy)
    (begin
        (asserts! (is-owner) ERR-NOT-STRATEGY-OWNER)
        (var-set strategy-live true)
        (var-set current-phase u0)
        (var-set total-capital u0)
        (ok true)))

(define-public (add-signal
    (signal-id uint)
    (description (string-utf8 256))
    (execution-hash (buff 32))
    (lockup-end uint)
    (profit-share uint))
    (begin
        (asserts! (is-owner) ERR-NOT-STRATEGY-OWNER)
        
        ;; Validate signal-id is within acceptable range
        (asserts! (<= signal-id MAX-SIGNAL-ID) ERR-INVALID-PARAMETER)
        
        ;; Validate lockup end is in the future
        (asserts! (>= lockup-end (var-get current-block-height)) ERR-INVALID-PARAMETER)
        
        ;; Validate execution hash is not empty
        (asserts! (> (len execution-hash) u0) ERR-INVALID-PARAMETER)
        
        ;; Validate description is not empty
        (asserts! (> (len description) u0) ERR-INVALID-PARAMETER)
        
        ;; Validate profit share is a positive amount
        (asserts! (> profit-share u0) ERR-INVALID-PARAMETER)
        
        ;; Set the signal data
        (map-set trading-signals signal-id
            {
                description: description,
                execution-hash: execution-hash,
                lockup-end: lockup-end,
                profit-share: profit-share,
                executed: false
            })
            
        ;; Calculate new capital safely
        (let ((new-capital (+ (var-get total-capital) profit-share)))
            ;; Make sure the addition doesn't overflow
            (asserts! (>= new-capital (var-get total-capital)) ERR-INVALID-PARAMETER)
            ;; Update the total capital
            (var-set total-capital new-capital))
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
                executed-signals: (list),
                last-trade: u0,
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
        (current-height (var-get current-block-height))
        )
        ;; Check signal availability
        (asserts! (var-get strategy-live) ERR-STRATEGY-NOT-LIVE)
        (asserts! (>= current-height (get lockup-end signal)) ERR-LOCKUP-PERIOD-ACTIVE)
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
                        executed-signals: (unwrap! (as-max-len? 
                            (append (get executed-signals trader) signal-id) u20)
                            ERR-INVALID-SIGNAL),
                        last-trade: current-height,
                        total-executed: (+ (get total-executed trader) u1)
                    }))
                
                ;; Record execution
                (map-set signal-executions
                    {signal: signal-id, trader: tx-sender}
                    {
                        attempts: u1,
                        executed-at: (some current-height)
                    })
                
                ;; Distribute profit share
                (try! (stx-transfer? (get profit-share signal) (var-get strategy-owner) tx-sender))
                
                (ok true))
            ERR-WRONG-EXECUTION-HASH)))

;; Read-only functions
(define-read-only (get-signal-description (signal-id uint))
    (match (map-get? trading-signals signal-id)
        signal (if (>= (var-get current-block-height) (get lockup-end signal))
            (ok (get description signal))
            ERR-LOCKUP-PERIOD-ACTIVE)
        ERR-INVALID-SIGNAL))

(define-read-only (get-trader-status (trader principal))
    (map-get? trader-performance trader))

(define-read-only (get-execution-status (signal-id uint) (trader principal))
    (map-get? signal-executions {signal: signal-id, trader: trader}))

(define-read-only (get-current-block-height)
    (var-get current-block-height))

(define-read-only (get-strategy-stats)
    {
        live: (var-get strategy-live),
        current-phase: (var-get current-phase),
        total-capital: (var-get total-capital),
        subscription-fee: (var-get subscription-fee),
        current-block-height: (var-get current-block-height)
    })