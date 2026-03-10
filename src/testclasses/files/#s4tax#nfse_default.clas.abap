CLASS /s4tax/nfse_default DEFINITION
  PUBLIC
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES: /s4tax/infse_data.

    CLASS-DATA:
      nfse_default     TYPE seoclname VALUE '/S4TAX/NFSE_DEFAULT',
      nfse_snro_object TYPE nrobj VALUE '/S4TAX/RPS'.

    CLASS-METHODS:
      get_instance IMPORTING branch_info   TYPE REF TO /s4tax/nfse_branch_info
                             documents     TYPE REF TO /s4tax/nfse_documents
                             reporter      TYPE REF TO /s4tax/ireporter OPTIONAL
                             extension     TYPE REF TO /s4tax/infse_extension OPTIONAL
                   RETURNING VALUE(result) TYPE REF TO /s4tax/infse_data
                   RAISING   cx_class_not_existent.

    METHODS:
      constructor IMPORTING branch_info TYPE REF TO /s4tax/nfse_branch_info
                            documents   TYPE REF TO /s4tax/nfse_documents
                            reporter    TYPE REF TO /s4tax/ireporter OPTIONAL
                            extension   TYPE REF TO /s4tax/infse_extension OPTIONAL
                  RAISING   cx_class_not_existent,


      get_rps_identificacao RETURNING VALUE(result) TYPE /s4tax/s_nfse_identificacao,

      get_rps_tomador RETURNING VALUE(result) TYPE /s4tax/s_nfse_tomador,

      get_rps_servico RETURNING VALUE(result) TYPE /s4tax/s_nfse_servico,

      get_rps_construc_civil RETURNING VALUE(result) TYPE /s4tax/s_nfse_construcao_civil,

      get_customer_email RETURNING VALUE(result) TYPE string,

      get_rps_pag RETURNING VALUE(result) TYPE /s4tax/s_nfse_pag,

      get_rps_ibs_cbs RETURNING VALUE(result) TYPE /s4tax/s_nfse_ibscbs,

      get_numero_lote RETURNING VALUE(result) TYPE string
                      RAISING   /s4tax/cx_nfse.

  PROTECTED SECTION.
    DATA:
      data           TYPE /s4tax/s_nfse_document_input,
      nfse_class     TYPE REF TO /s4tax/nfse_class,
      string_utils   TYPE REF TO /s4tax/string_utils,
      currency_utils TYPE REF TO /s4tax/currency_utils,
      snro_utils     TYPE REF TO /s4tax/snro_utils,
      branch         TYPE REF TO /s4tax/branch,
      doc            TYPE REF TO /s4tax/doc,
      active         TYPE REF TO /s4tax/nfse_active,
      extension      TYPE REF TO /s4tax/infse_extension,
      reporter       TYPE REF TO /s4tax/ireporter,
      tax_types      TYPE /s4tax/nfse_tax_t,
      nfse_cfg       TYPE REF TO /s4tax/nfse_cfg,
      tax_added      TYPE /s4tax/s_nfse_taxes_sum.

    METHODS:


      get_natureza_operacao RETURNING VALUE(result) TYPE string,

      get_taxes RETURNING VALUE(result) TYPE /s4tax/s_nfse_taxes,

      get_taxes_from_stx RETURNING VALUE(result) TYPE /s4tax/s_nfse_taxes,

      process_email IMPORTING customer      TYPE REF TO /s4tax/customer
                    RETURNING VALUE(result) TYPE /s4tax/s_nfse_tomador_contato-email,

      get_codigo_atividade RETURNING VALUE(result) TYPE /s4tax/s_nfse_servico-codigo_atividade,

      get_codigo_servico RETURNING VALUE(result) TYPE /s4tax/s_nfse_servico-codigo_atividade,

      get_item_lista_servico RETURNING VALUE(result) TYPE /s4tax/s_nfse_servico-item_lista_servico,

      get_cod_trib_municipio RETURNING VALUE(result) TYPE /s4tax/s_nfse_servico-codigo_tributacao_municipio,

      get_number RETURNING VALUE(result) TYPE string,

      get_cod_munic_incidencia RETURNING VALUE(result) TYPE string,

      get_cod_pais_incidencia RETURNING VALUE(result) TYPE string,

      get_discriminacao RETURNING VALUE(result) TYPE /s4tax/string_t,

      get_reg_espec_tributacao RETURNING VALUE(result) TYPE string,

      get_opt_simples_nacional RETURNING VALUE(result) TYPE string,

      get_incent_cultural RETURNING VALUE(result) TYPE string,

      get_cnae RETURNING VALUE(result) TYPE /s4tax/s_nfse_servico-cnae,

      get_iss IMPORTING iss           TYPE /s4tax/s_tax_values
              RETURNING VALUE(result) TYPE /s4tax/s_nfse_serv_valores-iss,

      get_pis IMPORTING pis           TYPE /s4tax/s_tax_values
              RETURNING VALUE(result) TYPE /s4tax/s_nfse_serv_valores-pis,

      get_cofins IMPORTING cofins        TYPE /s4tax/s_tax_values
                 RETURNING VALUE(result) TYPE /s4tax/s_nfse_serv_valores-cofins,

      get_inss IMPORTING inss          TYPE /s4tax/s_tax_values
               RETURNING VALUE(result) TYPE /s4tax/s_nfse_serv_valores-inss,

      get_ir IMPORTING ir            TYPE /s4tax/s_tax_values
             RETURNING VALUE(result) TYPE /s4tax/s_nfse_serv_valores-ir,

      get_csll IMPORTING csll          TYPE /s4tax/s_tax_values
               RETURNING VALUE(result) TYPE /s4tax/s_nfse_serv_valores-csll,

      get_ibsm IMPORTING ibsm          TYPE /s4tax/s_tax_values
               RETURNING VALUE(result) TYPE /s4tax/s_nfse_gibs_mun,

      get_valor_liquido IMPORTING total_tax     TYPE j_1btaxval
                                  total_value   TYPE j_1bnfstx-taxval
                        RETURNING VALUE(result) TYPE /s4tax/s_nfse_serv_valores-valor_liquido,

      get_number_from_snro RETURNING VALUE(result) TYPE string
                           RAISING   /s4tax/cx_nfse,

      sum_nfse_tax_values IMPORTING tax_values    TYPE /s4tax/s_nfse_taxes
                          RETURNING VALUE(result) TYPE /s4tax/s_nfse_taxes_sum,

      get_tp_operacao RETURNING VALUE(result) TYPE string,

      get_descricao RETURNING VALUE(result) TYPE /s4tax/string_t,

      get_situacao RETURNING VALUE(result) TYPE string,

      set_zeros_insc_municip IMPORTING rps_tomador     TYPE /s4tax/s_nfse_tomador
                                       amount_of_zeros TYPE string
                             RETURNING VALUE(result)   TYPE /s4tax/s_nfse_tomador-inscricao_municipal,

      get_rate_in_decimals IMPORTING tax_values_sum TYPE /s4tax/s_nfse_taxes_sum
                           RETURNING VALUE(result)  TYPE /s4tax/s_nfse_taxes_sum,

      get_tomador_contact IMPORTING customer      TYPE REF TO /s4tax/customer
                          RETURNING VALUE(result) TYPE /s4tax/s_nfse_tomador_contato,

      reg_espec_trib_letter_to_numb IMPORTING trib          TYPE string
                                    RETURNING VALUE(result) TYPE string,

      get_tax_total IMPORTING sum           TYPE /s4tax/s_nfse_taxes_sum
                    RETURNING VALUE(result) TYPE j_1btaxval,

      get_unidade RETURNING VALUE(result) TYPE /s4tax/s_nfse_servico-unidade,
      call_badi,

      get_servico_endereco RETURNING VALUE(result) TYPE /s4tax/s_nfse_serv_endereco,

      get_serv_total_dedut RETURNING VALUE(result) TYPE numb,

      get_outras_retencoes RETURNING VALUE(result) TYPE /s4tax/s_nfse_serv_valores-outras_retencoes,

      handle_dependencies,

      get_nbs RETURNING VALUE(result) TYPE /s4tax/s_nfse_servico-codigo_nbs,

      get_ibscbs_total RETURNING VALUE(result) TYPE /s4tax/s_nfse_totcibs,

      ibs_cbs_from_std_tables CHANGING result TYPE /s4tax/s_nfse_ibscbs,

      ibs_cbs_from_custom CHANGING result  TYPE /s4tax/s_nfse_ibscbs,

      get_com_exterior RETURNING VALUE(result) TYPE /s4tax/s_nfse_serv_com_ext,
      get_tax_reform_custom_list RETURNING VALUE(result) TYPE /s4tax/tax_reform_t.

  PRIVATE SECTION.
    DATA:
      address_utils TYPE REF TO /s4tax/address_utils,
      go_badi_nfse  TYPE REF TO /s4tax/badi_nfse.

    METHODS:
      get_true_or_false IMPORTING value         TYPE clike
                        RETURNING VALUE(result) TYPE string,

      sum_taxes IMPORTING tax_table     TYPE /s4tax/tax_values_t
                RETURNING VALUE(result) TYPE /s4tax/s_tax_values,

      get_total_value RETURNING VALUE(result) TYPE j_1bnetval,

      get_tipo_tomador IMPORTING tomador       TYPE /s4tax/s_nfse_tomador
                       RETURNING VALUE(result) TYPE string,

      get_tomador_address IMPORTING customer      TYPE REF TO /s4tax/customer
                          RETURNING VALUE(result) TYPE /s4tax/s_nfse_tomador_endereco,

      get_tomador_cpf IMPORTING codigo_pais   TYPE string
                                customer      TYPE REF TO /s4tax/customer
                      RETURNING VALUE(result) TYPE stcd2,

      get_issqn IMPORTING iss           TYPE /s4tax/s_nfse_serv_val_iss
                RETURNING VALUE(result) TYPE /s4tax/s_nfse_serv_val_issqn,

      get_discriminacao_from_message IMPORTING doc           TYPE REF TO /s4tax/doc
                                     RETURNING VALUE(result) TYPE /s4tax/string_t,


      is_tax_type_accepted IMPORTING tax           TYPE REF TO /s4tax/tax
                           RETURNING VALUE(result) TYPE /s4tax/tnfse_tax-tax,

      get_tax_reform_item RETURNING VALUE(result) TYPE REF TO /s4tax/item,

      if_value IMPORTING input TYPE any RETURNING VALUE(result) TYPE string,

      get_rps_ibs_cbs_dest RETURNING VALUE(result) TYPE /s4tax/s_nfse_ibscbs_dest.


ENDCLASS.



CLASS /s4tax/nfse_default IMPLEMENTATION.


  METHOD /s4tax/infse_data~get_reasons_cancellation.

  ENDMETHOD.


  METHOD /s4tax/infse_data~mount_input_data_emit.

    DATA: branch_config TYPE REF TO /s4tax/branch_config,
          nfse_error    TYPE REF TO /s4tax/cx_nfse.

    IF doc IS NOT BOUND OR branch IS NOT BOUND.
      RETURN.
    ENDIF.

    branch_config = branch->get_branch_config( ).
    data-branch_id =  branch_config->get_branch_id( ).
    data-_id = me->active->get_id( ).
    data-erp_id = me->doc->get_docnum( ).
    data-is_force_production_env = me->active->get_forced_to_prd( ).

    "RPS - Identificação
    data-rps-identificacao = get_rps_identificacao( ).

    "RPS - Tomador
    data-rps-tomador = get_rps_tomador( ).

    "RPS - Serviço
    data-rps-servico = get_rps_servico( ).

    "RPS - Pag
    data-rps-pag = get_rps_pag( ).

    "RPS - Construção civil
    data-rps-construcao_civil = get_rps_construc_civil( ).

    IF me->nfse_class->struct-tax_reform IS NOT INITIAL.
      "RPS - IBSCBS
      data-rps-ibscbs = get_rps_ibs_cbs( ).

      "DESCONTINUADO - Apenas para consulta e posterior deleção - Douglas
      "data-inf_nfse_pn = get_inf_nfse_pn( ).
    ENDIF.


    TRY.
        data-numero_lote = get_numero_lote(  ).
      CATCH /s4tax/cx_nfse INTO nfse_error.
        reporter->error( nfse_error ).
    ENDTRY.

    handle_dependencies( ).

    result = data.
  ENDMETHOD.


  METHOD handle_dependencies.
    IF go_badi_nfse IS BOUND.
      CALL BADI go_badi_nfse->customize_json_emit
        EXPORTING
          active              = active
          doc                 = doc
          nfse_data           = me
        CHANGING
          nfse_document_input = data.
    ENDIF.
  ENDMETHOD.


  METHOD constructor.
    me->branch = branch_info->get_branch( ).
    me->nfse_class = branch_info->get_class( ).
    me->tax_types = branch_info->get_tax_types( ).
    me->doc = documents->get_doc( ).
    me->active = documents->get_active( ).
    me->nfse_cfg = branch_info->get_nfse_cfg( ).

    CREATE OBJECT string_utils.
    CREATE OBJECT currency_utils.
    CREATE OBJECT address_utils.
    CREATE OBJECT snro_utils.

    me->reporter = reporter.
    IF me->reporter IS NOT BOUND.
      me->reporter = /s4tax/reporter_factory=>create( object    = /s4tax/reporter_factory=>object-s4tax
                                                      subobject = /s4tax/reporter_factory=>subobject-nfse ).
      call_badi( ).
    ENDIF.

    me->extension = extension.
    IF me->extension IS NOT BOUND.
      me->extension = /s4tax/nfse_ext=>get_instance( reporter = me->reporter doc = me->doc branch_info = branch_info ).
    ENDIF.

  ENDMETHOD.


  METHOD get_cnae.
    IF me->extension IS BOUND.
      result = me->extension->get_cnae(  ).
    ENDIF.
  ENDMETHOD.


  METHOD get_codigo_atividade.

    IF extension IS NOT BOUND.
      RETURN.
    ENDIF.

    result = extension->get_cod_atividade( ).

  ENDMETHOD.


  METHOD get_codigo_servico.
    IF extension IS NOT BOUND.
      RETURN.
    ENDIF.

    result = extension->get_codigo_servico( ).
  ENDMETHOD.


  METHOD get_cod_munic_incidencia.
    DATA: tax_address TYPE REF TO /s4tax/tax_address,
          first_item  TYPE REF TO /s4tax/item,
          tax_list    TYPE /s4tax/tax_t,
          tax         TYPE LINE OF /s4tax/tax_t.

    first_item = doc->get_item_by_index( 1 ).
    tax_list = first_item->get_tax_by_taxgrp_pattern( 'ISS*' ).
    READ TABLE tax_list INTO tax INDEX 1.

    IF tax IS BOUND.
      result = tax->get_tax_loc( ).
    ENDIF.

    tax_address = me->branch->get_tax_address( ).
    IF result IS INITIAL AND tax_address IS BOUND.
      result = tax_address->struct-taxjurcode.
    ENDIF.

    result = string_utils->replace_characters( result ).

  ENDMETHOD.

  METHOD get_cod_pais_incidencia.
    DATA: tax_address TYPE REF TO /s4tax/tax_address,
          first_item  TYPE REF TO /s4tax/item,
          tax_list    TYPE /s4tax/tax_t,
          tax         TYPE LINE OF /s4tax/tax_t,
          customer    TYPE REF TO /s4tax/customer.

    first_item = doc->get_item_by_index( 1 ).
    tax_list   = first_item->get_tax_by_taxgrp_pattern( 'ISS*' ).
    READ TABLE tax_list INTO tax INDEX 1.

    tax_address = me->branch->get_tax_address( ).
    IF tax_address IS BOUND.
      result = tax_address->struct-country.
    ENDIF.

    IF result IS INITIAL AND doc IS BOUND.
      customer = doc->get_customer( ).
      IF customer IS BOUND.
        tax_address = customer->get_tax_address( ).
      ENDIF.
      IF tax_address IS BOUND.
        result = tax_address->struct-country.
      ENDIF.
    ENDIF.

    IF result IS INITIAL. "Fallback para BR (padrão NFSe Brasil)
      result = 'BR'.
    ENDIF.

    result = string_utils->replace_characters( result ).
  ENDMETHOD.

  METHOD get_cod_trib_municipio.
    IF extension IS NOT BOUND.
      RETURN.
    ENDIF.

    result = extension->get_cod_trib_municipio( ).
  ENDMETHOD.


  METHOD get_cofins.

    result-valor = '0.00'.
    result-valor_retido = '0.00'.
    result-base_calculo = currency_utils->to_string( cofins-base ).
    result-aliquota = currency_utils->to_string( cofins-rate ).
    result-retido =  me->get_true_or_false( cofins-withhold ).

    IF cofins-withhold = abap_true.
      result-valor_retido = currency_utils->to_string( cofins-taxval ).
    ELSE.
      result-valor = currency_utils->to_string( cofins-taxval ).
    ENDIF.
  ENDMETHOD.


  METHOD get_csll.

    result-valor = '0.00'.
    result-valor_retido = '0.00'.

    result-base_calculo = currency_utils->to_string( csll-base ).
    result-aliquota = currency_utils->to_string( csll-rate ).

    IF csll-withhold = abap_true.
      result-valor_retido = currency_utils->to_string( csll-taxval ).
    ELSE.
      result-valor = currency_utils->to_string( csll-taxval ).
    ENDIF.

  ENDMETHOD.

  METHOD get_ibsm.



  ENDMETHOD.

  METHOD get_customer_email.

    result = data-rps-tomador-contato-email.

  ENDMETHOD.


  METHOD get_descricao.
    DATA: doc_messages     TYPE /s4tax/doc_message_t,
          doc_msg          TYPE LINE OF /s4tax/doc_message_t,
          doc_msg_ref_list TYPE /s4tax/doc_message_ref_t,
          doc_msg_ref      TYPE LINE OF /s4tax/doc_message_ref_t,
          text             TYPE string,
          text_line        TYPE string,
          text_layout      TYPE string.

    doc_messages = me->doc->get_doc_message_list(  ).
    IF doc_messages IS INITIAL.
      RETURN.
    ENDIF.

    SORT doc_messages BY table_line->struct-docnum table_line->struct-seqnum table_line->struct-linnum.
    doc_msg_ref_list = me->doc->get_doc_msg_ref_list(  ).

    SORT doc_msg_ref_list BY table_line->struct-docnum table_line->struct-itmnum table_line->struct-seqnum.

    text_layout = me->nfse_cfg->get_add_text_layout( ).
    LOOP AT doc_messages INTO doc_msg.
      READ TABLE doc_msg_ref_list INTO doc_msg_ref WITH KEY table_line->struct-docnum = doc_msg->struct-docnum
                                                            table_line->struct-seqnum = doc_msg->struct-seqnum.
      IF sy-subrc EQ 0.
        CONTINUE.
      ENDIF.

      text_line = string_utils->trim( doc_msg->struct-message ).

      IF text_layout IS INITIAL.
        APPEND text_line TO result.
        CONTINUE.
      ENDIF.

      CONCATENATE text text_line INTO text SEPARATED BY space.
    ENDLOOP.

    IF text IS INITIAL.
      RETURN.
    ENDIF.

    text = string_utils->shift_left_deleting( input = text char_delete = ' ' ).
    APPEND text TO result.

  ENDMETHOD.


  METHOD get_discriminacao.
    DATA: item             TYPE REF TO /s4tax/item,
          doc_msg_ref_list TYPE /s4tax/doc_message_ref_t,
          maktx            TYPE string,
          discriminacao    TYPE /s4tax/string_t.

    doc_msg_ref_list = doc->get_doc_msg_ref_list(  ).

    IF doc_msg_ref_list IS INITIAL.
      item = doc->get_item_by_index( 1 ).
      maktx = item->get_maktx( ).
      APPEND maktx TO discriminacao.
    ELSE.
      discriminacao = get_discriminacao_from_message( doc = doc ).
    ENDIF.

    APPEND LINES OF discriminacao TO result.

  ENDMETHOD.


  METHOD get_discriminacao_from_message.

    DATA: doc_messages     TYPE /s4tax/doc_message_t,
          doc_msg          TYPE LINE OF /s4tax/doc_message_t,
          doc_msg_ref_list TYPE /s4tax/doc_message_ref_t,
          text_line        TYPE string,
          doc_msg_ref      TYPE LINE OF /s4tax/doc_message_ref_t,
          text_layout      TYPE string,
          text             TYPE string.

    doc_messages = doc->get_doc_message_list(  ).
    doc_msg_ref_list = doc->get_doc_msg_ref_list(  ).

    SORT doc_msg_ref_list BY table_line->struct-docnum table_line->struct-itmnum table_line->struct-seqnum.

    SORT doc_messages BY table_line->struct-docnum table_line->struct-seqnum table_line->struct-linnum.

    text_layout = me->nfse_cfg->get_add_text_layout( ).

    LOOP AT doc_messages INTO doc_msg.
      READ TABLE doc_msg_ref_list INTO doc_msg_ref WITH KEY table_line->struct-docnum = doc_msg->struct-docnum
                                                            table_line->struct-seqnum = doc_msg->struct-seqnum.
      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.
      text_line = string_utils->trim( doc_msg->struct-message ).

      IF text_layout IS INITIAL.
        APPEND text_line TO result.
        CONTINUE.
      ENDIF.

      CONCATENATE text text_line INTO text SEPARATED BY space.
    ENDLOOP.

    IF text IS INITIAL.
      RETURN.
    ENDIF.

    text = string_utils->shift_left_deleting( input = text char_delete = ' ' ).
    APPEND text TO result.

  ENDMETHOD.


  METHOD get_incent_cultural.
    IF me->extension IS NOT BOUND.
      RETURN.
    ENDIF.

    result = me->extension->get_incent_cultural(  ).
  ENDMETHOD.


  METHOD get_inss.
    result-base_calculo = currency_utils->to_string( inss-base ).
    result-aliquota = currency_utils->to_string( inss-rate ).
    result-valor = currency_utils->to_string( inss-taxval ).
  ENDMETHOD.


  METHOD get_instance.
    DATA: class_name TYPE /s4tax/tnfseclas-class,
          class      TYPE REF TO /s4tax/nfse_class.

    class = branch_info->get_class( ).
    class_name = class->get_class( ).
    CREATE OBJECT result TYPE (class_name)
        EXPORTING documents = documents branch_info = branch_info reporter = reporter extension = extension.

  ENDMETHOD.


  METHOD get_ir.
    result-base_calculo = currency_utils->to_string( ir-base ).
    result-aliquota = currency_utils->to_string( ir-rate ).
    result-valor = currency_utils->to_string( ir-taxval ).
  ENDMETHOD.


  METHOD get_iss.

    result-valor = '0.00'.
    result-valor_retido = '0.00'.

    result-base_calculo = currency_utils->to_string( iss-base ).
    result-aliquota = currency_utils->to_string( iss-rate ).
    result-retido =  me->get_true_or_false( iss-withhold ).
    result-exigibilidade_iss = get_natureza_operacao( ).

    IF iss-withhold = abap_true.
      result-valor_retido = currency_utils->to_string( iss-taxval ).
    ELSE.
      result-valor = currency_utils->to_string( iss-taxval ).
    ENDIF.

  ENDMETHOD.


  METHOD get_issqn.

    result-valor = iss-valor_retido.
    IF result-valor <> '0.00'.
      RETURN.
    ENDIF.

    result-valor = iss-valor.
  ENDMETHOD.


  METHOD get_item_lista_servico.
    DATA: first_item TYPE REF TO /s4tax/item,
          tax_list   TYPE /s4tax/tax_t,
          tax        TYPE LINE OF /s4tax/tax_t.

    result = extension->get_item_lista_servico( ).

    IF result IS NOT INITIAL.
      RETURN.
    ENDIF.

    first_item = doc->get_item_by_index( 1 ).

    result = first_item->struct-ctribnac.

    IF result IS NOT INITIAL.
      RETURN.
    ENDIF.

    tax_list = first_item->get_tax_by_taxgrp_pattern( 'ISS*' ).
    READ TABLE tax_list INTO tax INDEX 1.

    IF tax IS BOUND.
      result = tax->get_servtype_out(  ).
    ENDIF.

  ENDMETHOD.


  METHOD get_natureza_operacao.
    DATA: first_item TYPE REF TO /s4tax/item.

    IF me->extension IS BOUND.
      result = me->extension->get_natureza_operacao(  ).
    ENDIF.

    IF result IS NOT INITIAL.
      RETURN.
    ENDIF.

    CLEAR result.
    first_item = doc->get_item_by_index( 1 ).
    result = first_item->get_taxsi3( ).
    SHIFT result LEFT DELETING LEADING '0'.

  ENDMETHOD.


  METHOD get_number.
    DATA: nfse_error     TYPE REF TO /s4tax/cx_nfse,
          rps_validation TYPE /s4tax/tnfseclas-rps_source,
          rps_value      TYPE string.

    rps_validation = me->nfse_class->get_rps_source( ).
    rps_value = /s4tax/nfse_constants=>rps_source-api.

    IF rps_validation = rps_value.
      RETURN.
    ENDIF.

    IF me->active->struct-num_rps IS NOT INITIAL.
      result = me->active->struct-num_rps.
      RETURN.
    ENDIF.

    TRY.
        result = me->get_number_from_snro(  ).
      CATCH /s4tax/cx_nfse INTO nfse_error.
        reporter->error( nfse_error ).
        RETURN.
    ENDTRY.

    IF result IS NOT INITIAL.
      RETURN.
    ENDIF.

    result = me->doc->struct-docnum.

  ENDMETHOD.


  METHOD get_number_from_snro.
    DATA: suboject TYPE /s4tax/tnfseclas-interval_num,
          msg      TYPE string.

    suboject = me->nfse_class->get_interval_num( ).
    IF suboject IS  INITIAL.
      RETURN.
    ENDIF.

    snro_utils->number_get_next( EXPORTING nr_range_nr = '01'
                                           object      = nfse_snro_object
                                           subobject   = suboject
                                 IMPORTING number      = result ).

    IF result IS INITIAL.
      RAISE EXCEPTION TYPE /s4tax/cx_nfse EXPORTING textid = /s4tax/cx_nfse=>snro_not_found msg_v1 = msg.
    ENDIF.

  ENDMETHOD.


  METHOD get_numero_lote.

    DATA: suboject TYPE /s4tax/tnfseclas-interval_num,
          msg      TYPE string.

    suboject = me->nfse_class->get_interval_num_lote( ).
    IF suboject IS  INITIAL.
      RETURN.
    ENDIF.

    snro_utils->number_get_next( EXPORTING nr_range_nr = '01'
                                           object      = nfse_snro_object
                                           subobject   = suboject
                                 IMPORTING number      = result ).

    IF result IS INITIAL.
      RAISE EXCEPTION TYPE /s4tax/cx_nfse EXPORTING textid = /s4tax/cx_nfse=>snro_not_found msg_v1 = msg.
    ENDIF.

  ENDMETHOD.


  METHOD get_opt_simples_nacional.
    DATA: crt_number TYPE char1.

    crt_number = me->extension->get_opt_simples_nacional(  ).

    IF crt_number IS INITIAL.
      crt_number = me->branch->get_crtn( ).
    ENDIF.

    CASE crt_number.
      WHEN /s4tax/nfse_constants=>opt_simples-simples_nacional OR /s4tax/nfse_constants=>opt_simples-simples_nacional_inf.
        result = /s4tax/nfse_constants=>confirm-yes.

      WHEN OTHERS.
        result = /s4tax/nfse_constants=>confirm-no.
    ENDCASE.

  ENDMETHOD.


  METHOD get_pis.

    result-valor = '0.00'.
    result-valor_retido = '0.00'.

    result-base_calculo = currency_utils->to_string( pis-base ).
    result-aliquota = currency_utils->to_string( pis-rate ).
    result-retido =  me->get_true_or_false( pis-withhold ).

    IF pis-withhold = abap_true.
      result-valor_retido = currency_utils->to_string( pis-taxval ).
    ELSE.
      result-valor = currency_utils->to_string( pis-taxval ).
    ENDIF.

  ENDMETHOD.


  METHOD get_rate_in_decimals.

    result = tax_values_sum.

    result-iss-rate = tax_values_sum-iss-rate / 100.
    result-pis-rate = tax_values_sum-pis-rate / 100 .
    result-cofins-rate = tax_values_sum-cofins-rate / 100.
    result-csll-rate = tax_values_sum-csll-rate / 100.
    result-inss-rate = tax_values_sum-inss-rate / 100.
    result-ir-rate = tax_values_sum-ir-rate / 100.

  ENDMETHOD.


  METHOD get_reg_espec_tributacao.

    IF me->extension IS NOT BOUND.
      RETURN.
    ENDIF.

    result = me->extension->get_reg_espec_tribut(  ).
  ENDMETHOD.


  METHOD get_rps_construc_civil.

  ENDMETHOD.


  METHOD get_rps_identificacao.

    DATA: date      TYPE REF TO /s4tax/date,
          date_time TYPE string.

    FIELD-SYMBOLS: <fs_j_1bnfdoc> TYPE j_1bnfdoc,
                   <fs_field>     TYPE any.

    result-serie =  doc->struct-series.

    CREATE OBJECT date EXPORTING date = doc->struct-credat time = doc->struct-cretim.

    IF date IS BOUND.
      date_time = date->to_utc_format( ).
      result-data_emissao = date_time(19).
    ENDIF.

    ASSIGN doc->struct  TO <fs_j_1bnfdoc>.
    ASSIGN COMPONENT 'DCOMPET' OF STRUCTURE <fs_j_1bnfdoc> TO <fs_field>.
    IF  <fs_field> IS ASSIGNED AND  <fs_field> IS NOT INITIAL.
      CREATE OBJECT date EXPORTING date = <fs_field>.
    ELSE.
      CREATE OBJECT date EXPORTING date = doc->struct-docdat.
    ENDIF.

    IF date IS BOUND.
      date_time = date->to_utc_format( ).
      result-competencia = date_time(19).
    ENDIF.

    result-numero = get_number( ).
    result-tipo_rps = /s4tax/infse_data=>nfse_type-rps.
    result-natureza_operacao = me->get_natureza_operacao( ).
    result-regime_especial_tributacao = me->get_reg_espec_tributacao( ).
    result-optante_simples_nacional = me->get_opt_simples_nacional(  ).
    result-incentivador_cultural  = me->get_incent_cultural( ).
    result-tp_operacao = me->get_tp_operacao( ).
    result-descricao = me->get_descricao(  ).
    result-situacao = me->get_situacao( ).

  ENDMETHOD.


  METHOD get_rps_pag.

    DATA: det_pag           TYPE /s4tax/s_nfse_pag_det_pag,
          payment_option    TYPE REF TO /s4tax/payment_option,
          payment_condition TYPE REF TO /s4tax/payment_conditions.


    payment_condition = doc->get_payment_condition( ).

    IF payment_condition IS NOT BOUND.
      RETURN.
    ENDIF.

    payment_option = payment_condition->get_payment_option(  ).

    IF payment_option IS NOT BOUND.
      RETURN.
    ENDIF.

    det_pag-t_pag = string_utils->concatenate( msg1 = payment_condition->struct-ztag1 msg2 = payment_option->struct-text1 ).

    APPEND det_pag TO result-det_pag.

  ENDMETHOD.


  METHOD get_rps_servico.
    DATA:
      total_value      TYPE j_1bnetval,
      total_deductions TYPE j_1bnetval,
      total_taxes      TYPE j_1bnetval,
      taxes            TYPE /s4tax/s_nfse_taxes.


    result-cnae = get_cnae( ).
    result-codigo_nbs = get_nbs( ).
    result-discriminacao = get_discriminacao( ).
    result-codigo_municipio_incidencia = get_cod_munic_incidencia( ).
    result-codigo_tributacao_municipio = get_cod_trib_municipio( ).
    result-item_lista_servico = get_item_lista_servico( ).
    result-codigo_atividade = get_codigo_atividade( ).
    result-codigo_servico = get_codigo_servico( ).
    result-quantidade = '1'.
    result-unidade = get_unidade(  ).

    total_value = get_total_value(  ).
    result-valor_unitario = currency_utils->to_string( total_value ).
    total_deductions = get_serv_total_dedut( ).

    taxes = me->get_taxes(  ).
    tax_added = me->sum_nfse_tax_values( taxes ).

    result-valores-iss = me->get_iss( tax_added-iss ).
    result-valores-pis = me->get_pis( tax_added-pis ).
    result-valores-cofins = me->get_cofins( tax_added-cofins ).
    result-valores-inss = me->get_inss( tax_added-inss ).
    result-valores-ir = me->get_ir( tax_added-ir ).
    result-valores-csll = me->get_csll( tax_added-csll ).

    total_taxes = me->get_tax_total( sum = tax_added ).
    result-valores-valor_total_tributos = currency_utils->to_string( total_taxes ).

    result-valores-total_servicos = currency_utils->to_string( total_value ).
    result-valores-total_deducoes = currency_utils->to_string( total_deductions ).
    result-valores-valor_liquido = me->get_valor_liquido( total_tax = total_taxes total_value = total_value ).
    result-valores-outras_retencoes = me->get_outras_retencoes( ).
    result-valores-outras_retencoes = currency_utils->to_string( result-valores-outras_retencoes ).

    result-com_ext = me->get_com_exterior(  ).

  ENDMETHOD.

  METHOD if_value.

    IF input IS INITIAL.
      RETURN.
    ENDIF.

    result = input.

  ENDMETHOD.


  METHOD get_rps_tomador.
    DATA: customer_rne TYPE string,
          customer     TYPE REF TO /s4tax/customer.

    customer = doc->get_customer( ).
    IF customer IS NOT BOUND.
      RETURN.
    ENDIF.

    result-cnpj = string_utils->if_value( customer->struct-stcd1 ).
    result-cnpj = string_utils->remove_special_characters( result-cnpj ).

    result-razao_social = string_utils->concatenate( msg1 = customer->struct-name1
                                                     msg2 = customer->struct-name2 ).
    result-razao_social = string_utils->trim( result-razao_social ).
    result-nome_fantasia = result-razao_social.
    result-inscricao_estadual = string_utils->remove_special_characters( customer->struct-stcd3 ).
    result-inscricao_municipal = string_utils->remove_special_characters( customer->struct-stcd4 ).

    result-endereco = get_tomador_address( customer = customer ).
    IF result-endereco IS INITIAL.
      RETURN.
    ENDIF.

    IF result-endereco-codigo_pais <> /s4tax/address_utils=>cod_brasil.
      customer_rne = customer->get_rne( ).
      IF customer_rne IS NOT INITIAL.
        result-cnpj = string_utils->if_value( customer_rne ).
      ENDIF.
      result-doc_estrangeiro = result-cnpj.
    ENDIF.

    result-cpf = get_tomador_cpf( customer    = customer
                                  codigo_pais = result-endereco-codigo_pais ).

    result-tipo = get_tipo_tomador( result ).

    result-contato = get_tomador_contact( customer ).

  ENDMETHOD.


  METHOD get_situacao.

    IF me->extension IS NOT BOUND.
      RETURN.
    ENDIF.
    result = me->extension->get_situacao( ).
    result = me->string_utils->to_lower_case( result ).

  ENDMETHOD.


  METHOD get_taxes.
    DATA: inss_extension TYPE /s4tax/s_tax_values.

    result = get_taxes_from_stx( ).

    IF me->extension IS BOUND.

      inss_extension =  me->extension->get_inss( ).
      IF inss_extension IS NOT INITIAL.

        REFRESH result-inss.
        APPEND inss_extension TO result-inss.

      ENDIF.
    ENDIF.

  ENDMETHOD.


  METHOD get_taxes_from_stx.
    DATA:
      tax_list       TYPE /s4tax/tax_t,
      tax            TYPE LINE OF /s4tax/tax_t,
      tax_value      TYPE /s4tax/s_tax_values,
      item_list      TYPE /s4tax/item_t,
      item           TYPE LINE OF /s4tax/item_t,
      tax_name       TYPE /s4tax/tnfse_tax-tax,
      is_statistical TYPE j_1bnfstx-stattx.

    item_list = me->doc->get_item_list( ).

    LOOP AT item_list INTO item.

      tax_list =  item->get_tax_list( ).
      LOOP AT tax_list INTO tax.

        is_statistical = tax->get_stattx(  ).
        IF is_statistical IS NOT INITIAL.
          CONTINUE.
        ENDIF.

        tax_value-base = tax->get_base( ).
        tax_value-rate = tax->get_rate( ).
        tax_value-taxval = tax->get_taxval( ).
        tax_value-withhold = tax->get_withhold(  ).

        tax_name = is_tax_type_accepted( tax ).
        IF tax_name IS INITIAL.
          CONTINUE.
        ENDIF.

        CASE tax_name.

          WHEN /s4tax/nfse_constants=>tax_name-iss.
            APPEND tax_value TO result-iss.

          WHEN /s4tax/nfse_constants=>tax_name-pis.
            APPEND tax_value TO result-pis.

          WHEN /s4tax/nfse_constants=>tax_name-cofins.
            APPEND tax_value TO result-cofins.

          WHEN /s4tax/nfse_constants=>tax_name-inss.
            APPEND tax_value TO result-inss.

          WHEN /s4tax/nfse_constants=>tax_name-ir.
            APPEND tax_value TO result-ir.

          WHEN /s4tax/nfse_constants=>tax_name-csll.
            APPEND tax_value TO result-csll.

          WHEN /s4tax/nfse_constants=>tax_name-ibsm.
            tax_value-rate = tax->get_rate4dec( ).
            APPEND tax_value TO result-ibsm.

          WHEN /s4tax/nfse_constants=>tax_name-ibss.
            tax_value-rate = tax->get_rate4dec( ).
            APPEND tax_value TO result-ibss.

          WHEN /s4tax/nfse_constants=>tax_name-cbs.
            tax_value-rate = tax->get_rate4dec( ).
            APPEND tax_value TO result-cbs.

        ENDCASE.

        CLEAR tax_value.
      ENDLOOP.

    ENDLOOP.

  ENDMETHOD.


  METHOD get_tipo_tomador.

    DATA: tax_address_branch TYPE REF TO /s4tax/tax_address,
          taxjurcode_branch  TYPE string.

    IF tomador-endereco-codigo_pais <> /s4tax/address_utils=>cod_brasil.
      result = /s4tax/nfse_constants=>tp_pessoa-pj_pais_dif.
      RETURN.
    ENDIF.

    IF tomador-cpf IS NOT INITIAL.
      result = /s4tax/nfse_constants=>tp_pessoa-pessoa_fisica.
      RETURN.
    ENDIF.

    IF tomador-cnpj IS INITIAL.
      result = /s4tax/nfse_constants=>tp_pessoa-outros.
      RETURN.
    ENDIF.

    tax_address_branch = me->branch->get_tax_address(  ).

    taxjurcode_branch = string_utils->replace_characters( tax_address_branch->struct-taxjurcode ).

    IF tomador-endereco-codigo_municipio = taxjurcode_branch.
      result = /s4tax/nfse_constants=>tp_pessoa-pj_municipio.
    ELSE.
      result = /s4tax/nfse_constants=>tp_pessoa-pj_municipio_dif.
    ENDIF.

  ENDMETHOD.


  METHOD get_tomador_address.

    DATA: addres_partner TYPE REF TO /s4tax/address_partner,
          tax_address    TYPE REF TO /s4tax/tax_address,
          country_code   TYPE REF TO /s4tax/country_code,
          country_text   TYPE REF TO /s4tax/country_text.


    addres_partner = customer->get_address_partner( ).
    IF addres_partner IS NOT BOUND.
      RETURN.
    ENDIF.

    address_utils->split_type_and_street( EXPORTING input  = addres_partner->struct-street
                                          IMPORTING type   = result-tipo_logradouro
                                                    street = result-logradouro ).

    result-numero = string_utils->replace_characters( addres_partner->struct-house_num1 ).
    IF result-numero IS INITIAL.
      result-numero = /s4tax/address_utils=>sn.
    ENDIF.

    result-complemento = addres_partner->get_house_num2( ).
    result-bairro = addres_partner->get_city2(  ).
    result-nome_uf = addres_partner->get_city1(  ).

    country_code = addres_partner->get_country_code(  ).
    IF country_code IS BOUND.
      result-codigo_pais = country_code->struct-cod_pais.
      SHIFT result-codigo_pais LEFT DELETING LEADING '0'.
      result-sigla_pais = addres_partner->get_country( ).
    ENDIF.


    country_text = addres_partner->get_country_text(  ).
    IF country_text IS BOUND.
      result-nome_pais = country_text->struct-landx.
    ENDIF.

    result-uf = addres_partner->get_region( ).
    result-cep = string_utils->remove_special_characters( addres_partner->struct-post_code1 ).
    result-tp_bairro = /s4tax/address_utils=>bairro.

    tax_address = customer->get_tax_address( ).

    IF tax_address IS BOUND.

      result-codigo_municipio = string_utils->replace_characters( tax_address->struct-taxjurcode ).
      result-nome_municipio = tax_address->get_text_by_country( country = tax_address->struct-country ).

    ENDIF.

    "Parceiro exterior
    IF result-codigo_pais <> /s4tax/address_utils=>cod_brasil.
      result-cep = /s4tax/address_utils=>foreign-cep.
      result-codigo_municipio = /s4tax/address_utils=>foreign-codigo_municipio.
      result-uf = /s4tax/address_utils=>foreign-uf.
      result-nome_municipio = /s4tax/address_utils=>foreign-nome_municipio.
    ENDIF.

  ENDMETHOD.


  METHOD get_tomador_contact.
    DATA: address_partner TYPE REF TO /s4tax/address_partner.

    result-email = process_email( customer ).
    address_partner = customer->get_address_partner( ).
    IF address_partner IS NOT BOUND.
      RETURN.
    ENDIF.

    result-telefone = string_utils->trim( input = address_partner->struct-tel_number no_gaps = abap_true ).
    address_utils->extract_ddd_phone_parentheses( EXPORTING telephone  = result-telefone
                                                  IMPORTING ddd        = result-ddd
                                                            tel_number = result-telefone ).

    result-telefone = string_utils->remove_special_characters( result-telefone ).

  ENDMETHOD.


  METHOD get_tomador_cpf.
    IF customer->struct-stcd1 IS NOT INITIAL.
      RETURN.
    ENDIF.

    IF codigo_pais <> /s4tax/address_utils=>cod_brasil.
      result = string_utils->if_value( /s4tax/address_utils=>foreign-cpf ).
      RETURN.
    ENDIF.

    result = string_utils->if_value( customer->struct-stcd2 ).
    result = string_utils->remove_special_characters( result ).

  ENDMETHOD.


  METHOD get_total_value.

    result = me->doc->get_total_value(  ).

  ENDMETHOD.


  METHOD get_tp_operacao.

    IF me->extension IS NOT BOUND.
      RETURN.
    ENDIF.
    result = me->extension->get_tp_operacao(  ).

  ENDMETHOD.


  METHOD get_true_or_false.
    result = /s4tax/constants=>proposition-false.

    IF string_utils->if_is_not_initial( value ) = abap_true.
      result = /s4tax/constants=>proposition-true.
    ENDIF.

  ENDMETHOD.


  METHOD get_valor_liquido.
    DATA: valor_liquido TYPE j_1bnfstx-taxval.

    valor_liquido = total_value - total_tax.
    result = currency_utils->to_string( valor_liquido ).

  ENDMETHOD.


  METHOD is_tax_type_accepted.
    DATA: tax_type TYPE REF TO /s4tax/tax_type,
          nfse_tax TYPE REF TO /s4tax/nfse_tax.

    tax_type = tax->get_tax_type( ).

    READ TABLE me->tax_types INTO nfse_tax WITH KEY table_line->struct-taxgrp = tax_type->struct-taxgrp
                                                    table_line->struct-taxtyp = tax_type->struct-taxtyp.
    IF sy-subrc = 0.
      result = nfse_tax->struct-tax.
    ENDIF.

  ENDMETHOD.


  METHOD process_email.
    DATA:
      email_address TYPE /s4tax/email_address_t,
      email         TYPE REF TO /s4tax/email_address.

    email_address = customer->get_emails( )."TODO verificar qual dos emails.
    IF email_address IS NOT INITIAL.
      READ TABLE email_address INTO email INDEX 1.
      result = email->get_smtp_addr( ).
    ENDIF.

  ENDMETHOD.


  METHOD set_zeros_insc_municip.

    DATA: tax_address_branch TYPE string,
          tax_address_obj    TYPE REF TO /s4tax/tax_address.

    result = rps_tomador-inscricao_municipal.

    IF rps_tomador-cpf IS NOT INITIAL.
      result = amount_of_zeros.
      RETURN.
    ENDIF.

    tax_address_obj = me->branch->get_tax_address( ).
    tax_address_branch = string_utils->replace_characters( tax_address_obj->struct-taxjurcode ).

    IF tax_address_branch <> rps_tomador-endereco-codigo_municipio.
      result = amount_of_zeros.
    ENDIF.

  ENDMETHOD.


  METHOD sum_nfse_tax_values.

    result-iss = me->sum_taxes( tax_values-iss ).
    result-pis = me->sum_taxes( tax_values-pis ).
    result-cofins = me->sum_taxes( tax_values-cofins ).
    result-inss = me->sum_taxes( tax_values-inss ).
    result-ir = me->sum_taxes( tax_values-ir ).
    result-csll = me->sum_taxes( tax_values-csll ).

    result-ibsm = me->sum_taxes( tax_values-ibsm ).
    result-ibss = me->sum_taxes( tax_values-ibss ).
    result-cbs = me->sum_taxes( tax_values-cbs ).

    IF go_badi_nfse IS BOUND.
      CALL BADI go_badi_nfse->nfse_tax_recalculation
        EXPORTING
          nfse_active = active
          doc         = doc
        CHANGING
          result      = result.
    ENDIF.

  ENDMETHOD.


  METHOD sum_taxes.
    DATA: tax TYPE /s4tax/s_tax_values.

    LOOP AT tax_table INTO tax.

      result-base = result-base + tax-base.
      result-taxval = result-taxval + tax-taxval.
      result-retido =  me->get_true_or_false( tax-withhold ).

      result-rate = tax-rate.
      result-withhold = tax-withhold.

      IF tax-withhold = abap_true.
      result-valor_retido = currency_utils->to_string( tax-taxval ).
    ELSE.
      result-valor = currency_utils->to_string( tax-taxval ).
    ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD reg_espec_trib_letter_to_numb.
    CASE trib.
      WHEN 'T'.
        result = '1'.
      WHEN 'M'.
        result = '5'.
      WHEN OTHERS.
        result = trib.
    ENDCASE.
  ENDMETHOD.


  METHOD get_tax_total.

    result = sum-pis-taxval + sum-cofins-taxval + sum-inss-taxval + sum-ir-taxval + sum-csll-taxval + sum-ibss-taxval + sum-ibsm-taxval + sum-cbs-taxval.
    "+sum-OutrasRetençoes + Desconto Incondicionado +Desconto Condicionado

    IF sum-iss-withhold = abap_true.
      result = result + sum-iss-taxval.
    ENDIF.

  ENDMETHOD.


  METHOD /s4tax/infse_data~get_file_format.

  ENDMETHOD.


  METHOD get_unidade.
    DATA: first_item TYPE REF TO /s4tax/item.

    first_item = doc->get_item_by_index( 1 ).
    result = first_item->struct-meins.

  ENDMETHOD.


  METHOD call_badi.
    GET BADI go_badi_nfse.
  ENDMETHOD.


  METHOD get_serv_total_dedut.
    result = 0.
  ENDMETHOD.


  METHOD get_servico_endereco.
    DATA: address1    TYPE addr1_val,
          type        TYPE string,
          tax_address TYPE REF TO /s4tax/tax_address.


    address1 = me->branch->get_address1( ).

    result-bairro = address1-city2.
    address_utils->split_type_and_street( EXPORTING input  = address1-street
                                          IMPORTING type   = type
                                                    street = result-logradouro ).

    result-numero = address1-house_num1.
    result-cep = address1-post_code1.
    result-tipo_logradouro = type.

    result-uf = address1-region.

    tax_address = me->branch->get_tax_address( ).

    IF tax_address IS BOUND.
      result-codigo_municipio = string_utils->replace_characters( tax_address->struct-taxjurcode ).

      result-nome_municipio = tax_address->get_text_by_country( country = tax_address->struct-country ).
    ENDIF.

  ENDMETHOD.


  METHOD get_outras_retencoes.
    result = me->doc->get_other_withholdings( ).
  ENDMETHOD.


  METHOD get_nbs.
    DATA: first_item TYPE REF TO /s4tax/item.

    result = extension->get_nbs(  ).
    IF result IS NOT INITIAL.
      RETURN.
    ENDIF.

    first_item = doc->get_item_by_index( 1 ).
    result = first_item->struct-nbs.
  ENDMETHOD.


  METHOD get_rps_ibs_cbs.
    DATA: dao_ref_trib           TYPE REF TO /s4tax/idao_ref_trib,
          tomador                TYPE /s4tax/s_nfse_tomador,
          items                  TYPE /s4tax/item_t,
          tax_reform_custom_list TYPE /s4tax/tax_reform_t,
          model                  TYPE            j_1bmodel,
          first_item             TYPE REF TO /s4tax/item.


    IF me->nfse_class IS NOT BOUND.
      RETURN.
    ENDIF.

    first_item = me->doc->get_first_item_ibscbs( ).
    IF first_item IS NOT BOUND.
      first_item = me->doc->get_item_by_index( 1 ).
    ENDIF.

    IF first_item IS NOT BOUND.
      RETURN.
    ENDIF.

    "===========================
    " IBSCBS
    "===========================

    result-fin_nfse = me->extension->get_finalidade( ).
    IF result-fin_nfse IS INITIAL.
      result-fin_nfse = me->doc->get_doctyp(  ).
    ENDIF.

    result-ind_final = me->extension->get_modo_prest_serv( ).
    IF result-ind_final IS INITIAL.
      result-ind_final = me->doc->get_ind_final( ).
    ENDIF.

    result-ind_dest = me->extension->get_ind_dest( ).
    IF result-ind_dest IS INITIAL.
      result-ind_dest = me->doc->get_inddest(  ).
    ENDIF.

    " result-tp_oper = me->extension->get_tp_operacao( ).
    IF result-tp_oper IS INITIAL.
      "result-tp_oper = first_item->get_tp "Falta indicação do campo std
    ENDIF.

    " result-tp_ente_gov = me->extension->get_ind_compra_gov( ).
    IF result-tp_ente_gov IS INITIAL.
      "result-tp_ente_gov = first_item-> "Falta indicação do campo std
    ENDIF.

    result-c_ind_op = me->extension->get_cod_ind_oper( ).
    IF result-c_ind_op IS INITIAL.
      result-c_ind_op = first_item->get_cindop( ).
    ENDIF.


    result-dest = me->get_rps_ibs_cbs_dest(  ).


    "===========================
    " SERVICOS
    "===========================

    result-servicos-modo_prest_serv   = extension->get_modo_prest_serv(  ).
    result-servicos-clocal_prest_serv = get_cod_munic_incidencia( ).
    result-servicos-c_pais_prest_serv = get_cod_pais_incidencia( ).
    result-servicos-c_cib             = ''. "(Será preenchido de acordo com cada cliente de construção civil)
    result-servicos-ind_compra_gov    = extension->get_ind_compra_gov(  ).

    CASE  me->nfse_class->struct-tax_reform.
      WHEN /s4tax/dfe_constants=>tax_reform_model-std_process OR /s4tax/dfe_constants=>tax_reform_model-table_std_process.
        me->ibs_cbs_from_std_tables( CHANGING result = result ).
      WHEN /s4tax/dfe_constants=>tax_reform_model-custom.
        me->ibs_cbs_from_custom( CHANGING result = result ).
    ENDCASE.


  ENDMETHOD.

  METHOD ibs_cbs_from_std_tables.

    DATA: tomador TYPE /s4tax/s_nfse_tomador,
          item    TYPE REF TO /s4tax/item.

    item = doc->get_first_item_ibscbs( ).
    IF item IS NOT BOUND.
      item = doc->get_item_by_index( 1 ).
    ENDIF.

    IF item IS NOT BOUND.
      RETURN.
    ENDIF.

    "===========================
    " VALORES
    "===========================

    result-valores-trib-cst          = item->get_cst( ).
    result-valores-trib-c_class_trib = item->get_cclasstrib( ).

    result-valores-trib-c_cred_pres = item->get_ccredprescbs( ).
    "result-valores-g_ibs_cred_pres-p_cred_pres_cbs = item->get_pcredprescbs( ).

    IF tax_added-ibss-base IS NOT INITIAL.
      result-valores-base_calculo = tax_added-ibss-base.
    ELSEIF tax_added-ibsm-base IS NOT INITIAL.
      result-valores-base_calculo = tax_added-ibsm-base.
    ELSE.
      result-valores-base_calculo = currency_utils->to_string( tax_added-cbs-base ).
    ENDIF.

    result-valores-ibs_uf-aliquota = currency_utils->to_string( tax_added-ibss-rate ).
    result-valores-ibs_uf-valor = currency_utils->to_string( tax_added-ibss-taxval ).
    result-valores-ibs_uf-percentual_diferimento = item->get_pdifibsuf( ).
    result-valores-ibs_uf-percentual_diferimento = currency_utils->to_string( result-valores-ibs_uf-percentual_diferimento ).
    result-valores-ibs_uf-valor_tributo_devolvido          = item->get_vdevtribibsuf( ).
    result-valores-ibs_uf-valor_tributo_devolvido = currency_utils->to_string( result-valores-ibs_uf-valor_tributo_devolvido ).
    "result-valores-ibs_uf-cod_situacao_trib_deson  = ''. "(Será avaliado forma de preenchimento depois)
    "result-valores-ibs_uf-cod_classific_trib_deson = ''. "(Será avaliado forma de preenchimento depois)
    "result-valores-ibs_uf-aliquota_desoneracao     = ''. "(Será avaliado forma de preenchimento depois)

    result-valores-ibs_mun-aliquota = currency_utils->to_string( tax_added-ibsm-rate ).
    result-valores-ibs_mun-valor = currency_utils->to_string( tax_added-ibsm-taxval ).
    result-valores-ibs_mun-percentual_diferimento      =  item->get_pdifibsmun( ).
    result-valores-ibs_mun-percentual_diferimento      = currency_utils->to_string( result-valores-ibs_mun-percentual_diferimento ).
    result-valores-ibs_mun-valor_tributo_devolvido     = item->get_vdevtribibsmun( ).
    result-valores-ibs_mun-valor_tributo_devolvido = currency_utils->to_string( result-valores-ibs_mun-valor_tributo_devolvido ).
    "result-valores-g_ibs_mun-cod_situacao_trib_deson  = ''. "(Será avaliado forma de preenchimento depois)
    "result-valores-g_ibs_mun-cod_classific_trib_deson = ''. "(Será avaliado forma de preenchimento depois)
    "result-valores-g_ibs_mun-aliquota_desoneracao     = ''. "(Será avaliado forma de preenchimento depois)

    result-valores-cbs-aliquota = currency_utils->to_string( tax_added-cbs-rate ).
    result-valores-cbs-valor = currency_utils->to_string( tax_added-cbs-taxval ).
    result-valores-cbs-percentual_diferimento      = item->get_pdifcbs( ).
    result-valores-cbs-percentual_diferimento = currency_utils->to_string( result-valores-cbs-percentual_diferimento ).
    result-valores-cbs-valor_tributo_devolvido          = item->get_vdevtribcbs( ).
    result-valores-cbs-valor_tributo_devolvido = currency_utils->to_string( result-valores-cbs-valor_tributo_devolvido ).
    "result-valores-g_cbs-tributacao-cod_situacao_trib_deson  = ''. "(Será avaliado forma de preenchimento depois)
    "result-valores-g_cbs-tributacao-cod_classific_trib_deson = ''. "(Será avaliado forma de preenchimento depois)
    "result-valores-g_cbs-tributacao-aliquota_desoneracao     = ''. "(Será avaliado forma de preenchimento depois)



    "result-valores-g_cbs-g_cbs_cred_pres-c_cred_pres  = item->get_ccredprescbs( ).
    "result-valores-g_cbs-g_cbs_cred_pres-p_cred_pres  = item->get_pcredprescbs( ).

  ENDMETHOD.

  METHOD ibs_cbs_from_custom.

    DATA: item                   TYPE REF TO /s4tax/item,
          ref_trib               TYPE REF TO /s4tax/tax_reform,
          tax_reform_custom_list TYPE /s4tax/tax_reform_t,
          model                  TYPE            j_1bmodel,
          base_calc              TYPE j_1btaxval.

    tax_reform_custom_list = me->get_tax_reform_custom_list( ).
    item = doc->get_item_by_index( 1 ).
    IF item IS NOT BOUND.
      RETURN.
    ENDIF.

    READ TABLE tax_reform_custom_list INTO ref_trib WITH KEY table_line->struct-model = '01'
                                                                 table_line->struct-cfop  = item->struct-cfop
                                                                 table_line->struct-ncm = item->struct-nbm
                                                                 table_line->struct-matnr = item->struct-matnr.

    IF ref_trib IS NOT BOUND.
      READ TABLE tax_reform_custom_list INTO ref_trib WITH KEY table_line->struct-model = '01'
                                                             table_line->struct-cfop  = item->struct-cfop
                                                             table_line->struct-ncm = item->struct-nbm
                                                             table_line->struct-matnr = ''.
    ENDIF.

    IF ref_trib IS NOT BOUND.
      READ TABLE tax_reform_custom_list INTO ref_trib WITH KEY table_line->struct-model = '01'
                                                             table_line->struct-cfop  = item->struct-cfop
                                                             table_line->struct-ncm = ''
                                                             table_line->struct-matnr = item->struct-matnr.
    ENDIF.

    IF ref_trib IS NOT BOUND.
      READ TABLE tax_reform_custom_list INTO ref_trib WITH KEY table_line->struct-model = '01'
                                                             table_line->struct-cfop  = item->struct-cfop
                                                             table_line->struct-ncm = ''
                                                             table_line->struct-matnr = ''.
    ENDIF.

    IF ref_trib IS NOT BOUND.
      RETURN.
    ENDIF.

    "===========================
    " VALORES
    "===========================

    result-valores-trib-cst          = ref_trib->get_cst( ).
    result-valores-trib-c_class_trib = ref_trib->get_cclass( ).

*    IF ref_trib->struct-cst = '410'.
*      RETURN.
*    ENDIF.


*    result-valores-trib-c_cred_pres = item->get_ccredprescbs( ).
*    "result-valores-g_ibs_cred_pres-p_cred_pres_cbs = item->get_pcredprescbs( ).
*
*    result-valores-ibs_uf-percentual_diferimento = item->get_pdifibsuf( ).
*    result-valores-ibs_uf-valor_tributo_devolvido          = item->get_vdevtribibsuf( ).
*    "result-valores-ibs_uf-cod_situacao_trib_deson  = ''. "(Será avaliado forma de preenchimento depois)
*    "result-valores-ibs_uf-cod_classific_trib_deson = ''. "(Será avaliado forma de preenchimento depois)
*    "result-valores-ibs_uf-aliquota_desoneracao     = ''. "(Será avaliado forma de preenchimento depois)
*
*    result-valores-ibs_mun-percentual_diferimento      = item->get_pdifibsmun( ).
*    result-valores-ibs_mun-valor_tributo_devolvido     = item->get_vdevtribibsmun( ).
*    "result-valores-g_ibs_mun-cod_situacao_trib_deson  = ''. "(Será avaliado forma de preenchimento depois)
*    "result-valores-g_ibs_mun-cod_classific_trib_deson = ''. "(Será avaliado forma de preenchimento depois)
*    "result-valores-g_ibs_mun-aliquota_desoneracao     = ''. "(Será avaliado forma de preenchimento depois)
*
*    "result-valores-g_cbs-g_cbs_cred_pres-c_cred_pres  = item->get_ccredprescbs( ).
*    "result-valores-g_cbs-g_cbs_cred_pres-p_cred_pres  = item->get_pcredprescbs( ).
*
*    result-valores-cbs-percentual_diferimento      = item->get_pdifcbs( ).
*    result-valores-cbs-valor_tributo_devolvido          = item->get_vdevtribcbs( ).
*    "result-valores-g_cbs-tributacao-cod_situacao_trib_deson  = ''. "(Será avaliado forma de preenchimento depois)
*    "result-valores-g_cbs-tributacao-cod_classific_trib_deson = ''. "(Será avaliado forma de preenchimento depois)
*    "result-valores-g_cbs-tributacao-aliquota_desoneracao     = ''. "(Será avaliado forma de preenchimento depois)

    """""""""NFE como base """"""""""""""""""" REMOVER

*    base_calc = prod_doc-v_prod.
*    valor_ibs = base_calc * ( ref_trib->struct-aliq_ibs / 100 ).
*    valor_cbs = base_calc * ( ref_trib->struct-aliq_cbs / 100 ).
*    ibs_cbs-grupo_ibscbs-base_calculo = base_calc.
*    ibs_cbs-grupo_ibscbs-base_calculo = me->string_utils->trim( ibs_cbs-grupo_ibscbs-base_calculo ).
*    ibs_cbs-grupo_ibscbs-ibsuf-aliquota = ref_trib->get_aliq_ibs( ).
*    ibs_cbs-grupo_ibscbs-ibsuf-aliquota = me->string_utils->trim( ibs_cbs-grupo_ibscbs-ibsuf-aliquota ).
*    ibs_cbs-grupo_ibscbs-ibsuf-valor = valor_ibs.
*    ibs_cbs-grupo_ibscbs-ibsuf-valor = me->string_utils->trim( ibs_cbs-grupo_ibscbs-ibsuf-valor ).
*    ibs_cbs-grupo_ibscbs-ibsmun-aliquota = aliq_ibs_mun.
*    ibs_cbs-grupo_ibscbs-ibsmun-aliquota = me->string_utils->trim( ibs_cbs-grupo_ibscbs-ibsmun-aliquota ).
*    ibs_cbs-grupo_ibscbs-ibsmun-valor = value_ibs_mun.
*    ibs_cbs-grupo_ibscbs-ibsmun-valor = me->string_utils->trim( ibs_cbs-grupo_ibscbs-ibsmun-valor ).
*    ibs_cbs-grupo_ibscbs-vibs = valor_ibs.
*    ibs_cbs-grupo_ibscbs-vibs = me->string_utils->trim( ibs_cbs-grupo_ibscbs-vibs ).
*    ibs_cbs-grupo_ibscbs-cbs-aliquota = ref_trib->get_aliq_cbs( ).
*    ibs_cbs-grupo_ibscbs-cbs-aliquota = me->string_utils->trim( ibs_cbs-grupo_ibscbs-cbs-aliquota ).
*    ibs_cbs-grupo_ibscbs-cbs-valor = valor_cbs.
*    ibs_cbs-grupo_ibscbs-cbs-valor = me->string_utils->trim( ibs_cbs-grupo_ibscbs-cbs-valor ).
*
*    "----TOTAL-----"
*    ibscbs_total_line-base = base_calc.
*    ibscbs_total_line-cbs_value = valor_cbs.
*    ibscbs_total_line-ibs_value = valor_ibs.
*    ibscbs_total_line-ibsuf_value = valor_ibs.
*    ibscbs_total_line-ibsuf_aliq = ref_trib->get_aliq_ibs( ).
*    ibscbs_total_line-ibsmun_value = value_ibs_mun.
*    ibscbs_total_line-ibsmun_aliq = aliq_ibs_mun.
*    "----TOTAL-----"
*
*    IF ref_trib->struct-cst = '200'.
*      "IBS
*      aliq_efetiva = abs( ref_trib->struct-aliq_ibs *  ( 1 - (  ref_trib->struct-perc_red_ibs  ) / 100 ) ) .
*
*      "UF
*      ibs_cbs-grupo_ibscbs-ibsuf-percentual_aliquota_red = ref_trib->get_perc_red_ibs( ).
*      ibs_cbs-grupo_ibscbs-ibsuf-percentual_aliquota_red = me->string_utils->trim( ibs_cbs-grupo_ibscbs-ibsuf-percentual_aliquota_red ).
*      ibs_cbs-grupo_ibscbs-ibsuf-aliquota_efetiva_red = aliq_efetiva.
*      ibs_cbs-grupo_ibscbs-ibsuf-aliquota_efetiva_red = me->string_utils->trim( ibs_cbs-grupo_ibscbs-ibsuf-aliquota_efetiva_red ).
*      valor_ibs = base_calc * ( aliq_efetiva / 100 ).
*      ibs_cbs-grupo_ibscbs-ibsuf-valor = valor_ibs.
*      ibs_cbs-grupo_ibscbs-ibsuf-valor = me->string_utils->trim( ibs_cbs-grupo_ibscbs-ibsuf-valor ).
*
*      valor_ibs_red = base_calc * ( aliq_efetiva / 100 ).
*      ibs_cbs-grupo_ibscbs-vibs = valor_ibs_red.
*      ibs_cbs-grupo_ibscbs-vibs = me->string_utils->trim( ibs_cbs-grupo_ibscbs-vibs ).
*
*      "MUN
*      ibs_cbs-grupo_ibscbs-ibsmun-percentual_aliquota_red = ref_trib->get_perc_red_ibs( ).
*      ibs_cbs-grupo_ibscbs-ibsmun-percentual_aliquota_red = me->string_utils->trim( ibs_cbs-grupo_ibscbs-ibsmun-percentual_aliquota_red ).
*      ibs_cbs-grupo_ibscbs-ibsmun-aliquota_efetiva_red = aliq_ibs_mun.
*      ibs_cbs-grupo_ibscbs-ibsmun-aliquota_efetiva_red = me->string_utils->trim( ibs_cbs-grupo_ibscbs-ibsmun-aliquota_efetiva_red ).
*      ibs_cbs-grupo_ibscbs-ibsmun-valor = value_ibs_mun.
*      ibs_cbs-grupo_ibscbs-ibsmun-valor = me->string_utils->trim( ibs_cbs-grupo_ibscbs-ibsmun-valor ).
*
*      "CBS
*      aliq_efetiva_cbs = abs( ref_trib->struct-aliq_cbs * (  1 - ( ref_trib->struct-perc_red_cbs ) / 100 )  ).
*
*      ibs_cbs-grupo_ibscbs-cbs-percentual_aliquota_red = ref_trib->get_perc_red_cbs( ).
*      ibs_cbs-grupo_ibscbs-cbs-percentual_aliquota_red = me->string_utils->trim( ibs_cbs-grupo_ibscbs-cbs-percentual_aliquota_red ).
*      ibs_cbs-grupo_ibscbs-cbs-aliquota_efetiva_red =  aliq_efetiva_cbs.
*      ibs_cbs-grupo_ibscbs-cbs-aliquota_efetiva_red =  me->string_utils->trim( ibs_cbs-grupo_ibscbs-cbs-aliquota_efetiva_red ).
*      valor_cbs = base_calc * ( aliq_efetiva_cbs / 100 ).
*      ibs_cbs-grupo_ibscbs-cbs-valor = valor_cbs.
*      ibs_cbs-grupo_ibscbs-cbs-valor = me->string_utils->trim( ibs_cbs-grupo_ibscbs-cbs-valor ).
*
*      valor_cbs_red = base_calc * ( aliq_efetiva_cbs / 100 ).
*      ibs_cbs-grupo_ibscbs-cbs-valor = valor_cbs_red.
*      ibs_cbs-grupo_ibscbs-cbs-valor = me->string_utils->trim( ibs_cbs-grupo_ibscbs-cbs-valor ).
*
*      "----TOTAL-----
*      ibscbs_total_line-ibs_value = valor_ibs_red.
*      ibscbs_total_line-ibsuf_value = valor_ibs_red.
*
*      ibscbs_total_line-cbs_value = valor_cbs_red.
*
*      ibscbs_total_line-ibsuf_perc_aliq_red = ref_trib->get_perc_red_ibs( ).
*      ibscbs_total_line-ibsuf_aliq_efet_red = aliq_efetiva.
*      ibscbs_total_line-ibsmun_perc_aliq_red = ref_trib->get_perc_red_ibs( ).
*      ibscbs_total_line-ibsmun_aliq_efet_red = aliq_ibs_mun.
*      ibscbs_total_line-cbs_perc_aliq_red = ref_trib->get_perc_red_cbs( ).
*      ibscbs_total_line-cbs_aliq_efet_red = aliq_efetiva_cbs.
*      "----TOTAL-----"
*    ENDIF.
*
*    APPEND ibscbs_total_line TO me->tax_reform_ibs_cbs_items.
    """""""""NFE como base """"""""""""""""""" REMOVER

  ENDMETHOD.


  METHOD get_ibscbs_total.
    DATA: item  TYPE REF TO /s4tax/item,
          total TYPE /s4tax/s_dfe_total_ibs_cbs_is.

    item = me->get_tax_reform_item( ).
    IF item IS NOT BOUND.
      RETURN.
    ENDIF.

    result-valor_total = me->doc->get_total_value( ).
    "result-g_ibs-v_cred_pres = item->get_vcredpresibs( ).

    " result-g_ibs-g_ibs_uf_tot-valor_total_diferimento          = item->get_vdifibsuf( ).
    "result-g_ibs-g_ibs_uf_tot-v_deson        = ''. "(Vazio na EF)
    "result-g_ibs-g_ibs_uf_tot-valor_ente_gov = ''. "(Vazio na EF)

    " result-g_ibs-g_ibs_mun_tot-valor_total_diferimento          = item->get_vdifibsmun( ).
    "result-g_ibs-g_ibs_mun_tot-v_deson        = ''. "(Vazio na EF)
    "result-g_ibs-g_ibs_mun_tot-valor_ente_gov = ''. "(Vazio na EF)

    total = me->doc->calculate_total_ibs_cbs( ).
    result-g_ibs-valor_total = total-ibs.

    result-g_cbs-valor_total_credito_presumido  = item->get_vcredprescbs( ).
    result-g_cbs-valor_total_diferimento          = item->get_vdifcbs( ).
    "result-g_cbs-v_deson        = ''. "(Vazio na EF)
    "result-g_cbs-valor_ente_gov = ''. "(Vazio na EF)
  ENDMETHOD.


  METHOD get_tax_reform_item.
    DATA: item       TYPE REF TO /s4tax/item,
          cst        TYPE string,
          class_trib TYPE string.

    IF me->doc IS NOT BOUND.
      RETURN.
    ENDIF.
    item = me->doc->get_first_item_ibscbs( ).
    IF item IS NOT BOUND.
      item = me->doc->get_item_by_index( 1 ).
    ENDIF.

    IF item IS NOT BOUND.
      RETURN.
    ENDIF.

    cst = item->get_cst( ).
    class_trib = item->get_cclasstrib( ).

    IF cst IS INITIAL AND class_trib IS INITIAL.
      RETURN.
    ENDIF.

    result = item.
  ENDMETHOD.

  METHOD get_com_exterior.

    DATA: mdprestacao TYPE /s4tax/e_j_1bmdprestacao,
          vinc_prest  TYPE /s4tax/e_j_1bvincprest,
          tpmoeda     TYPE  /s4tax/e_j_1btpmoeda,
          mecafcomexp TYPE  /s4tax/e_mec_afc_comex_p,
          mecafcomext TYPE  /s4tax/e_j_1bmecafcomext,
          movtempbens TYPE /s4tax/e_j_1bmovtempbens,
          mdic        TYPE /s4tax/e_j_1bmdic,
          vservmoeda  TYPE /s4tax/e_j_1bvservmoeda.

    mdprestacao = doc->get_mdprestacao( ).
    vinc_prest  = doc->get_vinc_prest( ).
    tpmoeda     = doc->get_tpmoeda( ).
    mecafcomexp = doc->get_mecafcomexp( ).
    mecafcomext = doc->get_mecafcomext( ).
    movtempbens = doc->get_movtempbens( ).
    mdic        = doc->get_mdic( ).
    vservmoeda  = doc->get_vservmoeda( ).

    result-md_prestacao = if_value( mdprestacao ).
    result-vinc_prest = if_value( vinc_prest ).
    result-tp_moeda = if_value( tpmoeda ).
    result-mec_afc_omex_p = if_value( mecafcomexp ).
    result-mec_afc_omex_t = if_value( mecafcomext ).
    result-mov_temp_bens = if_value( movtempbens ).
    result-mdic = if_value( mdic ).
    result-v_serv_moeda = if_value( vservmoeda ).
    result-v_serv_moeda = me->string_utils->trim( result-v_serv_moeda ).

  ENDMETHOD.

  METHOD get_rps_ibs_cbs_dest.

    DATA tomador TYPE /s4tax/s_nfse_tomador.

    tomador = me->get_rps_tomador( ).

    result-cnpj      = tomador-cnpj.
    result-cpf       = tomador-cpf.
    result-nif       = tomador-nif.
    result-c_nao_nif = ''. "tomador-doc_estrangeiro.
    result-caepf     = ''.
    result-x_nome    = tomador-nome_fantasia.
    result-fone      = tomador-contato-telefone.
    result-email     = tomador-contato-email.


    result-end-x_lgr          = tomador-endereco-logradouro.
    result-end-nro            = tomador-endereco-numero.
    result-end-x_cpl          = tomador-endereco-complemento.
    result-end-x_bairro       = tomador-endereco-bairro.

    IF tomador-endereco-codigo_pais = /s4tax/address_utils=>cod_brasil.
      result-end-end_nac-cep   = tomador-endereco-cep.
      result-end-end_nac-c_mun = tomador-endereco-codigo_municipio.
      result-end-end_nac-c_uf = tomador-endereco-uf.
    ELSE.
      IF result-nif IS INITIAL.
        result-c_nao_nif = '0'.
      ENDIF.
      result-end-end_ext-x_est_prov_reg = tomador-endereco-nome_uf.
      result-end-end_ext-c_pais         = tomador-endereco-sigla_pais.
      result-end-end_ext-c_end_post     = tomador-endereco-cep.
      result-end-end_ext-x_cidade       = tomador-endereco-nome_municipio.
    ENDIF.

  ENDMETHOD.

  METHOD get_tax_reform_custom_list.
    DATA:
      dao_pack_dfe TYPE REF TO /s4tax/idao_document,
      dao_ref_trib TYPE REF TO /s4tax/idao_ref_trib,
      da_dfe_cfg   TYPE REF TO /s4tax/idao_dfe_cfg,
      items        TYPE /s4tax/item_t.
    dao_pack_dfe = /s4tax/dao_document=>get_instance( ).
    da_dfe_cfg = dao_pack_dfe->dfe_cfg( ).

    items = me->doc->get_item_list( ).
    dao_ref_trib  = dao_pack_dfe->ref_trib( ).
    result = dao_ref_trib->get_many_by_items( model = '01' items = items ).
  ENDMETHOD.
ENDCLASS.
"