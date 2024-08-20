use sql_campusx_case_studies

select * from sharktank

/*1.	You Team must promote shark Tank India season 4, 
The senior come up with the idea to show highest funding domain 
wise so that new startups can be attracted, 
and you were assigned the task to show the same*/

--method 1

select Industry,MAX(total_deal_amount_in_lakhs) as Max_funding from sharktank
group by Industry
ORDER BY Max_funding DESC

--method 2
select * from
(
select industry,total_deal_amount_in_lakhs,ROW_NUMBER() OVER(partition by industry order by total_deal_amount_in_lakhs desc) as 'rankk'
from sharktank
)t where rankk = 1


/*2.	You have been assigned the role of finding the domain where female as 
pitchers have female to male pitcher ratio >70%*/

select * from sharktank


select *,ROUND((female/(male*1.0))*100,2) as percentage
from
(
select industry, SUM(female_presenters) as female,SUM(male_presenters) as male
from sharktank
group by industry
having SUM(female_presenters) > 0 and  SUM(male_presenters) > 0
)t
where ROUND((female/(male*1.0))*100,2) > 70

/*3.	You are working at marketing firm of Shark Tank India, you have got the task 
to determine volume of per season sale pitch made, pitches who received offer and pitches that were converted. 
Also show the percentage of pitches converted and percentage of pitches entertained.*/

select * from sharktank

select a.Season_Number,pitches,((received_offer/(pitches*1.0))*100) as 'receivedoffer_%',
((accepted_offer/(pitches*1.0))*100) as 'acceptdoffer_%' from
(
select season_number,count(startup_name) as 'pitches' from sharktank
group by season_number
)a
inner join
(
select season_number,count(startup_name) as 'received_offer' from sharktank
where received_offer = 1
group by season_number
)b on a.season_number = b.season_number
inner join
(
select season_number,count(startup_name) as 'accepted_offer' from sharktank
where accepted_offer = 1
group by season_number
)c on b.season_number = c.Season_Number

/*4.	As a venture capital firm specializing in investing in startups featured on a 
renowned entrepreneurship TV show, you are determining the season with the highest average monthly sales 
and identify the top 5 industries with the highest average monthly sales 
during that season to optimize investment decisions?*/

-- here we are finding top 5 industries with highest avg monthly sales for every season
select * from 
(
select *,ROW_NUMBER() OVER(partition by season_number order by average_monthly_sales desc) as 'rankk'
from
(

select season_number,industry,AVG(CAST(monthly_sales_in_lakhs as FLOAT)) as 'average_monthly_sales' from sharktank
where TRY_CAST(Monthly_Sales_in_lakhs as NUMERIC) is not null
group by season_number,industry
--order by Season_Number,average_monthly_sales desc
)t
)t1
where rankk in (1,2,3,4,5)


--here we are finding season with highest avg monthly sales and then getting the top 5 indsutries for that season
select * from sharktank

DECLARE @season_num INT --declaring var

set @season_num = 
(select season_number from
(
select TOP 1 season_number,ROUND(AVG(TRY_CAST(monthly_sales_in_lakhs as FLOAT)),2) as 'average_monthly_sales' from sharktank
--where TRY_CAST(Monthly_Sales_in_lakhs as NUMERIC) is not null
group by season_number
order by average_monthly_sales desc
)t)

select @season_num

select TOP 5 industry,ROUND(AVG(TRY_CAST(monthly_sales_in_lakhs as FLOAT)),2) as 'average_monthly_sales' from sharktank
where season_number = @season_num
group by industry
order by average_monthly_sales desc


/*5.	As a data scientist at our firm, your role involves solving real-world challenges 
like identifying industries with consistent increases in funds raised over multiple seasons. 
This requires focusing on industries where data is available across all three seasons. 
Once these industries are pinpointed, your task is to delve into the specifics, analyzing the 
number of pitches made, offers received, and offers converted per season within each industry.*/

select * from sharktank

--without pivot
select industry,season_number,ROUND(AVG(Total_Deal_Amount_in_lakhs),2) as 'average'
from sharktank
group by industry,Season_Number
order by industry



with tab as
(
--WITH PIVOT(case statement used to pivot)
select industry,
ROUND(AVG(CASE WHEN season_number = 1 then Total_Deal_Amount_in_lakhs END),2) as 'season_1',
ROUND(AVG(CASE WHEN season_number = 2 then Total_Deal_Amount_in_lakhs END),2) as 'season_2',
ROUND(AVG(CASE WHEN season_number = 3 then Total_Deal_Amount_in_lakhs END),2) as 'season_3'
from sharktank
group by industry
having ROUND(AVG(CASE WHEN season_number = 3 then Total_Deal_Amount_in_lakhs END),2) > ROUND(AVG(CASE WHEN season_number = 2 then Total_Deal_Amount_in_lakhs END),2) 
AND 
ROUND(AVG(CASE WHEN season_number = 2 then Total_Deal_Amount_in_lakhs END),2) > ROUND(AVG(CASE WHEN season_number = 1 then Total_Deal_Amount_in_lakhs END),2)
AND 
ROUND(AVG(CASE WHEN season_number = 1 then Total_Deal_Amount_in_lakhs END),2)!=0
)

select m.industry,n.season_number,count(n.startup_name) as 'total',
count(case when n.received_offer = 1 then n.startup_name end) as 'received',
count(case when n.accepted_offer = 1 then n.startup_name end) as 'accepted'
from tab as m
inner join
sharktank as n
on m.industry = n.industry
group by m.Industry,n.season_number


/*6.Every shark wants to know in how much year their investment will be returned,
so you must create a system for them, where shark will enter the name of the startup’s 
and the based on the total deal and equity given in how many years their principal 
amount will be returned and make their investment decisions.*/
select * from sharktank


CREATE PROCEDURE CalculateReturnPeriod @startup VARCHAR(50)
AS
BEGIN
    -- Retrieve relevant data for the given startup
    SELECT
        startup_name,
        Yearly_Revenue_in_lakhs,
        total_deal_amount_in_lakhs,
        total_deal_equity,
        -- Use CASE to handle conditional logic
        CASE
            -- Condition when the offer was not accepted
            WHEN accepted_offer = 0 THEN 'TOT cannot be calculated'
            -- Condition when yearly revenue is not mentioned
            WHEN Yearly_Revenue_in_lakhs = 'Not Mentioned' THEN 'TOT cannot be calculated'
            ELSE 
                -- Handle valid cases
                CASE
                    -- Check if yearly revenue can be converted to FLOAT and if total equity is not zero
                    WHEN TRY_CAST(Yearly_Revenue_in_lakhs AS FLOAT) IS NULL OR total_deal_equity = 0 THEN 'TOT cannot be calculated'
                    ELSE 
                        ROUND(CAST(total_deal_amount_in_lakhs AS FLOAT) / 
                        ((total_deal_equity / 100.0) * TRY_CAST(Yearly_Revenue_in_lakhs AS FLOAT)),2)
                END
        END AS years_to_return
    FROM sharktank
    WHERE startup_name = @startup;
END


EXEC CalculateReturnPeriod @startup = 'Bluepinefoods'

drop procedure CalculateReturnPeriod --to delete the procedure



/*7.	In the world of startup investing, we're curious to know which big-name investor,
often referred to as "sharks," tends to put the most money into each deal on average. 
This comparison helps us see who's the most generous with their investments and 
how they measure up against their fellow investors.*/

select * from sharktank


select sharkname, ROUND(AVG(invest),2) as 'average_deal' from 
(
select Namita_investment_amount_in_lakhs as 'invest',
'namita' as sharkname from sharktank where Namita_investment_amount_in_lakhs > 0

union all

select Vineeta_investment_amount_in_lakhs as 'invest',
'Vineeta' as sharkname from sharktank where Vineeta_investment_amount_in_lakhs > 0

union all

select Anupam_investment_amount_in_lakhs as 'invest',
'Anupam' as sharkname from sharktank where Anupam_investment_amount_in_lakhs > 0

union all

select Aman_investment_amount_in_lakhs as 'invest',
'Aman' as sharkname from sharktank where Aman_investment_amount_in_lakhs > 0

union all

select Peyush_investment_amount_in_lakhs as 'invest',
'Peyush' as sharkname from sharktank where Peyush_investment_amount_in_lakhs > 0

union all

select Amit_investment_amount_in_lakhs as 'invest',
'Amit' as sharkname from sharktank where Amit_investment_amount_in_lakhs > 0

union all

select Ashneer_investment_amount as 'invest',
'Ashneer' as sharkname from sharktank where Ashneer_investment_amount > 0
) t
group by sharkname
order by average_deal DESC


/*8.	Develop a stored procedure that accepts inputs for the season number and the name of a shark. 
The procedure will then provide detailed insights into the total investment made by that specific shark 
across different industries during the specified season. Additionally, it will calculate the percentage of 
their investment in each sector relative to the total investment in that year, 
giving a comprehensive understanding of the shark's investment distribution and impact.*/

select * from sharktank

CREATE PROCEDURE sharkinvestment
       @season INT,
	   @sharkname VARCHAR(50)
AS
BEGIN
     DECLARE @total_namita FLOAT
	 DECLARE @total_vineeta FLOAT
     
	 IF @sharkname = 'namita' 
	 BEGIN
		    SET @total_namita = (select SUM(Namita_investment_amount_in_lakhs) as 'sum' from sharktank where season_number = @season)
		    SELECT industry,ROUND(SUM(Namita_investment_amount_in_lakhs),2) as 'industry_wise_investment',ROUND(((SUM(Namita_investment_amount_in_lakhs))/@total_namita)*100,2) as 'percent_investment' from sharktank where season_number  = @season
			group by industry
	 END
	 ELSE IF @sharkname = 'vineeta'
	 BEGIN
		    SET @total_vineeta = (select SUM(vineeta_investment_amount_in_lakhs) as 'sum' from sharktank where season_number = @season)
		    SELECT industry,ROUND(SUM(vineeta_investment_amount_in_lakhs),2) as 'industry_wise_investment',ROUND(((SUM(vineeta_investment_amount_in_lakhs))/@total_vineeta)*100,2) as 'percent_investment' from sharktank where season_number  = @season
		    group by industry
	 END
	 ELSE print 'Invalid name'
END 

		       
EXEC sharkinvestment   
    @season = 2,
	@sharkname = 'ashneer'
     

DROP PROCEDURE sharkinvestment



























select SUM(Namita_investment_amount_in_lakhs) as 'sum' from sharktank where season_number = 1
--group by Industry



