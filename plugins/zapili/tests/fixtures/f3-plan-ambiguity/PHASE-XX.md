# PHASE-XX — refactor login flow

<files>{"writes": ["src/auth/login.ts"], "reads": ["src/auth/session.ts"]}</files>

## Task

Add support for "remember me" — when the user clicks the checkbox, sessions should last longer.

<!-- LINES 5-12: "longer" is undefined; could mean 24h, 30d, 1y. Two-incompatible-interpretations classic. -->
