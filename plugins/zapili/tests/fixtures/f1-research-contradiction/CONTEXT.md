# Context for JWT auth

<domain>
The /login endpoint gains JWT issuance backed by the same Postgres users table.
</domain>

<decisions>
**D-01:** Replace `jsonwebtoken@8.x` with `jose@5.x` for AES-GCM signing support and modern key rotation.
**D-02:** Keep `jsonwebtoken@8.x` exclusively for legacy verification.
</decisions>

<!-- LINES 12-15: D-01 directly contradicts TASK.md's "do NOT introduce a new auth dependency" constraint. -->
