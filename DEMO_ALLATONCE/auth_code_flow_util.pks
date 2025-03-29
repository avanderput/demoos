create or replace package AUTH_CODE_FLOW_UTIL as
  c_base_uri constant varchar2(200) := 'https://mrdwyhtiuwqtluj-dbkwintup01.adb.eu-frankfurt-1.oraclecloudapps.com/ords/';
  c_callback_uri  constant varchar2(200) := c_base_uri||'aw2020/acf/callback';
  c_token_collection_name constant varchar2(30) := 'TOKENS';

  function get_html_redirect(code in varchar2, state in varchar2, error in varchar2) return varchar2;
  procedure authorize(p_name in varchar2);
  procedure exchange_code_for_token(p_name in varchar2, p_code in varchar2);
  function get_access_token(p_name in varchar2) return varchar2;
  function collect_username(p_name in varchar2) return varchar2;
  function collect_additional_info(p_name in varchar2) return varchar2;
end AUTH_CODE_FLOW_UTIL;
/