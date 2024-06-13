/* Welcome to the SQL mini project. You will carry out this project partly in
the PHPMyAdmin interface, and partly in Jupyter via a Python connection.*/


/* QUESTIONS 
/* Q1: Some of the facilities charge a fee to members, but some do not.
Write a SQL query to produce a list of the names of the facilities that do. */

SELECT name 
FROM `Facilities` 
WHERE membercost > 0.0;

/* Q2: How many facilities do not charge a fee to members? */

SELECT COUNT(DISTINCT(name)) 
FROM `Facilities` 
WHERE membercost = 0.0;
-- 4 facilities do not charge

/* Q3: Write an SQL query to show a list of facilities that charge a fee to members,
where the fee is less than 20% of the facility's monthly maintenance cost.
Return the facid, facility name, member cost, and monthly maintenance of the
facilities in question. */

SELECT facid, name, membercost, monthlymaintenance 
FROM `Facilities` 
WHERE (membercost / monthlymaintenance < 0.20) AND membercost > 0; 

/* Q4: Write an SQL query to retrieve the details of facilities with ID 1 and 5.
Try writing the query without using the OR operator. */

SELECT * 
FROM `Facilities` 
WHERE facid IN (1,2,3,4,5);

/* Q5: Produce a list of facilities, with each labelled as
'cheap' or 'expensive', depending on if their monthly maintenance cost is
more than $100. Return the name and monthly maintenance of the facilities
in question. */

SELECT name, monthlymaintenance, 
	CASE WHEN monthlymaintenance > 100 THEN 'expensive' 
    ELSE 'cheap' 
END AS type 
FROM `Facilities`;

/* Q6: You'd like to get the first and last name of the last member(s)
who signed up. Try not to use the LIMIT clause for your solution. */

SELECT firstname, surname
FROM `Members`
WHERE joindate IN
	(SELECT MAX(STR_TO_DATE(joindate, '%Y-%m-%d %H:%i:%s'))
     FROM `Members`);



/* Q7: Produce a list of all members who have used a tennis court.
Include in your output the name of the court, and the name of the member
formatted as a single column. Ensure no duplicate data, and order by
the member name. */

SELECT DISTINCT(CONCAT(m.firstname, ' ', m.surname, ' - ', f.name)) AS member_court_name
FROM `Members` AS m
INNER JOIN `Bookings` AS b ON m.memid = b.memid
INNER JOIN `Facilities` AS f ON f.facid = b.facid
WHERE m.memid IN
	(SELECT b.memid
	 FROM `Bookings`
	 WHERE b.facid IN (0,1))
ORDER BY member_court_name;
	 
/* Q8: Produce a list of bookings on the day of 2012-09-14 which
will cost the member (or guest) more than $30. Remember that guests have
different costs to members (the listed costs are per half-hour 'slot'), and
the guest user's ID is always 0. Include in your output the name of the
facility, the name of the member formatted as a single column, and the cost.
Order by descending cost, and do not use any subqueries. */

SELECT CONCAT(m.firstname, ' ', m.surname) AS user_name, f.name AS facility, 
	CASE  WHEN m.memid <> 0 THEN f.membercost * b.slots
    ELSE f.guestcost * b.slots END AS cost
FROM `Facilities` AS f
INNER JOIN `Bookings` AS b ON f.facid = b.facid
INNER JOIN `Members` AS m ON b.memid = m.memid
WHERE b.starttime LIKE ('2012-09-14%') 
AND ( ((b.memid =0) AND (f.guestcost * b.slots >30)) 
	OR ((b.memid <>0) AND (f.membercost * b.slots >30)) )
ORDER BY COST DESC;


/* Q9: This time, produce the same result as in Q8, but using a subquery. */

SELECT * 
FROM (
	SELECT CONCAT( m.firstname,  ' ', m.surname ) AS user_name, f.name AS facility, 
	CASE WHEN b.memid =0 THEN f.guestcost * b.slots
	ELSE f.membercost * b.slots
	END AS cost
	FROM Bookings AS b
	INNER JOIN Facilities AS f ON b.facid = f.facid
	AND b.starttime LIKE  ('2012-09-14%')
	INNER JOIN Members AS m ON b.memid = m.memid
	) AS sub
WHERE sub.cost >30
ORDER BY sub.cost DESC


/* PART 2: SQLite

Export the country club data from PHPMyAdmin, and connect to a local SQLite instance from Jupyter notebook 
for the following questions.  



QUESTIONS:
/* Q10: Produce a list of facilities with a total revenue less than 1000.
The output of facility name and total revenue, sorted by revenue. Remember
that there's a different cost for guests and members! */

SELECT Facilities.name, 
	SUM(CASE WHEN Bookings.memid <> 0  
    THEN Facilities.membercost * Bookings.slots 
    ELSE Facilities.guestcost * Bookings.slots 
    END) AS total_revenue
FROM Facilities
INNER JOIN Bookings ON Facilities.facid = Bookings.facid
GROUP BY Facilities.name
HAVING total_revenue < 1000
ORDER BY total_revenue;


/* Q11: Produce a report of members and who recommended them in alphabetic surname,firstname order */

SELECT m.surname AS member_surname, m.firstname AS member_firstname, r.surname AS recomender_surname, r.firstname AS recomender_firstname
FROM Members AS m
JOIN Members AS r ON m.recommendedby = r.memid
WHERE m.recommendedby != 0
ORDER BY m.surname, m.firstname;

/* Q12: Find the facilities with their usage by member, but not guests */

SELECT f.name AS facility, m.firstname || ' ' || m.surname AS member_name, m.memid AS member_id
FROM Bookings AS b
INNER JOIN Facilities AS f ON b.facid = f.facid
INNER JOIN Members AS m ON b.memid = m.memid 
WHERE b.memid != 0
ORDER BY facility;

/* Q13: Find the facilities usage by month, but not guests */

SELECT STRFTIME('%m', starttime) AS month, COUNT(memid) AS facility_usage
FROM Bookings
WHERE memid != 0
GROUP BY month;
