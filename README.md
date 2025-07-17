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
