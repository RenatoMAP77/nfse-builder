*&---------------------------------------------------------------------*
*& Include /s4tax/nfse_sc4208203_t99
*&---------------------------------------------------------------------*
CLASS ltcl_nfse_sc4208203 DEFINITION FINAL FOR TESTING
  INHERITING FROM /s4tax/nfse_default_test
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.


    DATA: cut TYPE REF TO /s4tax/nfse_sc4208203.
    CLASS-DATA: cached_class_name TYPE seoclname.

    CLASS-METHODS: class_setup, class_teardown.

    METHODS: setup, teardown,
      get_rps_identificacao    FOR TESTING RAISING cx_static_check,
      get_rps_pag              FOR TESTING RAISING cx_static_check,
      get_reg_espec_tributacao FOR TESTING RAISING cx_static_check,
      get_reason_cancel        FOR TESTING RAISING cx_static_check.

ENDCLASS.

CLASS ltcl_nfse_sc4208203 IMPLEMENTATION.


  METHOD class_teardown.

  ENDMETHOD.
  METHOD class_setup.
    DATA: cut TYPE REF TO /s4tax/nfse_sc4208203.
    cached_class_name = /s4tax/tests_utils=>get_classname_by_data( cut ).
  ENDMETHOD.


  METHOD setup.
    DATA: cx_root    TYPE REF TO cx_root.
    TRY.
        me->branch_info->get_class( )->set_class( cached_class_name ).
        cut ?= /s4tax/nfse_default=>get_instance( branch_info = me->branch_info documents = me->documents reporter = reporter ).
      CATCH cx_root INTO cx_root.
    ENDTRY.
  ENDMETHOD.

  METHOD teardown.

  ENDMETHOD.

  METHOD get_rps_identificacao.
    DATA: expected      TYPE /s4tax/s_nfse_identificacao,
          identificacao TYPE /s4tax/s_nfse_identificacao.

    expected-serie = '5000'.
    expected-tipo_rps = '1'.
    expected-natureza_operacao = '104'.

    me->mock_identificacao( ).
    me->mock_extension( ).
    me->extension_head->set_nat_operacao( '4' ).

    identificacao = cut->get_rps_identificacao( ).

    cl_abap_unit_assert=>assert_equals( exp = expected-serie
                                        act = identificacao-serie ).

    cl_abap_unit_assert=>assert_equals( exp = expected-tipo_rps
                                        act = identificacao-tipo_rps ).

    cl_abap_unit_assert=>assert_equals( exp = expected-natureza_operacao
                                        act = identificacao-natureza_operacao ).
  ENDMETHOD.

  METHOD get_rps_pag.
*    DATA: pag_result TYPE /s4tax/s_nfse_pag,
*          det_pag    TYPE /s4tax/s_nfse_pag_det_pag.
*
*
*    doc->set_docnum( '123456' ).
*    pag_result = cut->get_rps_pag( ).
*    det_pag = pag_result-det_pag[ 1 ].
*
*    cl_abap_unit_assert=>assert_equals( exp = '10' act = det_pag-t_pag ).
*    cl_abap_unit_assert=>assert_equals( exp = 3 act = lines( det_pag-parcelas ) ).
*
*    cl_abap_unit_assert=>assert_equals( exp = '001'      act = det_pag-parcelas[ 1 ]-numero ).
*    cl_abap_unit_assert=>assert_equals( exp = 150 act = det_pag-parcelas[ 1 ]-valor ).
*    cl_abap_unit_assert=>assert_equals( exp = '20250830' act = det_pag-parcelas[ 1 ]-data_vencimento ).
*
*    cl_abap_unit_assert=>assert_equals( exp = '002'      act = det_pag-parcelas[ 2 ]-numero ).
*    cl_abap_unit_assert=>assert_equals( exp = 200 act = det_pag-parcelas[ 2 ]-valor ).
*    cl_abap_unit_assert=>assert_equals( exp = '20250929' act = det_pag-parcelas[ 2 ]-data_vencimento ).
*
*    cl_abap_unit_assert=>assert_equals( exp = '003'      act = det_pag-parcelas[ 3 ]-numero ).
*    cl_abap_unit_assert=>assert_equals( exp = 350 act = det_pag-parcelas[ 3 ]-valor ).
*    cl_abap_unit_assert=>assert_equals( exp = '20251028' act = det_pag-parcelas[ 3 ]-data_vencimento ).
*
*    doc->set_docnum( '999999' ).
*    pag_result = cut->get_rps_pag( ).
*
*    cl_abap_unit_assert=>assert_initial( pag_result ).
*
*    doc->set_docnum( '708090' ).
*    pag_result = cut->get_rps_pag( ).
*    det_pag = pag_result-det_pag[ 1 ].
*
*    cl_abap_unit_assert=>assert_equals( exp = 2 act = lines( det_pag-parcelas ) ).
*
*    cl_abap_unit_assert=>assert_equals( exp = '001'      act = det_pag-parcelas[ 1 ]-numero ).
*    cl_abap_unit_assert=>assert_equals( exp = 700 act = det_pag-parcelas[ 1 ]-valor ).
*    cl_abap_unit_assert=>assert_equals( exp = '20260131' act = det_pag-parcelas[ 1 ]-data_vencimento ).
*
*    cl_abap_unit_assert=>assert_equals( exp = '002'      act = det_pag-parcelas[ 2 ]-numero ).
*    cl_abap_unit_assert=>assert_equals( exp = 800 act = det_pag-parcelas[ 2 ]-valor ).
*    cl_abap_unit_assert=>assert_equals( exp = '20260228' act = det_pag-parcelas[ 2 ]-data_vencimento ).
  ENDMETHOD.

  METHOD get_reg_espec_tributacao.
    me->mock_identificacao( ).
    me->mock_extension( ).

    DATA(identificacao) = cut->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( act = identificacao-regime_especial_tributacao exp = '1' ).

    me->extension_head->set_reg_espec_tribut( 'M' ).

    identificacao = cut->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( act = identificacao-regime_especial_tributacao exp = '5' ).
  ENDMETHOD.

  METHOD get_reason_cancel.
    DATA(reason) = cut->/s4tax/infse_data~get_reasons_cancellation( '' ).

    cl_abap_unit_assert=>assert_equals( exp = 'Servico nao prestado' act = reason-motivo ).
    cl_abap_unit_assert=>assert_equals( exp = 'C999' act = reason-code ).
  ENDMETHOD.


ENDCLASS.