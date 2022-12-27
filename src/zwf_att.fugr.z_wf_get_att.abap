FUNCTION z_wf_get_att.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(USERID) TYPE  SYUNAME OPTIONAL
*"     VALUE(WORKITEMID) TYPE  SWR_STRUCT-WORKITEMID OPTIONAL
*"  EXPORTING
*"     VALUE(PDF_B64) TYPE  STRING
*"----------------------------------------------------------------------
  DATA: attachment_list    TYPE STANDARD TABLE OF soattlsti1 WITH HEADER LINE.
  DATA: contents_hex TYPE STANDARD TABLE OF solix.
  DATA: buffer TYPE xstring.
  DATA: input_length TYPE i.
  DATA: lt_attach TYPE STANDARD TABLE OF swr_object.
  DATA: ls_doc_id LIKE sofolenti1-doc_id.
  DATA: doc_data TYPE TABLE OF sofolenti1 WITH HEADER LINE.


  CALL FUNCTION 'SAP_WAPI_GET_ATTACHMENTS'
    EXPORTING
*     workitem_id = '000000148002'
      workitem_id = workitemid
*      user        = userid
    TABLES
      attachments = lt_attach.

*   Get documentid from attachment list
  IF lt_attach IS NOT INITIAL.
    READ TABLE lt_attach INTO DATA(wa) INDEX 1.

    DATA(ls_id) = wa-object_id.

    CONDENSE ls_id NO-GAPS.

    ls_doc_id = substring( val = ls_id  off = 4 ).


*   Read attachment.
    CALL FUNCTION 'SO_DOCUMENT_READ_API1'
      EXPORTING
        document_id           = ls_doc_id
      IMPORTING
        document_data         = doc_data
      TABLES
        attachment_list       = attachment_list
        contents_hex          = contents_hex
      EXCEPTIONS
        document_id_not_exist = 1
                                operation_no_authorization= 2
        x_error               = 3
        OTHERS                = 4.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

*   Get file length from doc data header
    input_length = doc_data-doc_size.

*   convert binary to xstring.
    CALL FUNCTION 'SCMS_BINARY_TO_XSTRING'
      EXPORTING
        input_length = input_length
      IMPORTING
        buffer       = buffer
      TABLES
        binary_tab   = contents_hex
      EXCEPTIONS
        failed       = 1
        OTHERS       = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

*   Convert xstring to b64 string
    CALL FUNCTION 'SCMS_BASE64_ENCODE_STR'
      EXPORTING
        input  = buffer
      IMPORTING
        output = pdf_b64.

  ENDIF.


ENDFUNCTION.
