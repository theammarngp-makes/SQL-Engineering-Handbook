-- Q: Show only departments that have MORE than 1 employee
-- (this is where HAVING comes in — not WHERE)
SELECT d.dept_name,COUNT(e.emp_id) as number_of_employes
FROM departments d
JOIN employes e
ON d.dept_id = e.dept_id
GROUP BY d.dept_name
HAVING number_of_employes > 1 ;
