## ADDED Requirements

### Requirement: Calculate remaining budget
The system SHALL calculate the remaining budget by subtracting total current month expenses from the user's set monthly budget.

#### Scenario: Calculate remaining budget with expenses
- **WHEN** user has set a monthly budget and has expenses in the current month
- **THEN** system calculates remaining budget as (Monthly Budget - Sum of Current Month Expenses)
- **AND** system displays the calculated remaining budget in INR format

#### Scenario: Calculate remaining budget with no expenses
- **WHEN** user has set a monthly budget but has no expenses in current month
- **THEN** system displays the full monthly budget as remaining budget

#### Scenario: Calculate remaining budget when over budget
- **WHEN** user's current month expenses exceed the set monthly budget
- **THEN** system displays negative remaining budget indicating overage
- **AND** system uses distinct visual styling to indicate over-budget status

### Requirement: Real-time budget updates
The system SHALL update the remaining budget calculation in real-time when expenses are added or modified.

#### Scenario: Budget updates after adding expense
- **WHEN** user adds a new expense for the current month
- **THEN** system immediately recalculates the remaining budget
- **AND** Dashboard displays the updated remaining budget

#### Scenario: Budget updates after editing expense
- **WHEN** user modifies an existing expense amount for the current month
- **THEN** system immediately recalculates the remaining budget
- **AND** Dashboard displays the updated remaining budget

#### Scenario: Budget updates after deleting expense
- **WHEN** user deletes an expense from the current month
- **THEN** system immediately recalculates the remaining budget
- **AND** Dashboard displays the updated remaining budget

### Requirement: Monthly expense aggregation
The system SHALL aggregate expenses for the current month only when calculating remaining budget.

#### Scenario: Calculate with multi-month expenses
- **WHEN** user has expenses from previous months and current month
- **THEN** system only includes current month expenses in remaining budget calculation
- **AND** previous month expenses are excluded from the calculation

#### Scenario: Month boundary handling
- **WHEN** the date transitions to a new month
- **THEN** system resets the expense calculation base to the new month
- **AND** remaining budget calculation uses only the new month's expenses

### Requirement: Display remaining budget on Dashboard
The system SHALL display the calculated remaining budget on the Dashboard Budget Left card.

#### Scenario: Dashboard shows dynamic budget
- **WHEN** user navigates to the Dashboard
- **THEN** Budget Left card displays the calculated remaining budget
- **AND** the amount is formatted in INR with appropriate currency symbol
- **AND** the card updates in real-time when budget calculations change