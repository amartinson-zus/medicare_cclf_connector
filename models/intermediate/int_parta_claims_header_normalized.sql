with beneficiary_xref as (

    select * from {{ ref('int_beneficiary_xref_deduped') }}

)

select
      parta_claims_header.*
    , coalesce(beneficiary_xref.crnt_num, parta_claims_header.bene_mbi_id) as current_bene_mbi_id
from {{ ref('stg_parta_claims_header') }} as parta_claims_header
left join beneficiary_xref
    on parta_claims_header.bene_mbi_id = beneficiary_xref.prvs_num
