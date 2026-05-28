# PHASE-XX — port login.kt to use the new Kotlin coroutine API

<files>{"writes": ["src/auth/Login.kt"], "reads": []}</files>

Migrate the suspending `login()` to use `flow {}` and idiomatic Kotlin null-safety.
