CLASS /s4tax/nfse_pr4124103 DEFINITION
  PUBLIC
  INHERITING FROM /s4tax/nfse_default
  FINAL
  CREATE PUBLIC.
" Santo Antonio da Platina/PR

  PUBLIC SECTION.
    CONSTANTS tax_address TYPE string VALUE 'PR 4124103'.
    METHODS:
      /s4tax/infse_data~get_reasons_cancellation REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS /s4tax/nfse_pr4124103 IMPLEMENTATION.

  METHOD /s4tax/infse_data~get_reasons_cancellation.
    result-motivo = 'Servico nao prestado'.
  ENDMETHOD.

ENDCLASS.