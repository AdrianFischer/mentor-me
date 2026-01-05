# Implementation Plan: Fix Hierarchy Navigation Focus Bug [checkpoint: a88d85d]

This plan addresses the double-press bug in hierarchical navigation after using `Enter` and `Esc` on an entry.

## Phase 1: Reproduction and Base Verification [checkpoint: a88d85d]
In this phase, we will establish failing tests that reproduce the reported bug and ensure the testing infrastructure is ready.

- [x] Task: Create reproduction test for upward navigation (Task -> Project) as described in Spec. a88d85d
- [x] Task: Create reproduction test for downward navigation (Task -> Subtask) as described in Spec. a88d85d
- [x] Task: Verify tests fail as expected (Red Phase). a88d85d
- [x] Task: Conductor - User Manual Verification 'Phase 1: Reproduction and Base Verification' (Protocol in workflow.md) a88d85d

## Phase 2: Logic Implementation and Fix
In this phase, we will implement the fix in the navigation/focus management logic to ensure single-press hierarchy jumping.

- [x] Task: Analyze existing focus and navigation providers (Riverpod) to identify why state requires double-press. cd0f2df
- [x] Task: Implement fix to ensure focus state is correctly restored to the item on `Esc`. cd0f2df
- [x] Task: Implement fix to ensure hierarchy navigation logic handles the "just-escaped" state correctly. cd0f2df
- [x] Task: Verify all tests pass (Green Phase). cd0f2df
- [ ] Task: Conductor - User Manual Verification 'Phase 2: Logic Implementation and Fix' (Protocol in workflow.md)

## Phase 3: Regression and Polish
Ensuring no other navigation features were broken and finalizing the code.

- [ ] Task: Run existing navigation tests to ensure no regressions.
- [ ] Task: Refactor navigation logic for clarity if necessary.
- [ ] Task: Verify code coverage for the fix exceeds 80%.
- [ ] Task: Conductor - User Manual Verification 'Phase 3: Regression and Polish' (Protocol in workflow.md)
