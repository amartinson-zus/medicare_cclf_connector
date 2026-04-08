with beneficiary_xref as (

    select * from {{ ref('int_beneficiary_xref_deduped') }}

)

select
      beneficiary_demographics.*
    , coalesce(beneficiary_xref.crnt_num, beneficiary_demographics.bene_mbi_id) as current_bene_mbi_id
from {{ ref('stg_beneficiary_demographics') }} as beneficiary_demographics
left join beneficiary_xref
    on beneficiary_demographics.bene_mbi_id = beneficiary_xref.prvs_num
