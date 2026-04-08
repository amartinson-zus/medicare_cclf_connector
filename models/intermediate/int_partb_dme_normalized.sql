with beneficiary_xref as (

    select * from {{ ref('int_beneficiary_xref_deduped') }}

)

select
      partb_dme.*
    , coalesce(beneficiary_xref.crnt_num, partb_dme.bene_mbi_id) as current_bene_mbi_id
from {{ ref('stg_partb_dme') }} as partb_dme
left join beneficiary_xref
    on partb_dme.bene_mbi_id = beneficiary_xref.prvs_num
