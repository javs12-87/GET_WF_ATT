FUNCTION Z_WF_GET_ATT_OLD.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(USERID) TYPE  SYUNAME OPTIONAL
*"     VALUE(WORKITEMID) TYPE  SWR_STRUCT-WORKITEMID OPTIONAL
*"  EXPORTING
*"     VALUE(PDF_B64) TYPE  STRING
*"----------------------------------------------------------------------
DATA: user_data TYPE soudatai1.
DATA: folder_content    TYPE STANDARD TABLE OF sofolenti1,wa_folder_content LIKE sofolenti1.
DATA: attachment_list    TYPE STANDARD TABLE OF soattlsti1 WITH HEADER LINE,wa_attachment_list LIKE soattlsti1.
DATA: contents_hex TYPE STANDARD TABLE OF solix.
DATA: buffer TYPE xstring.
DATA: lo_pdfobj    TYPE REF TO if_fp_pdf_object VALUE IS INITIAL, exc TYPE REF TO cx_root, xslt_message TYPE string.
DATA: input_length TYPE i.
DATA: lt_attach type standard table of swr_object.

*Set user id for demo
    user_data-userid = userid.

*get details of inbox folder of user userdata-inboxfol (not needed?).
*CALL FUNCTION 'SO_USER_READ_API1'
*  EXPORTING
*    prepare_for_folder_access = 'X'
*  IMPORTING
*    user_data                 = user_data
*  EXCEPTIONS
*    user_not_exist            = 1
*    parameter_error           = 2
*    x_error                   = 3
*    OTHERS                    = 4.
*IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*ENDIF.
*
**Read folder content (not needed?).
*CALL FUNCTION 'SO_FOLDER_READ_API1'
*  EXPORTING
*    folder_id                  = user_data-inboxfol
*  TABLES
*    folder_content             = folder_content
*  EXCEPTIONS
*    folder_not_exist           = 1
*    operation_no_authorization = 2
*    x_error                    = 3
*    OTHERS                     = 4.
*IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*ENDIF.

CALL FUNCTION 'SAP_WAPI_GET_ATTACHMENTS'
  EXPORTING
*    workitem_id           = '000000148002'
    workitem_id           = workitemid
    user                  = userid
  TABLES
    attachments           = lt_attach
  .

*Get documentid from attachment list
if lt_attach is not initial.
    READ table lt_attach into DATA(wa) INDEX 1.
ENDIF.

data(lv_tst) = wa-object_id.

condense lv_tst NO-GAPS.

data lv_tst1 LIKE sofolenti1-doc_id.

lv_tst1 = substring( val = lv_tst  off = 4 ).

DATA: DOC_DATA TYPE TABLE OF SOFOLENTI1 with HEADER LINE.

*This fm will read the attachment present in the mail.
  CALL FUNCTION 'SO_DOCUMENT_READ_API1'
    EXPORTING
      document_id           = lv_tst1
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

*Passing the length of the attachment to a variable
  input_length = doc_data-doc_size.

**This fm will read the attachment and will give in the binary format.
**Add for scenario with multiple attachments?
*  CALL FUNCTION 'SO_ATTACHMENT_READ_API1'
*    EXPORTING
*      attachment_id              = 'FOL42000000000004EXT47000000000052 '
*    TABLES
*      contents_hex               = contents_hex
*    EXCEPTIONS
*      attachment_not_exist       = 1
*      operation_no_authorization = 2
*      parameter_error            = 3
*      x_error                    = 4
*      enqueue_error              = 5
*      OTHERS                     = 6.
*  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*  ENDIF.

*This fm will convert the binary format to xstring format.
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

CALL FUNCTION 'SCMS_BASE64_ENCODE_STR'
        EXPORTING
          input  = buffer
        IMPORTING
          output = pdf_b64.


ENDFUNCTION.
