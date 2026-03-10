'''
Ajustar todas os includes/classes de testes criados no passo 1 e adicionar a estrutura de testes dentro dele.

Por exemplo, a classe /s4tax/nfse_mg3144805 terá o seu include de testes com o seguinte padrão:

CLASS ltcl_nfse_mg3144805 DEFINITION FINAL FOR TESTING
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
      "E outros métodos que a classe principal tiver. Nesse caso, ela só tem esses 3 métodos públicos redefinidos.
ENDCLASS.

CLASS ltcl_nfse_mg3144805 IMPLEMENTATION.
  
  METHOD class_setup.
    DATA: cut TYPE REF TO /s4tax/nfse_mg3144805.
    cached_class_name = /s4tax/tests_utils=>get_classname_by_data( cut ).
  ENDMETHOD.
  
  METHOD setup.
    TRY.
        me->branch_info->get_class( )->set_class( cached_class_name ).
        cut ?= /s4tax/nfse_default=>get_instance( branch_info = me->branch_info documents = me->documents reporter = reporter ).
      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.

  METHOD get_reasons_cancellation.
    "Vazio
  ENDMETHOD.

  METHOD get_rps_identificacao.
    "Vazio
  ENDMETHOD.

  METHOD get_rps_identificacao_series.
    "Vazio
  ENDMETHOD.

ENDCLASS.
'''