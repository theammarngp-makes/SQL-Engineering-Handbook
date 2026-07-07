-- DATABASE SCHEMA

CREATE TABLE employes (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(50),
    dept_id INT,
    manager_id INT,
    hire_date  DATE  NOT NULL
);

CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location_id INT
);

CREATE TABLE locations (
    location_id INT PRIMARY KEY,
    city VARCHAR(50),
    country VARCHAR(50)
);
