*&---------------------------------------------------------------------*
*& Include #s4tax#nfse_mg3169901_t99.inc
*&---------------------------------------------------------------------*
CLASS ltcl_nfse_mg3169901 DEFINITION FINAL FOR TESTING
  INHERITING FROM /s4tax/nfse_default_test
    DURATION SHORT
    RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA: cut TYPE REF TO /s4tax/nfse_mg3169901.
    CLASS-DATA: cached_class_name TYPE seoclname.
    CLASS-METHODS: class_setup.

    METHODS:
      setup,
      get_rps_identificacao FOR TESTING RAISING cx_static_check,
      get_reasons_cancellation FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_nfse_mg3169901 IMPLEMENTATION.
  
  METHOD class_setup.
    DATA: cut TYPE REF TO /s4tax/nfse_mg3169901.
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
    DATA(expected) = mount_identificacao_expected( ).
    expected-serie = 'NF'.
    expected-tipo_rps = '1'.
    me->mock_identificacao( ).
    me->doc->set_series( '' ).
    cl_abap_unit_assert=>assert_equals( exp = expected act = cut->get_rps_identificacao( ) ).
  ENDMETHOD.

  METHOD get_reasons_cancellation.
    DATA(reason) = cut->/s4tax/infse_data~get_reasons_cancellation( ).
    cl_abap_unit_assert=>assert_equals( exp = 'Erro na emissao'
                                        act = reason-motivo ).
  ENDMETHOD.

ENDCLASS.