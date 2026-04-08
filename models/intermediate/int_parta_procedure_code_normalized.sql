with beneficiary_xref as (

    select * from {{ ref('int_beneficiary_xref_deduped') }}

)

select
      parta_procedure_code.*
    , coalesce(beneficiary_xref.crnt_num, parta_procedure_code.bene_mbi_id) as current_bene_mbi_id
from {{ ref('stg_parta_procedure_code') }} as parta_procedure_code
left join beneficiary_xref
    on parta_procedure_code.bene_mbi_id = beneficiary_xref.prvs_num
