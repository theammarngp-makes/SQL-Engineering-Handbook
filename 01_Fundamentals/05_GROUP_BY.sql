-- Q: Find the total number of employees per city
SELECT 
    l.city,(COUNT(e.emp_id)) AS number_of_employes
FROM
	employes e 
        JOIN
	departments d    
    ON   e.dept_id=d.dept_id 
        JOIN
    locations l ON d.location_id = l.location_id
GROUP BY l.city ;

-- Output = 
--city	  number_of_employes
--Nagpur	3
--Pune	  2

