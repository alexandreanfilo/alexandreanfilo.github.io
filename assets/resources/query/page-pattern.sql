select json as row_data
  from ( select '{'
           :json_object
           || '}' json
         from (select y.*
                 from (select :object.*, rownum rn
                         from (:distinct
                              ) :object
                        where rownum <= (:skip + :take)
                      ) y
              ) x
        where x.rn > :skip
     )