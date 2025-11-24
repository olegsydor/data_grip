select :n,
       case
           when :n % 12 in (0, 2, 5, 7, 10) then 'black'
           else 'white' end as res
