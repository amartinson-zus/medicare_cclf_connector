with beneficiary_xref as (

    select * from {{ ref('int_beneficiary_xref_deduped') }}

)

select
      partb_physicians.*
    , coalesce(beneficiary_xref.crnt_num, partb_physicians.bene_mbi_id) as current_bene_mbi_id
from {{ ref('stg_partb_physicians') }} as partb_physicians
left join beneficiary_xref
    on partb_physicians.bene_mbi_id = beneficiary_xref.prvs_num
