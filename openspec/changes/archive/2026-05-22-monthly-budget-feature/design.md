## Context

The expense tracker app currently has a Budget tab and Dashboard with a "Budget Left" card, but both display hardcoded values rather than dynamic, user-configurable budget data. The app uses INR currency and has an existing theme system that needs to be maintained. The app structure includes a tabbar navigation, separate pages for Dashboard and Budget, and likely uses local storage for data persistence.

## Goals / Non-Goals

**Goals:**
- Enable users to set and update their monthly budget through the existing Budget page
- Display actual remaining budget (User's Set Budget - Total Monthly Expenses) on the Dashboard
- Maintain consistent UI/UX with existing app theme and INR currency formatting
- Ensure budget data persists across app sessions
- Provide real-time budget calculations based on current month's expenses

**Non-Goals:**
- Multi-currency support (focus on INR only)
- Historical budget tracking for previous months
- Budget categories or allocation features
- Advanced budget analytics or reporting

## Decisions

**Data Storage:** Use local storage for budget settings
- Rationale: Simple, offline-first approach matching existing app architecture
- Alternative: Cloud storage - rejected as it adds complexity likely not needed

**Budget Calculation Approach:** Calculate remaining budget as (Set Budget - Current Month Expenses)
- Rationale: Direct and easy for users to understand
- Alternative: Include previous month carryover - rejected for simplicity

**UI Update Strategy:** Enhance existing Budget page rather than create new flow
- Rationale: Maintains familiar user experience, less navigation complexity
- Alternative: Dedicated budget setup flow - rejected as overkill for this feature

**Real-time Updates:** Recalculate budget when expenses are added/edited
- Rationale: Users expect immediate feedback on budget status
- Alternative: Manual refresh only - rejected for poor UX

## Risks / Trade-offs

**[Data Persistence Risk]** User might lose budget data if local storage is cleared → Mitigation: Add backup/export feature in future iteration

**[Performance Risk]** Frequent budget recalculations could impact app performance → Mitigation: Cache calculated results and only recalculate when needed

**[UI Complexity Risk]** Adding budget editing to existing Budget page might make it cluttered → Mitigation: Use modal or inline editing that's contextually appropriate

**[Month Boundary Risk]** Budget resets at month start might confuse users → Mitigation: Clear month labeling and possibly transition period display