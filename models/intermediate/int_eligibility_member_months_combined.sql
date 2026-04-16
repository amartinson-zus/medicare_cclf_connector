{{ config(enabled=var('cms_alr_connector', false)) }}

with beneficiary_xref as (

    select
          prvs_num
        , crnt_num
    from {{ ref('int_beneficiary_xref_deduped') }}

)

, enrollment as (

    select
          cast(enrollment.current_bene_mbi_id as {{ dbt.type_string() }}) as bene_mbi_id
        , cast(coalesce(beneficiary_xref.crnt_num, enrollment.current_bene_mbi_id) as {{ dbt.type_string() }}) as current_bene_mbi_id
        , cast({{ date_from_parts('year(cast(enrollment.enrollment_start_date as date))', 'month(cast(enrollment.enrollment_start_date as date))', 1) }} as date) as coverage_month
        , cast(enrollment.enrollment_start_date as date) as enrollment_start_date
        , cast(enrollment.enrollment_end_date as date) as enrollment_end_date
        , cast(enrollment.bene_first_name as {{ dbt.type_string() }}) as bene_first_name
        , cast(enrollment.bene_last_name as {{ dbt.type_string() }}) as bene_last_name
        , cast(enrollment.bene_sex_cd as {{ dbt.type_string() }}) as bene_sex_cd
        , cast(enrollment.bene_race_cd as {{ dbt.type_string() }}) as bene_race_cd
        , cast(enrollment.bene_birth_date as date) as bene_birth_date
        , cast(enrollment.bene_death_date as date) as bene_death_date
        , cast(enrollment.bene_psnyrs_dual as {{ dbt.type_string() }}) as bene_psnyrs_dual
        , cast(enrollment.lti_status as {{ dbt.type_string() }}) as lti_status
        , cast(enrollment.geo_ssa_cnty_cd_name as {{ dbt.type_string() }}) as geo_ssa_cnty_cd_name
        , cast(enrollment.geo_ssa_state_name as {{ dbt.type_string() }}) as geo_ssa_state_name
        , cast(enrollment.file_name as {{ dbt.type_string() }}) as enrollment_file_name
        , cast(enrollment.file_date as date) as enrollment_file_date
        , row_number() over (
            partition by
                  cast(coalesce(beneficiary_xref.crnt_num, enrollment.current_bene_mbi_id) as {{ dbt.type_string() }})
                , cast({{ date_from_parts('year(cast(enrollment.enrollment_start_date as date))', 'month(cast(enrollment.enrollment_start_date as date))', 1) }} as date)
            order by
                  cast(enrollment.enrollment_end_date as date) desc
                , cast(enrollment.file_date as date) desc
          ) as row_num
    from {{ ref('int_enrollment') }} as enrollment
    left join beneficiary_xref
        on enrollment.current_bene_mbi_id = beneficiary_xref.prvs_num

)

, enrollment_deduped as (

    select
          bene_mbi_id
        , current_bene_mbi_id
        , coverage_month
        , enrollment_start_date
        , enrollment_end_date
        , bene_first_name
        , bene_last_name
        , bene_sex_cd
        , bene_race_cd
        , bene_birth_date
        , bene_death_date
        , bene_psnyrs_dual
        , lti_status
        , geo_ssa_cnty_cd_name
        , geo_ssa_state_name
        , enrollment_file_name
        , enrollment_file_date
    from enrollment
    where row_num = 1

)

, latest_enrollment_month as (

    select
          current_bene_mbi_id
        , max(coverage_month) as latest_enrollment_coverage_month
    from enrollment_deduped
    group by current_bene_mbi_id

)

, latest_alr_coverage_month as (

    select max(coverage_month) as latest_alr_coverage_month
    from enrollment_deduped

)

, active_in_latest_alr_month as (

    select distinct
          enrollment_deduped.current_bene_mbi_id
    from enrollment_deduped
    inner join latest_alr_coverage_month
        on enrollment_deduped.coverage_month = latest_alr_coverage_month.latest_alr_coverage_month

)

, demographics as (

    select
          cast(current_bene_mbi_id as {{ dbt.type_string() }}) as current_bene_mbi_id
        , cast(current_bene_mbi_id as {{ dbt.type_string() }}) as bene_mbi_id
        , cast(coverage_month as date) as coverage_month
        , cast(bene_hic_num as {{ dbt.type_string() }}) as bene_hic_num
        , cast(bene_fips_state_cd as {{ dbt.type_string() }}) as bene_fips_state_cd
        , cast(bene_fips_cnty_cd as {{ dbt.type_string() }}) as bene_fips_cnty_cd
        , cast(bene_zip_cd as {{ dbt.type_string() }}) as bene_zip_cd
        , cast(bene_dob as date) as bene_dob
        , cast(bene_sex_cd as {{ dbt.type_string() }}) as bene_sex_cd
        , cast(bene_race_cd as {{ dbt.type_string() }}) as bene_race_cd
        , cast(bene_mdcr_stus_cd as {{ dbt.type_string() }}) as bene_mdcr_stus_cd
        , cast(bene_dual_stus_cd as {{ dbt.type_string() }}) as bene_dual_stus_cd
        , cast(bene_death_dt as date) as bene_death_dt
        , cast(bene_rng_bgn_dt as date) as bene_rng_bgn_dt
        , cast(bene_rng_end_dt as date) as bene_rng_end_dt
        , cast(bene_1st_name as {{ dbt.type_string() }}) as bene_1st_name
        , cast(bene_midl_name as {{ dbt.type_string() }}) as bene_midl_name
        , cast(bene_last_name as {{ dbt.type_string() }}) as bene_last_name
        , cast(bene_orgnl_entlmt_rsn_cd as {{ dbt.type_string() }}) as bene_orgnl_entlmt_rsn_cd
        , cast(bene_entlmt_buyin_ind as {{ dbt.type_string() }}) as bene_entlmt_buyin_ind
        , cast(bene_part_a_enrlmt_bgn_dt as date) as bene_part_a_enrlmt_bgn_dt
        , cast(bene_part_b_enrlmt_bgn_dt as date) as bene_part_b_enrlmt_bgn_dt
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
        , cast(file_name as {{ dbt.type_string() }}) as demographics_file_name
        , cast(file_date as date) as demographics_file_date
    from {{ ref('int_beneficiary_demographics_deduped') }}

)

, combined as (

    select
          coalesce(enrollment_deduped.current_bene_mbi_id, demographics.current_bene_mbi_id) as current_bene_mbi_id
        , coalesce(enrollment_deduped.bene_mbi_id, demographics.bene_mbi_id) as bene_mbi_id
        , coalesce(enrollment_deduped.coverage_month, demographics.coverage_month) as coverage_month
        , cast(case
            when enrollment_deduped.current_bene_mbi_id is not null then 1
            when demographics.current_bene_mbi_id is not null
                and latest_alr_coverage_month.latest_alr_coverage_month is not null
                and demographics.coverage_month > latest_alr_coverage_month.latest_alr_coverage_month
                and active_in_latest_alr_month.current_bene_mbi_id is not null
                and nullif(trim(demographics.bene_entlmt_buyin_ind), '') is not null
                and trim(demographics.bene_entlmt_buyin_ind) != '0'
              then 1
            else 0
          end as integer) as eligibility_flag
        , cast(case when demographics.current_bene_mbi_id is not null then 1 else 0 end as integer) as data_sharing_flag
        , cast(case
            when enrollment_deduped.current_bene_mbi_id is not null then 0
            when demographics.current_bene_mbi_id is not null
                and latest_alr_coverage_month.latest_alr_coverage_month is not null
                and demographics.coverage_month > latest_alr_coverage_month.latest_alr_coverage_month
                and active_in_latest_alr_month.current_bene_mbi_id is not null
                and nullif(trim(demographics.bene_entlmt_buyin_ind), '') is not null
                and trim(demographics.bene_entlmt_buyin_ind) != '0'
              then 1
            else 0
          end as integer) as inferred_eligibility_flag
        , case
            when enrollment_deduped.enrollment_start_date is not null then enrollment_deduped.enrollment_start_date
            when demographics.current_bene_mbi_id is not null
                and latest_alr_coverage_month.latest_alr_coverage_month is not null
                and demographics.coverage_month > latest_alr_coverage_month.latest_alr_coverage_month
                and active_in_latest_alr_month.current_bene_mbi_id is not null
                and nullif(trim(demographics.bene_entlmt_buyin_ind), '') is not null
                and trim(demographics.bene_entlmt_buyin_ind) != '0'
              then demographics.coverage_month
            else null
          end as enrollment_start_date
        , case
            when enrollment_deduped.enrollment_end_date is not null then enrollment_deduped.enrollment_end_date
            when demographics.current_bene_mbi_id is not null
                and latest_alr_coverage_month.latest_alr_coverage_month is not null
                and demographics.coverage_month > latest_alr_coverage_month.latest_alr_coverage_month
                and active_in_latest_alr_month.current_bene_mbi_id is not null
                and nullif(trim(demographics.bene_entlmt_buyin_ind), '') is not null
                and trim(demographics.bene_entlmt_buyin_ind) != '0'
              then {{ last_day('demographics.coverage_month', 'month') }}
            else null
          end as enrollment_end_date
        , enrollment_deduped.bene_first_name
        , enrollment_deduped.bene_last_name
        , enrollment_deduped.bene_sex_cd as enrollment_bene_sex_cd
        , enrollment_deduped.bene_race_cd as enrollment_bene_race_cd
        , enrollment_deduped.bene_birth_date
        , enrollment_deduped.bene_death_date
        , enrollment_deduped.bene_psnyrs_dual
        , enrollment_deduped.lti_status
        , enrollment_deduped.geo_ssa_cnty_cd_name
        , enrollment_deduped.geo_ssa_state_name
        , enrollment_deduped.enrollment_file_name
        , enrollment_deduped.enrollment_file_date
        , demographics.bene_hic_num
        , demographics.bene_fips_state_cd
        , demographics.bene_fips_cnty_cd
        , demographics.bene_zip_cd
        , demographics.bene_dob
        , demographics.bene_sex_cd as demographics_bene_sex_cd
        , demographics.bene_race_cd as demographics_bene_race_cd
        , demographics.bene_mdcr_stus_cd
        , demographics.bene_dual_stus_cd
        , demographics.bene_death_dt
        , demographics.bene_rng_bgn_dt
        , demographics.bene_rng_end_dt
        , demographics.bene_1st_name
        , demographics.bene_midl_name
        , demographics.bene_last_name as demographics_bene_last_name
        , demographics.bene_orgnl_entlmt_rsn_cd
        , demographics.bene_entlmt_buyin_ind
        , demographics.bene_part_a_enrlmt_bgn_dt
        , demographics.bene_part_b_enrlmt_bgn_dt
        , demographics.bene_line_1_adr
        , demographics.bene_line_2_adr
        , demographics.bene_line_3_adr
        , demographics.bene_line_4_adr
        , demographics.bene_line_5_adr
        , demographics.bene_line_6_adr
        , demographics.geo_zip_plc_name
        , demographics.geo_usps_state_cd
        , demographics.geo_zip5_cd
        , demographics.geo_zip4_cd
        , demographics.demographics_file_name
        , demographics.demographics_file_date
    from enrollment_deduped
    full outer join demographics
        on enrollment_deduped.current_bene_mbi_id = demographics.current_bene_mbi_id
        and enrollment_deduped.coverage_month = demographics.coverage_month
    cross join latest_alr_coverage_month
    left join latest_enrollment_month
        on coalesce(enrollment_deduped.current_bene_mbi_id, demographics.current_bene_mbi_id) = latest_enrollment_month.current_bene_mbi_id
    left join active_in_latest_alr_month
        on coalesce(enrollment_deduped.current_bene_mbi_id, demographics.current_bene_mbi_id) = active_in_latest_alr_month.current_bene_mbi_id

)

select *
from combined
