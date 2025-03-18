create table auth_code_flow(
  id                number generated always as identity not null
, name              varchar2(100) not null
, authorization_url varchar2(1000)
, token_url         varchar2(1000)
, user_info_url     varchar2(1000)
, client_id         varchar2(1000)
, client_secret     varchar2(1000)
, scope             varchar2(1000)
, extra_parameters  varchar2(1000)
, username_field    varchar2(1000)
, additional_info_url varchar2(1000)
, additional_info_field varchar2(1000)
, constraint acw_pk  primary key (id) using index
, constraint acw_uk1 unique (name) using index
);
insert into auth_code_flow(
  name
, authorization_url
, token_url
, user_info_url
, client_id
, client_secret
, scope
, extra_parameters
, username_field)
values(
  'Spotify'
, 'https://accounts.spotify.com/authorize/'
, 'https://accounts.spotify.com/api/token'
, 'https://api.spotify.com/v1/me'
, ''
, ''
, 'user-read-private playlist-read-private'
, ''
, 'display_name');
insert into auth_code_flow(
  name
, authorization_url
, token_url
, user_info_url
, client_id
, client_secret
, scope
, extra_parameters
, username_field
, additional_info_url
, additional_info_field)
values(
  'Jira'
, 'https://auth.atlassian.com/authorize'
, 'https://auth.atlassian.com/oauth/token'
, 'https://api.atlassian.com/me'
, ''
, ''
, 'read:me read:jira-work'
, 'audience=api.atlassian.com&prompt=consent'
, 'name'
, 'https://api.atlassian.com/oauth/token/accessible-resources'
, '[1].id');
insert into auth_code_flow(
  name
, authorization_url
, token_url
, user_info_url
, client_id
, client_secret
, scope
, extra_parameters
, username_field)
values(
  'LinkedIn'
, 'https://www.linkedin.com/oauth/v2/authorization'
, 'https://www.linkedin.com/oauth/v2/accessToken'
, 'https://api.linkedin.com/v2/userinfo'
, ''
, ''
, 'email,profile,openid'
, ''
, 'email');
