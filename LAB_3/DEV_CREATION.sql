-- create the first schema
create user c##dev_user identified by dev_password;
grant connect, resource, create view, create procedure to c##dev_user;
-- create a table in the c##dev_user schema that does not exist in the c##prod_user schema
create table c##dev_user.departments (
  id number primary key,
  name varchar2(50),
  manager_id number
);

drop table c##dev_user.mytable1;
create table c##dev_user.mytable1 (
    id number,
    name varchar2(50),
    second_name varchar2(50),
    indexed_col number
);

select * from ALL_INDEXES where TABLE_OWNER like '%C##%';

create unique index index4_test on c##dev_user.mytable1(indexed_col);
create index id2_test on c##dev_user.mytable1(second_name);

-- create a table in the c##dev_user schema
create table c##dev_user.employee (
  id number primary key,
  name varchar2(50),
  department_id number(4),
  salary number,
  constraint fk_department_id foreign key (department_id) references c##dev_user.departments(id)
);

alter table c##dev_user.departments
add constraint fk_manager_id
foreign key (manager_id)
references c##dev_user.employee (id);

create table c##dev_user.customers (
  customer_id number(10) primary key,
  customer_name varchar2(50) not null,
  customer_address varchar2(100) not null,
  customer_phone number(10) not null
);

-- in the c##dev_user schema:
create table c##dev_user.products (
  product_id   number primary key,
  product_name varchar2(50) not null,
  price        number not null,
  quantity     number not null
);

create table c##dev_user.orders (
  order_id number primary key,
  customer_id number,
  order_date date,
  foreign key (customer_id) references c##dev_user.customers(customer_id)
);

create table c##dev_user.order_details (
  order_detail_id number primary key,
  order_id number,
  product_id number,
  quantity number,
  foreign key (order_id) references c##dev_user.orders(order_id),
  foreign key (product_id) references c##dev_user.products(product_id)
);

drop procedure c##dev_user.write_employees;

create or replace procedure c##dev_user.write_employees (
    employee_name_a in varchar2,
    employee_name_b in varchar2
)
as
begin
    dbms_output.put_line(employee_name_a || ' and ' || employee_name_b);
end;

create or replace procedure c##dev_user.test_proc (
    employee_name_a in varchar2,
    employee_name_b in varchar2
)
as
begin
    select * from c##dev_user.mytable1;
end;

