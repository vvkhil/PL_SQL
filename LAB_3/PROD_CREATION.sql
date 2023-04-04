-- create the second schema
create user prod_user identified by prod_password;
grant connect, resource, create view, create procedure to prod_user;

drop table prod_user.employee;

create table prod_user.departments (
  id number primary key
  -- name varchar2(50)
);


create table prod_user.mytable1 (
    id number,
    name varchar2(50)
);

create index id5_test on prod_user.mytable1(name);

create table prod_user.employee (
  id number primary key,
  name varchar2(50),
  department_id number(4),
  -- salary number,
  foreign key (department_id) references prod_user.departments(id)
);

create table prod_user.products (
  product_id   number primary key,
  product_name varchar2(50) not null,
  price        number not null,
  quantity     number not null
);

create table prod_user.customers (
  customer_id number(10) primary key,
  customer_name varchar2(50) not null,
  customer_address varchar2(100) not null,
  customer_phone number(10) not null
);

create table prod_user.orders (
  order_id number primary key,
  customer_id number,
  order_date date,
  foreign key (customer_id) references prod_user.customers(customer_id)
);

create table prod_user.order_details (
  order_detail_id number primary key,
  order_id number,
  product_id number,
  quantity number,
  foreign key (order_id) references prod_user.orders(order_id),
  foreign key (product_id) references prod_user.products(product_id)
);




