(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVESTMENT_EXISTS (err u101))
(define-constant ERR_INVESTMENT_NOT_FOUND (err u102))
(define-constant ERR_INVALID_SCORE (err u103))
(define-constant ERR_INVALID_AMOUNT (err u104))
(define-constant ERR_PORTFOLIO_EMPTY (err u105))
(define-constant ERR_INVALID_PRICE (err u106))
(define-constant ERR_PRICE_NOT_SET (err u107))
(define-constant ERR_ALREADY_VOTED (err u108))
(define-constant ERR_VERIFICATION_NOT_FOUND (err u109))
(define-constant ERR_INSUFFICIENT_REPUTATION (err u110))
(define-constant ERR_VOTING_CLOSED (err u111))
(define-constant ERR_GOAL_NOT_FOUND (err u112))
(define-constant ERR_INVALID_GOAL (err u113))
(define-constant ERR_GOAL_EXISTS (err u114))

(define-constant ERR_INVALID_WEIGHT (err u115))
(define-constant ERR_PREFERENCES_NOT_SET (err u116))

(define-data-var contract-active bool true)
(define-data-var total-investments uint u0)
(define-data-var verification-counter uint u0)
(define-data-var min-reputation-to-vote uint u10)

(define-map investments
  { investment-id: uint }
  {
    name: (string-ascii 50),
    symbol: (string-ascii 10),
    environmental-score: uint,
    social-score: uint,
    governance-score: uint,
    overall-score: uint,
    sector: (string-ascii 30),
    creator: principal,
    current-price: uint,
    last-price-update: uint
  }
)

(define-map price-history
  { investment-id: uint, block-height: uint }
  {
    price: uint,
    timestamp: uint
  }
)

(define-map user-portfolios
  { user: principal, investment-id: uint }
  {
    amount: uint,
    purchase-price: uint,
    purchase-block: uint
  }
)

(define-map user-portfolio-count
  { user: principal }
  { count: uint }
)

(define-map investment-holders
  { investment-id: uint }
  { holder-count: uint }
)

(define-map verifier-reputation
  { verifier: principal }
  { reputation-score: uint, total-votes: uint, accurate-votes: uint }
)

(define-map esg-verifications
  { verification-id: uint }
  {
    investment-id: uint,
    proposed-env-score: uint,
    proposed-social-score: uint,
    proposed-gov-score: uint,
    proposer: principal,
    voting-end-block: uint,
    total-votes: uint,
    approval-votes: uint,
    status: uint
  }
)

(define-map verification-votes
  { verification-id: uint, voter: principal }
  { vote: bool, voting-power: uint }
)

(define-map ethical-goals
  { user: principal }
  {
    min-environmental-score: uint,
    min-social-score: uint,
    min-governance-score: uint,
    min-overall-score: uint,
    created-at: uint,
    last-checked: uint,
    is-active: bool
  }
)

(define-map goal-compliance-history
  { user: principal, check-block: uint }
  {
    was-compliant: bool,
    portfolio-env-score: uint,
    portfolio-social-score: uint,
    portfolio-gov-score: uint,
    portfolio-overall-score: uint
  }
)

(define-map user-achievements
  { user: principal }
  {
    total-checks: uint,
    compliant-checks: uint,
    current-streak: uint,
    longest-streak: uint,
    last-achievement-block: uint
  }
)

(define-map user-esg-preferences
  { user: principal }
  {
    env-weight: uint,
    social-weight: uint,
    gov-weight: uint,
    created-at: uint
  }
)

(define-public (add-investment 
  (name (string-ascii 50))
  (symbol (string-ascii 10))
  (environmental-score uint)
  (social-score uint)
  (governance-score uint)
  (sector (string-ascii 30)))
  (let 
    (
      (investment-id (+ (var-get total-investments) u1))
      (overall-score (/ (+ environmental-score social-score governance-score) u3))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (and (<= environmental-score u100) (<= social-score u100) (<= governance-score u100)) ERR_INVALID_SCORE)
    (asserts! (is-none (map-get? investments { investment-id: investment-id })) ERR_INVESTMENT_EXISTS)
    
    (map-set investments
      { investment-id: investment-id }
      {
        name: name,
        symbol: symbol,
        environmental-score: environmental-score,
        social-score: social-score,
        governance-score: governance-score,
        overall-score: overall-score,
        sector: sector,
        creator: tx-sender,
        current-price: u0,
        last-price-update: u0
      }
    )
    
    (map-set investment-holders
      { investment-id: investment-id }
      { holder-count: u0 }
    )
    
    (var-set total-investments investment-id)
    (ok investment-id)
  )
)

(define-private (apply-price-update (update { investment-id: uint, new-price: uint }) (acc { updated: uint, failed: uint }))
  (let 
    (
      (investment (map-get? investments { investment-id: (get investment-id update) }))
      (price (get new-price update))
    )
    (if (and (is-some investment) (> price u0))
      (let 
        (
          (inv (unwrap-panic investment))
        )
        (map-set investments
          { investment-id: (get investment-id update) }
          (merge inv {
            current-price: price,
            last-price-update: stacks-block-height
          })
        )
        (map-set price-history
          { investment-id: (get investment-id update), block-height: stacks-block-height }
          {
            price: price,
            timestamp: stacks-block-height
          }
        )
        {
          updated: (+ (get updated acc) u1),
          failed: (get failed acc)
        }
      )
      {
        updated: (get updated acc),
        failed: (+ (get failed acc) u1)
      }
    )
  )
)

(define-public (batch-update-investment-prices (updates (list 20 { investment-id: uint, new-price: uint })))
  (begin
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (ok (fold apply-price-update updates { updated: u0, failed: u0 }))
  )
)
(define-public (add-to-portfolio 
  (investment-id uint)
  (amount uint)
  (purchase-price uint))
  (let 
    (
      (investment (unwrap! (map-get? investments { investment-id: investment-id }) ERR_INVESTMENT_NOT_FOUND))
      (current-count (default-to u0 (get count (map-get? user-portfolio-count { user: tx-sender }))))
      (existing-holding (map-get? user-portfolios { user: tx-sender, investment-id: investment-id }))
      (holder-info (unwrap! (map-get? investment-holders { investment-id: investment-id }) ERR_INVESTMENT_NOT_FOUND))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> purchase-price u0) ERR_INVALID_AMOUNT)
    
    (if (is-some existing-holding)
      (let ((current-holding (unwrap-panic existing-holding)))
        (map-set user-portfolios
          { user: tx-sender, investment-id: investment-id }
          {
            amount: (+ (get amount current-holding) amount),
            purchase-price: (get purchase-price current-holding),
            purchase-block: (get purchase-block current-holding)
          }
        )
      )
      (begin
        (map-set user-portfolios
          { user: tx-sender, investment-id: investment-id }
          {
            amount: amount,
            purchase-price: purchase-price,
            purchase-block: stacks-block-height
          }
        )
        (map-set user-portfolio-count
          { user: tx-sender }
          { count: (+ current-count u1) }
        )
        (map-set investment-holders
          { investment-id: investment-id }
          { holder-count: (+ (get holder-count holder-info) u1) }
        )
      )
    )
    (ok true)
  )
)

(define-public (remove-from-portfolio (investment-id uint) (amount uint))
  (let 
    (
      (holding (unwrap! (map-get? user-portfolios { user: tx-sender, investment-id: investment-id }) ERR_INVESTMENT_NOT_FOUND))
      (current-amount (get amount holding))
      (current-count (default-to u0 (get count (map-get? user-portfolio-count { user: tx-sender }))))
      (holder-info (unwrap! (map-get? investment-holders { investment-id: investment-id }) ERR_INVESTMENT_NOT_FOUND))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (>= current-amount amount) ERR_INVALID_AMOUNT)
    
    (if (is-eq current-amount amount)
      (begin
        (map-delete user-portfolios { user: tx-sender, investment-id: investment-id })
        (map-set user-portfolio-count
          { user: tx-sender }
          { count: (- current-count u1) }
        )
        (map-set investment-holders
          { investment-id: investment-id }
          { holder-count: (- (get holder-count holder-info) u1) }
        )
      )
      (map-set user-portfolios
        { user: tx-sender, investment-id: investment-id }
        {
          amount: (- current-amount amount),
          purchase-price: (get purchase-price holding),
          purchase-block: (get purchase-block holding)
        }
      )
    )
    (ok true)
  )
)

(define-read-only (get-investment (investment-id uint))
  (map-get? investments { investment-id: investment-id })
)

(define-read-only (get-portfolio-holding (user principal) (investment-id uint))
  (map-get? user-portfolios { user: user, investment-id: investment-id })
)

(define-read-only (get-portfolio-count (user principal))
  (default-to u0 (get count (map-get? user-portfolio-count { user: user })))
)

(define-read-only (get-investment-holders (investment-id uint))
  (default-to u0 (get holder-count (map-get? investment-holders { investment-id: investment-id })))
)

(define-read-only (calculate-portfolio-ethics (user principal))
  (let 
    (
      (portfolio-count (get-portfolio-count user))
    )
    (if (is-eq portfolio-count u0)
      (err ERR_PORTFOLIO_EMPTY)
      (ok (fold calculate-ethics-helper (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20) 
               { user: user, total-env: u0, total-social: u0, total-gov: u0, total-overall: u0, count: u0 }))
    )
  )
)

(define-private (calculate-ethics-helper (investment-id uint) (acc { user: principal, total-env: uint, total-social: uint, total-gov: uint, total-overall: uint, count: uint }))
  (let 
    (
      (holding (map-get? user-portfolios { user: (get user acc), investment-id: investment-id }))
      (investment (map-get? investments { investment-id: investment-id }))
    )
    (if (and (is-some holding) (is-some investment))
      (let 
        (
          (inv-data (unwrap-panic investment))
          (current-count (get count acc))
        )
        {
          user: (get user acc),
          total-env: (+ (get total-env acc) (get environmental-score inv-data)),
          total-social: (+ (get total-social acc) (get social-score inv-data)),
          total-gov: (+ (get total-gov acc) (get governance-score inv-data)),
          total-overall: (+ (get total-overall acc) (get overall-score inv-data)),
          count: (+ current-count u1)
        }
      )
      acc
    )
  )
)

(define-read-only (filter-portfolio-by-environmental (user principal) (min-score uint))
  (get results (fold filter-env-helper (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)
             { user: user, min-score: min-score, results: (list) }))
)

(define-private (filter-env-helper (investment-id uint) (acc { user: principal, min-score: uint, results: (list 10 uint) }))
  (let 
    (
      (holding (map-get? user-portfolios { user: (get user acc), investment-id: investment-id }))
      (investment (map-get? investments { investment-id: investment-id }))
    )
    (if (and (is-some holding) (is-some investment))
      (let 
        (
          (inv-data (unwrap-panic investment))
          (current-results (get results acc))
        )
        (if (>= (get environmental-score inv-data) (get min-score acc))
          {
            user: (get user acc),
            min-score: (get min-score acc),
            results: (default-to current-results (as-max-len? (append current-results investment-id) u10))
          }
          acc
        )
      )
      acc
    )
  )
)

(define-read-only (filter-portfolio-by-social (user principal) (min-score uint))
  (ok (get results (fold filter-social-helper (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)
             { user: user, min-score: min-score, results: (list) })))
)

(define-private (filter-social-helper (investment-id uint) (acc { user: principal, min-score: uint, results: (list 10 uint) }))
  (let 
    (
      (holding (map-get? user-portfolios { user: (get user acc), investment-id: investment-id }))
      (investment (map-get? investments { investment-id: investment-id }))
    )
    (if (and (is-some holding) (is-some investment))
      (let 
        (
          (inv-data (unwrap-panic investment))
          (current-results (get results acc))
        )
        (if (>= (get social-score inv-data) (get min-score acc))
          {
            user: (get user acc),
            min-score: (get min-score acc),
            results: (default-to current-results (as-max-len? (append current-results investment-id) u10))
          }
          acc
        )
      )
      acc
    )
  )
)

(define-read-only (filter-portfolio-by-governance (user principal) (min-score uint))
  (ok (get results (fold filter-gov-helper (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)
             { user: user, min-score: min-score, results: (list) })))
)

(define-private (filter-gov-helper (investment-id uint) (acc { user: principal, min-score: uint, results: (list 10 uint) }))
  (let 
    (
      (holding (map-get? user-portfolios { user: (get user acc), investment-id: investment-id }))
      (investment (map-get? investments { investment-id: investment-id }))
    )
    (if (and (is-some holding) (is-some investment))
      (let 
        (
          (inv-data (unwrap-panic investment))
          (current-results (get results acc))
        )
        (if (>= (get governance-score inv-data) (get min-score acc))
          {
            user: (get user acc),
            min-score: (get min-score acc),
            results: (default-to current-results (as-max-len? (append current-results investment-id) u10))
          }
          acc
        )
      )
      acc
    )
  )
)

(define-read-only (filter-portfolio-by-overall (user principal) (min-score uint))
  (ok (get results (fold filter-overall-helper (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)
             { user: user, min-score: min-score, results: (list) })))
)

(define-private (filter-overall-helper (investment-id uint) (acc { user: principal, min-score: uint, results: (list 10 uint) }))
  (let 
    (
      (holding (map-get? user-portfolios { user: (get user acc), investment-id: investment-id }))
      (investment (map-get? investments { investment-id: investment-id }))
    )
    (if (and (is-some holding) (is-some investment))
      (let 
        (
          (inv-data (unwrap-panic investment))
          (current-results (get results acc))
        )
        (if (>= (get overall-score inv-data) (get min-score acc))
          {
            user: (get user acc),
            min-score: (get min-score acc),
            results: (default-to current-results (as-max-len? (append current-results investment-id) u10))
          }
          acc
        )
      )
      acc
    )
  )
)

(define-read-only (filter-by-sector (user principal) (sector (string-ascii 30)))
  (ok (get results (fold filter-sector-helper (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)
             { user: user, sector: sector, results: (list) })))
)

(define-private (filter-sector-helper (investment-id uint) (acc { user: principal, sector: (string-ascii 30), results: (list 10 uint) }))
  (let 
    (
      (holding (map-get? user-portfolios { user: (get user acc), investment-id: investment-id }))
      (investment (map-get? investments { investment-id: investment-id }))
    )
    (if (and (is-some holding) (is-some investment))
      (let 
        (
          (inv-data (unwrap-panic investment))
          (current-results (get results acc))
        )
        (if (is-eq (get sector inv-data) (get sector acc))
          {
            user: (get user acc),
            sector: (get sector acc),
            results: (default-to current-results (as-max-len? (append current-results investment-id) u10))
          }
          acc
        )
      )
      acc
    )
  )
)

(define-read-only (get-total-investments)
  (var-get total-investments)
)

(define-read-only (is-contract-active)
  (var-get contract-active)
)

(define-public (toggle-contract-active)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set contract-active (not (var-get contract-active)))
    (ok (var-get contract-active))
  )
)

(define-public (update-investment-price (investment-id uint) (new-price uint))
  (let 
    (
      (investment (unwrap! (map-get? investments { investment-id: investment-id }) ERR_INVESTMENT_NOT_FOUND))
      (old-price (get current-price investment))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (> new-price u0) ERR_INVALID_PRICE)
    
    (map-set investments
      { investment-id: investment-id }
      (merge investment {
        current-price: new-price,
        last-price-update: stacks-block-height
      })
    )
    
    (map-set price-history
      { investment-id: investment-id, block-height: stacks-block-height }
      {
        price: new-price,
        timestamp: stacks-block-height
      }
    )
    
    (ok { old-price: old-price, new-price: new-price, change: (if (> new-price old-price) (- new-price old-price) (- old-price new-price)) })
  )
)

(define-read-only (get-investment-price (investment-id uint))
  (let 
    (
      (investment (unwrap! (map-get? investments { investment-id: investment-id }) ERR_INVESTMENT_NOT_FOUND))
    )
    (ok {
      current-price: (get current-price investment),
      last-update: (get last-price-update investment)
    })
  )
)

(define-read-only (calculate-portfolio-value (user principal))
  (let 
    (
      (portfolio-count (get-portfolio-count user))
    )
    (if (is-eq portfolio-count u0)
      (err ERR_PORTFOLIO_EMPTY)
      (ok (fold calculate-value-helper (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)
               { user: user, total-value: u0, total-cost: u0, count: u0 }))
    )
  )
)

(define-private (calculate-value-helper (investment-id uint) (acc { user: principal, total-value: uint, total-cost: uint, count: uint }))
  (let 
    (
      (holding (map-get? user-portfolios { user: (get user acc), investment-id: investment-id }))
      (investment (map-get? investments { investment-id: investment-id }))
    )
    (if (and (is-some holding) (is-some investment))
      (let 
        (
          (holding-data (unwrap-panic holding))
          (investment-data (unwrap-panic investment))
          (current-price (get current-price investment-data))
          (amount (get amount holding-data))
          (purchase-price (get purchase-price holding-data))
          (current-value (* amount current-price))
          (original-cost (* amount purchase-price))
        )
        {
          user: (get user acc),
          total-value: (+ (get total-value acc) current-value),
          total-cost: (+ (get total-cost acc) original-cost),
          count: (+ (get count acc) u1)
        }
      )
      acc
    )
  )
)

(define-read-only (calculate-investment-return (user principal) (investment-id uint))
  (let 
    (
      (holding (unwrap! (map-get? user-portfolios { user: user, investment-id: investment-id }) ERR_INVESTMENT_NOT_FOUND))
      (investment (unwrap! (map-get? investments { investment-id: investment-id }) ERR_INVESTMENT_NOT_FOUND))
      (current-price (get current-price investment))
      (purchase-price (get purchase-price holding))
      (amount (get amount holding))
    )
    (asserts! (> current-price u0) ERR_PRICE_NOT_SET)
    (asserts! (> purchase-price u0) ERR_PRICE_NOT_SET)
    
    (let 
      (
        (current-value (* amount current-price))
        (original-cost (* amount purchase-price))
        (absolute-return (if (> current-value original-cost) 
                           (- current-value original-cost) 
                           (- original-cost current-value)))
        (is-profit (> current-value original-cost))
        (return-percentage (if (> original-cost u0) 
                             (/ (* absolute-return u100) original-cost) 
                             u0))
      )
      (ok {
        original-cost: original-cost,
        current-value: current-value,
        absolute-return: absolute-return,
        return-percentage: return-percentage,
        is-profit: is-profit
      })
    )
  )
)

(define-read-only (get-price-history (investment-id uint) (target-block uint))
  (map-get? price-history { investment-id: investment-id, block-height: target-block })
)

(define-read-only (calculate-portfolio-return (user principal))
  (let 
    (
      (portfolio-value-result (calculate-portfolio-value user))
    )
    (match portfolio-value-result
      success 
        (let 
          (
            (total-value (get total-value success))
            (total-cost (get total-cost success))
            (absolute-return (if (> total-value total-cost) 
                               (- total-value total-cost) 
                               (- total-cost total-value)))
            (is-profit (> total-value total-cost))
            (return-percentage (if (> total-cost u0) 
                                 (/ (* absolute-return u100) total-cost) 
                                 u0))
          )
          (ok {
            total-cost: total-cost,
            total-value: total-value,
            absolute-return: absolute-return,
            return-percentage: return-percentage,
            is-profit: is-profit,
            investment-count: (get count success)
          })
        )
      error (err error)
    )
  )
)

(define-read-only (get-top-performers (user principal))
  (ok (fold performance-ranking-helper (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)
           { user: user, performers: (list) }))
)

(define-private (performance-ranking-helper (investment-id uint) (acc { user: principal, performers: (list 5 { investment-id: uint, return-percentage: uint }) }))
  (let 
    (
      (holding (map-get? user-portfolios { user: (get user acc), investment-id: investment-id }))
      (investment (map-get? investments { investment-id: investment-id }))
    )
    (if (and (is-some holding) (is-some investment))
      (let 
        (
          (holding-data (unwrap-panic holding))
          (investment-data (unwrap-panic investment))
          (current-price (get current-price investment-data))
          (purchase-price (get purchase-price holding-data))
          (amount (get amount holding-data))
          (current-performers (get performers acc))
        )
        (if (and (> current-price u0) (> purchase-price u0))
          (let 
            (
              (current-value (* amount current-price))
              (original-cost (* amount purchase-price))
              (return-percentage (if (> original-cost u0) 
                                   (/ (* (if (> current-value original-cost) 
                                           (- current-value original-cost) 
                                           u0) u100) original-cost) 
                                   u0))
              (performance-entry { investment-id: investment-id, return-percentage: return-percentage })
            )
            {
              user: (get user acc),
              performers: (default-to current-performers 
                            (as-max-len? (append current-performers performance-entry) u5))
            }
          )
          acc
        )
      )
      acc
    )
  )
)
(define-public (propose-esg-verification 
  (investment-id uint)
  (proposed-env-score uint)
  (proposed-social-score uint)
  (proposed-gov-score uint))
  (let 
    (
      (verification-id (+ (var-get verification-counter) u1))
      (investment (unwrap! (map-get? investments { investment-id: investment-id }) ERR_INVESTMENT_NOT_FOUND))
      (proposer-reputation (default-to { reputation-score: u0, total-votes: u0, accurate-votes: u0 } 
                             (map-get? verifier-reputation { verifier: tx-sender })))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (and (<= proposed-env-score u100) (<= proposed-social-score u100) (<= proposed-gov-score u100)) ERR_INVALID_SCORE)
    (asserts! (>= (get reputation-score proposer-reputation) (var-get min-reputation-to-vote)) ERR_INSUFFICIENT_REPUTATION)
    
    (map-set esg-verifications
      { verification-id: verification-id }
      {
        investment-id: investment-id,
        proposed-env-score: proposed-env-score,
        proposed-social-score: proposed-social-score,
        proposed-gov-score: proposed-gov-score,
        proposer: tx-sender,
        voting-end-block: (+ stacks-block-height u144),
        total-votes: u0,
        approval-votes: u0,
        status: u0
      }
    )
    
    (var-set verification-counter verification-id)
    (ok verification-id)
  )
)

(define-public (vote-on-verification (verification-id uint) (approve bool))
  (let 
    (
      (verification (unwrap! (map-get? esg-verifications { verification-id: verification-id }) ERR_VERIFICATION_NOT_FOUND))
      (voter-reputation (default-to { reputation-score: u0, total-votes: u0, accurate-votes: u0 } 
                          (map-get? verifier-reputation { verifier: tx-sender })))
      (existing-vote (map-get? verification-votes { verification-id: verification-id, voter: tx-sender }))
      (voting-power (let ((calculated-power (/ (get reputation-score voter-reputation) u10)))
                      (if (> calculated-power u0) calculated-power u1)))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (>= (get reputation-score voter-reputation) (var-get min-reputation-to-vote)) ERR_INSUFFICIENT_REPUTATION)
    (asserts! (< stacks-block-height (get voting-end-block verification)) ERR_VOTING_CLOSED)
    (asserts! (is-none existing-vote) ERR_ALREADY_VOTED)
    (asserts! (is-eq (get status verification) u0) ERR_VOTING_CLOSED)
    
    (map-set verification-votes
      { verification-id: verification-id, voter: tx-sender }
      { vote: approve, voting-power: voting-power }
    )
    
    (map-set esg-verifications
      { verification-id: verification-id }
      (merge verification {
        total-votes: (+ (get total-votes verification) voting-power),
        approval-votes: (+ (get approval-votes verification) (if approve voting-power u0))
      })
    )
    
    (ok true)
  )
)

(define-public (finalize-verification (verification-id uint))
  (let 
    (
      (verification (unwrap! (map-get? esg-verifications { verification-id: verification-id }) ERR_VERIFICATION_NOT_FOUND))
      (investment (unwrap! (map-get? investments { investment-id: (get investment-id verification) }) ERR_INVESTMENT_NOT_FOUND))
      (approval-rate (if (> (get total-votes verification) u0) 
                       (/ (* (get approval-votes verification) u100) (get total-votes verification))
                       u0))
      (is-approved (>= approval-rate u60))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (>= stacks-block-height (get voting-end-block verification)) ERR_VOTING_CLOSED)
    (asserts! (is-eq (get status verification) u0) ERR_VOTING_CLOSED)
    
    (if is-approved
      (let 
        (
          (new-overall-score (/ (+ (get proposed-env-score verification) 
                                   (get proposed-social-score verification) 
                                   (get proposed-gov-score verification)) u3))
        )
        (map-set investments
          { investment-id: (get investment-id verification) }
          (merge investment {
            environmental-score: (get proposed-env-score verification),
            social-score: (get proposed-social-score verification),
            governance-score: (get proposed-gov-score verification),
            overall-score: new-overall-score
          })
        )
        (map-set esg-verifications
          { verification-id: verification-id }
          (merge verification { status: u1 })
        )
        (unwrap-panic (update-verifier-reputation (get proposer verification) true))
      )
      (begin
        (map-set esg-verifications
          { verification-id: verification-id }
          (merge verification { status: u2 })
        )
        (unwrap-panic (update-verifier-reputation (get proposer verification) false))
      )
    )
    
    (ok is-approved)
  )
)

(define-private (update-verifier-reputation (verifier principal) (was-accurate bool))
  (let 
    (
      (current-rep (default-to { reputation-score: u0, total-votes: u0, accurate-votes: u0 } 
                     (map-get? verifier-reputation { verifier: verifier })))
      (new-total-votes (+ (get total-votes current-rep) u1))
      (new-accurate-votes (+ (get accurate-votes current-rep) (if was-accurate u1 u0)))
      (new-reputation-score (if (> new-total-votes u0) 
                              (/ (* new-accurate-votes u100) new-total-votes)
                              u0))
    )
    (map-set verifier-reputation
      { verifier: verifier }
      {
        reputation-score: new-reputation-score,
        total-votes: new-total-votes,
        accurate-votes: new-accurate-votes
      }
    )
    (ok true)
  )
)

(define-read-only (get-verification (verification-id uint))
  (map-get? esg-verifications { verification-id: verification-id })
)

(define-read-only (get-verifier-reputation (verifier principal))
  (map-get? verifier-reputation { verifier: verifier })
)

(define-read-only (get-verification-vote (verification-id uint) (voter principal))
  (map-get? verification-votes { verification-id: verification-id, voter: voter })
)

(define-read-only (get-active-verifications)
  (ok (fold collect-active-verifications (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)
           { results: (list), current-block: stacks-block-height }))
)

(define-private (collect-active-verifications (verification-id uint) (acc { results: (list 10 uint), current-block: uint }))
  (let 
    (
      (verification (map-get? esg-verifications { verification-id: verification-id }))
      (current-results (get results acc))
    )
    (if (is-some verification)
      (let 
        (
          (verification-data (unwrap-panic verification))
        )
        (if (and (< (get current-block acc) (get voting-end-block verification-data))
                 (is-eq (get status verification-data) u0))
          {
            results: (default-to current-results 
                       (as-max-len? (append current-results verification-id) u10)),
            current-block: (get current-block acc)
          }
          acc
        )
      )
      acc
    )
  )
)

(define-read-only (calculate-consensus-score (investment-id uint))
  (let 
    (
      (investment (unwrap! (map-get? investments { investment-id: investment-id }) ERR_INVESTMENT_NOT_FOUND))
      (verification-count (fold count-verifications (list u1 u2 u3 u4 u5 u6 u7 u8 u9 u10 u11 u12 u13 u14 u15 u16 u17 u18 u19 u20)
                            { target-investment: investment-id, count: u0 }))
    )
    (ok {
      current-scores: {
        environmental: (get environmental-score investment),
        social: (get social-score investment),
        governance: (get governance-score investment),
        overall: (get overall-score investment)
      },
      verification-count: (get count verification-count),
      consensus-strength: (let ((calculated-strength (* (get count verification-count) u10)))
                        (if (< calculated-strength u100) calculated-strength u100))
    })
  )
)

(define-private (count-verifications (verification-id uint) (acc { target-investment: uint, count: uint }))
  (let 
    (
      (verification (map-get? esg-verifications { verification-id: verification-id }))
    )
    (if (is-some verification)
      (let 
        (
          (verification-data (unwrap-panic verification))
        )
        (if (and (is-eq (get investment-id verification-data) (get target-investment acc))
                 (is-eq (get status verification-data) u1))
          {
            target-investment: (get target-investment acc),
            count: (+ (get count acc) u1)
          }
          acc
        )
      )
      acc
    )
  )
)

(define-read-only (get-verification-counter)
  (var-get verification-counter)
)

(define-read-only (get-min-reputation-to-vote)
  (var-get min-reputation-to-vote)
)

(define-public (set-min-reputation-to-vote (new-min uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (var-set min-reputation-to-vote new-min)
    (ok new-min)
  )
)

(define-public (set-ethical-goal 
  (min-env-score uint)
  (min-social-score uint)
  (min-gov-score uint)
  (min-overall-score uint))
  (let 
    (
      (existing-goal (map-get? ethical-goals { user: tx-sender }))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (and (<= min-env-score u100) (<= min-social-score u100) (<= min-gov-score u100) (<= min-overall-score u100)) ERR_INVALID_SCORE)
    (asserts! (or (> min-env-score u0) (> min-social-score u0) (> min-gov-score u0) (> min-overall-score u0)) ERR_INVALID_GOAL)
    
    (map-set ethical-goals
      { user: tx-sender }
      {
        min-environmental-score: min-env-score,
        min-social-score: min-social-score,
        min-governance-score: min-gov-score,
        min-overall-score: min-overall-score,
        created-at: stacks-block-height,
        last-checked: stacks-block-height,
        is-active: true
      }
    )
    
    (if (is-none existing-goal)
      (map-set user-achievements
        { user: tx-sender }
        {
          total-checks: u0,
          compliant-checks: u0,
          current-streak: u0,
          longest-streak: u0,
          last-achievement-block: stacks-block-height
        }
      )
      true
    )
    
    (ok true)
  )
)

(define-public (update-ethical-goal 
  (min-env-score uint)
  (min-social-score uint)
  (min-gov-score uint)
  (min-overall-score uint))
  (let 
    (
      (existing-goal (unwrap! (map-get? ethical-goals { user: tx-sender }) ERR_GOAL_NOT_FOUND))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (and (<= min-env-score u100) (<= min-social-score u100) (<= min-gov-score u100) (<= min-overall-score u100)) ERR_INVALID_SCORE)
    (asserts! (or (> min-env-score u0) (> min-social-score u0) (> min-gov-score u0) (> min-overall-score u0)) ERR_INVALID_GOAL)
    
    (map-set ethical-goals
      { user: tx-sender }
      (merge existing-goal {
        min-environmental-score: min-env-score,
        min-social-score: min-social-score,
        min-governance-score: min-gov-score,
        min-overall-score: min-overall-score
      })
    )
    
    (ok true)
  )
)

(define-public (toggle-goal-active)
  (let 
    (
      (existing-goal (unwrap! (map-get? ethical-goals { user: tx-sender }) ERR_GOAL_NOT_FOUND))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    
    (map-set ethical-goals
      { user: tx-sender }
      (merge existing-goal {
        is-active: (not (get is-active existing-goal))
      })
    )
    
    (ok (not (get is-active existing-goal)))
  )
)

(define-public (check-goal-compliance)
  (let 
    (
      (goal (unwrap! (map-get? ethical-goals { user: tx-sender }) ERR_GOAL_NOT_FOUND))
      (portfolio-ethics (unwrap! (calculate-portfolio-ethics tx-sender) ERR_PORTFOLIO_EMPTY))
      (achievements (default-to 
                      { total-checks: u0, compliant-checks: u0, current-streak: u0, longest-streak: u0, last-achievement-block: u0 }
                      (map-get? user-achievements { user: tx-sender })))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (get is-active goal) ERR_UNAUTHORIZED)
    
    (let 
      (
        (portfolio-env (get total-env portfolio-ethics))
        (portfolio-social (get total-social portfolio-ethics))
        (portfolio-gov (get total-gov portfolio-ethics))
        (portfolio-overall (get total-overall portfolio-ethics))
        (portfolio-count (get count portfolio-ethics))
        (avg-env (if (> portfolio-count u0) (/ portfolio-env portfolio-count) u0))
        (avg-social (if (> portfolio-count u0) (/ portfolio-social portfolio-count) u0))
        (avg-gov (if (> portfolio-count u0) (/ portfolio-gov portfolio-count) u0))
        (avg-overall (if (> portfolio-count u0) (/ portfolio-overall portfolio-count) u0))
        (is-compliant (and 
                        (>= avg-env (get min-environmental-score goal))
                        (>= avg-social (get min-social-score goal))
                        (>= avg-gov (get min-governance-score goal))
                        (>= avg-overall (get min-overall-score goal))))
        (new-streak (if is-compliant (+ (get current-streak achievements) u1) u0))
        (new-longest-streak (if (> new-streak (get longest-streak achievements)) new-streak (get longest-streak achievements)))
      )
      
      (map-set goal-compliance-history
        { user: tx-sender, check-block: stacks-block-height }
        {
          was-compliant: is-compliant,
          portfolio-env-score: avg-env,
          portfolio-social-score: avg-social,
          portfolio-gov-score: avg-gov,
          portfolio-overall-score: avg-overall
        }
      )
      
      (map-set user-achievements
        { user: tx-sender }
        {
          total-checks: (+ (get total-checks achievements) u1),
          compliant-checks: (+ (get compliant-checks achievements) (if is-compliant u1 u0)),
          current-streak: new-streak,
          longest-streak: new-longest-streak,
          last-achievement-block: stacks-block-height
        }
      )
      
      (map-set ethical-goals
        { user: tx-sender }
        (merge goal {
          last-checked: stacks-block-height
        })
      )
      
      (ok {
        is-compliant: is-compliant,
        portfolio-avg-env: avg-env,
        portfolio-avg-social: avg-social,
        portfolio-avg-gov: avg-gov,
        portfolio-avg-overall: avg-overall,
        current-streak: new-streak
      })
    )
  )
)

(define-read-only (get-ethical-goal (user principal))
  (map-get? ethical-goals { user: user })
)

(define-read-only (get-goal-compliance-at-block (user principal) (target-block uint))
  (map-get? goal-compliance-history { user: user, check-block: target-block })
)

(define-read-only (get-user-achievements (user principal))
  (map-get? user-achievements { user: user })
)

(define-read-only (calculate-compliance-rate (user principal))
  (let 
    (
      (achievements (map-get? user-achievements { user: user }))
    )
    (if (is-some achievements)
      (let 
        (
          (achievement-data (unwrap-panic achievements))
          (total (get total-checks achievement-data))
          (compliant (get compliant-checks achievement-data))
        )
        (ok {
          total-checks: total,
          compliant-checks: compliant,
          compliance-rate: (if (> total u0) (/ (* compliant u100) total) u0),
          current-streak: (get current-streak achievement-data),
          longest-streak: (get longest-streak achievement-data)
        })
      )
      (err ERR_GOAL_NOT_FOUND)
    )
  )
)

(define-read-only (is-portfolio-compliant (user principal))
  (let 
    (
      (goal (map-get? ethical-goals { user: user }))
      (portfolio-ethics-result (calculate-portfolio-ethics user))
    )
    (if (and (is-some goal) (is-ok portfolio-ethics-result))
      (let 
        (
          (goal-data (unwrap-panic goal))
          (portfolio-ethics (unwrap-panic portfolio-ethics-result))
          (portfolio-env (get total-env portfolio-ethics))
          (portfolio-social (get total-social portfolio-ethics))
          (portfolio-gov (get total-gov portfolio-ethics))
          (portfolio-overall (get total-overall portfolio-ethics))
          (portfolio-count (get count portfolio-ethics))
          (avg-env (if (> portfolio-count u0) (/ portfolio-env portfolio-count) u0))
          (avg-social (if (> portfolio-count u0) (/ portfolio-social portfolio-count) u0))
          (avg-gov (if (> portfolio-count u0) (/ portfolio-gov portfolio-count) u0))
          (avg-overall (if (> portfolio-count u0) (/ portfolio-overall portfolio-count) u0))
        )
        (ok {
          is-compliant: (and 
                          (>= avg-env (get min-environmental-score goal-data))
                          (>= avg-social (get min-social-score goal-data))
                          (>= avg-gov (get min-governance-score goal-data))
                          (>= avg-overall (get min-overall-score goal-data))),
          current-env: avg-env,
          required-env: (get min-environmental-score goal-data),
          current-social: avg-social,
          required-social: (get min-social-score goal-data),
          current-gov: avg-gov,
          required-gov: (get min-governance-score goal-data),
          current-overall: avg-overall,
          required-overall: (get min-overall-score goal-data)
        })
      )
      (err ERR_GOAL_NOT_FOUND)
    )
  )
)

(define-read-only (get-goal-gap-analysis (user principal))
  (match (is-portfolio-compliant user)
    success 
      (let 
        (
          (env-gap (if (< (get current-env success) (get required-env success))
                     (- (get required-env success) (get current-env success))
                     u0))
          (social-gap (if (< (get current-social success) (get required-social success))
                        (- (get required-social success) (get current-social success))
                        u0))
          (gov-gap (if (< (get current-gov success) (get required-gov success))
                     (- (get required-gov success) (get current-gov success))
                     u0))
          (overall-gap (if (< (get current-overall success) (get required-overall success))
                         (- (get required-overall success) (get current-overall success))
                         u0))
        )
        (ok {
          environmental-gap: env-gap,
          social-gap: social-gap,
          governance-gap: gov-gap,
          overall-gap: overall-gap,
          needs-improvement: (or (> env-gap u0) (> social-gap u0) (> gov-gap u0) (> overall-gap u0))
        })
      )
    error (err error)
  )
)

(define-public (set-esg-preferences (env-weight uint) (social-weight uint) (gov-weight uint))
  (let 
    (
      (sum (+ env-weight (+ social-weight gov-weight)))
    )
    (asserts! (var-get contract-active) ERR_UNAUTHORIZED)
    (asserts! (<= env-weight u100) ERR_INVALID_SCORE)
    (asserts! (<= social-weight u100) ERR_INVALID_SCORE)
    (asserts! (<= gov-weight u100) ERR_INVALID_SCORE)
    (asserts! (is-eq sum u100) ERR_INVALID_WEIGHT)
    (map-set user-esg-preferences
      { user: tx-sender }
      {
        env-weight: env-weight,
        social-weight: social-weight,
        gov-weight: gov-weight,
        created-at: stacks-block-height
      }
    )
    (ok true)
  )
)

(define-read-only (get-esg-preferences (user principal))
  (map-get? user-esg-preferences { user: user })
)

(define-read-only (calculate-weighted-portfolio-ethics (user principal))
  (let 
    (
      (prefs (map-get? user-esg-preferences { user: user }))
      (portfolio-ethics-result (calculate-portfolio-ethics user))
    )
    (if (is-some prefs)
      (match portfolio-ethics-result
        success 
          (let 
            (
              (pref-data (unwrap-panic prefs))
              (portfolio-env (get total-env success))
              (portfolio-social (get total-social success))
              (portfolio-gov (get total-gov success))
              (portfolio-overall (get total-overall success))
              (portfolio-count (get count success))
              (avg-env (if (> portfolio-count u0) (/ portfolio-env portfolio-count) u0))
              (avg-social (if (> portfolio-count u0) (/ portfolio-social portfolio-count) u0))
              (avg-gov (if (> portfolio-count u0) (/ portfolio-gov portfolio-count) u0))
              (weighted-overall (/ (+ (* avg-env (get env-weight pref-data)) (* avg-social (get social-weight pref-data)) (* avg-gov (get gov-weight pref-data))) u100))
            )
            (ok {
              avg-env: avg-env,
              avg-social: avg-social,
              avg-gov: avg-gov,
              weighted-overall: weighted-overall
            })
          )
        error (err error)
      )
      (err ERR_PREFERENCES_NOT_SET)
    )
  )
)
