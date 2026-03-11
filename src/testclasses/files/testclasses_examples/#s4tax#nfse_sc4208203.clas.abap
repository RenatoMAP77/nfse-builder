CLASS /s4tax/nfse_sc4208203 DEFINITION PUBLIC
  INHERITING FROM /s4tax/nfse_default CREATE PUBLIC.

  PUBLIC SECTION.
    CONSTANTS: tax_address TYPE string VALUE 'SC 4208203'.
    METHODS:
      get_rps_identificacao REDEFINITION,
      get_rps_pag REDEFINITION,
      /s4tax/infse_data~get_reasons_cancellation REDEFINITION.

  PROTECTED SECTION.
    METHODS:
      get_reg_espec_tributacao REDEFINITION,
      get_discriminacao REDEFINITION.

  PRIVATE SECTION.
ENDCLASS.

CLASS /s4tax/nfse_sc4208203 IMPLEMENTATION.

  METHOD get_rps_identificacao.

    result = super->get_rps_identificacao( ).
    result-tipo_rps = '1'.

    result-serie = '5000'.

    CASE result-natureza_operacao.
      WHEN '4'.
        result-natureza_operacao = '104'.
      WHEN '3'.
        result-natureza_operacao = '103'.
      WHEN '1'.
        result-natureza_operacao = '101'.
      WHEN '30'.
        result-natureza_operacao = '102'.
      WHEN '28'.
        result-natureza_operacao = '106'.
    ENDCASE.

  ENDMETHOD.

  METHOD get_discriminacao.

    result = super->get_discriminacao( ).

*    DATA: tradenotes    TYPE /s4tax/tradenote_t,
*          tradenote     TYPE REF TO /s4tax/tradenote,
*          docnum        TYPE j_1bnfdoc-docnum,
*          discriminacao TYPE string,
*          dao_pack      TYPE REF TO /s4tax/idao_pack_model_busines,
*          dao_tradenote TYPE REF TO /s4tax/idao_tradenote.
*
*    docnum = doc->get_docnum( ).
*
*    dao_pack = /s4tax/dao_pack_model_business=>default_instance( ).
*    dao_tradenote = dao_pack->tradenote( ).
*    tradenotes = dao_tradenote->get_for_doc( docnum ).
*
*    IF tradenotes IS INITIAL.
*      RETURN.
*    ENDIF.
*
*    LOOP AT tradenotes INTO tradenote.
*      CLEAR discriminacao.
*      discriminacao = |Nº Parcela: { tradenote->get_ndup( ) } | &&
*                      |Data de Vencimento: { tradenote->get_dvenc( ) DATE = USER } | &&
*                      |Valor: { tradenote->get_vdup( ) CURRENCY = 'BRL' }|.
*      APPEND discriminacao TO result.
*    ENDLOOP.

  ENDMETHOD.

  METHOD get_rps_pag.

    DATA: dao_pack      TYPE REF TO /s4tax/idao_pack_model_busines,
          dao_tradenote TYPE REF TO /s4tax/idao_tradenote,
          det_pag       TYPE /s4tax/s_nfse_pag_det_pag,
          parcela       TYPE /s4tax/s_det_pag_parcelas,
          tradenotes    TYPE /s4tax/tradenote_t,
          tradenote     TYPE REF TO /s4tax/tradenote,
          docnum        TYPE j_1bnfdoc-docnum,
          data_venc     TYPE d,
          date_utils    TYPE REF TO /s4tax/date.

    det_pag-t_pag = '10'. "Boleto

    docnum = doc->get_docnum( ).

    dao_pack = /s4tax/dao_pack_model_business=>default_instance( ).
    dao_tradenote = dao_pack->tradenote( ).
    tradenotes = dao_tradenote->get_for_doc( docnum ).

    IF tradenotes IS INITIAL.
      RETURN.
    ENDIF.

    LOOP AT tradenotes INTO tradenote.
      CLEAR: data_venc, date_utils.
      data_venc = tradenote->get_dvenc( ).
      CREATE OBJECT date_utils EXPORTING date = data_venc.

      parcela-numero          = tradenote->get_ndup( ).
      parcela-data_vencimento = date_utils->to_iso_format( ).
      parcela-valor           = tradenote->get_vdup( ).
      APPEND parcela TO det_pag-parcelas.
    ENDLOOP.

    APPEND det_pag TO result-det_pag.

  ENDMETHOD.

  METHOD get_reg_espec_tributacao.

    result = super->get_reg_espec_tributacao( ).
    result = me->reg_espec_trib_letter_to_numb( trib = result ).

  ENDMETHOD.

  METHOD /s4tax/infse_data~get_reasons_cancellation.

    result-code = 'C999'.
    result-motivo = 'Servico nao prestado'.

  ENDMETHOD.

ENDCLASS.
