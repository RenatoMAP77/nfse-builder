CLASS /s4tax/nfse_mg3161106 DEFINITION
  PUBLIC
  INHERITING FROM /s4tax/nfse_default
  FINAL
  CREATE PUBLIC.
" São Francisco/MG

  PUBLIC SECTION.
    CONSTANTS: tax_address TYPE string VALUE 'MG 3161106'.
    METHODS:
      get_rps_identificacao REDEFINITION,
      /s4tax/infse_data~get_reasons_cancellation REDEFINITION.

  PROTECTED SECTION.
    METHODS:
      get_iss REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.



CLASS /s4tax/nfse_mg3161106 IMPLEMENTATION.


  METHOD get_rps_identificacao.
    DATA: codigo_municipio_incidencia TYPE string,
          tax_address_branch          TYPE string,
          tax_address_obj             TYPE REF TO /s4tax/tax_address.

    result = super->get_rps_identificacao( ).

    result-regime_especial_tributacao = reg_espec_trib_letter_to_numb( result-regime_especial_tributacao ).

    tax_address_obj = me->branch->get_tax_address( ).
    tax_address_branch = tax_address_obj->struct-taxjurcode.
    tax_address_branch = me->string_utils->get_x_last_chars( input          = tax_address_branch
                                                             num_last_chars = 7 ).

    codigo_municipio_incidencia = get_cod_munic_incidencia( ).

    IF codigo_municipio_incidencia NE tax_address_branch.
      result-natureza_operacao = '2'.
    ELSE.
      result-natureza_operacao = '1'.
    ENDIF.
  ENDMETHOD.


  METHOD /s4tax/infse_data~get_reasons_cancellation.
    CASE reason_domain.
      WHEN '1'.
        result-codigo = '1'.
        result-motivo = 'Erro na emissao'.
      WHEN '2'.
        result-codigo = '2'.
        result-motivo = 'Servico nao prestado'.
      WHEN '3'.
        result-codigo = '3'.
        result-motivo = 'Erro de assinatura'.
      WHEN '4'.
        result-codigo = '4'.
        result-motivo = 'Duplicidade de nota'.
      WHEN '5'.
        result-codigo = '5'.
        result-motivo = 'Erro de processamento'.
      WHEN OTHERS.
        result-codigo = '2'.
        result-motivo = 'Servico nao prestado'.
    ENDCASE.
  ENDMETHOD.


  METHOD get_iss.
    result = super->get_iss( iss = iss ).
    result-exigibilidade = '2'.
  ENDMETHOD.


ENDCLASS.