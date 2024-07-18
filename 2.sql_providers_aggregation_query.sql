USE ClinicalProvider
GO

------------------------------------------------------------------
-- Function: Validation of Aggregation of Providers and 
--           Specialty Taxonomy records
-- Output File: 2.providers_aggregate_data_noclientfilter.csv
------------------------------------------------------------------
WITH 
allfollowups AS (
	SELECT * FROM [Followup2009-1]
	UNION ALL
	SELECT * FROM [Followup2009-2]
	UNION ALL
	SELECT * FROM [Followup2009-3]
	UNION ALL
	SELECT * FROM [Followup2009-4]
	UNION ALL
	SELECT * FROM [Followup2009-5]
	UNION ALL
	SELECT * FROM [Followup2009-6]
	UNION ALL
	SELECT * FROM [Followup2009-7]
),

allproviderpairs AS
(
SELECT DISTINCT
	s.City,
	s.State,
	s.Country,
	COUNT(*) AS TotalProviderPairs,
	SUM(f.Unique_Clients) AS TotalUniqueClients
FROM
	allfollowups AS f
	INNER JOIN Provider_clean AS s ON
		f.Source_Provider = s.Provider
	INNER JOIN Provider_clean AS t ON
		f.Target_Provider = t.Provider AND
		s.City = t.City AND
		s.State = t.State AND
		s.City IS NOT NULL AND
		s.State IS NOT NULL AND
		s.Country = t.Country AND 
		s.Country = 'US' AND 
		s.Individual = 1 AND
		t.Individual = 1
GROUP BY
	s.City,
	s.State,
	s.Country
HAVING SUM(f.Unique_Clients) > 10
),

allproviders AS
(
SELECT DISTINCT
	City,
	State,
	Country,
	COUNT(*) AS TotalProviders
FROM
	Provider_clean AS p
WHERE
	Country = 'US'
	AND
	Individual = 1
GROUP BY
	City,
	State,
	Country
),

-- Validate total count of specialist vs total providers
-- with taxonomy record
providertaxonomy AS
(
SELECT
	p.City,
	p.State,
	p.Country,
	COUNT(*) TotalSpecialist
FROM Provider_clean AS p
	INNER JOIN Specialty AS s ON
		s.Provider = p.Provider
	INNER JOIN Taxonomy AS t ON
		s.Code = t.Code
WHERE p.Country = 'US' 
	AND 
	p.Individual = 1
GROUP BY
	p.City,
	p.State,
	p.Country
),

-- Validate total count of specialist vs total providers
-- with no taxonomy record
providernotaxonomy AS
(
SELECT
	p.City,
	p.State,
	p.Country,
	COUNT(*) TotalNoTaxonomyRecord
FROM Provider_clean AS p
	FULL JOIN Specialty AS s ON
		s.Provider = p.Provider
WHERE
	p.Country = 'US' 
	AND 
	p.Individual = 1
	AND
	(s.Provider IS NULL OR s.Code IS NULL)
GROUP BY
	p.City,
	p.State,
	p.Country
)

SELECT
	p.City,
	p.State,
	p.Country,
	p.TotalProviders,
	pp.TotalProviderPairs,
	pp.TotalUniqueClients,
	pt.TotalSpecialist,
	npt.TotalNoTaxonomyRecord
FROM allproviders AS p
	LEFT JOIN allproviderpairs AS pp ON
		p.City = pp.City 
		AND
		p.State = pp.State 
		AND
		p.City IS NOT NULL 
		AND
		p.State IS NOT NULL
		LEFT JOIN providertaxonomy AS pt ON
			p.City = pt.City AND
			p.State = pt.State
			LEFt JOIN providernotaxonomy AS npt ON
				pt.City = npt.City AND
				pt.State = npt.State
ORDER BY TotalProviders DESC;
---------------------------------------------------------------------------------------
-- NOTE: For regression analysis, need to filter not blank totalprovider and totaluniqueclients
---------------------------------------------------------------------------------------

--------------------------------------------------------------------
---- Function: With Grouping, Classification and Specialization
---- Output File: providers_specialist_data.csv
--------------------------------------------------------------------
SELECT
	p.City,
	p.State,
	p.Country,
	tx.Grouping,
	tx.Classification,
	tx.Specialization,
	COUNT(*) TotalSpecialist
FROM Provider_clean AS p
	INNER JOIN Specialty AS s ON
		s.Provider = p.Provider
	INNER JOIN Taxonomy AS tx ON
		s.Code = tx.Code
WHERE p.Country = 'US' 
	AND 
	p.Individual = 1
GROUP BY
	p.City,
	p.State,
	p.Country,
	tx.Grouping,
	tx.Classification,
	tx.Specialization
ORDER BY TotalSpecialist DESC;
---------------------------------------------------------------------------------------
-- NOTE: We don't filter empty City and State so 
-- we can check it in visualization
--------------------------------------------------------------------


---------------------------------------------------------------------------------------
-- Function: Aggregation of distinct provider pair by city, state
-- Ouutput File: 2.providers_pairs_data.csv
---------------------------------------------------------------------------------------
WITH 
allfollowups AS (
	SELECT * FROM [Followup2009-1]
	UNION ALL
	SELECT * FROM [Followup2009-2]
	UNION ALL
	SELECT * FROM [Followup2009-3]
	UNION ALL
	SELECT * FROM [Followup2009-4]
	UNION ALL
	SELECT * FROM [Followup2009-5]
	UNION ALL
	SELECT * FROM [Followup2009-6]
	UNION ALL
	SELECT * FROM [Followup2009-7]
),

allproviderpairs AS
(
SELECT DISTINCT
	s.City,
	s.State,
	s.Country,
	COUNT(*) AS TotalProviderPairs,
	SUM(f.Unique_Clients) AS TotalUniqueClients
FROM
	allfollowups AS f
	INNER JOIN Provider_clean AS s ON
		f.Source_Provider = s.Provider
	INNER JOIN Provider_clean AS t ON
		f.Target_Provider = t.Provider AND
		s.City = t.City AND
		s.State = t.State AND
		s.City IS NOT NULL AND
		s.State IS NOT NULL AND
		s.Country = t.Country AND 
		s.Country = 'US' AND 
		s.Individual = 1 AND
		t.Individual = 1
GROUP BY
	s.City,
	s.State,
	s.Country
HAVING SUM(f.Unique_Clients) > 10
),

allproviders AS
(
SELECT DISTINCT
	City,
	State,
	Country,
	COUNT(*) AS TotalProviders
FROM
	Provider_clean AS p
WHERE
	Country = 'US'
	AND
	Individual = 1
GROUP BY
	City,
	State,
	Country
)

SELECT
	p.City,
	p.State,
	p.Country,
	p.TotalProviders,
	pp.TotalProviderPairs,
	pp.TotalUniqueClients
FROM allproviders AS p
	LEFT JOIN allproviderpairs AS pp ON
		p.City = pp.City AND
		p.State = pp.State AND
		p.City IS NOT NULL AND
		p.State IS NOT NULL AND
		p.TotalProviders IS NOT NULL AND p.TotalProviders > 0 AND
		pp.TotalUniqueClients IS NOT NULL AND pp.TotalUniqueClients > 10
ORDER BY TotalProviders DESC;
---------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------
-- Function: Aggregation of distinct provider pair by city, state
-- Ouutput File: 2.providers_data.csv
---------------------------------------------------------------------------------------
SELECT DISTINCT
	City,
	State,
	Country,
	Individual,
	COUNT(*) AS TotalProviders
FROM
	Provider_clean AS p
WHERE
	Country = 'US'
GROUP BY
	City,
	State,
	Country,
	Individual
ORDER BY TotalProviders DESC;