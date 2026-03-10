*&---------------------------------------------------------------------*
*& Include /s4tax/nfse_default_t99
*&---------------------------------------------------------------------*

CLASS lcl_nfse_default DEFINITION
INHERITING FROM /s4tax/nfse_default.

  PUBLIC SECTION.
    METHODS:
      get_numero_lote REDEFINITION.

  PROTECTED SECTION.
    METHODS:
      get_number_from_snro REDEFINITION,
      handle_dependencies REDEFINITION,
      get_tax_reform_custom_list REDEFINITION,
      call_badi REDEFINITION.
  PRIVATE SECTION.

ENDCLASS.

CLASS lcl_nfse_default IMPLEMENTATION.

  METHOD get_number_from_snro.
    DATA: suboject   TYPE /s4tax/tnfseclas-interval_num.

    suboject = me->nfse_class->get_interval_num( ).
    IF suboject IS  INITIAL.
      RETURN.
    ENDIF.

    result = '9999999999'.
  ENDMETHOD.

  METHOD get_numero_lote.
    DATA: suboject   TYPE /s4tax/tnfseclas-interval_num_lote.

    suboject = me->nfse_class->get_interval_num_lote( ).
    IF suboject IS  INITIAL.
      RETURN.
    ENDIF.

    result = '1'.
  ENDMETHOD.

  METHOD call_badi.

  ENDMETHOD.

  METHOD handle_dependencies.

  ENDMETHOD.

  METHOD get_tax_reform_custom_list.
    DATA(item_1) = NEW /s4tax/tax_reform( ).
    item_1->set_cfop( '1' ).
    item_1->set_model( '1' ).
    item_1->set_cclass( 'teste' ).
    item_1->set_cst( '1' ).
    APPEND item_1 TO result.
  ENDMETHOD.

ENDCLASS.

CLASS ltcl_nfse_default DEFINITION FINAL FOR TESTING
    INHERITING FROM /s4tax/nfse_default_test
  DURATION SHORT
  RISK LEVEL HARMLESS.

  PRIVATE SECTION.
    DATA:
      cut         TYPE REF TO lcl_nfse_default.

    METHODS:
      setup,
      get_instance FOR TESTING RAISING cx_static_check,
      mount_input_data_emit FOR TESTING RAISING cx_static_check,
      input_data_with_header_filled FOR TESTING RAISING cx_static_check,
      get_rps_identificacao FOR TESTING RAISING cx_static_check,
      get_rps_ident_ext FOR TESTING RAISING cx_static_check,
      get_rps_ident_dcompet FOR TESTING RAISING cx_static_check,
      get_rps_ident_number_exists FOR TESTING RAISING cx_static_check,
      get_rps_ident_snro_exception FOR TESTING RAISING cx_static_check,
      get_rps_ident_number_docnum FOR TESTING RAISING cx_static_check,
      get_rps_tomador FOR TESTING RAISING cx_static_check,
      get_rps_tomador_no_name2 FOR TESTING RAISING cx_static_check,
      get_rps_tomador_no_addr FOR TESTING RAISING cx_static_check,
      get_rps_tomador_not_bound FOR TESTING RAISING cx_static_check,
      get_rps_servico_one_item FOR TESTING RAISING cx_static_check,
      get_rps_servico_ctribnac FOR TESTING RAISING cx_static_check,
      get_rps_serv_many_itens FOR TESTING RAISING cx_static_check,
      get_rps_serv_iss_not_withheld FOR TESTING RAISING cx_static_check,
      get_rps_serv_extension FOR TESTING RAISING cx_static_check,
      get_rps_construc_civil FOR TESTING RAISING cx_static_check,
      get_tipo_tomador_5 FOR TESTING RAISING cx_static_check,
      get_tipo_tomador_3 FOR TESTING RAISING cx_static_check,
      get_tipo_tomador_4 FOR TESTING RAISING cx_static_check,
      get_tipo_tomador_1 FOR TESTING RAISING cx_static_check,
      get_rps_serv_discriminacao FOR TESTING RAISING cx_static_check,
      get_rps_pag FOR TESTING RAISING cx_static_check,
      get_rps_serv_endereco FOR TESTING RAISING cx_static_check,
      get_rps_source FOR TESTING RAISING cx_static_check,
      get_discriminacao_layout FOR TESTING RAISING cx_static_check,
      get_descricao_layout FOR TESTING RAISING cx_static_check,
      mount_input_data_emit_doc_init FOR TESTING RAISING cx_static_check,
      get_rps_ibscbs_standard FOR TESTING RAISING cx_static_check,
      get_rps_ibs_cbs_indfinal FOR TESTING RAISING cx_static_check,
      get_rps_ibscbs_custom FOR TESTING RAISING cx_static_check,
      get_rps_ibs_cbs_ind_final_doc FOR TESTING RAISING cx_static_check.
ENDCLASS.

CLASS ltcl_nfse_default IMPLEMENTATION.

  METHOD setup.
    DATA: cx_root           TYPE REF TO cx_root,
          reporter_settings TYPE REF TO /s4tax/ireporter_settings.

    reporter_settings = /s4tax/reporter_factory=>create_settings( ).
    reporter_settings->set_autosave( abap_false ).
    reporter = /s4tax/reporter_factory=>create( object    = /s4tax/reporter_factory=>object-s4tax
                                                subobject = /s4tax/reporter_factory=>subobject-task
                                                settings  = reporter_settings ).
    TRY.
        cut = NEW #( branch_info = me->branch_info documents = me->documents reporter = reporter extension = me->extension ).
      CATCH cx_root INTO cx_root.
    ENDTRY.

  ENDMETHOD.

  METHOD get_instance.
    DATA: lx_class TYPE REF TO cx_class_not_existent,
          lx_root  TYPE REF TO cx_root.

    TRY.
        me->branch_info->get_class( )->set_class( '/S4TAX/NFSE_MG3106200' ).
        DATA(nfse_exist) = /s4tax/nfse_default=>get_instance( branch_info = me->branch_info documents = me->documents reporter = reporter ).
        cl_abap_unit_assert=>assert_bound( act = nfse_exist ).

        me->branch_info->get_class( )->set_class( '/S4TAX/NFSE_DEFAULT' ) .
        DATA(nfse_default) = /s4tax/nfse_default=>get_instance( branch_info = me->branch_info documents = me->documents reporter = reporter ).
        cl_abap_unit_assert=>assert_bound( act = nfse_default ).

        me->branch_info->get_class( )->set_class( '/S4TAX/NFSE_NOT' ).
        DATA(nfse_not_exist) = /s4tax/nfse_default=>get_instance( branch_info = me->branch_info documents = me->documents reporter = reporter ).

      CATCH cx_class_not_existent INTO lx_class.
        cl_abap_unit_assert=>assert_not_bound( act = nfse_not_exist ).
      CATCH cx_root INTO lx_root.
        cl_abap_unit_assert=>assert_not_bound( act = nfse_not_exist ).
    ENDTRY.

  ENDMETHOD.

  METHOD mount_input_data_emit.
    DATA: data     TYPE /s4tax/s_nfse_document_input,
          expected TYPE /s4tax/s_nfse_document_input.

    me->mock_all( ).

    expected = mount_header_input(  ).
    expected-rps-identificacao = mount_identificacao_expected( ).
    expected-rps-tomador = mount_tomador_base_expected( ).
    expected-rps-tomador-endereco = mount_tomador_end_expected( ).
    expected-rps-tomador-contato = mount_tomador_contato_expected(  ).
    expected-rps-servico = mount_rps_serv_base_expected( ).

    data = cut->/s4tax/infse_data~mount_input_data_emit( ).
    cl_abap_unit_assert=>assert_equals( act = data exp = expected ).
  ENDMETHOD.

  METHOD input_data_with_header_filled.
    DATA: data     TYPE /s4tax/s_nfse_document_input,
          expected TYPE /s4tax/s_nfse_document_input.

    me->mock_all( ).

    "Com intervalo de numeração no get_number
    me->branch_info->get_class(  )->set_interval_num_lote( '000001' ).
    me->active->set_id( '111111111' ).
    me->active->set_forced_to_prd( 'X' ).

    expected-branch_id = 'xxxxxxxx-xxxx-Mxxx-Nxxx-xxxxxxxxxxxx'.
    expected-numero_lote = '1'.
    expected-_id = '111111111'.
    expected-erp_id = '0123456789'.
    expected-is_force_production_env = 'X'.

    data = cut->/s4tax/infse_data~mount_input_data_emit( ).
    cl_abap_unit_assert=>assert_equals( act = data-numero_lote exp = expected-numero_lote ).
    cl_abap_unit_assert=>assert_equals( act = data-branch_id exp = expected-branch_id ).
    cl_abap_unit_assert=>assert_equals( act = data-erp_id exp = expected-erp_id ).
    cl_abap_unit_assert=>assert_equals( act = data-is_force_production_env exp = expected-is_force_production_env ).
    cl_abap_unit_assert=>assert_equals( act = data-_id exp = expected-_id ).

  ENDMETHOD.

  METHOD get_rps_identificacao.
    DATA: identificacao TYPE /s4tax/s_nfse_identificacao,
          expected      TYPE /s4tax/s_nfse_identificacao.

    expected = mount_identificacao_expected( ).
    me->mock_identificacao( ).

    identificacao = cut->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( act = identificacao exp = expected ).

    "Com intervalo de numeração no get_number
    me->branch_info->get_class(  )->set_interval_num( '000001' ).
    identificacao = cut->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( act = identificacao-numero exp = '9999999999' ).

    "Com extension não optante pelo simples/ natureza da operação
    branch->set_crtn( '' ).
    me->mock_extension(  ).
    identificacao = cut->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( act = identificacao-optante_simples_nacional exp = '2' ).
    cl_abap_unit_assert=>assert_equals( act = identificacao-regime_especial_tributacao exp = 'T' ).
    cl_abap_unit_assert=>assert_equals( act = identificacao-natureza_operacao exp = '2' ).

  ENDMETHOD.

  METHOD get_rps_ident_ext.
    DATA: identificacao TYPE /s4tax/s_nfse_identificacao,
          expected      TYPE /s4tax/s_nfse_identificacao.

    expected = mount_identificacao_expected( ).
    expected-incentivador_cultural = '1'.
    expected-regime_especial_tributacao = 'T'.
    expected-tp_operacao = '1'.
    expected-optante_simples_nacional = '2'.
    expected-situacao = 'tp'.
    expected-natureza_operacao = '2'.
    me->mock_identificacao( ).
    me->mock_extension( ).

    identificacao = cut->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( act = identificacao exp = expected ).
  ENDMETHOD.

  METHOD get_rps_tomador.
    DATA: tomador  TYPE /s4tax/s_nfse_tomador,
          expected TYPE /s4tax/s_nfse_tomador.

    "geral
    expected = mount_tomador_base_expected( ).
    me->mock_servico( ).
    me->mock_tomador( ).

    "Com endereço
    expected-endereco = mount_tomador_end_expected( ).
    expected-contato = mount_tomador_contato_expected( ).

    me->mock_tomador_address( ).
    tomador = cut->get_rps_tomador( ).
    cl_abap_unit_assert=>assert_equals( act = tomador exp = expected ).

    "Sem número
    me->customer->get_address_partner( )->set_house_num1( '' ).
    tomador = cut->get_rps_tomador( ).
    cl_abap_unit_assert=>assert_equals( act = tomador-endereco-numero exp = 'S/N' ).

    "exterior
    me->customer->get_address_partner( )->set_country( 'CA' ).
    me->customer->get_address_partner( )->get_country_code(  )->set_cod_pais( '01111' ).
    me->customer->set_stcd1( '' ).
    tomador = cut->get_rps_tomador( ).
    cl_abap_unit_assert=>assert_equals( act = tomador-cpf exp = '' ).
    cl_abap_unit_assert=>assert_equals( act = tomador-endereco-cep exp = '00000000' ).
    cl_abap_unit_assert=>assert_equals( act = tomador-endereco-codigo_municipio exp = '99999' ).
    cl_abap_unit_assert=>assert_equals( act = tomador-endereco-uf exp = 'EX' ).

  ENDMETHOD.

  METHOD get_rps_tomador_not_bound.
    DATA: tomador      TYPE /s4tax/s_nfse_tomador.

    "customer not bound
    tomador = cut->get_rps_tomador( ).
    cl_abap_unit_assert=>assert_initial( act = tomador ).
  ENDMETHOD.

  METHOD get_rps_tomador_no_addr.

    DATA: tomador  TYPE /s4tax/s_nfse_tomador,
          expected TYPE /s4tax/s_nfse_tomador.

    "geral
    expected = mount_tomador_base_expected( ).
    expected-tipo = ''.

    "Sem endereço
    me->mock_tomador( ).
    tomador = cut->get_rps_tomador( ).
    cl_abap_unit_assert=>assert_equals( act = tomador exp = expected ).
  ENDMETHOD.

  METHOD get_rps_servico_one_item.
    DATA: servico  TYPE /s4tax/s_nfse_servico,
          expected TYPE /s4tax/s_nfse_servico.

    expected = mount_rps_serv_base_expected( ).
    me->mock_identificacao( ).
    me->mock_servico( ).

    servico = cut->get_rps_servico( ).
    DATA(bool) = cl_abap_unit_assert=>assert_equals( exp = expected act = servico ).

  ENDMETHOD.

  METHOD get_rps_serv_many_itens.

    DATA: servico  TYPE /s4tax/s_nfse_servico,
          expected TYPE /s4tax/s_nfse_servico.

    expected = mount_rps_serv_base_expected( ).

    expected-valores-total_servicos = '200.20'.
    expected-valor_unitario = '200.20'.
    expected-quantidade = '1'.
    expected-valores-valor_liquido = '120.20'.
    expected-valores-iss-valor_retido = '20.00'.
    expected-valores-iss-valor = '0.00'.
    expected-valores-iss-aliquota = '1.0000'.
    expected-valores-iss-base_calculo = '200.00'.
    expected-valores-outras_retencoes = '5.50'.

    expected-valores-valor_total_tributos = '80.00'.

    me->mock_identificacao( ).
    me->mock_servico( ).
    me->mock_second_item( ).

    servico = cut->get_rps_servico( ).
    cl_abap_unit_assert=>assert_equals( exp = expected act = servico ).
  ENDMETHOD.

  METHOD get_rps_serv_extension.
    DATA: servico  TYPE /s4tax/s_nfse_servico,
          expected TYPE /s4tax/s_nfse_servico.

    expected = mount_rps_serv_ext_expected( ).
    expected-valores-iss-exigibilidade_iss = '2'.
    expected-valores-inss-aliquota = '0.2000'.
    expected-valores-valor_total_tributos = '65.00'.
    expected-codigo_nbs = 'teste'.

    me->mock_identificacao( ).
    me->mock_servico( ).
    me->mock_extension( ).

    servico = cut->get_rps_servico( ).
    cl_abap_unit_assert=>assert_equals( exp = expected act = servico ).

  ENDMETHOD.

  METHOD get_rps_serv_iss_not_withheld.
    DATA: servico  TYPE /s4tax/s_nfse_servico,
          expected TYPE /s4tax/s_nfse_servico.

    expected = mount_rps_serv_base_expected( ).
    me->mock_identificacao( ).
    me->mock_servico( ).
    expected-valores-iss-retido = /s4tax/constants=>proposition-false.
    expected-valores-iss-valor = '10.00'.
    expected-valores-iss-valor_retido = '0.00'.
    expected-valores-valor_liquido = '40.10'.
    expected-valores-valor_total_tributos = '60.00'.

    me->item_1->get_tax_by_index( 1 )->set_withhold( '' ).
    me->item_1->get_tax_by_index( 1 )->set_taxtyp( /s4tax/nfse_constants=>tax_type-issa ).
    servico = cut->get_rps_servico( ).
    cl_abap_unit_assert=>assert_equals( exp = expected act = servico ).

  ENDMETHOD.

  METHOD get_rps_construc_civil.
    DATA: construcao_civil TYPE /s4tax/s_nfse_construcao_civil,
          expected         TYPE /s4tax/s_nfse_construcao_civil.


    me->mock_construc_civil(  ).
    construcao_civil = cut->get_rps_construc_civil( ).
    cl_abap_unit_assert=>assert_equals( exp = expected act = construcao_civil ).
  ENDMETHOD.

  METHOD get_tipo_tomador_5.
    DATA: tomador      TYPE /s4tax/s_nfse_tomador,
          expected     TYPE /s4tax/s_nfse_tomador,
          country_code TYPE REF TO /s4tax/country_code.
    CREATE OBJECT country_code.

    "geral
    expected = mount_tomador_base_expected( ).
    me->mock_tomador( ).

    "Com endereço
    expected-endereco = mount_tomador_end_expected( ).
    expected-contato = mount_tomador_contato_expected( ).

    me->mock_tomador_address( ).
    expected-tipo = '5'.
    expected-endereco-codigo_pais = '1055'.
    country_code->set_cod_pais( '1055' ).

    me->customer->get_address_partner( )->set_country_code( country_code ).
    tomador = cut->get_rps_tomador( ).
    cl_abap_unit_assert=>assert_equals( act = tomador-tipo exp = expected-tipo ).

  ENDMETHOD.

  METHOD get_tipo_tomador_3.
    DATA: tomador  TYPE /s4tax/s_nfse_tomador,
          expected TYPE /s4tax/s_nfse_tomador.

    me->tax_address_branch_adr->set_taxjurcode( 'MG3118601' ).
    "geral
    expected = mount_tomador_base_expected( ).
    me->mock_tomador( ).
    me->customer->set_stcd2( '' ).

    "Com endereço
    expected-endereco = mount_tomador_end_expected( ).
    expected-contato = mount_tomador_contato_expected( ).
    me->mock_tomador_address( ).
    expected-cpf = ''.
    expected-tipo = '3'.

    tomador = cut->get_rps_tomador( ).
    cl_abap_unit_assert=>assert_equals( act = tomador exp = expected ).
  ENDMETHOD.

  METHOD get_tipo_tomador_1.
    DATA: tomador  TYPE /s4tax/s_nfse_tomador,
          expected TYPE /s4tax/s_nfse_tomador.

    "geral
    expected = mount_tomador_base_expected( ).
    me->mock_tomador( ).
    me->customer->set_stcd1( '' ).
    me->customer->set_stcd2( '' ).

    "Com endereço
    expected-endereco = mount_tomador_end_expected( ).
    expected-contato = mount_tomador_contato_expected( ).
    me->mock_tomador_address( ).
    expected-cpf = ''.
    expected-cnpj = ''.
    expected-tipo = '1'.

    tomador = cut->get_rps_tomador( ).
    cl_abap_unit_assert=>assert_equals( act = tomador exp = expected ).
  ENDMETHOD.

  METHOD get_tipo_tomador_4.
    DATA: tomador  TYPE /s4tax/s_nfse_tomador,
          expected TYPE /s4tax/s_nfse_tomador.

    me->tax_address_branch_adr->set_taxjurcode( 'ES215641' ).
    "geral
    expected = mount_tomador_base_expected( ).
    me->mock_tomador( ).
    me->customer->set_stcd2( '' ).

    "Com endereço
    expected-endereco = mount_tomador_end_expected( ).
    expected-contato = mount_tomador_contato_expected( ).
    me->mock_tomador_address( ).
    expected-cpf = ''.
    expected-tipo = '4'.

    tomador = cut->get_rps_tomador( ).
    cl_abap_unit_assert=>assert_equals( act = tomador exp = expected ).
  ENDMETHOD.

  METHOD get_rps_ident_number_exists.
    DATA: identificacao TYPE /s4tax/s_nfse_identificacao,
          expected      TYPE /s4tax/s_nfse_identificacao.

    expected = mount_identificacao_expected( ).
    me->mock_identificacao( ).
    me->active->set_num_rps( '1111111111' ).

    "Com intervalo de numeração no get_number
    me->branch_info->get_class(  )->set_interval_num( '000001' ).
    identificacao = cut->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( act = identificacao-numero exp = '1111111111' ).

  ENDMETHOD.

  METHOD get_rps_ident_snro_exception.
    DATA: identificacao TYPE /s4tax/s_nfse_identificacao,
          expected      TYPE /s4tax/s_nfse_identificacao,
          cut_super     TYPE REF TO /s4tax/nfse_default.

    expected = mount_identificacao_expected( ).
    me->mock_identificacao( ).

    "Com intervalo de numeração no get_number
    me->branch_info->get_class(  )->set_interval_num( '000001' ).

    cut_super = NEW #( branch_info = me->branch_info documents = me->documents reporter = reporter extension = me->extension ).
    identificacao = cut_super->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( act = identificacao-numero exp = '' ).

  ENDMETHOD.

  METHOD get_rps_ident_number_docnum.
    DATA: identificacao TYPE /s4tax/s_nfse_identificacao,
          expected      TYPE /s4tax/s_nfse_identificacao.

    expected = mount_identificacao_expected( ).
    me->mock_identificacao( ).

    "Com intervalo de numeração no get_number
    identificacao = cut->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( act = identificacao-numero exp = '0123456789' ).
  ENDMETHOD.

  METHOD get_rps_serv_discriminacao.

    DATA: servico  TYPE /s4tax/s_nfse_servico,
          expected TYPE /s4tax/s_nfse_servico.

    expected = mount_rps_serv_base_expected( ).

    me->mock_identificacao( ).
    me->mock_servico( ).

    me->doc_message_1->set_docnum( '12345' ).
    me->doc_message_1->set_seqnum( '1' ).
    me->doc_message_2->set_docnum( '1111111' ).
    me->doc_message_2->set_seqnum( '2' ).

    me->doc_msg_ref1->set_docnum( '12345' ).
    me->doc_msg_ref1->set_seqnum( '1' ).
    me->doc_msg_ref2->set_docnum( '1111111' ).
    me->doc_msg_ref2->set_seqnum( '2' ).

    servico = cut->get_rps_servico( ).
    cl_abap_unit_assert=>assert_equals( exp = expected act = servico ).

  ENDMETHOD.

  METHOD get_rps_serv_endereco.
    DATA: servico  TYPE /s4tax/s_nfse_servico,
          expected TYPE /s4tax/s_nfse_servico.

    me->mock_identificacao( ).
    me->mock_servico( ).
    expected = mount_rps_serv_base_expected( ).

    servico = cut->get_rps_servico( ).
    cl_abap_unit_assert=>assert_equals( act = servico-endereco exp = expected-endereco ).

  ENDMETHOD.

  METHOD get_rps_pag.
    DATA: pag      TYPE /s4tax/s_nfse_pag,
          expected TYPE /s4tax/s_nfse_pag.

    expected = mount_rps_pag_expected(  ).
    me->mock_pag( ).

    pag = cut->get_rps_pag( ).
    cl_abap_unit_assert=>assert_equals( act = pag exp = expected ).
  ENDMETHOD.

  METHOD get_rps_tomador_no_name2.
    DATA: tomador  TYPE /s4tax/s_nfse_tomador,
          expected TYPE /s4tax/s_nfse_tomador.

    expected = mount_tomador_base_expected( ).
    expected-tipo = ''.
    expected-razao_social = 'NOME'.
    expected-nome_fantasia = expected-razao_social.

    me->mock_tomador( ).
    me->customer->set_name2( ' ' ).
    tomador = cut->get_rps_tomador( ).
    cl_abap_unit_assert=>assert_equals( act = tomador exp = expected ).

  ENDMETHOD.

  METHOD get_rps_source.
    DATA: identificacao TYPE /s4tax/s_nfse_identificacao,
          expected      TYPE /s4tax/s_nfse_identificacao,
          cut_super     TYPE REF TO /s4tax/nfse_default.

    expected = mount_identificacao_expected( ).
    me->mock_identificacao( ).

    me->branch_info->get_class(  )->set_rps_source( iv_rps_source = '2' ).

    cut_super = NEW #( branch_info = me->branch_info documents = me->documents reporter = reporter extension = me->extension ).
    identificacao = cut_super->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( act = identificacao-numero exp = '' ).
  ENDMETHOD.

  METHOD get_rps_ident_dcompet.

    DATA: identificacao TYPE /s4tax/s_nfse_identificacao,
          expected      TYPE /s4tax/s_nfse_identificacao.

    expected = mount_identificacao_expected( ).
    me->mock_identificacao( ).
    doc->set_dcompet( '20210203' ).

    identificacao = cut->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( act = identificacao exp = expected ).

  ENDMETHOD.

  METHOD get_discriminacao_layout.
    DATA: expected TYPE /s4tax/s_nfse_servico.

    me->branch_info->get_nfse_cfg( )->set_add_text_layout( '01' ).

    me->mock_identificacao( ).
    me->mock_servico( ).
    DATA(text) = 'message_1 message_2'.
    APPEND text TO expected-discriminacao.

    DATA(servico) = cut->get_rps_servico( ).
    cl_abap_unit_assert=>assert_equals( act = servico-discriminacao
                                        exp = expected-discriminacao ).

  ENDMETHOD.

  METHOD get_descricao_layout.
    DATA: expected TYPE /s4tax/s_nfse_identificacao.

    me->branch_info->get_nfse_cfg( )->set_add_text_layout( '01' ).

    me->mock_identificacao( ).
    me->mock_servico( ).
    DATA(text) = 'message_3'.
    APPEND text TO expected-descricao.

    DATA(identificacao) = cut->get_rps_identificacao( ).
    cl_abap_unit_assert=>assert_equals( act = identificacao-descricao
                                        exp = expected-descricao ).

  ENDMETHOD.

  METHOD mount_input_data_emit_doc_init.
    DATA:
        documents TYPE REF TO /s4tax/nfse_documents.
    CREATE OBJECT documents.
    CREATE OBJECT cut
      EXPORTING
        documents   = documents
        branch_info = branch_info.
    DATA(result) = cut->/s4tax/infse_data~mount_input_data_emit( ).
    cl_abap_unit_assert=>assert_initial( result ).
  ENDMETHOD.

  METHOD get_rps_ibscbs_standard.
    me->mock_all( ).
    me->mock_nfse_ext( ).
    me->mock_nfse_tax_reform_standard( ).
    DATA(expected) = me->mount_ibscbs_expected_nacional( ).

    DATA(result) = cut->get_rps_ibs_cbs( ).
    cl_abap_unit_assert=>assert_equals( act = result exp = expected ).
  ENDMETHOD.

  METHOD get_rps_ibs_cbs_indfinal.
    me->mock_tomador(  ).
    me->mock_tomador_address(  ).
    me->mock_servico(  ).
    doc->set_series( '001' ).
    doc->set_credat( '20210303' ).
    doc->set_docdat( '20210203' ).
    doc->set_cretim( '020000' ).
    doc->set_docnum( '0123456789' ).
    doc->set_doctyp( '0' ).
    doc->set_inddest( '1' ).
    item_1->set_docnum( me->doc->struct-docnum ).
    item_1->set_itmnum( '000001' ).
    item_1->set_taxsi3( '1' ).
    item_1->set_matnr( '123456' ).
    item_1->set_maktx( 'item_description' ).
    item_1->set_cindop( 'teste' ).
    branch->set_crtn( '1' ).

    doc_message_1->set_docnum( me->doc->struct-docnum ).
    doc_message_1->set_seqnum( '1' ).
    doc_message_1->set_message( 'message_1' ).

    doc_message_2->set_docnum( me->doc->struct-docnum ).
    doc_message_2->set_seqnum( '2' ).
    doc_message_2->set_message( 'message_2' ).

    doc_message_3->set_docnum( me->doc->struct-docnum ).
    doc_message_3->set_linnum( '1' ).
    doc_message_3->set_message( 'message_3' ).

    doc_msg_ref1->set_docnum( me->doc->struct-docnum ).
    doc_msg_ref1->set_itmnum( '000001' ).
    doc_msg_ref1->set_seqnum( '1' ).

    doc_msg_ref2->set_docnum( me->doc->struct-docnum ).
    doc_msg_ref2->set_itmnum( '000001' ).
    doc_msg_ref2->set_seqnum( '2' ).
    me->mock_construc_civil(  ).
    me->mock_nfse_tax_reform_standard( ).
    DATA(expected) = me->mount_ibscbs_expected_nacional( ).
    DATA(result) = cut->get_rps_ibs_cbs( ).
    cl_abap_unit_assert=>assert_equals( act = result exp = expected ).
  ENDMETHOD.

  METHOD get_rps_ibscbs_custom.
    item_1->set_cfop( '1' ).
    item_1->set_nbm( '01' ).
    item_1->set_matnr( '01' ).
    me->mock_tax_reform_custom_list( ).
    me->configuration_mock( ).
    me->mock_all( ).
    me->mock_nfse_ext( ).
    me->mock_nfse_tax_reform_custom( ).
    DATA(result) = cut->get_rps_ibs_cbs( ).
    cl_abap_unit_assert=>assert_equals( act = result-valores-trib-c_class_trib exp = 'teste' ).
    cl_abap_unit_assert=>assert_equals( act = result-valores-trib-cst exp = '1' ).

  ENDMETHOD.

  METHOD get_rps_ibs_cbs_ind_final_doc.
    me->mock_all( ).
    me->mock_nfse_ext( ).
    me->mock_nfse_tax_reform_standard( ).
    me->clear_ind_final( ).
    DATA(expected) = me->mount_ibscbs_expected_nacional( ).

    DATA(result) = cut->get_rps_ibs_cbs( ).
    cl_abap_unit_assert=>assert_equals( act = result exp = expected ).
  ENDMETHOD.

  METHOD get_rps_servico_ctribnac.
    DATA: servico  TYPE /s4tax/s_nfse_servico,
          expected TYPE /s4tax/s_nfse_servico.

    expected = mount_rps_serv_base_expected( ).
    expected-item_lista_servico = '123456'.

    me->mock_identificacao( ).
    me->mock_servico( ).
    me->item_1->set_ctribnac( '123456' ).

    servico = cut->get_rps_servico( ).
*    DATA(bool) = cl_abap_unit_assert=>assert_equals( exp = expected act = servico ).

  ENDMETHOD.

ENDCLASS.