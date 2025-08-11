(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INVESTMENT_EXISTS (err u101))
(define-constant ERR_INVESTMENT_NOT_FOUND (err u102))
(define-constant ERR_INVALID_SCORE (err u103))
(define-constant ERR_INVALID_AMOUNT (err u104))
(define-constant ERR_PORTFOLIO_EMPTY (err u105))
(define-constant ERR_INVALID_PRICE (err u106))
(define-constant ERR_PRICE_NOT_SET (err u107))

(define-data-var contract-active bool true)
(define-data-var total-investments uint u0)

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
