CLASS /s4tax/nfse_mg3144805 DEFINITION
 PUBLIC
  INHERITING FROM /s4tax/nfse_default
  CREATE PUBLIC .

  PUBLIC SECTION.
    CONSTANTS: tax_address TYPE string VALUE 'MG 3144805'.

    METHODS:
      /s4tax/infse_data~get_reasons_cancellation REDEFINITION,
      get_rps_identificacao REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS /s4tax/nfse_mg3144805 IMPLEMENTATION.

  METHOD /s4tax/infse_data~get_reasons_cancellation.
    result-code = '2'.
    result-motivo = 'Serviço não prestado'.
  ENDMETHOD.

  METHOD get_rps_identificacao.
    result = super->get_rps_identificacao( ).

    IF result-serie IS INITIAL.
      result-serie = 'NF'.
    ENDIF.
  ENDMETHOD.

ENDCLASS.