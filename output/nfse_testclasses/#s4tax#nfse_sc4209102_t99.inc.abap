*&---------------------------------------------------------------------*
*& Include #s4tax#nfse_sc4209102_t99.inc
*&---------------------------------------------------------------------*
CLASS ltcl_nfse_sc4209102 DEFINITION FINAL FOR TESTING
  INHERITING FROM /s4tax/nfse_default_test
    DURATION SHORT
    RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA: cut TYPE REF TO /s4tax/nfse_sc4209102.
    CLASS-DATA: cached_class_name TYPE seoclname.
    CLASS-METHODS: class_setup.

    METHODS:
      setup,
      get_reasons_cancellation FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_nfse_sc4209102 IMPLEMENTATION.
  
  METHOD class_setup.
    DATA: cut TYPE REF TO /s4tax/nfse_sc4209102.
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

  METHOD get_reasons_cancellation.
    METHOD get_reasons_cancellation.
    DATA(res) = cut->/s4tax/infse_data~get_reasons_cancellation( 'C001' ).
    cl_abap_unit_assert=>assert_equals( exp = 'Dados do tomador incorretos' act = res-motivo ).
    res = cut->/s4tax/infse_data~get_reasons_cancellation( 'C005' ).
    cl_abap_unit_assert=>assert_equals( exp = 'Informacoes de descontos ou tributos incorretos' act = res-motivo ).
    res = cut->/s4tax/infse_data~get_reasons_cancellation( '' ).
    cl_abap_unit_assert=>assert_equals( exp = 'Outros' act = res-motivo ).
  ENDMETHOD.
  ENDMETHOD.

ENDCLASS.