-- A claim's amounts and submission time must agree with its status:
-- billed is positive, paid is between zero and billed, money is paid exactly when the status is paid,
-- and submitted_at is null exactly when the claim is pending.
-- These mirror check constraints in the source, so a violation means data was damaged on its way into BigQuery.
-- Returns the violating claims; the test passes when no rows come back.

select
    claim_id,
    claim_status,
    amount_billed,
    amount_paid,
    submitted_at

from {{ ref('stg_caremetrics__claims') }}

where amount_billed <= 0
    or amount_paid < 0
    or amount_paid > amount_billed
    or (amount_paid > 0) != (claim_status = 'paid')
    or (submitted_at is null) != (claim_status = 'pending')
