-- CTE that selects from either the source table or the demo data seed based on the 'demo_data_only' variable
with enrollment as (
  select pi.value as bene_mbi_id, * 
  from {{ source('fhir', 'patient')}} p
  inner join {{ source('fhir', 'patient_identifier')}} pi 
    on pi.patient_id = p.id
  where pi.system = 'http://hl7.org/fhir/sid/us-mbi'
)

{% if var('cms_alr_connector', var('demo_data_only', false)) %}

select *
from enrollment

{% else %}

select
      bene_mbi_id as CURRENT_BENE_MBI_ID
    , date_trunc('year', current_date) as ENROLLMENT_START_DATE
    , cast(extract(year from current_date) || '-12-31' as date) as ENROLLMENT_END_DATE
    , null as BENE_MEMBER_MONTH
    , null as FILE_NAME
    , null as FILE_DATE
from enrollment

{% endif %}
