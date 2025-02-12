create table tbloom as
select (random() * 1000000)::int as i1,
       (random() * 1000000)::int as i2,
       (random() * 1000000)::int as i3,
       (random() * 1000000)::int as i4,
       (random() * 1000000)::int as i5,
       (random() * 1000000)::int as i6
from
    generate_series(1, 10000000);

select *
from tbloom
where i2 = 576628
  and i5 = 730493;

create index bloomidx on tbloom using bloom (i1, i2, i3, i4, i5, i6);