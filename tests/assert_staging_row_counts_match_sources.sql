-- Every staging model has exactly as many rows as its raw source table.
-- Staging only renames columns, so a difference means a filter or join was added and rows were lost or duplicated.
-- Returns one row per mismatched table; the test passes when no rows come back.

{% set tables = ['locations', 'payers', 'providers', 'patients', 'appointments', 'encounters', 'claims'] %}

with row_counts as (

    {% for table in tables %}
        select
            '{{ table }}' as table_name,
            (select count(*) from {{ source('caremetrics', table) }}) as source_rows,
            (select count(*) from {{ ref('stg_caremetrics__' ~ table) }}) as staging_rows
        {% if not loop.last %}union all{% endif %}
    {% endfor %}

)

select
    table_name,
    source_rows,
    staging_rows
from row_counts
where source_rows != staging_rows
