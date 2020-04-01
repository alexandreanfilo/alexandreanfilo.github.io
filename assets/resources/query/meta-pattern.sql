select x.*
  from (select y.*
           from (select :object.*, rownum rn
                   from (:query) :object
                  where rownum <= 0
         ) y
      ) x
where x.rn > 0