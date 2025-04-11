create or replace procedure DECOMPOSE_JSON(l_values apex_json.t_values)
as
  c_coll constant varchar2(100) := 'AUTHENTICATION_JSON';
  l_idx varchar2(32767);
begin
  if not apex_collection.collection_exists(c_coll)
  then
    apex_collection.create_collection(c_coll);
  end if;
  l_idx := l_values.first;
  while l_idx is not null
  loop
      apex_collection.add_member(p_collection_name => c_coll
                                ,p_c001            => l_idx
                                ,p_c002            => l_values(l_idx).varchar2_value
                                ,p_c003            => apex_string.join(l_values(l_idx).object_members,';')
                                ,p_c004            => l_values(l_idx).kind
                                ,p_n001            => l_values(l_idx).number_value
                                ,p_d001            => sysdate
                                ,p_clob001         => l_values(l_idx).clob_value
                                );
    l_idx := l_values.next(l_idx);
  end loop;
exception
  when others then
      apex_collection.add_member(p_collection_name => c_coll
                                ,p_c001            => sqlerrm
                                ,p_d001            => sysdate
                                );
end DECOMPOSE_JSON;
/