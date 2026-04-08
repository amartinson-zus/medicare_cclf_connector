with institutional_rank_input as (

    select
          'institutional' as source_model
        , claim_id
        , claim_line_number
        , file_name
        , file_date
        , paid_date
        , branch_row_key
    from {{ ref('int_institutional_claim_deduped') }}

)

, physician_rank_input as (

    select
          'physician' as source_model
        , claim_id
        , claim_line_number
        , file_name
        , {{ try_to_cast_date('ingest_datetime') }} as file_date
        , paid_date
        , branch_row_key
    from {{ ref('int_physician_claim_deduped') }}

)

, dme_rank_input as (

    select
          'dme' as source_model
        , claim_id
        , claim_line_number
        , file_name
        , {{ try_to_cast_date('ingest_datetime') }} as file_date
        , paid_date
        , branch_row_key
    from {{ ref('int_dme_claim_deduped') }}

)

, ranked_input as (

    select * from institutional_rank_input
    union all
    select * from physician_rank_input
    union all
    select * from dme_rank_input

)

, branch_deduped as (

    select
          branch_row_key
        , claim_id
        , claim_line_number
        , file_name
        , file_date
        , paid_date
        , source_model
        , row_number() over (
            partition by branch_row_key
            order by
                  file_date desc
                , paid_date desc
                , source_model desc
                , file_name desc
                , branch_row_key desc
          ) as branch_row_num
    from ranked_input

)

select
      branch_row_key
    , row_number() over (
        partition by claim_id, claim_line_number
        order by
              file_date desc
            , paid_date desc
            , source_model desc
            , file_name desc
            , branch_row_key desc
      ) as row_num
from branch_deduped
where branch_row_num = 1
