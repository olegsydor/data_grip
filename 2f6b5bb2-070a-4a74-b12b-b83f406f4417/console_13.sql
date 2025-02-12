create table tbloom as
    insert into tbloom
select (random() * 1000000)::int as i1,
       (random() * 1000000)::int as i2,
       (random() * 1000000)::int as i3,
       (random() * 1000000)::int as i4,
       (random() * 1000000)::int as i5,
       (random() * 1000000)::int as i6
from
    generate_series(1, 100000000);

select *
from tbloom
where true
--   and i2 = 576628
--   and i5 = 730493
  and i3 = 40;

create
-- drop
    index bloomidx
    on tbloom using bloom (i1, i2, i3, i4, i5, i6);