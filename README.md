# 🌱 Ethical Investment Tracker

A Clarity smart contract for tracking and filtering investment portfolios based on ESG (Environmental, Social, Governance) criteria.

## 📋 Overview

This contract allows users to:
- 📊 Add investments with detailed ESG scoring
- 💼 Build personalized investment portfolios  
- 🔍 Filter investments by ethical criteria
- 📈 Calculate portfolio-wide ethics scores
- 🏭 Filter by business sectors

## 🚀 Features

### Investment Management
- ✅ Create new investments with ESG scores (0-100)
- 📝 Track company name, symbol, and sector
- 🔢 Auto-calculate overall ethical score

### Portfolio Management  
- 💰 Add investments to personal portfolio
- 📉 Remove investments from portfolio
- 📊 Track purchase amounts and prices
- 🕐 Record purchase block height

### Filtering & Analytics
- 🌿 Filter by environmental score threshold
- 👥 Filter by social responsibility score
- 🏛️ Filter by governance score threshold
- 🎯 Filter by overall ESG score
- 🏭 Filter by business sector
- 📋 Calculate portfolio-wide ethics averages

### Performance Tracking
- 💹 Real-time investment price tracking
- 📊 Portfolio valuation calculations
- 📈 Individual investment return analysis
- 💰 Portfolio-wide return calculations
- 🏆 Top performing investments ranking
- 📝 Price history tracking

### Community ESG Verification
- 🗳️ Decentralized ESG score validation system
- 🏅 Reputation-based verifier scoring
- 📊 Community-driven consensus mechanisms
- ⚖️ Democratic dispute resolution
- 🔒 Time-locked voting periods
- 📈 Consensus strength indicators

### Ethical Investment Goals & Compliance
- 🎯 Personalized ESG target setting for portfolios
- ✅ Automated compliance monitoring and tracking
- 📊 Real-time gap analysis and improvement insights
- 🏆 Achievement system with streak tracking
- 📈 Historical compliance rate calculations
- 🎮 Gamified ethical investing experience

## 🔧 Contract Functions

### Public Functions

#### `add-investment`
```clarity
(add-investment name symbol environmental-score social-score governance-score sector)
```
Creates a new investment with ESG scores (0-100 each).

#### `add-to-portfolio`
```clarity
(add-to-portfolio investment-id amount purchase-price)
```
Adds an investment to your portfolio with specified amount and price.

#### `remove-from-portfolio`
```clarity
(remove-from-portfolio investment-id amount)
```
Removes specified amount of an investment from your portfolio.

#### `toggle-contract-active`
```clarity
(toggle-contract-active)
```
Owner-only function to activate/deactivate the contract.

#### `update-investment-price`
```clarity
(update-investment-price investment-id new-price)
```
Updates the current price of an investment and records price history.

#### `propose-esg-verification`
```clarity
(propose-esg-verification investment-id proposed-env-score proposed-social-score proposed-gov-score)
```
Proposes new ESG scores for community verification and voting.

#### `vote-on-verification`
```clarity
(vote-on-verification verification-id approve)
```
Casts a weighted vote on a proposed ESG verification.

#### `finalize-verification`
```clarity
(finalize-verification verification-id)
```
Finalizes a verification proposal and updates scores if approved.

#### `set-min-reputation-to-vote`
```clarity
(set-min-reputation-to-vote new-min)
```
Owner-only function to set minimum reputation required to participate in voting.

#### `set-ethical-goal`
```clarity
(set-ethical-goal min-env-score min-social-score min-gov-score min-overall-score)
```
Creates personalized ESG targets for your portfolio with minimum thresholds.

#### `update-ethical-goal`
```clarity
(update-ethical-goal min-env-score min-social-score min-gov-score min-overall-score)
```
Updates existing ethical investment goals with new thresholds.

#### `toggle-goal-active`
```clarity
(toggle-goal-active)
```
Activates or pauses goal compliance tracking for your portfolio.

#### `check-goal-compliance`
```clarity
(check-goal-compliance)
```
Performs compliance check against your goals and updates achievement stats.

### Read-Only Functions

#### `get-investment`
```clarity
(get-investment investment-id)
```
Returns investment details including ESG scores.

#### `get-portfolio-holding`
```clarity
(get-portfolio-holding user investment-id)
```
Returns user's holding details for specific investment.

#### `calculate-portfolio-ethics`
```clarity
(calculate-portfolio-ethics user)
```
Calculates average ESG scores across user's portfolio.

#### `filter-portfolio-by-environmental`
```clarity
(filter-portfolio-by-environmental user min-score)
```
Returns investments meeting minimum environmental score.

#### `filter-portfolio-by-social`
```clarity
(filter-portfolio-by-social user min-score)
```
Returns investments meeting minimum social score.

#### `filter-portfolio-by-governance`
```clarity
(filter-portfolio-by-governance user min-score)
```
Returns investments meeting minimum governance score.

#### `filter-portfolio-by-overall`
```clarity
(filter-portfolio-by-overall user min-score)
```
Returns investments meeting minimum overall ESG score.

#### `filter-by-sector`
```clarity
(filter-by-sector user sector)
```
Returns investments from specific business sector.

#### `get-investment-price`
```clarity
(get-investment-price investment-id)
```
Returns current price and last update information for an investment.

#### `calculate-portfolio-value`
```clarity
(calculate-portfolio-value user)
```
Calculates total portfolio value and cost basis.

#### `calculate-investment-return`
```clarity
(calculate-investment-return user investment-id)
```
Calculates return percentage and profit/loss for a specific investment.

#### `calculate-portfolio-return`
```clarity
(calculate-portfolio-return user)
```
Calculates overall portfolio return percentage and total gains/losses.

#### `get-top-performers`
```clarity
(get-top-performers user)
```
Returns the top performing investments in a user's portfolio.

#### `get-price-history`
```clarity
(get-price-history investment-id block-height)
```
Returns historical price data for a specific investment at a given block.

#### `get-verification`
```clarity
(get-verification verification-id)
```
Returns verification proposal details and voting status.

#### `get-verifier-reputation`
```clarity
(get-verifier-reputation verifier)
```
Returns reputation score and voting history for a verifier.

#### `get-verification-vote`
```clarity
(get-verification-vote verification-id voter)
```
Returns a specific voter's choice and voting power for a verification.

#### `get-active-verifications`
```clarity
(get-active-verifications)
```
Returns list of currently active verification proposals.

#### `calculate-consensus-score`
```clarity
(calculate-consensus-score investment-id)
```
Returns investment scores with consensus strength indicators.

#### `get-ethical-goal`
```clarity
(get-ethical-goal user)
```
Returns user's ethical investment goals and current status.

#### `get-goal-compliance-at-block`
```clarity
(get-goal-compliance-at-block user block-height)
```
Returns historical compliance status at a specific block height.

#### `get-user-achievements`
```clarity
(get-user-achievements user)
```
Returns achievement statistics including streaks and compliance history.

#### `calculate-compliance-rate`
```clarity
(calculate-compliance-rate user)
```
Calculates overall compliance percentage and streak information.

#### `is-portfolio-compliant`
```clarity
(is-portfolio-compliant user)
```
Checks if current portfolio meets all ethical goal thresholds.

#### `get-goal-gap-analysis`
```clarity
(get-goal-gap-analysis user)
```
Analyzes gaps between current scores and goals for improvement guidance.

## 🎯 Usage Examples

### Adding an Investment
```clarity
(contract-call? .ethical-investment-tracker add-investment 
  "Tesla Inc" 
  "TSLA" 
  u85 
  u70 
  u75 
  "Technology")
```

### Building Your Portfolio
```clarity
(contract-call? .ethical-investment-tracker add-to-portfolio 
  u1 
  u100 
  u50000)
```

### Filtering High Environmental Performers
```clarity
(contract-call? .ethical-investment-tracker filter-portfolio-by-environmental 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 
  u80)
```

### Calculating Portfolio Ethics
```clarity
(contract-call? .ethical-investment-tracker calculate-portfolio-ethics 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Performance Tracking Examples

#### Updating Investment Price
```clarity
(contract-call? .ethical-investment-tracker update-investment-price 
  u1 
  u55000)
```

#### Calculating Portfolio Returns
```clarity
(contract-call? .ethical-investment-tracker calculate-portfolio-return 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

#### Getting Top Performers
```clarity
(contract-call? .ethical-investment-tracker get-top-performers 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Community Verification Examples

#### Proposing ESG Score Updates
```clarity
(contract-call? .ethical-investment-tracker propose-esg-verification 
  u1 
  u90 
  u85 
  u88)
```

#### Voting on Verifications
```clarity
(contract-call? .ethical-investment-tracker vote-on-verification 
  u1 
  true)
```

#### Checking Consensus Strength
```clarity
(contract-call? .ethical-investment-tracker calculate-consensus-score 
  u1)
```

### Goal Tracking Examples

#### Setting Ethical Goals
```clarity
(contract-call? .ethical-investment-tracker set-ethical-goal 
  u75 
  u70 
  u80 
  u75)
```

#### Checking Compliance
```clarity
(contract-call? .ethical-investment-tracker check-goal-compliance)
```

#### Viewing Gap Analysis
```clarity
(contract-call? .ethical-investment-tracker get-goal-gap-analysis 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

#### Tracking Achievements
```clarity
(contract-call? .ethical-investment-tracker calculate-compliance-rate 
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## 📊 ESG Scoring System

- **Environmental (0-100)**: Climate impact, sustainability practices
- **Social (0-100)**: Labor practices, community impact, diversity
- **Governance (0-100)**: Board composition, executive compensation, transparency
- **Overall Score**: Automatic average of E, S, G scores

## 🛠️ Development Setup

1. **Install Clarinet**
   ```bash
   npm install -g @hirosystems/clarinet-cli
   ```

2. **Deploy Contract**
   ```bash
   clarinet deploy
   ```

3. **Run Tests**
   ```bash
   clarinet test
   ```

## 🔐 Security Features

- ✅ Input validation for all scores (0-100 range)
- ✅ Authorization checks for sensitive operations
- ✅ Portfolio ownership verification
- ✅ Contract activation toggle for emergency stops

## 📈 Future Enhancements

- 🔄 Time-weighted portfolio returns
- 📊 Sector diversification analysis
- 🎯 Custom ESG weighting preferences
- 📱 Investment recommendation engine
- 🌍 Global ESG standard integration

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is open source and available under the MIT License.

---

*Built with 💚 for ethical investing and sustainable finance*
