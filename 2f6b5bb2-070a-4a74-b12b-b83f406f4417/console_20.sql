select *
from
        lateral(
                select regexp_split_to_table(:l_list, ', ') as x)