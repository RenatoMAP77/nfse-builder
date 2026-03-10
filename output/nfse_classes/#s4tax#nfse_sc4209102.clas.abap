CLASS /s4tax/nfse_sc4209102 DEFINITION
  PUBLIC
  INHERITING FROM /s4tax/nfse_default
  FINAL
  CREATE PUBLIC.
" Joinville/SC

  PUBLIC SECTION.
    CONSTANTS tax_address TYPE string VALUE 'SC 4209102'.
    METHODS:
      /s4tax/infse_data~get_reasons_cancellation REDEFINITION.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS /s4tax/nfse_sc4209102 IMPLEMENTATION.

  METHOD /s4tax/infse_data~get_reasons_cancellation.
    CASE reason_domain.
      WHEN 'C001'.
        result-motivo = 'Dados do tomador incorretos'.
      WHEN 'C002'.
        result-motivo = 'Erro na descricao do servico'.
      WHEN 'C003'.
        result-motivo = 'Erro no valor do servico'.
      WHEN 'C004'.
        result-motivo = 'Natureza da operacao ou codigo do item incorreto'.
      WHEN 'C005'.
        result-motivo = 'Informacoes de descontos ou tributos incorretos'.
      WHEN OTHERS.
        result-motivo = 'Outros'.
    ENDCASE.
  ENDMETHOD.

ENDCLASS.