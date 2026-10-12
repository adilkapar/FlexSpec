CLASS lhc_specflex DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR specflex RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE specflex.

    METHODS setdeletionflag FOR MODIFY
      IMPORTING keys FOR ACTION specflex~setdeletionflag RESULT result.

    METHODS removedeletionflag FOR MODIFY
      IMPORTING keys FOR ACTION specflex~removedeletionflag RESULT result.

    METHODS uploadexcel FOR MODIFY
      IMPORTING keys FOR ACTION specflex~uploadexcel RESULT result.

ENDCLASS.

CLASS lhc_specflex IMPLEMENTATION.

  METHOD get_instance_authorizations.
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      APPEND VALUE #(
        %tky                       = <key>-%tky
        %update                    = if_abap_behv=>auth-allowed
        %action-setdeletionflag    = if_abap_behv=>auth-allowed
        %action-removedeletionflag = if_abap_behv=>auth-allowed
      ) TO result.
    ENDLOOP.
  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA: lv_number  TYPE cl_numberrange_runtime=>nr_number,
          lv_specid  TYPE zspec_flex-specid,
          lv_num_str TYPE string.

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).

      IF <entity>-specid IS INITIAL.
        TRY.
            cl_numberrange_runtime=>number_get(
              EXPORTING
                nr_range_nr = '01'
                object      = 'ZNR_SPECF'
              IMPORTING
                number      = lv_number
            ).

            lv_num_str = lv_number.
            IF strlen( lv_num_str ) >= 18.
              lv_num_str = lv_num_str+2(18).
            ENDIF.
            CONDENSE lv_num_str NO-GAPS.
            lv_specid = |SF{ lv_num_str }|.

            APPEND VALUE #(
              %cid      = <entity>-%cid
              %key      = VALUE #( specid = lv_specid )
              %is_draft = <entity>-%is_draft
            ) TO mapped-specflex.

          CATCH cx_number_ranges INTO DATA(lx_nr).
            APPEND VALUE #( %cid = <entity>-%cid ) TO failed-specflex.
            APPEND VALUE #( %cid = <entity>-%cid
                            %msg = new_message_with_text(
                            severity = if_abap_behv_message=>severity-error
                            text     = |Number Range Error: { lx_nr->get_text( ) }| )
                          ) TO reported-specflex.
        ENDTRY.

      ELSE.
        APPEND VALUE #(
          %cid      = <entity>-%cid
          %key      = VALUE #( specid = <entity>-specid )
          %is_draft = <entity>-%is_draft
        ) TO mapped-specflex.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

  METHOD setdeletionflag.
    MODIFY ENTITIES OF zr_spec_flex IN LOCAL MODE
      ENTITY specflex
        UPDATE FIELDS ( delflag )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky delflag = abap_true ) ).
    READ ENTITIES OF zr_spec_flex IN LOCAL MODE
      ENTITY specflex ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_specs).
    result = VALUE #( FOR spec IN lt_specs ( %tky = spec-%tky %param = spec ) ).
  ENDMETHOD.

  METHOD removedeletionflag.
    MODIFY ENTITIES OF zr_spec_flex IN LOCAL MODE
      ENTITY specflex
        UPDATE FIELDS ( delflag )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky delflag = abap_false ) ).
    READ ENTITIES OF zr_spec_flex IN LOCAL MODE
      ENTITY specflex ALL FIELDS WITH CORRESPONDING #( keys ) RESULT DATA(lt_specs).
    result = VALUE #( FOR spec IN lt_specs ( %tky = spec-%tky %param = spec ) ).
  ENDMETHOD.


  METHOD uploadexcel.

    DATA: lv_xstring TYPE xstring,
          lo_xlsx    TYPE REF TO cl_fdt_xl_spreadsheet.

    DATA lt_col_names TYPE TABLE OF string.
    DATA lv_col_idx TYPE i.
    DATA lv_row_counter TYPE i.
    DATA lv_item_counter TYPE n LENGTH 5.
    DATA lv_data_col TYPE i.
    DATA lv_check_idx TYPE i.
    DATA lv_row_empty TYPE abap_bool.
    DATA lv_header_cid TYPE string.
    DATA lv_attr_name TYPE string.

    READ TABLE keys INTO DATA(ls_key) INDEX 1.
    IF sy-subrc <> 0 OR ls_key-%param-file_content IS INITIAL.
      APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'No file content received.' ) ) TO reported-specflex.
      RETURN.
    ENDIF.
    lv_xstring = ls_key-%param-file_content.

    TRY.
        lo_xlsx = NEW cl_fdt_xl_spreadsheet( document_name = 'upload.xlsx' xdocument = lv_xstring ).
      CATCH cx_root INTO DATA(lx_parse).
        APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = |Parse Error: { lx_parse->get_text( ) }| ) ) TO reported-specflex.
        RETURN.
    ENDTRY.

    lo_xlsx->if_fdt_doc_spreadsheet~get_worksheet_names( IMPORTING worksheet_names = DATA(lt_sheets) ).
    IF lt_sheets IS INITIAL.
      APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'No worksheets found.' ) ) TO reported-specflex.
      RETURN.
    ENDIF.

    DATA lv_sheet TYPE string.
    IF lines( lt_sheets ) >= 2.
      lv_sheet = lt_sheets[ 2 ].
    ELSE.
      lv_sheet = lt_sheets[ 1 ].
    ENDIF.
    DATA(lo_table) = lo_xlsx->if_fdt_doc_spreadsheet~get_itab_from_worksheet( lv_sheet ).

    FIELD-SYMBOLS <lt_data> TYPE STANDARD TABLE.
    ASSIGN lo_table->* TO <lt_data>.
    IF <lt_data> IS NOT ASSIGNED OR lines( <lt_data> ) = 0.
      APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'The uploaded file is empty.' ) ) TO reported-specflex.
      RETURN.
    ENDIF.

    DATA lt_header_create TYPE TABLE FOR CREATE zr_spec_flex\\specflex.
    DATA lt_item_create   TYPE TABLE FOR CREATE zr_spec_flex\\specflex\_items.

    READ TABLE <lt_data> ASSIGNING FIELD-SYMBOL(<header_row>) INDEX 1.
    IF sy-subrc <> 0.
      APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'Cannot read header row.' ) ) TO reported-specflex.
      RETURN.
    ENDIF.

    CLEAR lt_col_names.
    lv_col_idx = 1.
    DO.
      ASSIGN COMPONENT lv_col_idx OF STRUCTURE <header_row> TO FIELD-SYMBOL(<col_name>).
      IF sy-subrc <> 0. EXIT. ENDIF.
      APPEND CONV string( <col_name> ) TO lt_col_names.
      lv_col_idx = lv_col_idx + 1.
    ENDDO.

    IF lines( lt_col_names ) < 3.
      APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'Need at least 3 columns.' ) ) TO reported-specflex.
      RETURN.
    ENDIF.

    DATA: lv_col_row_id   TYPE i VALUE 0,
          lv_col_attr_id  TYPE i VALUE 0,
          lv_col_attr_val TYPE i VALUE 0,
          lv_col_desc     TYPE i VALUE 0.
    DATA lv_upper_col TYPE string.

    lv_col_idx = 1.
    LOOP AT lt_col_names INTO lv_attr_name.
      lv_upper_col = to_upper( lv_attr_name ).
      CONDENSE lv_upper_col NO-GAPS.
      IF lv_upper_col = 'ROW_ID' OR lv_upper_col = 'ROWID' OR lv_upper_col = 'ROW'.
        lv_col_row_id = lv_col_idx.
      ELSEIF lv_upper_col = 'ATTRIBUTE_ID' OR lv_upper_col = 'ATTRIBUTEID' OR lv_upper_col = 'ATTR_ID'.
        lv_col_attr_id = lv_col_idx.
      ELSEIF lv_upper_col = 'ATTRIBUTE_VALUE' OR lv_upper_col = 'ATTRIBUTEVALUE' OR lv_upper_col = 'ATTR_VALUE' OR lv_upper_col = 'VALUE'.
        lv_col_attr_val = lv_col_idx.
      ELSEIF lv_upper_col = 'DESCRIPTION' OR lv_upper_col = 'SPEC_DESCRIPTION' OR lv_upper_col = 'SPECDESCRIPTION'.
        lv_col_desc = lv_col_idx.
      ENDIF.
      lv_col_idx = lv_col_idx + 1.
    ENDLOOP.

    IF lv_col_row_id = 0 OR lv_col_attr_id = 0 OR lv_col_attr_val = 0.
      APPEND VALUE #( %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error text = 'Required columns not found. Need: ROW_ID, ATTRIBUTE_ID, ATTRIBUTE_VALUE.' ) ) TO reported-specflex.
      RETURN.
    ENDIF.

    TYPES: BEGIN OF ty_item_data,
             attribute_id    TYPE string,
             attribute_value TYPE string,
           END OF ty_item_data.
    TYPES: BEGIN OF ty_spec_group,
             row_id      TYPE string,
             description TYPE string,
             items       TYPE STANDARD TABLE OF ty_item_data WITH EMPTY KEY,
           END OF ty_spec_group.
    DATA lt_spec_groups TYPE STANDARD TABLE OF ty_spec_group WITH EMPTY KEY.

    DATA lv_row_id    TYPE string.
    DATA lv_attr_id   TYPE string.
    DATA lv_attr_val  TYPE string.
    DATA lv_desc_val  TYPE string.
    DATA lv_dot_pos   TYPE i.
    DATA lv_spec_desc TYPE string.

    LOOP AT <lt_data> ASSIGNING FIELD-SYMBOL(<row>).
      IF sy-tabix = 1. CONTINUE. ENDIF.

      ASSIGN COMPONENT lv_col_row_id OF STRUCTURE <row> TO FIELD-SYMBOL(<fld_row_id>).
      IF sy-subrc <> 0 OR <fld_row_id> IS INITIAL. CONTINUE. ENDIF.
      lv_row_id = CONV string( <fld_row_id> ).
      CONDENSE lv_row_id NO-GAPS.
      lv_dot_pos = find( val = lv_row_id sub = '.' ).
      IF lv_dot_pos > 0. lv_row_id = lv_row_id+0(lv_dot_pos). ENDIF.

      ASSIGN COMPONENT lv_col_attr_id OF STRUCTURE <row> TO FIELD-SYMBOL(<fld_attr_id>).
      IF sy-subrc <> 0 OR <fld_attr_id> IS INITIAL. CONTINUE. ENDIF.
      lv_attr_id = CONV string( <fld_attr_id> ).

      ASSIGN COMPONENT lv_col_attr_val OF STRUCTURE <row> TO FIELD-SYMBOL(<fld_attr_val>).
      IF sy-subrc = 0.
        lv_attr_val = CONV string( <fld_attr_val> ).
      ELSE.
        CLEAR lv_attr_val.
      ENDIF.

      CLEAR lv_desc_val.
      IF lv_col_desc > 0.
        ASSIGN COMPONENT lv_col_desc OF STRUCTURE <row> TO FIELD-SYMBOL(<fld_desc>).
        IF sy-subrc = 0 AND <fld_desc> IS NOT INITIAL.
          lv_desc_val = CONV string( <fld_desc> ).
        ENDIF.
      ENDIF.

      READ TABLE lt_spec_groups ASSIGNING FIELD-SYMBOL(<group>) WITH KEY row_id = lv_row_id.
      IF sy-subrc <> 0.
        APPEND INITIAL LINE TO lt_spec_groups ASSIGNING <group>.
        <group>-row_id = lv_row_id.
        IF lv_desc_val IS NOT INITIAL. <group>-description = lv_desc_val. ENDIF.
      ENDIF.

      APPEND VALUE ty_item_data( attribute_id = lv_attr_id attribute_value = lv_attr_val ) TO <group>-items.
    ENDLOOP.

    lv_row_counter = 0.
    LOOP AT lt_spec_groups ASSIGNING FIELD-SYMBOL(<spec_grp>).
      lv_row_counter = lv_row_counter + 1.
      lv_header_cid = |UPLOAD_H_{ lv_row_counter }|.

      IF <spec_grp>-description IS NOT INITIAL.
        lv_spec_desc = <spec_grp>-description.
      ELSE.
        lv_spec_desc = |Flex Spec Row { <spec_grp>-row_id }|.
      ENDIF.

      APPEND VALUE #( %cid = lv_header_cid %is_draft = if_abap_behv=>mk-off specdescription = CONV #( lv_spec_desc ) ) TO lt_header_create.

      APPEND INITIAL LINE TO lt_item_create ASSIGNING FIELD-SYMBOL(<item_cba>).
      <item_cba>-%cid_ref  = lv_header_cid.
      <item_cba>-%is_draft = if_abap_behv=>mk-off.

      lv_item_counter = '00000'.
      LOOP AT <spec_grp>-items INTO DATA(ls_item).
        lv_item_counter = lv_item_counter + 1.
        APPEND VALUE #( %cid = |UPLOAD_I_{ lv_row