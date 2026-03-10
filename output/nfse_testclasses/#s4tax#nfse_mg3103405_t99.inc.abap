*&---------------------------------------------------------------------*
*& Include #s4tax#nfse_mg3103405_t99.inc
*&---------------------------------------------------------------------*
CLASS ltcl_nfse_mg3103405 DEFINITION FINAL FOR TESTING
  INHERITING FROM /s4tax/nfse_default_test
    DURATION SHORT
    RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA: cut TYPE REF TO /s4tax/nfse_mg3103405.
    CLASS-DATA: cached_class_name TYPE seoclname.
    CLASS-METHODS: class_setup.

    METHODS:
      setup,
      get_rps_identificacao FOR TESTING RAISING cx_static_check,
      get_reasons_cancellation FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_nfse_mg3103405 IMPLEMENTATION.
  
  METHOD class_setup.
    DATA: cut TYPE REF TO /s4tax/nfse_mg3103405.
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
    "Vazio
  ENDMETHOD.

  METHOD get_reasons_cancellation.
    "Vazio
  ENDMETHOD.

ENDCLASS.