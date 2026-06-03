## Why

Users need to set and track their monthly budget to better manage their finances. The current hardcoded budget values don't provide real financial insights, preventing users from understanding their actual spending patterns and remaining budget.

## What Changes

- Add functionality to set and update a total monthly budget on the existing Budget page
- Update the Budget Left card on Dashboard to calculate actual remaining budget (User's Set Budget - Total Monthly Expenses)
- Ensure all budget displays use INR currency and match the current app theme
- Implement persistent storage for budget settings

## Capabilities

### New Capabilities
- `monthly-budget-management`: Capability for users to set, update, and view their monthly budget settings
- `budget-calculation`: Capability to calculate remaining budget based on user's budget and actual expenses

### Modified Capabilities
- Leave empty - no requirement changes to existing capabilities

## Impact

- Budget page UI will be enhanced with budget setting/editing functionality
- Dashboard Budget Left card will be updated to show dynamic calculations
- New data storage requirements for user budget preferences
- Budget calculation logic will need to aggregate monthly expenses dynamically