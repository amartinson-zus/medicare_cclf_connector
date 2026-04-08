with staged_data as (

    select
          cast(bene_mbi_id as {{ dbt.type_string() }}) as bene_mbi_id
        , cast(bene_hic_num as {{ dbt.type_string() }}) as bene_hic_num
        , cast(bene_fips_state_cd as {{ dbt.type_string() }}) as bene_fips_state_cd
        , cast(bene_fips_cnty_cd as {{ dbt.type_string() }}) as bene_fips_cnty_cd
        , cast(bene_zip_cd as {{ dbt.type_string() }}) as bene_zip_cd
        , cast(bene_dob as {{ dbt.type_string() }}) as bene_dob
        , cast(bene_sex_cd as {{ dbt.type_string() }}) as bene_sex_cd
        , cast(bene_race_cd as {{ dbt.type_string() }}) as bene_race_cd
        , cast(bene_age as {{ dbt.type_string() }}) as bene_age
        , cast(bene_mdcr_stus_cd as {{ dbt.type_string() }}) as bene_mdcr_stus_cd
        , cast(bene_dual_stus_cd as {{ dbt.type_string() }}) as bene_dual_stus_cd
        , cast(bene_death_dt as {{ dbt.type_string() }}) as bene_death_dt
        , cast(bene_rng_bgn_dt as {{ dbt.type_string() }}) as bene_rng_bgn_dt
        , cast(bene_rng_end_dt as {{ dbt.type_string() }}) as bene_rng_end_dt
        , cast(bene_1st_name as {{ dbt.type_string() }}) as bene_1st_name
        , cast(bene_midl_name as {{ dbt.type_string() }}) as bene_midl_name
        , cast(bene_last_name as {{ dbt.type_string() }}) as bene_last_name
        , cast(bene_orgnl_entlmt_rsn_cd as {{ dbt.type_string() }}) as bene_orgnl_entlmt_rsn_cd
        , cast(bene_entlmt_buyin_ind as {{ dbt.type_string() }}) as bene_entlmt_buyin_ind
        , cast(bene_part_a_enrlmt_bgn_dt as {{ dbt.type_string() }}) as bene_part_a_enrlmt_bgn_dt
        , cast(bene_part_b_enrlmt_bgn_dt as {{ dbt.type_string() }}) as bene_part_b_enrlmt_bgn_dt
        , cast(bene_line_1_adr as {{ dbt.type_string() }}) as bene_line_1_adr
        , cast(bene_line_2_adr as {{ dbt.type_string() }}) as bene_line_2_adr
        , cast(bene_line_3_adr as {{ dbt.type_string() }}) as bene_line_3_adr
        , cast(bene_line_4_adr as {{ dbt.type_string() }}) as bene_line_4_adr
        , cast(bene_line_5_adr as {{ dbt.type_string() }}) as bene_line_5_adr
        , cast(bene_line_6_adr as {{ dbt.type_string() }}) as bene_line_6_adr
        , cast(geo_zip_plc_name as {{ dbt.type_string() }}) as geo_zip_plc_name
        , cast(geo_usps_state_cd as {{ dbt.type_string() }}) as geo_usps_state_cd
        , cast(geo_zip5_cd as {{ dbt.type_string() }}) as geo_zip5_cd
        , cast(geo_zip4_cd as {{ dbt.type_string() }}) as geo_zip4_cd
        , file_name
        , file_date
        , cast({{ date_from_parts('year(file_date)', 'month(file_date)', 1) }} as {{ dbt.type_string() }}) as coverage_month
    from {{ ref('stg_beneficiary_demographics') }}

)

/* dedupe full rows that may appear in multiple files */
, add_row_num as (

    select *, row_number() over (
        partition by
              bene_mbi_id
            , bene_hic_num
            , bene_fips_state_cd
            , bene_fips_cnty_cd
            , bene_zip_cd
            , bene_dob
            , bene_sex_cd
            , bene_race_cd
            /*, bene_age*/ --commenting out since it causes duplicates and is not used
            , bene_mdcr_stus_cd
            , bene_dual_stus_cd
            , bene_death_dt
            , bene_rng_bgn_dt
            , bene_rng_end_dt
            , bene_1st_name
            , bene_midl_name
            , bene_last_name
            , bene_orgnl_entlmt_rsn_cd
            , bene_entlmt_buyin_ind
            , bene_part_a_enrlmt_bgn_dt
            , bene_part_b_enrlmt_bgn_dt
            , bene_line_1_adr
            , bene_line_2_adr
            , bene_line_3_adr
            , bene_line_4_adr
            , bene_line_5_adr
            , bene_line_6_adr
            , geo_zip_plc_name
            , geo_usps_state_cd
            , geo_zip5_cd
            , geo_zip4_cd
            , coverage_month
        order by file_date desc
        ) as row_num
    from staged_data

)

, beneficiary_xref as (

    select
          crnt_num
        , prvs_num
    from {{ ref('int_beneficiary_xref_deduped') }}

)

, add_mbi_xref as (

    select
          add_row_num.bene_mbi_id
        , coalesce(beneficiary_xref.crnt_num, add_row_num.bene_mbi_id) as current_bene_mbi_id
        , add_row_num.bene_hic_num
        , add_row_num.bene_fips_state_cd
        , add_row_num.bene_fips_cnty_cd
        , add_row_num.bene_zip_cd
        , add_row_num.bene_dob
        , add_row_num.bene_sex_cd
        , add_row_num.bene_race_cd
        , add_row_num.bene_mdcr_stus_cd
        , add_row_num.bene_dual_stus_cd
        , add_row_num.bene_death_dt
        , add_row_num.bene_rng_bgn_dt
        , add_row_num.bene_rng_end_dt
        , add_row_num.bene_1st_name
        , add_row_num.bene_midl_name
        , add_row_num.bene_last_name
        , add_row_num.bene_orgnl_entlmt_rsn_cd
        , add_row_num.bene_entlmt_buyin_ind
        , add_row_num.bene_part_a_enrlmt_bgn_dt
        , add_row_num.bene_part_b_enrlmt_bgn_dt
        , add_row_num.bene_line_1_adr
        , add_row_num.bene_line_2_adr
        , add_row_num.bene_line_3_adr
        , add_row_num.bene_line_4_adr
        , add_row_num.bene_line_5_adr
        , add_row_num.bene_line_6_adr
        , add_row_num.geo_zip_plc_name
        , add_row_num.geo_usps_state_cd
        , add_row_num.geo_zip5_cd
        , add_row_num.geo_zip4_cd
        , add_row_num.coverage_month
        , add_row_num.file_name
        , add_row_num.file_date
    from add_row_num
        left join beneficiary_xref
            on add_row_num.bene_mbi_id = beneficiary_xref.prvs_num
    where row_num = 1

)

, get_latest_mbi as (

    select
          bene_mbi_id
        , current_bene_mbi_id
        , bene_hic_num
        , bene_fips_state_cd
        , bene_fips_cnty_cd
        , bene_zip_cd
        , bene_dob
        , bene_sex_cd
        , bene_race_cd
        , bene_mdcr_stus_cd
        , bene_dual_stus_cd
        , bene_death_dt
        , bene_rng_bgn_dt
        , bene_rng_end_dt
        , bene_1st_name
        , bene_midl_name
        , bene_last_name
        , bene_orgnl_entlmt_rsn_cd
        , bene_entlmt_buyin_ind
        , bene_part_a_enrlmt_bgn_dt
        , bene_part_b_enrlmt_bgn_dt
        , bene_line_1_adr
        , bene_line_2_adr
        , bene_line_3_adr
        , bene_line_4_adr
        , bene_line_5_adr
        , bene_line_6_adr
        , geo_zip_plc_name
        , geo_usps_state_cd
        , geo_zip5_cd
        , geo_zip4_cd
        , coverage_month
        , file_name
        , file_date
        , row_number() over (
            partition by current_bene_mbi_id, coverage_month
            order by file_date desc
          ) as row_num
    from add_mbi_xref

)

select
      current_bene_mbi_id
    , bene_hic_num
    , bene_fips_state_cd
    , bene_fips_cnty_cd
    , bene_zip_cd
    , {{ try_to_cast_date('bene_dob') }} as bene_dob
    , bene_sex_cd
    , bene_race_cd
    , bene_mdcr_stus_cd
    , bene_dual_stus_cd
    , {{ try_to_cast_date('bene_death_dt') }} as bene_death_dt
    , {{ try_to_cast_date('bene_rng_bgn_dt') }} as bene_rng_bgn_dt
    , {{ try_to_cast_date('bene_rng_end_dt') }} as bene_rng_end_dt
    , bene_1st_name
    , bene_midl_name
    , bene_last_name
    , bene_orgnl_entlmt_rsn_cd
    , bene_entlmt_buyin_ind
    , {{ try_to_cast_date('bene_part_a_enrlmt_bgn_dt') }} as bene_part_a_enrlmt_bgn_dt
    , {{ try_to_cast_date('bene_part_b_enrlmt_bgn_dt') }} as bene_part_b_enrlmt_bgn_dt
    , bene_line_1_adr
    , bene_line_2_adr
    , bene_line_3_adr
    , bene_line_4_adr
    , bene_line_5_adr
    , bene_line_6_adr
    , geo_zip_plc_name
    , geo_usps_state_cd
    , geo_zip5_cd
    , geo_zip4_cd
    , {{ try_to_cast_date('coverage_month') }} as coverage_month
    , file_name
    , file_date
from get_latest_mbi
where row_num = 1
