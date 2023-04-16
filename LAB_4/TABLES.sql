drop table table2;
drop table table1;

CREATE TABLE table1 (
  id NUMBER,
  name VARCHAR2(100),
  age NUMBER
);

CREATE TABLE table2 (
  id NUMBER,
  address VARCHAR2(100),
  phone VARCHAR2(100)
);

INSERT INTO table1 (id, name, age)
VALUES (1, 'Alice', 25);

INSERT INTO table1 (id, name, age)
VALUES (2, 'Bob', 30);

INSERT INTO table1 (id, name, age)
VALUES (3, 'Charlie', 35);

INSERT INTO table2 (id, address, phone)
VALUES (1, '123 Main St', '555-1234');

INSERT INTO table2 (id, address, phone)
VALUES (2, '456 Oak St', '555-5678');

INSERT INTO table2 (id, address, phone)
VALUES (3, '789 Elm St', '555-9012');