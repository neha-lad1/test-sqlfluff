CREATE TABLE employees (
    employee_id NUMBER PRIMARY KEY,  -- lint warning: primary key should be defined as 'NOT NULL'
    first_name VARCHAR2(50),  -- lint warning: column names should be snake_case
    last_name VARCHAR2(50),
    hire_date DATE DEFAULT SYSDATE,
    salary NUMBER
);