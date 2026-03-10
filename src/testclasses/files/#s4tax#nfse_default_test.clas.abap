CLASS /s4tax/nfse_default_test DEFINITION
  PUBLIC
  ABSTRACT
  CREATE PUBLIC
  FOR TESTING
  DURATION SHORT
  RISK LEVEL HARMLESS .

  PUBLIC SECTION.

    CONSTANTS: interface_reporter       TYPE seoclsname VALUE '/S4TAX/IREPORTER',
               interface_danfe_maneger  TYPE seoclsname VALUE '/S4TAX/IF_DANFE_MANAGER',
               interface_api_document   TYPE seoclsname VALUE '/S4TAX/IAPI_DOCUMENT',
               interface_nfse_processor TYPE seoclsname VALUE '/S4TAX/INFSE_PROCESSOR',
               interface_document       TYPE seoclsname VALUE '/S4TAX/IDAO_DOCUMENT',
               interface_ref_trib       TYPE seoclsname VALUE '/s4tax/idao_ref_trib'.

    CLASS-DATA:mock_reporter       TYPE REF TO /s4tax/ireporter,
               mock_danfe_maneger  TYPE REF TO /s4tax/if_danfe_manager,
               mock_api_document   TYPE REF TO /s4tax/iapi_document,
               mock_nfse_processor TYPE REF TO /s4tax/infse_processor,
               mock_document       TYPE REF TO /s4tax/idao_document,
               mock_ref_trib       TYPE REF TO /s4tax/idao_ref_trib,
               settings            TYPE REF TO /s4tax/reporter_settings,
               reporter            TYPE REF TO /s4tax/ireporter,
               tax_type_accepted   TYPE /s4tax/nfse_tax_t.

    DATA:
      branch_info            TYPE REF TO /s4tax/nfse_branch_info,
      documents              TYPE REF TO /s4tax/nfse_documents,
      doc                    TYPE REF TO /s4tax/doc,
      active                 TYPE REF TO /s4tax/nfse_active,
      class                  TYPE REF TO /s4tax/nfse_class,
      item_1                 TYPE REF TO /s4tax/item,
      item_2                 TYPE REF TO /s4tax/item,
      branch                 TYPE REF TO /s4tax/branch,
      extension              TYPE REF TO /s4tax/nfse_ext,
      extension_item         TYPE REF TO /s4tax/nfse_extension_item,
      extension_head         TYPE REF TO /s4tax/nfse_extension_header,
      customer               TYPE REF TO /s4tax/customer,
      address_partner        TYPE REF TO /s4tax/address_partner,
      tax_address_cust_adr   TYPE REF TO /s4tax/tax_address,
      tax_address_branch     TYPE REF TO /s4tax/tax_address,
      tax_address_branch_adr TYPE REF TO /s4tax/tax_address,
      tax_address_text       TYPE REF TO /s4tax/tax_address_text,
      doc_message_1          TYPE REF TO /s4tax/doc_message,
      doc_message_2          TYPE REF TO /s4tax/doc_message,
      doc_message_3          TYPE REF TO /s4tax/doc_message,
      tax_iss                TYPE REF TO /s4tax/tax,
      tax_iss_2              TYPE REF TO /s4tax/tax,
      tax_pis                TYPE REF TO /s4tax/tax,
      tax_cofins             TYPE REF TO /s4tax/tax,
      tax_inss               TYPE REF TO /s4tax/tax,
      tax_ir                 TYPE REF TO /s4tax/tax,
      tax_csll               TYPE REF TO /s4tax/tax,
      tax_cbs                TYPE REF TO /s4tax/tax,
      tax_type_iss           TYPE REF TO /s4tax/tax_type,
      tax_type_iss_2         TYPE REF TO /s4tax/tax_type,
      tax_type_pis           TYPE REF TO /s4tax/tax_type,
      tax_type_cofins        TYPE REF TO /s4tax/tax_type,
      tax_type_inss          TYPE REF TO /s4tax/tax_type,
      tax_type_ir            TYPE REF TO /s4tax/tax_type,
      tax_type_csll          TYPE REF TO /s4tax/tax_type,
      tax_type_cbs           TYPE REF TO /s4tax/tax_type,
      branch_config          TYPE REF TO /s4tax/branch_config,
      invoice                TYPE REF TO /s4tax/invoice,
      doc_msg_ref1           TYPE REF TO /s4tax/doc_message_ref,
      doc_msg_ref2           TYPE REF TO /s4tax/doc_message_ref,
      customer_company       TYPE REF TO /s4tax/customer_company,
      payment_option         TYPE REF TO /s4tax/payment_option,
      payment_condition      TYPE REF TO /s4tax/payment_conditions,
      intermediario          TYPE /s4tax/s_nfse_intermediario,
      address1               TYPE addr1_val,
      go_badi_nfse           TYPE REF TO /s4tax/badi_nfse,
      tax_address_text_list  TYPE /s4tax/tax_address_text_t,
      tax_reform_custom_list TYPE /s4tax/tax_reform_t,
      tax_reform_custom      TYPE REF TO /s4tax/tax_reform,
      nfse_cfg               TYPE REF TO /s4tax/nfse_cfg,
      dao_ref_trib           TYPE REF TO /s4tax/dao_ref_trib.

  PROTECTED SECTION.

    METHODS:
      mock_all,
      mock_identificacao,
      mock_extension,
      mock_inss_extension,
      mock_tomador,
      mock_tomador_external,
      mock_tomador_address,
      mock_tomador_address_external,
      mock_servico,
      mock_second_item,
      mock_construc_civil,
      mock_pag,
      mock_intermediario,
      mock_nfse_ext,
      mock_nfse_tax_reform_standard,
      clear_doc,
      mount_header_input RETURNING VALUE(result) TYPE /s4tax/s_nfse_document_input,

      mount_rps_serv_base_expected RETURNING VALUE(result) TYPE /s4tax/s_nfse_servico,

      mount_rps_serv_ext_expected RETURNING VALUE(result) TYPE /s4tax/s_nfse_servico,

      mount_rps_serv_end_expected RETURNING VALUE(result) TYPE /s4tax/s_nfse_serv_endereco,

      mount_identificacao_expected RETURNING VALUE(result) TYPE /s4tax/s_nfse_identificacao,

      mount_tomador_base_expected RETURNING VALUE(result) TYPE /s4tax/s_nfse_tomador,

      mount_tomador_external_exp RETURNING VALUE(result) TYPE /s4tax/s_nfse_tomador,

      mount_tomador_end_expected RETURNING VALUE(result) TYPE /s4tax/s_nfse_tomador_endereco,

      mount_tom_end_external_exp RETURNING VALUE(result) TYPE /s4tax/s_nfse_tomador_endereco,

      mount_tomador_contato_expected RETURNING VALUE(result) TYPE /s4tax/s_nfse_tomador_contato,

      mount_construc_civilo_expected RETURNING VALUE(result) TYPE /s4tax/s_nfse_construcao_civil,

      mount_rate_decimals_expected IMPORTING servico       TYPE /s4tax/s_nfse_servico
                                   RETURNING VALUE(result) TYPE /s4tax/s_nfse_servico,

      mount_rps_pag_expected RETURNING VALUE(result) TYPE /s4tax/s_nfse_pag,

      get_instance_by_name IMPORTING class_name    TYPE seoclname
                           RETURNING VALUE(result) TYPE REF TO /s4tax/infse_data,
      mount_ibscbs_expected_nacional RETURNING VALUE(result) TYPE /s4tax/s_nfse_ibscbs,
      mock_nfse_tax_reform_custom,
      mock_tax_reform_custom_list,
      configuration_mock,
      clear_ind_final.
  PRIVATE SECTION.

    DATA email_address TYPE REF TO /s4tax/email_address .

    METHODS:
      setup.

    CLASS-METHODS:
      generate_tax_type_accepted RETURNING VALUE(result) TYPE /s4tax/nfse_tax_t.



    CLASS-METHODS:
      class_setup,
      class_teardown.
    CLASS-DATA:
      dbtables         TYPE REF TO if_osql_test_environment,
      test_tnfse_class TYPE STANDARD TABLE OF /s4tax/tnfseclas,
      t_ref_trib       TYPE STANDARD TABLE OF /s4tax/tref_trib.
ENDCLASS.


CLASS /s4tax/nfse_default_test IMPLEMENTATION.

  METHOD setup.

    CREATE OBJECT class.
    CREATE OBJECT tax_address_branch_adr.
    CREATE OBJECT branch_config.
    CREATE OBJECT branch.
    CREATE OBJECT nfse_cfg.



    branch->set_tax_address( tax_address_branch_adr ).
    branch->set_branch_config( branch_config ).

    CREATE OBJECT me->branch_info.
    me->branch_info->set_class( class ).
    me->branch_info->set_branch( branch ).
    me->branch_info->set_nfse_cfg( nfse_cfg ).

    CREATE OBJECT item_1.

    item_1->set_cst( '1' ).
    item_1->set_cclasstrib( '1' ).
    item_1->set_ccredprescbs( '1' ).
    item_1->set_pdifibsuf( '1' ).
    item_1->set_vdevtribibsuf( '1' ).
    item_1->set_pdifibsmun( '1' ).
    item_1->set_vdevtribibsmun( '1' ).
    item_1->set_pdifcbs( '1' ).
    item_1->set_vdevtribcbs( '1' ).

    CREATE OBJECT doc_message_1.
    CREATE OBJECT doc_message_2.
    CREATE OBJECT doc_message_3.

    CREATE OBJECT doc_msg_ref1.
    CREATE OBJECT doc_msg_ref2.

    CREATE OBJECT me->doc.

    me->doc->add_item( item_1 ).

    me->doc->add_doc_message( doc_message_1 ).
    me->doc->add_doc_message( doc_message_2 ).
    me->doc->add_doc_message( doc_message_3 ).
    me->doc->add_doc_msg_ref( doc_msg_ref1 ).
    me->doc->add_doc_msg_ref( doc_msg_ref2 ).

    CREATE OBJECT invoice.
    me->doc->set_invoice( invoice ).

    CREATE OBJECT extension_item.
    extension_item->set_matnr( '123456' ).
    CREATE OBJECT extension_head.
    extension_head->add_extension_item( extension_item ).
    branch_info->set_extension_header( extension_head ).
    extension_item->set_modo_prest_serv( '1' ).
    CREATE OBJECT extension EXPORTING reporter = me->reporter doc = me->doc branch_info = branch_info.

    CREATE OBJECT active.
    CREATE OBJECT documents EXPORTING doc = doc active = active.

    branch_info->set_tax_types( tax_type_accepted ).



  ENDMETHOD.


  METHOD mock_all.

    branch_config->set_branch_id( 'xxxxxxxx-xxxx-Mxxx-Nxxx-xxxxxxxxxxxx' ).
    me->mock_identificacao( ).
    me->mock_tomador(  ).
    me->mock_tomador_address(  ).
    me->mock_servico(  ).
    me->mock_construc_civil(  ).

  ENDMETHOD.


  METHOD mock_construc_civil.
    "result-matricula_cei = space.
    "result-numero_art  = space.
    "result-codigo_serie_art  = space.
    "result-data_emissao_art  = space.
  ENDMETHOD.


  METHOD mock_extension.
    extension_head->set_reg_espec_tribut( 'T' ).
    extension_head->set_optante_simples_nac( '3' ).
    extension_head->set_incent_cultural( '1' ).
    extension_head->set_nat_operacao( '2' ).
    extension_head->set_finalidade( '1' ).

    extension_item->set_modo_prest_serv( '1' ).

    extension_item->set_matnr( '123456' ).
    extension_item->set_cod_atividade( '01234567890123456789' ).
    extension_item->set_cod_servico( '01234567890123456789' ).
    extension_item->set_cod_trib_municipio( '01234567890123456789' ).
    extension_item->set_item_lista_serv( '14.01' ).
    extension_item->set_cnae( '888888' ).
    extension_item->set_tp_operacao( '1' ).
    extension_item->set_situacao( 'TP' ).
    extension_item->set_nbs( 'teste' ).

    me->mock_inss_extension(  ).

  ENDMETHOD.


  METHOD mock_identificacao.

    doc->set_series( '001' ).
    doc->set_credat( '20210303' ).
    doc->set_docdat( '20210203' ).
    doc->set_cretim( '020000' ).
    doc->set_docnum( '0123456789' ).
    doc->set_doctyp( '0' ).
    doc->set_inddest( '1' ).
    doc->set_ind_final( '1' ).


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
    "r_result-numero_lote = space.
    "r_result-serie_prestacao = space.
    "r_result-descricao = space.
  ENDMETHOD.


  METHOD mock_inss_extension.
    DATA: tax_definition_list TYPE /s4tax/nfse_tax_definition_t,
          tax_definition      TYPE REF TO /s4tax/nfse_tax_deifnition,
          condition_list      TYPE /s4tax/condition_t,
          condition           TYPE LINE OF /s4tax/condition_t.

    CREATE OBJECT tax_definition.
    tax_definition->set_imp_definition( '1' ). "Base
    tax_definition->set_kschl( 'XXX' ).
    APPEND tax_definition TO tax_definition_list.

    CREATE OBJECT tax_definition.
    tax_definition->set_imp_definition( '2' ). "Aliquota
    tax_definition->set_kschl( 'YYY' ).
    APPEND tax_definition TO tax_definition_list.

    CREATE OBJECT tax_definition.
    tax_definition->set_imp_definition( '3' ). "valor
    tax_definition->set_kschl( 'ZZZ' ).
    APPEND tax_definition TO tax_definition_list.

    CREATE OBJECT condition.
    condition->set_kschl( 'XXX' ). "Base
    condition->set_kawrt( '100.00' ).
    APPEND condition TO condition_list.

    CREATE OBJECT condition.
    condition->set_kschl( 'YYY' ). "Aliquota
    condition->set_kbetr( '2.00' ).
    APPEND condition TO condition_list.

    CREATE OBJECT condition.
    condition->set_kschl( 'ZZZ' ). "valor
    condition->set_kwert( '5.00' ).
    APPEND condition TO condition_list.

    me->extension->set_tax_def_list( tax_definition_list ).

    me->doc->get_invoice( )->set_condition_list( condition_list ).
  ENDMETHOD.


  METHOD mock_second_item.

    CREATE OBJECT item_2.
    me->doc->add_item( item_2 ).

    CREATE OBJECT: tax_iss_2, tax_type_iss_2.
    tax_iss_2->set_tax_type( tax_type_iss_2 ).

    item_2->add_tax( tax_iss_2 ).
    item_2->set_netwr( '100.10' ).
    item_2->set_menge( 1 ).
    item_2->set_netdis( '5.5' ).

    tax_iss_2->get_tax_type( )->set_taxtyp( /s4tax/nfse_constants=>tax_type-issf ).
    tax_iss_2->get_tax_type( )->set_taxgrp( /s4tax/nfse_constants=>tax_group-isss ).
    tax_iss_2->set_base( '100.00' ).
    tax_iss_2->set_rate( '1.00' ).
    tax_iss_2->set_taxval( '10.00' ).
    tax_iss_2->set_withhold( 'X' ).

  ENDMETHOD.


  METHOD mock_servico.

    CREATE OBJECT: tax_ir, tax_type_ir.
    CREATE OBJECT: tax_iss, tax_type_iss.
    CREATE OBJECT: tax_pis, tax_type_pis.
    CREATE OBJECT: tax_inss, tax_type_inss.
    CREATE OBJECT: tax_csll, tax_type_csll.
    CREATE OBJECT: tax_cofins, tax_type_cofins.
    CREATE OBJECT: tax_address_text.
    CREATE OBJECT: tax_cbs, tax_type_cbs.
    tax_ir->set_tax_type( tax_type_ir ).
    tax_iss->set_tax_type( tax_type_iss ).
    tax_pis->set_tax_type( tax_type_pis ).
    tax_inss->set_tax_type( tax_type_inss ).
    tax_csll->set_tax_type( tax_type_csll ).
    tax_cofins->set_tax_type( tax_type_cofins ).
    tax_cbs->set_tax_type( tax_type_cbs ).

    item_1->add_tax( tax_iss ).
    item_1->add_tax( tax_pis ).
    item_1->add_tax( tax_cofins ).
    item_1->add_tax( tax_inss ).
    item_1->add_tax( tax_ir ).
    item_1->add_tax( tax_csll ).
    item_1->add_tax( tax_cbs ).
*    branch->set_cnae( '1111111' ).
    address1-city2 = 'bairro'.
    address1-house_num1 = '123'.
    address1-post_code1 = '55555-333'.
    address1-street = 'Afonso Pena'.
    address1-region = 'MG'.

    branch->set_address1( address1 ).
    item_1->set_maktx( 'item_1' ).
    item_1->set_matnr( '123456' ).
    tax_address_branch_adr->set_taxjurcode( '3118601' ).
    tax_address_branch_adr->set_country( 'BR' ).
    tax_address_text->set_text( 'NOME_CIDADE' ).
    tax_address_text->set_country( 'BR' ).

    APPEND tax_address_text TO tax_address_text_list.
    tax_address_branch_adr->set_text_list( tax_address_text_list ).


    item_1->set_netwr( '100.10' ).
    item_1->set_menge( 1 ).
    item_1->set_maktx( 'discriminacao' ).
    item_1->set_meins( 'UN' ).

    tax_iss->get_tax_type( )->set_taxtyp( /s4tax/nfse_constants=>tax_type-issb ).
    tax_iss->get_tax_type( )->set_taxgrp( /s4tax/nfse_constants=>tax_group-isss ).
    tax_iss->set_base( '100.00' ).
    tax_iss->set_rate( '1.00' ).
    tax_iss->set_taxval( '10.00' ).
    tax_iss->set_withhold( 'X' ).
    tax_iss->set_servtype_out( '14.01' ).

    tax_pis->get_tax_type( )->set_taxtyp( /s4tax/nfse_constants=>tax_type-ipsw ).
    tax_pis->get_tax_type( )->set_taxgrp( /s4tax/nfse_constants=>tax_group-pis ).
    tax_pis->set_base( '100.00' ).
    tax_pis->set_rate( '1.00' ).
    tax_pis->set_taxval( '10.00' ).

    tax_cofins->get_tax_type( )->set_taxtyp( /s4tax/nfse_constants=>tax_type-icow ).
    tax_cofins->get_tax_type( )->set_taxgrp( /s4tax/nfse_constants=>tax_group-cofins ).
    tax_cofins->set_base( '100.00' ).
    tax_cofins->set_rate( '1.00' ).
    tax_cofins->set_taxval( '10.00' ).

    tax_inss->get_tax_type( )->set_taxtyp( /s4tax/nfse_constants=>tax_type-insw ).
    tax_inss->get_tax_type( )->set_taxgrp( /s4tax/nfse_constants=>tax_group-inss ).
    tax_inss->set_base( '100.00' ).
    tax_inss->set_rate( '1.00' ).
    tax_inss->set_taxval( '10.00' ).

    tax_ir->get_tax_type( )->set_taxtyp( /s4tax/nfse_constants=>tax_type-iirw ).
    tax_ir->get_tax_type( )->set_taxgrp( /s4tax/nfse_constants=>tax_group-ir ).
    tax_ir->set_base( '100.00' ).
    tax_ir->set_rate( '1.00' ).
    tax_ir->set_taxval( '10.00' ).

    tax_csll->get_tax_type( )->set_taxtyp( /s4tax/nfse_constants=>tax_type-icsw ).
    tax_csll->get_tax_type( )->set_taxgrp( /s4tax/nfse_constants=>tax_group-csll ).
    tax_csll->set_base( '100.00' ).
    tax_csll->set_rate( '1.00' ).
    tax_csll->set_taxval( '10.00' ).

    tax_cbs->get_tax_type( )->set_taxtyp( /s4tax/nfse_constants=>tax_type-cbs ).
    tax_cbs->get_tax_type( )->set_taxgrp( /s4tax/nfse_constants=>tax_group-pis ).
    tax_cbs->set_base( '100.00' ).
    tax_cbs->set_rate( '1.00' ).
    tax_cbs->set_taxval( '10.00' ).
    tax_cbs->set_withhold( 'X' ).
  ENDMETHOD.


  METHOD mock_tomador.
    CREATE OBJECT customer.
    me->doc->set_customer( customer ).

    customer->set_name1( 'NOME' ).
    customer->set_name2( 'NOME_FANTASIA' ).
    customer->set_stcd1( '01234567890123' ).
    customer->set_stcd2( '0123456789' ).
    customer->set_stcd3( '0123456789' ).
    customer->set_stcd4( '0123456789' ).


  ENDMETHOD.

  METHOD mock_tomador_external.

    CREATE OBJECT customer.
    me->doc->set_customer( customer ).

    customer->set_name1( 'NAME' ).
    customer->set_name2( 'FANTASY_NAME' ).


  ENDMETHOD.


  METHOD mock_tomador_address.
    DATA: country_code TYPE REF TO /s4tax/country_code,
          country_text TYPE REF TO /s4tax/country_text.

    CREATE OBJECT address_partner.
    CREATE OBJECT tax_address_cust_adr.
    CREATE OBJECT email_address.
    CREATE OBJECT country_code.
    CREATE OBJECT country_text.
    CREATE OBJECT tax_address_text.
    CREATE OBJECT tax_address_branch.


    address_partner->set_street( 'Rua aqui' ).
    address_partner->set_house_num1( '01' ).
    address_partner->set_house_num2( 'ali' ).
    address_partner->set_city2( 'Bairro' ).
    address_partner->set_country( 'BR' ).
    address_partner->set_region( 'MG' ).
    address_partner->set_post_code1( '36.570-000' ).
    address_partner->set_tel_number( '(31) -  9999 99999'  ).

    customer->set_tax_address( tax_address_cust_adr ).
    tax_address_cust_adr->set_taxjurcode( 'MG3118601' ).
    tax_address_text->set_text( 'NOME_CIDADE' ).

    APPEND tax_address_text TO tax_address_text_list.
    tax_address_cust_adr->set_text_list( tax_address_text_list ).

    customer->add_email_address( email_address ).
    email_address->set_smtp_addr( 'email@domain.com' ).
    customer->set_address_partner( address_partner ).

    country_code->set_cod_pais( '1058' ).
    address_partner->set_country_code( country_code ).

    country_text->set_land1( 'BR' ).
    country_text->set_landx( 'Brasil' ).
    address_partner->set_country_text( country_text ).
    tax_address_branch->set_country( 'BR' ).

  ENDMETHOD.


  METHOD mock_tomador_address_external.
    DATA: country_code TYPE REF TO /s4tax/country_code,
          country_text TYPE REF TO /s4tax/country_text.

    CREATE OBJECT address_partner.
    CREATE OBJECT country_code.
    CREATE OBJECT country_text.

    address_partner->set_house_num1( '01' ).
    address_partner->set_region( 'EX' ).

    customer->set_address_partner( address_partner ).

    country_code->set_cod_pais( '9999' ).
    address_partner->set_country_code( country_code ).

    country_text->set_land1( 'BR' ).
    country_text->set_landx( 'EXTERIOR' ).
    address_partner->set_country_text( country_text ).

  ENDMETHOD.

  METHOD mock_pag.
    CREATE OBJECT payment_condition.
    CREATE OBJECT payment_option.

    payment_condition->set_zterm( 'E050' ).
    payment_condition->set_zlsch( 'B' ).
    payment_condition->set_ztag1( '028' ).
    payment_condition->set_payment_option( payment_option ).

    me->doc->set_zterm( 'E050' ).
    me->doc->set_payment_condition( payment_condition ).

    payment_option->set_zlsch( 'B' ).
    payment_option->set_text1( 'Boleto empresa').

  ENDMETHOD.

  METHOD mock_intermediario.

    me->intermediario-cpf = '01234567899'.
  ENDMETHOD.

  METHOD mount_identificacao_expected.

    result-serie = '001'.
    result-data_emissao = '2021-03-03T02:00:00'.
    result-competencia = '2021-02-03T00:00:00'.
    result-numero = '0123456789'.
    result-tipo_rps = '1'.
    result-natureza_operacao = '1'.
    result-optante_simples_nacional = '1'.
    APPEND 'message_3' TO result-descricao.

  ENDMETHOD.


  METHOD mount_rps_serv_base_expected.

*    result-cnae = '1111111'.
    APPEND 'message_1' TO result-discriminacao.
    APPEND 'message_2' TO result-discriminacao.
    result-codigo_municipio_incidencia = '3118601'.
    result-item_lista_servico = '14.01'.

    result-valores-total_servicos = '100.10'.
    result-valor_unitario = '100.10'.
    result-quantidade = '1'.
    result-unidade = 'UN'.
    result-valores-valor_liquido = '30.10'.
    result-valores-iss-retido = /s4tax/constants=>proposition-true.
    result-valores-iss-exigibilidade_iss = '1'.
    result-valores-iss-valor_retido = '10.00'.
    result-valores-iss-valor = '0.00'.
    result-valores-iss-aliquota = '1.0000'.
    result-valores-iss-base_calculo = '100.00'.

    result-valores-pis-base_calculo = '100.00'.
    result-valores-pis-aliquota = '1.0000'.
    result-valores-pis-valor = '10.00'.

    result-valores-cofins-base_calculo = '100.00'.
    result-valores-cofins-aliquota = '1.0000'.
    result-valores-cofins-valor = '10.00'.

    result-valores-inss-base_calculo = '100.00'.
    result-valores-inss-aliquota = '1.0000'.
    result-valores-inss-valor = '10.00'.

    result-valores-ir-base_calculo = '100.00'.
    result-valores-ir-aliquota = '1.0000'.
    result-valores-ir-valor = '10.00'.

    result-valores-csll-base_calculo = '100.00'.
    result-valores-csll-aliquota = '1.0000'.
    result-valores-csll-valor = '10.00'.
    result-valores-total_servicos = '100.10'.
    result-valores-valor_total_tributos = '70.00'.

    result-valores-outras_retencoes = '0.00'.
    result-valores-total_deducoes = '0.00'.

  ENDMETHOD.


  METHOD mount_rps_serv_ext_expected.

    result = mount_rps_serv_base_expected( ).

    "extension
    result-codigo_tributacao_municipio = '01234567890123456789'.
    result-item_lista_servico = '14.01'.
    result-codigo_atividade = '01234567890123456789'.
    result-codigo_servico = '01234567890123456789'.
    result-cnae = '888888'.


    result-valores-inss-aliquota = '2.00'.
    result-valores-inss-valor = '5.00'.
    result-valores-valor_liquido = '35.10'.

  ENDMETHOD.


  METHOD mount_rps_serv_end_expected.

    result-bairro = 'bairro'.
    result-numero = '123'.
    result-cep = '55555-333'.
    result-logradouro = 'Afonso Pena'.
    result-uf = 'MG'.
    result-codigo_municipio = '3118601'.
    result-nome_municipio = 'NOME_CIDADE'.
    result-tipo_logradouro = 'Via'.

  ENDMETHOD.


  METHOD mount_tomador_base_expected.

    result-cnpj = '01234567890123'.
    result-razao_social = 'NOME NOME_FANTASIA'.
    result-nome_fantasia = result-razao_social.
    result-inscricao_estadual = '0123456789'.
    result-inscricao_municipal = '0123456789'.
    result-tipo = '3'.
    result-nif = ''.


  ENDMETHOD.

  METHOD mount_tomador_external_exp.

    result-cpf = '00000000000'.
    result-razao_social = 'NAME FANTASY_NAME'.
    result-nome_fantasia = result-razao_social.
    result-tipo = '5'.

  ENDMETHOD.


  METHOD mount_tomador_contato_expected.

    result-ddd = '31'.
    result-email = 'email@domain.com'.
    result-telefone = '999999999'.

  ENDMETHOD.


  METHOD mount_tomador_end_expected.

    result-tipo_logradouro = 'Rua'.
    result-logradouro = 'aqui'.
    result-numero = '01'.
    result-complemento = 'ali'.
    result-bairro = 'Bairro'.
    result-tp_bairro = 'Bairro'.
    result-codigo_pais = '1058'.
    result-nome_pais = 'Brasil'.
    result-uf = 'MG'.
    result-cep = '36570000'.
    result-codigo_municipio = '3118601'.
    result-nome_municipio = 'NOME_CIDADE'.
    result-sigla_pais = 'BR'.

  ENDMETHOD.

  METHOD mount_tom_end_external_exp.

    result-numero = '01'.
    result-tp_bairro = 'Bairro'.
    result-codigo_pais = '9999'.
    result-nome_pais = 'EXTERIOR'.
    result-uf = 'EX'.
    result-cep = '00000000'.
    result-codigo_municipio = '99999'.
    result-nome_municipio = 'EXTERIOR'.

  ENDMETHOD.


  METHOD mount_rate_decimals_expected.

    result = servico.

    result-valores-iss-aliquota = '0.0100'.
    result-valores-pis-aliquota = '0.0100'.
    result-valores-cofins-aliquota = '0.0100'.
    result-valores-inss-aliquota = '0.0100'.
    result-valores-ir-aliquota = '0.0100'.
    result-valores-csll-aliquota = '0.0100'.

  ENDMETHOD.


  METHOD mount_rps_pag_expected.
    result-det_pag = VALUE #( ( t_pag = '028 Boleto empresa' ) ).
  ENDMETHOD.


  METHOD mount_construc_civilo_expected.
    result-codigo_serie_art = '17'.
  ENDMETHOD.


  METHOD generate_tax_type_accepted.

    DATA: tax_type TYPE REF TO /s4tax/nfse_tax.

    CREATE OBJECT tax_type.
    tax_type->set_tax( /s4tax/nfse_constants=>tax_name-iss ).
    tax_type->set_taxgrp( /s4tax/nfse_constants=>tax_group-isss ).
    tax_type->set_taxtyp( /s4tax/nfse_constants=>tax_type-issb ).
    APPEND tax_type TO result.

    CREATE OBJECT tax_type.
    tax_type->set_tax( /s4tax/nfse_constants=>tax_name-iss ).
    tax_type->set_taxgrp( /s4tax/nfse_constants=>tax_group-isss ).
    tax_type->set_taxtyp( /s4tax/nfse_constants=>tax_type-issa ).
    APPEND tax_type TO result.

    CREATE OBJECT tax_type.
    tax_type->set_tax( /s4tax/nfse_constants=>tax_name-iss ).
    tax_type->set_taxgrp( /s4tax/nfse_constants=>tax_group-isss ).
    tax_type->set_taxtyp( /s4tax/nfse_constants=>tax_type-issf ).
    APPEND tax_type TO result.

    CREATE OBJECT tax_type.
    tax_type->set_tax( /s4tax/nfse_constants=>tax_name-iss ).
    tax_type->set_taxgrp( /s4tax/nfse_constants=>tax_group-issp ).
    tax_type->set_taxtyp( /s4tax/nfse_constants=>tax_type-issb ).
    APPEND tax_type TO result.

    CREATE OBJECT tax_type.
    tax_type->set_tax( /s4tax/nfse_constants=>tax_name-iss ).
    tax_type->set_taxgrp( /s4tax/nfse_constants=>tax_group-issp ).
    tax_type->set_taxtyp( /s4tax/nfse_constants=>tax_type-issa ).
    APPEND tax_type TO result.

    CREATE OBJECT tax_type.
    tax_type->set_tax( /s4tax/nfse_constants=>tax_name-iss ).
    tax_type->set_taxgrp( /s4tax/nfse_constants=>tax_group-issp ).
    tax_type->set_taxtyp( /s4tax/nfse_constants=>tax_type-issf ).
    APPEND tax_type TO result.

    CREATE OBJECT tax_type.
    tax_type->set_tax( /s4tax/nfse_constants=>tax_name-pis ).
    tax_type->set_taxgrp( /s4tax/nfse_constants=>tax_group-pis ).
    tax_type->set_taxtyp( /s4tax/nfse_constants=>tax_type-ipsw ).
    APPEND tax_type TO result.

    CREATE OBJECT tax_type.
    tax_type->set_tax( /s4tax/nfse_constants=>tax_name-cofins ).
    tax_type->set_taxgrp( /s4tax/nfse_constants=>tax_group-cofins ).
    tax_type->set_taxtyp( /s4tax/nfse_constants=>tax_type-icow ).
    APPEND tax_type TO result.

    CREATE OBJECT tax_type.
    tax_type->set_tax( /s4tax/nfse_constants=>tax_name-inss ).
    tax_type->set_taxgrp( /s4tax/nfse_constants=>tax_group-inss  ).
    tax_type->set_taxtyp( /s4tax/nfse_constants=>tax_type-insw ).
    APPEND tax_type TO result.

    CREATE OBJECT tax_type.
    tax_type->set_tax( /s4tax/nfse_constants=>tax_name-ir ).
    tax_type->set_taxgrp( /s4tax/nfse_constants=>tax_group-ir  ).
    tax_type->set_taxtyp( /s4tax/nfse_constants=>tax_type-iirw ).
    APPEND tax_type TO result.

    CREATE OBJECT tax_type.
    tax_type->set_tax( /s4tax/nfse_constants=>tax_name-csll ).
    tax_type->set_taxgrp(  /s4tax/nfse_constants=>tax_group-csll  ).
    tax_type->set_taxtyp( /s4tax/nfse_constants=>tax_type-icsw ).
    APPEND tax_type TO result.

    CREATE OBJECT tax_type.
    tax_type->set_tax( /s4tax/nfse_constants=>tax_name-cbs ).
    tax_type->set_taxgrp(  /s4tax/nfse_constants=>tax_group-pis  ).
    tax_type->set_taxtyp(  /s4tax/nfse_constants=>tax_type-cbs  ).
    APPEND tax_type TO result.


  ENDMETHOD.


  METHOD mount_header_input.
    result-branch_id = 'xxxxxxxx-xxxx-Mxxx-Nxxx-xxxxxxxxxxxx'.
    result-erp_id = '0123456789'.
    "result-numero_lote
    "result-_id
    "result-is_force_production_env
  ENDMETHOD.

  METHOD get_instance_by_name.
    DATA: cx_root TYPE REF TO cx_root,
          go_badi TYPE REF TO /s4tax/cl_badi_nfse.

    IF mock_reporter IS INITIAL.
      mock_reporter           ?= cl_abap_testdouble=>create( interface_reporter ).
      mock_danfe_maneger      ?= cl_abap_testdouble=>create( interface_danfe_maneger ).
      mock_api_document       ?= cl_abap_testdouble=>create( interface_api_document ).
      mock_document           ?= cl_abap_testdouble=>create( interface_document ).
      mock_nfse_processor           ?= cl_abap_testdouble=>create( interface_nfse_processor ).
      mock_ref_trib           ?= cl_abap_testdouble=>create( interface_ref_trib ).
    ENDIF.
    go_badi = NEW #( reporter = mock_reporter danfe_manager = mock_danfe_maneger nfse_processor = mock_nfse_processor dao_document = mock_document ).

    "GET BADI go_badi_nfse.

    TRY.
        me->branch_info->get_class( )->set_class( class_name ).
        result ?= /s4tax/nfse_default=>get_instance( branch_info = me->branch_info
                                                     documents   = me->documents
                                                     reporter    = reporter ).
      CATCH cx_root INTO cx_root.
    ENDTRY.
  ENDMETHOD.
  METHOD mount_ibscbs_expected_nacional.
    DATA: s_g_ded_red TYPE /s4tax/s_g_ded_red.
    result-c_ind_op = 'teste'.
    result-dest-caepf = ''.
    result-dest-cnpj = '01234567890123'.
    result-dest-cpf = ''.
    result-dest-c_nao_nif = ''.
    result-dest-email = 'email@domain.com'.
    result-dest-end-end_nac-cep = '36570000'.
    result-dest-end-end_nac-c_mun = '3118601'.
    result-dest-end-end_nac-c_uf = 'MG'.
    result-dest-end-nro = '01'.
    result-dest-end-x_bairro = 'Bairro'.
    result-dest-end-x_cpl = 'ali'.
    result-dest-end-x_lgr = 'aqui'.
    result-dest-fone = '999999999'.
    result-dest-nif = ''.
    result-dest-x_nome = 'NOME NOME_FANTASIA'.
    result-fin_nfse = '0'.
    result-ind_dest = '1'.
    result-ind_final = '1'.
    result-servicos-clocal_prest_serv = '3118601'.
    result-servicos-c_cib = ''.
    result-servicos-c_pais_prest_serv = ''.
    result-servicos-ind_compra_gov = ''.
    result-servicos-modo_prest_serv = '1'.
*    result-total-g_cbs-aliquota_credito_presumido = 'teste'.
*    result-total-g_cbs-valor_total = 'teste'.
*    result-total-g_cbs-valor_total_credito_presumido = 'teste'.
*    result-total-g_cbs-valor_total_devolucao_tributos = 'teste'.
*    result-total-g_cbs-valor_total_diferimento = 'teste'.
*    result-total-g_cbs-valo_tota_cred_pres_susp = 'teste'.
*    result-total-g_ibs-aliquota_credito_presumido = 'teste'.
*    result-total-g_ibs-g_ibsmun-valor_total = 'teste'.
*    result-total-g_ibs-g_ibsmun-valor_total_devolucao_tributos = 'teste'.
*    result-total-g_ibs-g_ibsmun-valor_total_diferimento = 'teste'.
*    result-total-g_ibs-g_ibsuf-valor_total = 'teste'.
*    result-total-g_ibs-g_ibsuf-valor_total_devolucao_tributos = 'teste'.
*    result-total-g_ibs-g_ibsuf-valor_total_diferimento = 'teste'.
*    result-total-g_ibs-valor_total = 'teste'.
*    result-total-g_ibs-valor_total_credito_presumido = 'teste'.
*    result-total-g_ibs-valo_tota_cred_pres_susp = 'teste'.
*    result-total-g_trib_compra_gov-p_aliq_cbs = 'teste'.
*    result-total-g_trib_compra_gov-p_aliq_ibsmun = 'teste'.
*    result-total-g_trib_compra_gov-p_aliq_ibsuf = 'teste'.
*    result-total-g_trib_compra_gov-v_trib_cbs = 'teste'.
*    result-total-g_trib_compra_gov-v_trib_ibsmun = 'teste'.
*    result-total-g_trib_compra_gov-v_trib_ibsuf = 'teste'.
*    result-total-tributacao_regular-cod_classif_tributaria_ibscbs = 'teste'.
*    result-total-tributacao_regular-cod_situacao_tributaria_ibscbs = 'teste'.
*    result-total-tributacao_regular-valor_aliquota_cbs = 'teste'.
*    result-total-tributacao_regular-valor_aliquota_ibsmun = 'teste'.
*    result-total-tributacao_regular-valor_aliquota_ibsuf = 'teste'.
*    result-total-tributacao_regular-valor_tributo_cbs = 'teste'.
*    result-total-tributacao_regular-valor_tributo_ibsmun = 'teste'.
*    result-total-tributacao_regular-valor_tributo_ibsuf = 'teste'.
*    result-total-valor_total = 'teste'.
    result-tp_ente_gov = ''.
    result-tp_oper = ''.
    result-valores-base_calculo = '0.00'.
    result-valores-cbs-aliquota = '0.0000'.
*    result-valores-cbs-aliquota_efetiva_red = 'teste'.
*    result-valores-cbs-percentual_aliquota_red = 'teste'.
    result-valores-cbs-percentual_diferimento = '1.0000'.
    result-valores-cbs-valor = '0.00'.
*    result-valores-cbs-valor_diferimento = 'teste'.
    result-valores-cbs-valor_tributo_devolvido = '1.00'.
*    s_g_ded_red-tp_ded_red_ibscbs = 'teste'.
*    s_g_ded_red-vlr_ded_red_ibscbs = 'teste'.
*    s_g_ded_red-x_tp_ded_red_ibscbs = 'teste'.
*    APPEND s_g_ded_red TO result-valores-g_ded_red.
*    result-valores-g_ree_rep_res = 'teste'.
    result-valores-ibs_mun-aliquota = '0.0000'.
*    result-valores-ibs_mun-aliquota_efetiva_red = 'teste'.
*    result-valores-ibs_mun-percentual_aliquota_red = 'teste'.
    result-valores-ibs_mun-percentual_diferimento = '1.0000'.
    result-valores-ibs_mun-valor = '0.00'.
*    result-valores-ibs_mun-valor_diferimento = 'teste'.
    result-valores-ibs_mun-valor_tributo_devolvido = '1.00'.
    result-valores-ibs_uf-aliquota = '0.0000'.
*    result-valores-ibs_uf-aliquota_efetiva_red = 'teste'.
*    result-valores-ibs_uf-percentual_aliquota_red = 'teste'.
    result-valores-ibs_uf-percentual_diferimento = '1.0000'.
    result-valores-ibs_uf-valor = '0.00'.
*    result-valores-ibs_uf-valor_diferimento = 'teste'.
    result-valores-ibs_uf-valor_tributo_devolvido = '1.00'.
    result-valores-trib-cst = '1'.
    result-valores-trib-c_class_trib = '1'.
    result-valores-trib-c_cred_pres = '1'.
*    result-valores-trib-g_dif-p_dif_cbs = 'teste'.
*    result-valores-trib-g_dif-p_dif_mun = 'teste'.
*    result-valores-trib-g_dif-p_dif_uf = 'teste'.
*    result-valores-trib-g_estorno_cred = 'teste'.
*    result-valores-trib-g_pag_antecipado = 'teste'.
*    result-valores-trib-g_trib_regular-cod_classif_tributaria_ibscbs = 'teste'.
**    result-valores-trib-g_trib_regular-cod_situacao_tributaria_ibscbs = 'teste'.
*    result-valores-trib-g_trib_regular-valor_aliquota_cbs = 'teste'.
*    result-valores-trib-g_trib_regular-valor_aliquota_ibsmun = 'teste'.
*    result-valores-trib-g_trib_regular-valor_aliquota_ibsuf = 'teste'.
*    result-valores-trib-g_trib_regular-valor_tributo_cbs = 'teste'.
*    result-valores-trib-g_trib_regular-valor_tributo_ibsmun = 'teste'.
*    result-valores-trib-g_trib_regular-valor_tributo_ibsuf = 'teste'.
  ENDMETHOD.


  METHOD mock_nfse_ext.
    DATA:
      nfse_ext    TYPE REF TO /s4tax/nfse_ext,
      branch_info TYPE REF TO /s4tax/nfse_branch_info.
    CREATE OBJECT branch_info.
    CREATE OBJECT nfse_ext EXPORTING branch_info = branch_info doc = doc.

  ENDMETHOD.

  METHOD clear_doc.
    CLEAR me->doc.
  ENDMETHOD.
  METHOD class_setup.
    CREATE OBJECT settings.
    settings->/s4tax/ireporter_settings~set_autosave( abap_false ).
    reporter = /s4tax/reporter_factory=>create( object    = /s4tax/reporter_factory=>object-s4tax
                                                subobject = /s4tax/reporter_factory=>subobject-nfse
                                                settings  = settings ).
    tax_type_accepted = generate_tax_type_accepted( ).

    dbtables = cl_osql_test_environment=>create( i_dependency_list = VALUE #( ( '/s4tax/tref_trib' )  ) ).
    t_ref_trib = VALUE #(
    ( model = '02' cfop = '1' ncm = '01' matnr = '01' )
    ).
    dbtables->insert_test_data( t_ref_trib ).
  ENDMETHOD.

  METHOD class_teardown.
    dbtables->destroy( ).
  ENDMETHOD.

  METHOD mock_nfse_tax_reform_standard.
    class->set_tax_reform( '1' ).
  ENDMETHOD.

  METHOD mock_nfse_tax_reform_custom.
    class->set_tax_reform( '3' ).
  ENDMETHOD.
  METHOD mock_tax_reform_custom_list.
    tax_reform_custom = NEW #( ).
    tax_reform_custom->set_model( '01' ).
    tax_reform_custom->set_cfop( '1' ).
    tax_reform_custom->set_ncm( '01' ).
    tax_reform_custom->set_matnr( '01' ).
    APPEND tax_reform_custom TO tax_reform_custom_list.
  ENDMETHOD.

  METHOD configuration_mock.
    DATA:
        items TYPE /s4tax/item_t.
    mock_ref_trib           ?= cl_abap_testdouble=>create( interface_ref_trib ).
    me->mock_tax_reform_custom_list( ).
    cl_abap_testdouble=>configure_call( mock_ref_trib )->returning( tax_reform_custom_list )->set_parameter( name = 'model' value = '01' ).
    mock_ref_trib->get_many_by_items( model = '01' items = items ).
  ENDMETHOD.

  METHOD clear_ind_final.
    CLEAR me->extension_item.
  ENDMETHOD.

ENDCLASS.