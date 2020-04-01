with recinto_ref_codes
  as (select rf.rv_abbreviation as abbreviation
           , rf.rv_low_value as rv_low_value
           , rf.rv_domain as rv_domain
        from recinto.v$cg_ref_codes rf
     )
   , cacesso_ref_codes
  as (select rf.rv_abbreviation as abbreviation
           , rf.rv_low_value as rv_low_value
           , rf.rv_domain as rv_domain
        from cacesso.v$cg_ref_codes rf
     )
   , cartao_pessoa
  as (select kss.fnc_concat_all(distinct kss.to_concat_expr(c.identificador ||' - '|| ct.descricao ,'<br/>'||chr(13)||chr(10))) as cartao_desc
           , pe.pessoa_id as pessoa_id
        from cacesso.v$pessoa pe
       inner join cacesso.v$pessoa_cartao pc
          on pc.pessoa_id =  pe.pessoa_id
       inner join cacesso.v$cartao c
          on pc.cartao_id = c.cartao_id
       inner join cacesso.v$cartao_tipo ct
          on c.tipo_id = ct.tipo_id
       where (pc.data_fim is null or pc.data_fim >= sysdate)
         and c.data_cancelamento is null
         and c.data_validade >= sysdate
       group by pe.pessoa_id
     )
   , documento_pessoa
  as (select pd.documento as documento
           , pd.categoria as categoria
           , pd.pessoa_id as pessoa_id
           , pd.data_validade as data_validade
           , pd.tipo_documento_id as tipo_documento_id
           , pd.mopp as mopp
        from cacesso.v$pessoa_documento pd
       where rownum = 1
     )
   , documentos
  as (select kss.fnc_concat_all(kss.to_concat_expr(tdoc.descricao||': '||pdoc.documento, ' | ')) as doctos
           , pdoc.pessoa_id as pessoa_id
        from cacesso.v$pessoa_documento pdoc
       inner join cacesso.v$tipo_documento tdoc
          on tdoc.tipo_documento_id = pdoc.tipo_documento_id
       group by pdoc.pessoa_id
     )
   , empresa
  as (select emp.nome as nome
           , emp.pessoa_id as pessoa_id
           , emp.cnpj_cpf_cuit as cnpj
        from recinto.v$pessoa emp
       inner join recinto.v$cidade c
          on c.cidade_id = emp.cidade_id
     )
 select p.pessoa_id
        , p.nome
        , p.tipo_pessoa_id
        , p.data_nascimento
        , p.pais_id
        , pa.descricao_portugues as pais_nome
        , kss.pkg_string.fnc_formata_cep(p.cep) as cep
        , p.endereco
        , p.complemento
        , p.bairro
        , p.cidade_id
        , c.nome as cidade_nome
        , c.sigla_uf as uf
        , p.tel_celular
        , p.tel_comercial
        , p.tel_residencial
        , p.email
        , replace(replace(p.observacao, CHR(13), ''), CHR(10), ' ') as observacao
        , p.ativo
        , p.autoridade
        , p.aprovado
        , (select nvl(abbreviation, '')
             from recinto_ref_codes rf
            where rf.rv_low_value = p.aprovado
              and rf.rv_domain = 'STATUS.APROVACAO'
        ) as aprovado_desc
        , p.presente
        , p.empresa_id
        , (select nvl(cartao_desc, '')
             from cartao_pessoa c
            where c.pessoa_id = p.pessoa_id
        ) as cartao
        , p.user_insert
        , p.date_insert
        , p.user_update
        , p.date_update
        , (select nvl(doctos, '')
             from documentos d
            where d.pessoa_id = p.pessoa_id
        ) as doctos
        , (select abbreviation
             from cacesso_ref_codes rf
            where rf.rv_domain = 'PESSOA.TIPO_ID'
              and rf.rv_low_value = p.tipo_pessoa_id
        ) as tipo_pessoa
        , (select nvl(nome, '')
             from empresa e
            where e.pessoa_id = p.empresa_id
        ) as empresa_nome
        , (select nvl(cnpj, '')
             from empresa e
            where e.pessoa_id = p.empresa_id
        ) as empresa_cnpj
        -- biometria
        , (select case when count(1) > 0 then 1 else 0 end
             from cacesso.v$pessoa_digital
            where pessoa_id = p.pessoa_id
         ) as tem_bio
         -- foto
         , (select case when count(1) > 0 then 1 else 0 end
              from cacesso.v$pessoa_foto
             where pessoa_id = p.pessoa_id
           ) as tem_foto
         -- doc
         , (select case when count(1) > 0 then 1 else 0 end
              from cacesso.v$pessoa_documento
             where pessoa_id = p.pessoa_id
           ) as tem_doc
         -- cartão
         , (select case when count(1) > 0 then 1 else 0 end
              from cacesso.v$pessoa_cartao
             where data_fim is null 
               and pessoa_id = p.pessoa_id
           ) as tem_cartao
         , (select documento
              from documento_pessoa pd
             where pd.tipo_documento_id = 1
               and pd.pessoa_id = p.pessoa_id
           ) as cpf
         , (select documento
              from documento_pessoa pd
             where pd.tipo_documento_id = 2 -- cnh
               and pd.pessoa_id = p.pessoa_id
           ) as cnh_numero
         , (select categoria
              from documento_pessoa pd
             where pd.tipo_documento_id = 2 -- cnh
               and pd.pessoa_id = p.pessoa_id
           ) as cnh_categoria
         , (select data_validade
              from documento_pessoa pd
             where pd.tipo_documento_id = 2 -- cnh
               and pd.pessoa_id = p.pessoa_id
           ) as cnh_validade
         , (select nvl(pd.mopp,0)
              from documento_pessoa pd
             where pd.tipo_documento_id = 2 -- cnh
               and pd.pessoa_id = p.pessoa_id
           ) as cnh_moop
         , (select max(to_char(l.descricao)) keep(dense_rank first order by l.log_id desc) as descricao
              from cacesso_log.v$log l
             inner join cacesso_log.v$pessoa pl
                on pl.log_id = l.log_id
             where l.evento_id in (10,11)
               and pl.pessoa_id = p.pessoa_id
               and p.aprovado != 0
           ) as motivo_aprovado
      from cacesso.v$pessoa p
     inner join recinto.v$cidade c
        on c.cidade_id = p.cidade_id
     inner join cep.v$pais pa
        on pa.pais_id = c.pais_id