{{ config(severity='warn') }}

-- A paid claim recovers between 20% and 90% of its billed amount.
-- This is a plausibility check on payer behavior, not a source rule, so a violation warns instead of failing.
-- Returns the paid claims outside the range; the test passes when no rows come back.

select
    claim_id,
    payer_id,
    amount_billed,
    amount_paid,
    safe_divide(amount_paid, amount_billed) as paid_share

from {{ ref('stg_caremetrics__claims') }}

where
    claim_status = 'paid'
    and safe_divide(amount_paid, amount_billed) not between 0.20 and 0.90
