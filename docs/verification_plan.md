# AXI4-Lite Slave — Verification Plan

## DUT: AXI4-Lite Slave (Register Bank / GPIO Controller)
## Spec Reference: ARM IHI 0022 (AXI4-Lite)
## Engineer: [Your Name]
## Start Date: Day 1

## Verification Goals
- 100% of AXI4-Lite protocol features exercised
- >95% functional coverage closure
- All protocol rules checked via SVA
- Scoreboard-verified every transaction

## Feature List (to be expanded on Day 4)
| ID | Feature | Priority | Status |
|----|---------|----------|--------|
| F01 | Single write transaction | High | Pending |
| F02 | Single read transaction | High | Pending |
| F03 | Write response (BRESP) checking | High | Pending |
| F04 | Read response (RRESP) checking | High | Pending |
| F05 | Back-to-back writes | Medium | Pending |
| F06 | Back-to-back reads | Medium | Pending |
| F07 | Simultaneous read and write | Medium | Pending |
| F08 | Write with partial strobes | Medium | Pending |
| F09 | Out-of-range address access | Medium | Pending |
| F10 | Reset behavior | High | Pending |

## Test List (to be expanded as we build)
| ID | Test Name | Sequences | Coverage Target |
|----|-----------|-----------|-----------------|
| T01 | Directed write/read | Single W + R | F01, F02 |

