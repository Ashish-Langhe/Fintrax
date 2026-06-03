## 1. Data Layer Setup

- [x] 1.1 Create budget data model/interface for monthly budget storage
- [x] 1.2 Implement local storage functions for saving/loading budget data
- [x] 1.3 Add budget validation functions (positive numbers only)
- [x] 1.4 Create budget calculation utilities for remaining budget computation

## 2. Budget Page Enhancement

- [x] 2.1 Update Budget page component to display current budget amount
- [x] 2.2 Add budget input field with INR currency formatting
- [x] 2.3 Implement budget save/update functionality with validation
- [x] 2.4 Add success/error feedback for budget operations
- [x] 2.5 Ensure theme consistency with existing app UI

## 3. Budget Calculation Logic

- [x] 3.1 Implement function to aggregate current month expenses
- [x] 3.2 Create remaining budget calculation (Budget - Total Expenses)
- [x] 3.3 Add month boundary handling for expense aggregation
- [x] 3.4 Implement over-budget detection and styling logic

## 4. Dashboard Integration

- [x] 4.1 Update Budget Left card to use calculated remaining budget
- [x] 4.2 Remove hardcoded budget values from Dashboard
- [x] 4.3 Implement real-time budget updates when expenses change
- [x] 4.4 Add event listeners for expense CRUD operations
- [x] 4.5 Ensure proper INR formatting on Dashboard display

## 5. Real-time Updates

- [x] 5.1 Integrate budget recalculation into expense add flow
- [x] 5.2 Integrate budget recalculation into expense edit flow
- [x] 5.3 Integrate budget recalculation into expense delete flow
- [x] 5.4 Add state management for budget data across components

## 6. Testing & Validation

- [x] 6.1 Test budget setting with valid inputs
- [x] 6.2 Test budget validation with invalid inputs (negative, zero, non-numeric)
- [x] 6.3 Test budget persistence across app sessions
- [x] 6.4 Test remaining budget calculation accuracy
- [x] 6.5 Test real-time updates when expenses are modified
- [x] 6.6 Test month boundary behavior
- [x] 6.7 Test Dashboard Budget Left card updates
- [x] 6.8 Test over-budget scenarios and visual indicators