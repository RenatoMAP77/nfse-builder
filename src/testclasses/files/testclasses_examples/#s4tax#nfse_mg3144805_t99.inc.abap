*&---------------------------------------------------------------------*
*& Include /s4tax/nfse_mg3144805_t99
*&---------------------------------------------------------------------*
class ltcl_nfse_mg3144805 definition final for testing
  INHERITING FROM /s4tax/nfse_default_test
    DURATION SHORT
    RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA: cut TYPE REF TO /s4tax/nfse_mg3144805.
    CLASS-DATA: cached_class_name TYPE seoclname.
    CLASS-METHODS: class_setup.

    METHODS:
      setup,
      get_reasons_cancellation FOR TESTING RAISING cx_static_check,
      get_rps_identificacao_series FOR TESTING RAISING cx_static_check,
      get_rps_identificacao FOR TESTING RAISING cx_static_check.
endclass.


class ltcl_nfse_mg3144805 implementation.

  METHOD get_reasons_cancellation.

    DATA: reason TYPE /s4tax/s_nfse_cancel_fields.

    reason = cut->/s4tax/infse_data~get_reasons_cancellation( '' ).

    cl_abap_unit_assert=>assert_equals( exp = '2'
                                        act = reason-code ).

    cl_abap_unit_assert=>assert_equals( exp = 'Serviço não prestado'
                                        act = reason-motivo ).

  ENDMETHOD.

  METHOD get_rps_identificacao.
    DATA: expected      TYPE /s4tax/s_nfse_identificacao,
          identificacao TYPE /s4tax/s_nfse_identificacao.

    expected = mount_identificacao_expected( ).
    expected-serie = '001'.
    expected-tipo_rps = '1'.
    me->mock_identificacao( ).

    identificacao = cut->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( exp = expected act =  identificacao ).

  ENDMETHOD.

  METHOD get_rps_identificacao_series.
    DATA: expected      TYPE /s4tax/s_nfse_identificacao,
          identificacao TYPE /s4tax/s_nfse_identificacao.

    expected = mount_identificacao_expected( ).
    expected-serie = 'NF'.
    expected-tipo_rps = '1'.

    me->mock_identificacao( ).


    DATA(serieVazia) = me->doc->get_series( ).
    CLEAR serieVazia.

    me->doc->set_series( serieVazia ).

    identificacao = cut->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( exp = expected act =  identificacao ).

  ENDMETHOD.
  METHOD class_setup.
    DATA: cut TYPE REF TO /s4tax/nfse_mg3144805.
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

endclass.