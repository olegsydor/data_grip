SELECT e.employee_id,
       e.first_name,
       e.last_name,
       d.department_name,
       e.salary AS old_salary,
       e.salary * (1 + pctIncrease(e.department_id)) AS new_salary
  FROM employees   e,
       departments d
 WHERE e.department_id = d.department_id
 ORDER BY 1;

with dep as (select department_id, department_name, pctIncrease(e.department_id) as incr from departments)
SELECT e.employee_id,
       e.first_name,
       e.last_name,
       d.department_name,
       e.salary              AS old_salary,
       e.salary * (1 + incr) AS new_salary
FROM employees e,
     dep d
WHERE e.department_id = d.department_id
ORDER BY 1;

create table training.users
(
    id   int4 not null
        constraint users_pk primary key,
    info jsonb
);

INSERT INTO training.users (id, info) VALUES
(6, '{
  "name": "Andrew",
  "pets": [
    {
      "name": "Anton",
      "type": "dog"
    },
    {
      "name": "Tom",
      "type": "cat"
    }
  ]
}'::jsonb),

(2, '{
  "name": "Bob",
  "pets": [
    {
      "name": "Goldie",
      "type": "fish"
    }
  ]
}'::jsonb),

(3, '{
  "name": "Charlie",
  "pets": []
}'::jsonb),

(4, '{
  "name": "Diana",
  "pets": [
    {
      "name": "Coco",
      "type": "parrot"
    },
    {
      "name": "Max",
      "type": "dog"
    },
    {
      "name": "Snow",
      "type": "rabbit"
    }
  ]
}'::jsonb);

with base as (select (jsonb_array_elements(info -> 'pets')) ->> 'name' as pets_name, info ->> 'name' as user_name, id
              from training.users)
select left(pets_name, 1)                      as first_letter,
       count(*)                                as pet_count,
       string_agg(distinct user_name, ', ' order by user_name) as user_names
from base
group by left(pets_name, 1)
order by 2 desc, 1 asc;

SELECT
    group_id,
    ARRAY_AGG(col1 ORDER BY col2 ASC) AS ordered_unique_array
FROM (
    SELECT DISTINCT ON (group_id, col1)
        group_id,
        col1,
        col2
    FROM my_table
    ORDER BY group_id, col1, col2 ASC
) sub
GROUP BY group_id;