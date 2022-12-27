*&---------------------------------------------------------------------*
*& Report zwf_get_attachments
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zwf_get_attachments.

DATA: user_data TYPE soudatai1.
DATA: folder_content    TYPE STANDARD TABLE OF sofolenti1,wa_folder_content LIKE sofolenti1.
DATA: attachment_list    TYPE STANDARD TABLE OF soattlsti1 WITH HEADER LINE,wa_attachment_list LIKE soattlsti1.
DATA: contents_hex TYPE STANDARD TABLE OF solix.
DATA: buffer TYPE xstring.
DATA: lo_pdfobj    TYPE REF TO if_fp_pdf_object VALUE IS INITIAL, exc TYPE REF TO cx_root, xslt_message TYPE string.
DATA: input_length TYPE i.
DATA: lt_attach type standard table of swr_object.

    user_data-userid = 'I834429'.

*This fm will read the folder details in the sap inbox for the particular user id.
CALL FUNCTION 'SO_USER_READ_API1'
  EXPORTING
    prepare_for_folder_access = 'X'
  IMPORTING
    user_data                 = user_data
  EXCEPTIONS
    user_not_exist            = 1
    parameter_error           = 2
    x_error                   = 3
    OTHERS                    = 4.
IF sy-subrc <> 0.
  MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.

*This fm will read the folder content present in the sap inbox folder.
CALL FUNCTION 'SO_FOLDER_READ_API1'
  EXPORTING
    folder_id                  = user_data-inboxfol
  TABLES
    folder_content             = folder_content
  EXCEPTIONS
    folder_not_exist           = 1
    operation_no_authorization = 2
    x_error                    = 3
    OTHERS                     = 4.
IF sy-subrc <> 0.
  MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.

CALL FUNCTION 'SAP_WAPI_GET_ATTACHMENTS'
  EXPORTING
    workitem_id           = '000000148002'
    user                  = 'I834429'
*    language              = SY-LANGU
*    comment_semantic_only = space
*  IMPORTING
*    return_code           =
  TABLES
    attachments           = lt_attach
*    message_lines         =
*    message_struct        =
  .
*CLEAR wa_folder_content.
*SORT folder_content BY obj_name obj_descr creat_date creat_time.
*
*READ TABLE folder_content INTO wa_folder_content WITH KEY obj_descr = 'Office Document'.
*
*IF NOT wa_folder_content IS INITIAL.

if lt_attach is not initial.
    READ table lt_attach into DATA(wa) INDEX 1.
ENDIF.

CONDENSE wa-object_id.

DATA: DOC_DATA TYPE TABLE OF SOFOLENTI1 with HEADER LINE.

*This fm will read the attachment present in the mail.
  CALL FUNCTION 'SO_DOCUMENT_READ_API1'
    EXPORTING
      document_id           = 'FOL42000000000004EXT47000000000052 '
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

WRITE buffer.

*ENDIF.
