-- Each record's snapshot versions form an unbroken timeline:
-- every version has a positive period (valid-from before valid-to),
-- and every version ends exactly when the record's next version begins (no gaps, no overlaps,
-- and only the newest version is open).
-- Returns the violating versions; the test passes when no rows come back.
--
-- is distinct from treats null as a value: a current version (valid-to null, no next version) passes,
-- while a version that was never closed even though a newer one exists fails.

{% set snapshots = {
    'claims_snapshot': 'claim_id',
    'patients_snapshot': 'patient_id',
    'providers_snapshot': 'provider_id',
    'appointments_snapshot': 'appointment_id',
} %}

with versions as (

    {% for snapshot, key in snapshots.items() %}
        select
            '{{ snapshot }}' as snapshot_name,
            {{ key }} as record_id,
            dbt_valid_from,
            dbt_valid_to,
            lead(dbt_valid_from) over (
                partition by {{ key }}
                order by dbt_valid_from
            ) as next_valid_from
        from {{ ref(snapshot) }}
        {% if not loop.last %}union all{% endif %}
    {% endfor %}

)

select
    snapshot_name,
    record_id,
    dbt_valid_from,
    dbt_valid_to,
    next_valid_from
from versions
where
    dbt_valid_from >= dbt_valid_to
    or dbt_valid_to is distinct from next_valid_from
