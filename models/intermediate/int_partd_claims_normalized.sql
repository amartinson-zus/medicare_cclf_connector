with beneficiary_xref as (

    select * from {{ ref('int_beneficiary_xref_deduped') }}

)

select
      partd_claims.*
    , coalesce(beneficiary_xref.crnt_num, partd_claims.bene_mbi_id) as current_bene_mbi_id
from {{ ref('stg_partd_claims') }} as partd_claims
left join beneficiary_xref
    on partd_claims.bene_mbi_id = beneficiary_xref.prvs_num
