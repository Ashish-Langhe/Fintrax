## ADDED Requirements

### Requirement: Set monthly budget
The system SHALL allow users to set a monthly budget amount in INR.

#### Scenario: User sets initial budget
- **WHEN** user navigates to the Budget page
- **THEN** system displays an input field to enter monthly budget amount
- **WHEN** user enters a valid budget amount and saves
- **THEN** system stores the budget amount and shows success confirmation

#### Scenario: User sets invalid budget
- **WHEN** user enters a negative number or zero as budget amount
- **THEN** system displays validation error message
- **WHEN** user enters non-numeric input
- **THEN** system displays validation error message prompting for valid amount

### Requirement: Update existing monthly budget
The system SHALL allow users to modify their existing monthly budget.

#### Scenario: User updates budget
- **WHEN** user has an existing budget and navigates to Budget page
- **THEN** system displays current budget amount with option to edit
- **WHEN** user modifies the budget amount and saves
- **THEN** system updates the stored budget amount
- **AND** system recalculates and updates the remaining budget display

### Requirement: View current budget
The system SHALL display the user's current monthly budget on the Budget page.

#### Scenario: User views budget page
- **WHEN** user navigates to the Budget page
- **THEN** system displays the current monthly budget amount in INR format
- **AND** system displays UI elements for editing the budget

### Requirement: Budget data persistence
The system SHALL persist budget settings across app sessions.

#### Scenario: Budget persists after app restart
- **WHEN** user sets a monthly budget and closes the app
- **THEN** upon reopening the app, the budget remains saved
- **AND** system displays the previously set budget amount

#### Scenario: Budget survives page navigation
- **WHEN** user navigates away from Budget page and returns
- **THEN** system displays the previously set budget amount without requiring re-entry