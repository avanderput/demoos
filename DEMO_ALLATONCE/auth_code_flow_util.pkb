create or replace package body AUTH_CODE_FLOW_UTIL as
    procedure callback(code varchar2, state varchar2, error varchar2)
    is
        l_redirect_url  varchar2(2000);
    begin
        l_redirect_url := base_uri||'f?p=125:1:';--||state||'::::P1_ERROR,P1_CODE:'||error||','||code;
    --owa_util.redirect_url(l_redirect_url, true);
    -- de owa_util.redirect_url werkt niet, dus dan maar zo:
    htp.print('<body onload="document.location.href='''||l_redirect_url||'''"></body>');
    end callback;

  function get_html_redirect(code in varchar2, state in varchar2, error in varchar2)
    return varchar2
  is
    l_redirect_url varchar2(2000);
  begin
    l_redirect_url := '../../f?p=125:1:'||state||'::::P1_ERROR,P1_CODE:'||error||','||code;
    return '<body onload="document.location.href='''||l_redirect_url||'''"></body>';
  end get_html_redirect;

  procedure authorize
  is
  begin
    apex_util.redirect_url(
      p_url => 'https://accounts.spotify.com/authorize/?' || 
                 'client_id='     || client_id                                 || chr(38) || 
                 'response_type=' || 'code'                                    || chr(38) || 
                 'redirect_uri='  || apex_util.url_encode(callback_uri)        || chr(38) || 
                 'scope='         || 'user-read-private playlist-read-private' || chr(38) || 
                 'state='         || v('APP_SESSION')
    );
  end authorize;

  procedure store_in_session(p_access_token  in varchar2
                            ,p_token_type    in varchar2
                            ,p_refresh_token in varchar2
                            ,p_expires_in    in number
                            ,p_clob          in clob)
  is
    cursor c_tkn
    is
      select seq_id
      from   apex_collections
      where  collection_name = token_collection_name
      and    c001 = 'SPOTIFY';
    l_seq_id number;
  begin
    if not apex_collection.collection_exists(token_collection_name)
    then
      apex_collection.create_collection(token_collection_name);
    end if;
    open c_tkn;
    fetch c_tkn into l_seq_id;
    close c_tkn;
    if l_seq_id is null
    then
      apex_collection.add_member(p_collection_name => token_collection_name
                                ,p_c001            => 'SPOTIFY'
                                ,p_c002            => p_access_token
                                ,p_c003            => p_token_type
                                ,p_c004            => p_refresh_token
                                ,p_n001            => p_expires_in
                                ,p_clob001         => p_clob);
    else
      apex_collection.update_member(p_collection_name => token_collection_name
                                   ,p_seq             => l_seq_id
                                   ,p_c001            => 'SPOTIFY'
                                   ,p_c002            => p_access_token
                                   ,p_c003            => p_token_type
                                   ,p_c004            => p_refresh_token
                                   ,p_n001            => p_expires_in
                                   ,p_clob001         => p_clob);
    end if;
  end store_in_session;

  procedure exchange_code_for_token(code in varchar2)
  is
    l_clob          CLOB;
    l_postdata      clob;
    l_redirect_url  varchar2(2000);
    l_token         varchar2(2000);
    l_refresh_token varchar2(2000);
    l_token_type    varchar2(100);
    l_expires_in    number;
  begin
    if code is not null
    then
      l_postdata := 'grant_type=authorization_code'                     ||chr(38)||
                    'code='||code                                       ||chr(38)||
                    'redirect_uri='||callback_uri                       ||chr(38)||
--                    'redirect_uri='||apex_util.url_encode(callback_uri) ||chr(38)||
                    'client_id='||client_id                             ||chr(38)||
                    'client_secret='||client_secret;
      apex_web_service.g_request_headers(1).name := 'Content-Type';
      apex_web_service.g_request_headers(1).value := 'application/x-www-form-urlencoded'; 
      l_clob := apex_web_service.make_rest_request(
        p_url         => 'https://accounts.spotify.com/api/token'
      , p_http_method => 'POST'
      , p_body        => l_postdata
      );
      apex_json.parse(l_clob);
      l_token := apex_json.get_varchar2('access_token');
      l_refresh_token := apex_json.get_varchar2('refresh_token');
      l_token_type := apex_json.get_varchar2('token_type');
      l_expires_in := apex_json.get_number('expires_in');
      -- store data in sty_session_info table
      store_in_session(p_access_token => l_token
                      ,p_token_type => l_token_type
                      ,p_refresh_token => l_refresh_token
                      ,p_expires_in => l_expires_in
                      ,p_clob => l_clob);
    end if;
  end exchange_code_for_token;

  function get_access_token
    return varchar2
  is
    cursor c_tkn
    is
      select c002
      from   apex_collections
      where  collection_name = token_collection_name
      and    c001 = 'SPOTIFY';
    l_access_token varchar2(2000);
  begin
    open c_tkn;
    fetch c_tkn into l_access_token;
    close c_tkn;
    return l_access_token;
  end get_access_token;
end AUTH_CODE_FLOW_UTIL;
/