@EndUserText.label: 'Flex Spec Excel Upload Parameter'
define abstract entity ZA_FLEX_UPLOAD
{
  file_content : abap.rawstring(0);
  file_name    : abap.char(128);
}