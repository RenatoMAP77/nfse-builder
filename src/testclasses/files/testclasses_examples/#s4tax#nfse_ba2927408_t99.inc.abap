*&---------------------------------------------------------------------*
*& Include /s4tax/nfse_ba2927408_t99
*&---------------------------------------------------------------------*
CLASS ltcl_nfse_ba2927408_t99 DEFINITION FINAL FOR TESTING
INHERITING FROM /s4tax/nfse_default_test
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA: cut TYPE REF TO /s4tax/nfse_ba2927408.
    CLASS-DATA: cached_class_name TYPE seoclname.
    CLASS-METHODS: class_setup.

    METHODS:
      setup,
      get_identificacao FOR TESTING RAISING cx_static_check,
      regime_changed    FOR TESTING RAISING cx_static_check,
      sum_nfse_tax_values FOR TESTING RAISING cx_static_check.
ENDCLASS.


CLASS ltcl_nfse_ba2927408_t99 IMPLEMENTATION.
  METHOD class_setup.
    DATA: cut TYPE REF TO /s4tax/nfse_ba2927408.
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

  METHOD get_identificacao.

    DATA: expected      TYPE /s4tax/s_nfse_identificacao,
          identificacao TYPE /s4tax/s_nfse_identificacao.

    expected = mount_identificacao_expected( ).
    expected-serie = 'NF'.

    me->mock_identificacao( ).
    me->mock_tomador(  ).
    me->mock_tomador_address(  ).
*    me->mock

    identificacao = cut->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( exp = expected act =  identificacao ).

  ENDMETHOD.

  METHOD regime_changed.
    DATA: identificacao TYPE /s4tax/s_nfse_identificacao.

    me->mock_identificacao( ).
    me->mock_extension( ).

    identificacao = cut->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( exp = '1' act = identificacao-regime_especial_tributacao ).

    me->extension_head->set_reg_espec_tribut( 'M' ).
    identificacao = cut->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( exp = '5' act = identificacao-regime_especial_tributacao ).
  ENDMETHOD.

  METHOD sum_nfse_tax_values.
    DATA: servico  TYPE /s4tax/s_nfse_servico,
          expected TYPE /s4tax/s_nfse_servico.

    expected = mount_rps_serv_base_expected( ).
    expected = mount_rate_decimals_expected( expected ).

    me->mock_identificacao( ).
    me->mock_servico( ).

    servico = cut->get_rps_servico( ).
    cl_abap_unit_assert=>assert_equals( exp = expected act = servico ).
  ENDMETHOD.

ENDCLASS.