*&---------------------------------------------------------------------*
*& Include #s4tax#nfse_rj3303401_t99.inc
*&---------------------------------------------------------------------*
CLASS ltcl_nfse_rj3303401 DEFINITION FINAL FOR TESTING
  INHERITING FROM /s4tax/nfse_default_test
    DURATION SHORT
    RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA: cut TYPE REF TO /s4tax/nfse_rj3303401.
    CLASS-DATA: cached_class_name TYPE seoclname.
    CLASS-METHODS: class_setup.

    METHODS:
      setup,
      get_rps_identificacao FOR TESTING RAISING cx_static_check,
      get_reasons_cancellation FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_nfse_rj3303401 IMPLEMENTATION.
  
  METHOD class_setup.
    DATA: cut TYPE REF TO /s4tax/nfse_rj3303401.
    cached_class_name = /s4tax/tests_utils=>get_classname_by_data( cut ).
  ENDMETHOD.
  
  METHOD setup.
    DATA: cx_root TYPE REF TO cx_root.
    TRY.
        me->branch_info->get_class( )->set_class( cached_class_name ).
        cut ?= /s4tax/nfse_default=>get_instance( branch_info = me->branch_info documents = me->documents reporter = reporter ).
      CATCH cx_root INTO cx_root.
    ENDTRY.
  ENDMETHOD.

  METHOD get_rps_identificacao.
    me->mock_identificacao( ).
    me->mock_servico( ).
    DATA(res) = cut->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( exp = '1' act = res-natureza_operacao ).

    me->tax_address_branch_adr->set_taxjurcode( '9999999' ).
    res = cut->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( exp = '2' act = res-natureza_operacao ).
  ENDMETHOD.

  METHOD get_reasons_cancellation.
    DATA(res) = cut->/s4tax/infse_data~get_reasons_cancellation( ).
    cl_abap_unit_assert=>assert_equals( exp = 'Servico nao prestado' act = res-motivo ).
  ENDMETHOD.

ENDCLASS.