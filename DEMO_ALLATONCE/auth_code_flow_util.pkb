create or replace package body AUTH_CODE_FLOW_UTIL as

    cursor c_tkn(b_name varchar2)
    is
      select seq_id
      from   apex_collections
      where  collection_name = c_token_collection_name
      and    c001 = b_name;

    procedure callback(code varchar2, state varchar2, error varchar2)
    is
        l_redirect_url  varchar2(2000);
    begin
        l_redirect_url := c_base_uri||'f?p=125:1:';--||state||'::::P1_ERROR,P1_CODE:'||error||','||code;
    --owa_util.redirect_url(l_redirect_url, true);
    -- de owa_util.redirect_url werkt niet, dus dan maar zo:
    htp.print('<body onload="document.location.href='''||l_redirect_url||'''"></body>');
    end callback;

  function get_html_redirect(code in varchar2, state in varchar2, error in varchar2)
    return varchar2
  is
    l_redirect_url varchar2(2000);
    l_session      varchar2(1000);
    l_name         varchar2(100);
  begin
    l_name := substr(state,1,instr(state,';')-1);
    l_session := substr(state,instr(state,';')+1);
    l_redirect_url := '../../f?p=125:1:'||l_session||':EXCHANGE:YES::P1_ERROR,P1_CODE,P1_NAME:'||error||','||code||','||l_name;
    return '<body onload="document.location.href='''||l_redirect_url||'''"></body>';
  end get_html_redirect;

  procedure authorize(p_name in varchar2)
  is
    l_authorization_url varchar2(1000);
    l_client_id         varchar2(1000);
    l_scope             varchar2(1000);
    l_extra_parameters  varchar2(1000);
  begin
    select authorization_url
    ,      client_id
    ,      scope
    ,      extra_parameters
    into   l_authorization_url
    ,      l_client_id
    ,      l_scope
    ,      l_extra_parameters
    from   auth_code_flow
    where  name = p_name;
    apex_util.redirect_url(
      p_url => l_authorization_url||'?' || 
                 'client_id='     || l_client_id                               || chr(38) || 
                 'response_type=' || 'code'                                    || chr(38) || 
                 'redirect_uri='  || apex_util.url_encode(c_callback_uri)      || chr(38) || 
                 'scope='         || l_scope                                   || chr(38) || 
                 'state='         || p_name || ';' || v('APP_SESSION')         ||
                 case when l_extra_parameters is not null then '&'||l_extra_parameters else '' end
    );
  end authorize;

  procedure store_in_session(p_name          in varchar2
                            ,p_access_token  in varchar2
                            ,p_token_type    in varchar2
                            ,p_refresh_token in varchar2
                            ,p_expires_in    in number
                            ,p_clob          in clob)
  is
    l_seq_id number;
  begin
    if not apex_collection.collection_exists(c_token_collection_name)
    then
      apex_collection.create_collection(c_token_collection_name);
    end if;
    open c_tkn(p_name);
    fetch c_tkn into l_seq_id;
    close c_tkn;
    apex_debug.message('seq id = '||l_seq_id);
    if l_seq_id is null
    then
      apex_collection.add_member(p_collection_name => c_token_collection_name
                                ,p_c001            => p_name
                                ,p_c002            => p_access_token
                                ,p_c003            => p_token_type
                                ,p_c004            => p_refresh_token
                                ,p_n001            => p_expires_in
                                ,p_d001            => sysdate
                                ,p_clob001         => p_clob);
    else
      apex_collection.update_member(p_collection_name => c_token_collection_name
                                   ,p_seq             => l_seq_id
                                   ,p_c001            => p_name
                                   ,p_c002            => p_access_token
                                   ,p_c003            => p_token_type
                                   ,p_c004            => p_refresh_token
                                   ,p_n001            => p_expires_in
                                   ,p_d001            => sysdate
                                   ,p_clob001         => p_clob);
      apex_debug.message('member updated with token '||p_access_token);
    end if;
  end store_in_session;

  procedure update_in_session(p_name     in varchar2
                             ,p_field    in number
                             ,p_value    in varchar2)
  is
    l_seq_id number;
  begin
    open c_tkn(p_name);
    fetch c_tkn into l_seq_id;
    close c_tkn;
    if l_seq_id is not null
    then
      apex_collection.update_member_attribute(p_collection_name => c_token_collection_name
                                             ,p_seq             => l_seq_id
                                             ,p_attr_number     => p_field
                                             ,p_attr_value      => p_value);
    end if;
  end update_in_session;

  procedure exchange_code_for_token(p_name in varchar2, p_code in varchar2)
  is
    l_clob          clob;
    l_postdata      clob;
    l_client_id     varchar2(1000);
    l_client_secret varchar2(1000);
    l_token_url     varchar2(1000);
    l_redirect_url  varchar2(2000);
    l_token         varchar2(2000);
    l_refresh_token varchar2(2000);
    l_token_type    varchar2(100);
    l_expires_in    number;
    l_username      varchar2(1000);
    l_additional_info varchar2(1000);
  begin
    select token_url
    ,      client_id
    ,      client_secret
    into   l_token_url
    ,      l_client_id
    ,      l_client_secret
    from   auth_code_flow
    where  name = p_name;
    if p_code is not null
    then
      l_postdata := 'grant_type=authorization_code'                     ||chr(38)||
                    'code='||p_code                                       ||chr(38)||
                    'redirect_uri='||c_callback_uri                       ||chr(38)||
--                    'redirect_uri='||apex_util.url_encode(callback_uri) ||chr(38)||
                    'client_id='||l_client_id                             ||chr(38)||
                    'client_secret='||l_client_secret;
      apex_web_service.g_request_headers(1).name := 'Content-Type';
      apex_web_service.g_request_headers(1).value := 'application/x-www-form-urlencoded'; 
      l_clob := apex_web_service.make_rest_request(
        p_url         => l_token_url
      , p_http_method => 'POST'
      , p_body        => l_postdata
      );
      apex_json.parse(l_clob);
      l_token := apex_json.get_varchar2('access_token');
      l_refresh_token := apex_json.get_varchar2('refresh_token');
      l_token_type := apex_json.get_varchar2('token_type');
      l_expires_in := apex_json.get_number('expires_in');
      -- store data in collection
      store_in_session(p_name => p_name
                      ,p_access_token => l_token
                      ,p_token_type => l_token_type
                      ,p_refresh_token => l_refresh_token
                      ,p_expires_in => l_expires_in
                      ,p_clob => l_clob);
      l_username := collect_username(p_name);
      update_in_session(p_name  => p_name
                       ,p_field => 5
                       ,p_value => l_username);
      apex_util.set_session_state('P1_'||upper(p_name)||'_LOGIN'
                                 ,l_username);
      l_additional_info := collect_additional_info(p_name);
      update_in_session(p_name  => p_name
                       ,p_field => 6
                       ,p_value => l_additional_info);
    end if;
  end exchange_code_for_token;

  function get_access_token(p_name in varchar2)
    return varchar2
  is
    cursor c_tkn
    is
      select c002
      from   apex_collections
      where  collection_name = c_token_collection_name
      and    c001 = p_name;
    l_access_token varchar2(2000);
  begin
    open c_tkn;
    fetch c_tkn into l_access_token;
    close c_tkn;
    return l_access_token;
  end get_access_token;

  function collect_username(p_name in varchar2)
    return varchar2
  is
    l_clob           clob;
    l_user_info_url  varchar2(1000);
    l_username_field varchar2(1000);
    l_username       varchar2(1000);
  begin
    select user_info_url
    ,      username_field
    into   l_user_info_url
    ,      l_username_field
    from   auth_code_flow
    where  name = p_name;
    apex_web_service.g_request_headers(1).name := 'Authorization';
    apex_web_service.g_request_headers(1).value := 'Bearer ' || get_access_token(p_name);
    l_clob := apex_web_service.make_rest_request(
      p_url         => l_user_info_url
    , p_http_method => 'GET'
    );
      apex_debug.message(l_clob);
    apex_json.parse(l_clob);
    l_username := apex_json.get_varchar2(l_username_field);
    return l_username;
  end collect_username;

  function collect_additional_info(p_name in varchar2)
    return varchar2
  is
    l_clob                  clob;
    l_additional_info_url   varchar2(1000);
    l_additional_info_field varchar2(1000);
    l_additional_info       varchar2(1000);
  begin
    select additional_info_url
    ,      additional_info_field
    into   l_additional_info_url
    ,      l_additional_info_field
    from   auth_code_flow
    where  name = p_name;
    if l_additional_info_url is not null
    then
      apex_web_service.g_request_headers(1).name := 'Authorization';
      apex_web_service.g_request_headers(1).value := 'Bearer ' || get_access_token(p_name);
      l_clob := apex_web_service.make_rest_request(
        p_url         => l_additional_info_url
      , p_http_method => 'GET'
      );
      apex_debug.message(l_clob);
      apex_json.parse(l_clob);
      l_additional_info := apex_json.get_varchar2(l_additional_info_field);
    end if;
    return l_additional_info;
  end collect_additional_info;
end AUTH_CODE_FLOW_UTIL;
/