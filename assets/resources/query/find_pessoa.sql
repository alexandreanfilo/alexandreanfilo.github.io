declare
   function find_pessoa
      return varchar2 as
         v_column varchar2(30);
   begin
      select p.nome
        into v_column
        from cacesso.v$pessoa p
       where p.pessoa_id = 1107;
    
      return v_column;
   end;
begin
   dbms_output.enable();
   DBMS_OUTPUT.PUT_LINE(find_pessoa());
end;