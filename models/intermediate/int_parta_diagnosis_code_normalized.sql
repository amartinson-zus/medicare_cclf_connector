with beneficiary_xref as (

    select * from {{ ref('int_beneficiary_xref_deduped') }}

)

select
      parta_diagnosis_code.*
    , coalesce(beneficiary_xref.crnt_num, parta_diagnosis_code.bene_mbi_id) as current_bene_mbi_id
from {{ ref('stg_parta_diagnosis_code') }} as parta_diagnosis_code
left join beneficiary_xref
    on parta_diagnosis_code.bene_mbi_id = beneficiary_xref.prvs_num
