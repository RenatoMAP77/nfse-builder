CLASS /s4tax/nfse_rj3300100 DEFINITION
  PUBLIC
  INHERITING FROM /s4tax/nfse_default
  CREATE PUBLIC.
" Angra dos Reis/RJ

  PUBLIC SECTION.

    CONSTANTS tax_address TYPE string VALUE 'RJ 3300100'.

    METHODS:
      get_rps_identificacao REDEFINITION,
      /s4tax/infse_data~get_reasons_cancellation REDEFINITION,
      get_rps_tomador REDEFINITION.

  PROTECTED SECTION.
    METHODS:
      handle_dependencies REDEFINITION,
      get_cod_trib_municipio REDEFINITION,
      get_item_lista_servico REDEFINITION,
      get_iss REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.



CLASS /s4tax/nfse_rj3300100 IMPLEMENTATION.


  METHOD get_rps_identificacao.
    DATA: tax_address_branch          TYPE string,
          codigo_municipio_incidencia TYPE string,
          tax_address_obj             TYPE REF TO /s4tax/tax_address.

    result = super->get_rps_identificacao( ).

    tax_address_obj = me->branch->get_tax_address( ).
    tax_address_branch = tax_address_obj->struct-taxjurcode.

    me->string_utils->get_x_last_chars( EXPORTING input          = tax_address_branch
                                                  num_last_chars = 7
                                        RECEIVING result         = tax_address_branch ).

    codigo_municipio_incidencia = get_cod_munic_incidencia( ).

    result-natureza_operacao = '1'.
    IF codigo_municipio_incidencia NE tax_address_branch.
      result-natureza_operacao = '2'.
    ENDIF.

    IF result-serie IS INITIAL.
      result-serie = 'NF'.
    ENDIF.

  ENDMETHOD.


  METHOD /s4tax/infse_data~get_reasons_cancellation.
    result-motivo = 'Servico nao prestado'.
  ENDMETHOD.


  METHOD get_rps_tomador.
    result = super->get_rps_tomador( ).
    result-cpf = string_utils->if_value( result-cpf ).
  ENDMETHOD.


  METHOD get_cod_trib_municipio.
    result = super->get_cod_trib_municipio( ).
    result = me->string_utils->remove_special_characters( result ).
  ENDMETHOD.


  METHOD get_item_lista_servico.
    result = super->get_item_lista_servico( ).
    result = me->string_utils->remove_special_characters( result ).
  ENDMETHOD.


  METHOD get_iss.
    result = super->get_iss( iss = iss ).

    IF result-retido = /s4tax/constants=>proposition-true.
      result-valor = result-valor_retido.
    ENDIF.
  ENDMETHOD.


  METHOD handle_dependencies.
    super->handle_dependencies( ).

    IF me->data-rps-tomador-endereco-codigo_pais <> /s4tax/address_utils=>cod_brasil.
      data-rps-identificacao-natureza_operacao = '3'.
    ENDIF.
  ENDMETHOD.


ENDCLASS.