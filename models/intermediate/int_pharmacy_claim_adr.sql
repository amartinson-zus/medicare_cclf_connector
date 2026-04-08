with staged_data as (

    select
          cast(cur_clm_uniq_id as {{ dbt.type_string() }}) as cur_clm_uniq_id
        , cast(bene_mbi_id as {{ dbt.type_string() }}) as bene_mbi_id
        , cast(bene_hic_num as {{ dbt.type_string() }}) as bene_hic_num
        , cast(clm_line_ndc_cd as {{ dbt.type_string() }}) as clm_line_ndc_cd
        , cast(clm_type_cd as {{ dbt.type_string() }}) as clm_type_cd
        , cast(clm_line_from_dt as {{ dbt.type_string() }}) as clm_line_from_dt
        , cast(prvdr_srvc_id_qlfyr_cd as {{ dbt.type_string() }}) as prvdr_srvc_id_qlfyr_cd
        , cast(clm_srvc_prvdr_gnrc_id_num as {{ dbt.type_string() }}) as clm_srvc_prvdr_gnrc_id_num
        , cast(clm_dspnsng_stus_cd as {{ dbt.type_string() }}) as clm_dspnsng_stus_cd
        , cast(clm_daw_prod_slctn_cd as {{ dbt.type_string() }}) as clm_daw_prod_slctn_cd
        , cast(clm_line_srvc_unit_qty as {{ dbt.type_string() }}) as clm_line_srvc_unit_qty
        , cast(clm_line_days_suply_qty as {{ dbt.type_string() }}) as clm_line_days_suply_qty
        , cast(prvdr_prsbng_id_qlfyr_cd as {{ dbt.type_string() }}) as prvdr_prsbng_id_qlfyr_cd
        , cast(clm_prsbng_prvdr_gnrc_id_num as {{ dbt.type_string() }}) as clm_prsbng_prvdr_gnrc_id_num
        , cast(clm_line_bene_pmt_amt as {{ dbt.type_string() }}) as clm_line_bene_pmt_amt
        , cast(clm_adjsmt_type_cd as {{ dbt.type_string() }}) as clm_adjsmt_type_cd
        , cast(clm_efctv_dt as {{ dbt.type_string() }}) as clm_efctv_dt
        , cast(clm_idr_ld_dt as {{ dbt.type_string() }}) as clm_idr_ld_dt
        , cast(clm_line_rx_srvc_rfrnc_num as {{ dbt.type_string() }}) as clm_line_rx_srvc_rfrnc_num
        , cast(clm_line_rx_fill_num as {{ dbt.type_string() }}) as clm_line_rx_fill_num
        , cast(clm_phrmcy_srvc_type_cd as {{ dbt.type_string() }}) as clm_phrmcy_srvc_type_cd
        , file_name
        , file_date
    from {{ ref('stg_partd_claims') }}

)

, beneficiary_xref as (

  select * from {{ ref('int_beneficiary_xref_deduped') }}

)

/*
    dedupe full rows that may appear in multiple files
    source fields not mapped or used for adjustment logic are commented out
*/
, add_row_num as (

    select *, row_number() over (
        partition by
              cur_clm_uniq_id
            , bene_mbi_id
            , bene_hic_num
            , clm_line_ndc_cd
            /*, clm_type_cd*/
            , clm_line_from_dt
            , prvdr_srvc_id_qlfyr_cd
            , clm_srvc_prvdr_gnrc_id_num
            , clm_dspnsng_stus_cd
            /*, clm_daw_prod_slctn_cd*/
            , clm_line_srvc_unit_qty
            , clm_line_days_suply_qty
            , prvdr_prsbng_id_qlfyr_cd
            , clm_prsbng_prvdr_gnrc_id_num
            , clm_line_bene_pmt_amt
            , clm_adjsmt_type_cd
            /*, clm_efctv_dt*/
            /*, clm_idr_ld_dt*/
            , clm_line_rx_srvc_rfrnc_num
            , clm_line_rx_fill_num
            /*, clm_phrmcy_srvc_type_cd*/
        order by file_date desc
        ) as row_num
    from staged_data

)

, dedupe as (

    select
          cur_clm_uniq_id
        , bene_mbi_id
        , bene_hic_num
        , clm_line_ndc_cd
        , clm_line_from_dt
        , prvdr_srvc_id_qlfyr_cd
        , clm_srvc_prvdr_gnrc_id_num
        , clm_dspnsng_stus_cd
        , clm_line_srvc_unit_qty
        , clm_line_days_suply_qty
        , prvdr_prsbng_id_qlfyr_cd
        , clm_prsbng_prvdr_gnrc_id_num
        , clm_line_bene_pmt_amt
        , clm_adjsmt_type_cd
        , clm_line_rx_srvc_rfrnc_num
        , clm_line_rx_fill_num
        , file_name
        , file_date
    from add_row_num
    where row_num = 1

)

/* coalesce current MBI from XREF if exists and MBI on claim */
, add_current_mbi as (

    select
          dedupe.cur_clm_uniq_id
        , dedupe.bene_mbi_id
        , coalesce(beneficiary_xref.crnt_num, dedupe.bene_mbi_id) as current_bene_mbi_id
        , dedupe.bene_hic_num
        , dedupe.clm_line_ndc_cd
        , dedupe.clm_line_from_dt
        , dedupe.prvdr_srvc_id_qlfyr_cd
        , dedupe.clm_srvc_prvdr_gnrc_id_num
        , dedupe.clm_dspnsng_stus_cd
        , dedupe.clm_line_srvc_unit_qty
        , dedupe.clm_line_days_suply_qty
        , dedupe.prvdr_prsbng_id_qlfyr_cd
        , dedupe.clm_prsbng_prvdr_gnrc_id_num
        , dedupe.clm_line_bene_pmt_amt
        , dedupe.clm_adjsmt_type_cd
        , dedupe.clm_line_rx_srvc_rfrnc_num
        , dedupe.clm_line_rx_fill_num
        , dedupe.file_name
        , dedupe.file_date
    from dedupe
        left join beneficiary_xref
            on dedupe.bene_mbi_id = beneficiary_xref.prvs_num

)

, normalized_data as (

    select *,
        row_number() over (
            partition by
                  cur_clm_uniq_id
                , current_bene_mbi_id
                , bene_hic_num
                , clm_line_ndc_cd
                , clm_line_from_dt
                , prvdr_srvc_id_qlfyr_cd
                , clm_srvc_prvdr_gnrc_id_num
                , clm_dspnsng_stus_cd
                , clm_line_srvc_unit_qty
                , clm_line_days_suply_qty
                , prvdr_prsbng_id_qlfyr_cd
                , clm_prsbng_prvdr_gnrc_id_num
                , clm_line_bene_pmt_amt
                , clm_adjsmt_type_cd
                , clm_line_rx_srvc_rfrnc_num
                , clm_line_rx_fill_num
            order by file_date desc
        ) as normalized_row_num
    from add_current_mbi

)

/*
    apply adjustment logic by grouping part D claims by their natural keys:
     - CLM_LINE_FROM_DT
     - PRVDR_SRVC_ID_QLFYR_CD
     - CLM_SRVC_PRVDR_GNRC_ID_NUM
     - CLM_DSPNSNG_STUS_CD
     - CLM_LINE_RX_SRVC_RFRNC_NUM
     - CLM_LINE_RX_FILL_NUM

    then sorting them by the CLM_ADJSMT_TYPE_CD code
    0 = Original Claim
    1 = Cancellation Claim
    2 = Adjustment claim

    final filtering takes place in dedupe model
*/
, sort_adjusted_claims as (

    select
          cur_clm_uniq_id
        , bene_mbi_id
        , current_bene_mbi_id
        , bene_hic_num
        , clm_line_ndc_cd
        , clm_line_from_dt
        , prvdr_srvc_id_qlfyr_cd
        , clm_srvc_prvdr_gnrc_id_num
        , clm_dspnsng_stus_cd
        , clm_line_srvc_unit_qty
        , clm_line_days_suply_qty
        , prvdr_prsbng_id_qlfyr_cd
        , clm_prsbng_prvdr_gnrc_id_num
        , clm_line_bene_pmt_amt
        , clm_adjsmt_type_cd
        , clm_line_rx_srvc_rfrnc_num
        , clm_line_rx_fill_num
        , file_name
        , file_date
        , row_number() over (
            partition by
                  clm_line_from_dt
                , prvdr_srvc_id_qlfyr_cd
                , clm_srvc_prvdr_gnrc_id_num
                , clm_dspnsng_stus_cd
                , clm_line_rx_srvc_rfrnc_num
                , clm_line_rx_fill_num
            order by clm_adjsmt_type_cd desc
        ) as row_num
    from normalized_data
    where normalized_row_num = 1

)

select
      cur_clm_uniq_id
    , bene_mbi_id
    , current_bene_mbi_id
    , bene_hic_num
    , clm_line_ndc_cd
    , clm_line_from_dt
    , prvdr_srvc_id_qlfyr_cd
    , clm_srvc_prvdr_gnrc_id_num
    , clm_dspnsng_stus_cd
    , clm_line_srvc_unit_qty
    , clm_line_days_suply_qty
    , prvdr_prsbng_id_qlfyr_cd
    , clm_prsbng_prvdr_gnrc_id_num
    , clm_line_bene_pmt_amt
    , clm_adjsmt_type_cd
    , clm_line_rx_srvc_rfrnc_num
    , clm_line_rx_fill_num
    , file_name
    , file_date
    , row_num
from sort_adjusted_claims
