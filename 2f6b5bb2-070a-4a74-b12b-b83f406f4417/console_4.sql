select ct.name, fi.rating, count(*) * 1.00 / min(cat.cntg)
from film.film fi
         join film.film_category fc on fc.film_id = fi.film_id
         join film.category ct on ct.category_id = fc.category_id
         left join lateral (select count(*) as cntg
                            from film.film fii
                                     join film.film_category fci on fci.film_id = fii.film_id
                                     join film.category cti on cti.category_id = fci.category_id
                            where cti.category_id = ct.category_id
                            limit 1) cat on true
group by ct.name, fi.rating;


-- Your SQL here
set search_path to film
with ca as (select cat.category_id, count(*) as cntg
            from film fl
                     join film_category fc on fc.film_id = fl.film_id
                     join category cat on cat.category_id = fc.category_id
            group by cat.category_id)
select ct.name                                                        as category_name,
       fi.rating                                                      as film_rating,
       to_char(round(count(*) * 1.00 / min(ca.cntg), 3), 'FM990.000')::numeric as percentage
from film fi
         join film_category fc on fc.film_id = fi.film_id
         join category ct on ct.category_id = fc.category_id
         join ca on ca.category_id = ct.category_id
group by ct.name, fi.rating
order by 1;
