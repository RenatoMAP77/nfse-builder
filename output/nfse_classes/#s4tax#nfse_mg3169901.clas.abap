CLASS /s4tax/nfse_mg3169901 DEFINITION
  PUBLIC
  INHERITING FROM /s4tax/nfse_default
  FINAL
  CREATE PUBLIC.
  " Uba/MG

  PUBLIC SECTION.
    CONSTANTS tax_address TYPE string VALUE 'MG 3169901'.
    METHODS:
      get_rps_identificacao REDEFINITION,
      /s4tax/infse_data~get_reasons_cancellation REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS /s4tax/nfse_mg3169901 IMPLEMENTATION.


  METHOD get_rps_identificacao.
    DATA: codigo_municipio_incidencia TYPE string,
          tax_address_branch          TYPE string,
          tax_address_obj             TYPE REF TO /s4tax/tax_address.

    result = super->get_rps_identificacao( ).

    tax_address_obj = me->branch->get_tax_address( ).
    tax_address_branch = tax_address_obj->struct-taxjurcode.

    tax_address_branch = me->string_utils->get_x_last_chars(
      input          = tax_address_branch
      num_last_chars = 7 ).

    codigo_municipio_incidencia = get_cod_munic_incidencia( ).

    IF codigo_municipio_incidencia NE tax_address_branch.
      result-natureza_operacao = '2'.
    ELSE.
      result-natureza_operacao = '1'.
    ENDIF.

    IF result-serie IS INITIAL.
      result-serie = 'NF'.
    ENDIF.

    result-tipo_rps = '1'.

  ENDMETHOD.


  METHOD /s4tax/infse_data~get_reasons_cancellation.
    result-motivo = 'Erro na emissao'.
  ENDMETHOD.


ENDCLASS.