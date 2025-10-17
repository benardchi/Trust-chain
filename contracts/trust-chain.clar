;; ----------------------------------------------------
;; TrustChain - Decentralized Reputation System
;; Purpose: Maintain transparent and tamper-proof reputation scores
;; Use cases: Marketplaces, DAOs, lending, hiring
;; ----------------------------------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Constants & Errors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-constant ERR-NOT-VERIFIER (err u100))
(define-constant ERR-NOT-AUTHORIZED (err u101))
(define-constant ERR-USER-NOT-FOUND (err u102))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Data Structures
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Map of user -> reputation score
(define-map reputations
  { user: principal }
  { score: int })

;; Map of user -> list of actions (for audit logs)
(define-map actions
  { id: uint }
  {
    user: principal,
    verifier: principal,
    delta: int,
    reason: (string-ascii 100)
  })

;; Verifiers who can adjust reputation
(define-map verifiers
  { verifier: principal }
  { approved: bool })

(define-data-var next-action-id uint u1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Admin Functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Contract deployer is admin
(define-constant contract-admin tx-sender)

(define-public (add-verifier (v principal))
  (begin
    (asserts! (is-eq tx-sender contract-admin) ERR-NOT-AUTHORIZED)
    (map-set verifiers { verifier: v } { approved: true })
    (ok true)))

(define-public (remove-verifier (v principal))
  (begin
    (asserts! (is-eq tx-sender contract-admin) ERR-NOT-AUTHORIZED)
    (map-delete verifiers { verifier: v })
    (ok true)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Core Reputation Logic
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-public (adjust-reputation (user principal) (delta int) (reason (string-ascii 100)))
  (begin
    ;; only verifier can call
    (asserts! (default-to false (get approved (map-get? verifiers { verifier: tx-sender }))) ERR-NOT-VERIFIER)

    ;; get old score or start from 0
    (let ((old-score (default-to 0 (get score (map-get? reputations { user: user }))))
          (new-id (var-get next-action-id)))
      
      ;; update reputation
      (map-set reputations { user: user } { score: (+ old-score delta) })

      ;; log the action
      (map-set actions { id: new-id }
        { user: user, verifier: tx-sender, delta: delta, reason: reason })
      (var-set next-action-id (+ new-id u1))

      (ok true)
    )
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Read-Only Queries
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-read-only (get-score (user principal))
  (default-to 0 (get score (map-get? reputations { user: user }))))


(define-read-only (is-verifier (v principal))
  (default-to false (get approved (map-get? verifiers { verifier: v }))))


(define-read-only (get-action (id uint))
  (map-get? actions { id: id }))
