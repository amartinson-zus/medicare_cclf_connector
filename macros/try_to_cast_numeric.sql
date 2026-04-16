{#-
    Safely casts source values to numeric or integer types after normalizing
    blanks to null.
-#}

{%- macro try_to_cast_numeric(column_name) -%}

    {{ dbt.safe_cast(clean_source_value(column_name), dbt.type_numeric()) }}

{%- endmacro -%}

{%- macro try_to_cast_int(column_name) -%}

    {{ dbt.safe_cast(clean_source_value(column_name), dbt.type_int()) }}

{%- endmacro -%}
