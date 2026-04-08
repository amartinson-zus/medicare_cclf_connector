with recursive staged_data as (

    select
          hicn_mbi_xref_ind
        , crnt_num
        , prvs_num
        , prvs_id_efctv_dt
        , prvs_id_obslt_dt
        , bene_rrb_num
        , file_name
        , file_date
    from {{ ref('stg_beneficiary_xref') }}

)

/* keep only the latest observed mapping for each previous MBI */
, latest_edges as (

    select
          hicn_mbi_xref_ind
        , crnt_num
        , prvs_num
        , prvs_id_efctv_dt
        , prvs_id_obslt_dt
        , bene_rrb_num
        , file_name
        , file_date
    from (
        select
              staged_data.*
            , row_number() over (
                partition by prvs_num
                order by
                      file_date desc
                    , prvs_id_efctv_dt desc
                    , prvs_id_obslt_dt desc
                    , crnt_num desc
              ) as row_num
        from staged_data
    ) latest
    where row_num = 1

)

/* recursively follow current->previous links until the chain ends */
, mbi_chain as (

    select
          prvs_num as original_prvs_num
        , prvs_num
        , crnt_num
        , 1 as depth
        , concat('|', coalesce(prvs_num, ''), '|', coalesce(crnt_num, ''), '|') as path
    from latest_edges

    union all

    select
          mbi_chain.original_prvs_num
        , latest_edges.prvs_num
        , latest_edges.crnt_num
        , mbi_chain.depth + 1 as depth
        , concat(mbi_chain.path, coalesce(latest_edges.crnt_num, ''), '|') as path
    from mbi_chain
    inner join latest_edges
        on mbi_chain.crnt_num = latest_edges.prvs_num
    where mbi_chain.crnt_num <> latest_edges.crnt_num
      and mbi_chain.depth < 25
      and strpos(mbi_chain.path, concat('|', coalesce(latest_edges.crnt_num, ''), '|')) = 0

)

, final_mappings as (

    select
          original_prvs_num as prvs_num
        , crnt_num
        , row_number() over (
            partition by original_prvs_num
            order by depth desc, crnt_num desc
          ) as row_num
    from mbi_chain

)

select
      prvs_num
    , crnt_num
from final_mappings
where row_num = 1
