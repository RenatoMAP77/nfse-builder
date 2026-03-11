CLASS /s4tax/nfse_pr4127700 DEFINITION
  PUBLIC
  INHERITING FROM /s4tax/nfse_default
  FINAL
  CREATE PUBLIC.
" Toledo/PR

  PUBLIC SECTION.
    CONSTANTS tax_address TYPE string VALUE 'PR 4127700'.
    METHODS:
      /s4tax/infse_data~get_reasons_cancellation REDEFINITION.

  PROTECTED SECTION.
   METHODS:
  get_iss REDEFINITION.


  PRIVATE SECTION.
ENDCLASS.



CLASS /s4tax/nfse_pr4127700 IMPLEMENTATION.


  METHOD /s4tax/infse_data~get_reasons_cancellation.
    result-motivo = 'Servico nao prestado'.
  ENDMETHOD.

   METHOD get_iss.
    result = super->get_iss( iss = iss ).
    result-exigibilidade_iss = '2'.
  ENDMETHOD.


ENDCLASS.