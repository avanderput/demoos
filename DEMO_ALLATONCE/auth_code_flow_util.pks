create or replace package AUTH_CODE_FLOW_UTIL as
  base_uri constant varchar2(200) := 'https://mrdwyhtiuwqtluj-dbkwintup01.adb.eu-frankfurt-1.oraclecloudapps.com/ords/';
  callback_uri  constant varchar2(200) := base_uri||'aw2020/acf/callback';
  client_id     constant varchar2(200) := 'c6ca68254dcc4387ac2254bca79b96b6';
  client_secret constant varchar2(200) := '5c5acc6548ec40d0b68ce86188c8f892';
  token_collection_name constant varchar2(30) := 'TOKENS';
  procedure callback(code varchar2, state varchar2, error varchar2);
  function get_html_redirect(code in varchar2, state in varchar2, error in varchar2) return varchar2;
  procedure authorize;
  procedure exchange_code_for_token(code in varchar2);
  function get_access_token return varchar2;
end AUTH_CODE_FLOW_UTIL;
/