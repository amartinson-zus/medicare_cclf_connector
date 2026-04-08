{#

    This macros takes in a date column and date format (defaults to 'YYYY-MM-DD')
    then runs a try to cast macro based on the adapter type. Returns NULL
    casted as date if the try to cast fails.

#}

{%- macro clean_source_value(column_name) -%}

    nullif(trim(cast({{ column_name }} as {{ dbt.type_string() }})), '')

{%- endmacro -%}

{%- macro try_to_cast_date(column_name, date_format='YYYY-MM-DD') -%}

    {{ return(adapter.dispatch('try_to_cast_date')(column_name, date_format)) }}

{%- endmacro -%}

{%- macro bigquery__try_to_cast_date(column_name, date_format) -%}

    {%- set cleaned_value -%}
    {{ clean_source_value(column_name) }}
    {%- endset -%}

    case
      when {{ cleaned_value }} in ('1000-01-01', '9999-12-31', '10000101', '99991231')
        then cast(null as date)
    {%- if date_format == 'YYYY-MM-DD HH:MI:SS' -%}
      else safe_cast(date({{ cleaned_value }}) as date)
    {%- else -%}
      else safe_cast({{ cleaned_value }} as date)
    {%- endif -%}
    end

{%- endmacro -%}

{%- macro default__try_to_cast_date(column_name, date_format) -%}

    {%- set cleaned_value -%}
    {{ clean_source_value(column_name) }}
    {%- endset -%}

    case
      when {{ cleaned_value }} in ('1000-01-01', '9999-12-31', '10000101', '99991231')
        then cast(null as date)
      else try_cast( {{ cleaned_value }} as date )
    end

{%- endmacro -%}

{%- macro postgres__try_to_cast_date(column_name, date_format) -%}

    {%- set cleaned_value -%}
    {{ clean_source_value(column_name) }}
    {%- endset -%}

    case
      when {{ cleaned_value }} in ('1000-01-01', '9999-12-31', '10000101', '99991231')
        then date(NULL)
    {%- if date_format == 'YYYY-MM-DD' -%}
      when {{ cleaned_value }} similar to '[0-9]{4}-[0-9]{2}-[0-9]{2}'
      then to_date( {{ cleaned_value }}, 'YYYY-MM-DD')
      else date(NULL)
    end
    {%- elif date_format == 'YYYYMMDD' -%}
      when {{ cleaned_value }} similar to '[0-9]{4}[0-9]{2}[0-9]{2}'
      then to_date( {{ cleaned_value }}, 'YYYYMMDD')
      else date(NULL)
    {%- elif date_format == 'MM/DD/YYYY' -%}
      when {{ cleaned_value }} similar to '[0-9]{2}/[0-9]{2}/[0-9]{4}'
      then to_date( {{ cleaned_value }}, 'MM/DD/YYYY')
      else date(NULL)
    {%- elif date_format == 'YYYY-MM-DD HH:MI:SS' -%}
      when {{ cleaned_value }} similar to '[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}'
      then to_date( {{ cleaned_value }}, 'YYYY-MM-DD HH:MI:SS')
      else date(NULL)
    {%- else -%}
      else date(NULL)
    {%- endif -%}
    end

{%- endmacro -%}

{%- macro redshift__try_to_cast_date(column_name, date_format) -%}

    {%- set cleaned_value -%}
    {{ clean_source_value(column_name) }}
    {%- endset -%}

    case
      when {{ cleaned_value }} in ('1000-01-01', '9999-12-31', '10000101', '99991231')
        then date(NULL)
    {%- if date_format == 'YYYY-MM-DD' -%}
      when {{ cleaned_value }} similar to '\\d{4}-\\d{2}-\\d{2}'
      then to_date( {{ cleaned_value }}, 'YYYY-MM-DD')
      else date(NULL)
    {%- elif date_format == 'YYYYMMDD' -%}
      when {{ cleaned_value }} similar to '\\d{4}\\d{2}\\d{2}'
      then to_date( {{ cleaned_value }}, 'YYYYMMDD')
      else date(NULL)
    {%- elif date_format == 'MM/DD/YYYY' -%}
      when {{ cleaned_value }} similar to '\\d{2}/\\d{2}/\\d{4}'
      then to_date( {{ cleaned_value }}, 'MM/DD/YYYY')
      else date(NULL)
    {%- elif date_format == 'YYYY-MM-DD HH:MI:SS' -%}
      when {{ cleaned_value }} similar to '\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}'
      then to_date( {{ cleaned_value }}, 'YYYY-MM-DD HH:MI:SS')
      else date(NULL)
    {%- else -%}
      else date(NULL)
    {%- endif -%}
    end

{%- endmacro -%}

{%- macro snowflake__try_to_cast_date(column_name, date_format) -%}

    {%- set cleaned_value -%}
    {{ clean_source_value(column_name) }}
    {%- endset -%}

    case
      when {{ cleaned_value }} in ('1000-01-01', '9999-12-31', '10000101', '99991231')
        then cast(null as date)
      else try_cast( {{ cleaned_value }} as date )
    end

{%- endmacro -%}
