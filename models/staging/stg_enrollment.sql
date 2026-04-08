-- CTE that selects from either the source table or the demo data seed based on the 'demo_data_only' variable
with enrollment as (
  SELECT
    * 
  FROM
  {% if var('cms_alr_connector', var('demo_data_only', false)) %} {{ ref('enrollment') }} {% else %} {{ source('medicare_cclf','enrollment') }}{% endif %}
)

{% if var('cms_alr_connector', var('demo_data_only', false)) %}

select *
from enrollment

{% else %}

select
      CURRENT_BENE_MBI_ID
    , {{ try_to_cast_date('ENROLLMENT_START_DATE') }} as ENROLLMENT_START_DATE
    , {{ try_to_cast_date('ENROLLMENT_END_DATE') }} as ENROLLMENT_END_DATE
    , {{ try_to_cast_date('BENE_MEMBER_MONTH') }} as BENE_MEMBER_MONTH
    , FILE_NAME
    , {{ try_to_cast_date('FILE_DATE') }} as FILE_DATE
from enrollment

{% endif %}
