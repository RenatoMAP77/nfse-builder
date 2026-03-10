CLASS /s4tax/nfse_ba2927408 DEFINITION
  PUBLIC
  INHERITING FROM /s4tax/nfse_default
  CREATE PUBLIC .

  PUBLIC SECTION.

    CONSTANTS tax_address TYPE string VALUE 'BA 2927408'.

    METHODS get_rps_identificacao REDEFINITION.
  PROTECTED SECTION.

    METHODS:
      sum_nfse_tax_values REDEFINITION.
  PRIVATE SECTION.
ENDCLASS.



CLASS /s4tax/nfse_ba2927408 IMPLEMENTATION.

  METHOD get_rps_identificacao.
    DATA: codigo_municipio_incidencia TYPE string,
          tax_address_branch          TYPE string,
          tax_address_obj             TYPE REF TO /s4tax/tax_address,
          string_utils                TYPE REF TO /s4tax/string_utils.

    result = super->get_rps_identificacao( ).
    result-serie = 'NF'.

    result-regime_especial_tributacao = reg_espec_trib_letter_to_numb( result-regime_especial_tributacao ).

    codigo_municipio_incidencia = get_cod_munic_incidencia( ).

    tax_address_obj = me->branch->get_tax_address( ).
    tax_address_branch = tax_address_obj->struct-taxjurcode.

    CREATE OBJECT string_utils.
    tax_address_branch = string_utils->replace_characters( tax_address_branch ).
  ENDMETHOD.

  METHOD sum_nfse_tax_values.
    result = super->sum_nfse_tax_values( tax_values =  tax_values ).
    result = get_rate_in_decimals( tax_values_sum = result ).
  ENDMETHOD.

ENDCLASS.