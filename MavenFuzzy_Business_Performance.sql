/*
Creator: Jin
Create Date: 03/26/2023
 */

#---Query #1: pull out overall session and order volume trended by quarter until the latest quarter.

SELECT MIN(created_at)
     , MAX(created_at)
FROM website_sessions
; #---Find the time range, which is 2012-03-19 to 2015-03-19.

SELECT YEAR(ws.created_at) AS Year
     , QUARTER(ws.created_at) AS Quarter
     , COUNT(DISTINCT ws.website_session_id) AS Overall_sessions
     , COUNT(DISTINCT o.order_id) AS Overall_orders
FROM website_sessions ws
LEFT JOIN orders o
    ON ws.website_session_id = o.website_session_id
WHERE ws.created_at >= '2012-04-01'
AND ws.created_at < '2015-01-01'
GROUP BY 1,2
;

#---Query #2: Show quarterly session-to-order conversion rate, revenue per order, and revenue per session since the launch.

SELECT YEAR(ws.created_at) AS Year
     , QUARTER(ws.created_at) AS Quarter
     , COUNT(DISTINCT o.order_id) / COUNT(DISTINCT ws.website_session_id) AS session_to_order_conv_rate
     , SUM(o.price_usd) / COUNT(DISTINCT o.order_id) AS revenue_per_order
     , SUM(o.price_usd) / COUNT(DISTINCT ws.website_session_id) AS revenue_per_session
FROM website_sessions ws
LEFT JOIN orders o
    ON ws.website_session_id = o.website_session_id
WHERE ws.created_at >= '2012-04-01'
AND ws.created_at < '2015-01-01'
GROUP BY 1,2
;

#---Query #3: Pull quarterly view of orders from different channels.

SELECT YEAR(ws.created_at) AS Year
     , QUARTER(ws.created_at) AS Quarter
     , COUNT(DISTINCT CASE WHEN ws.utm_source = 'Gsearch' AND ws.utm_campaign = 'nonbrand' THEN o.order_id ELSE NULL END)
                    AS Gsearch_nonbrand_orders
     , COUNT(DISTINCT CASE WHEN ws.utm_source = 'Bsearch' AND ws.utm_campaign = 'nonbrand' THEN o.order_id ELSE NULL END)
                    AS Bsearch_nonbrand_orders
     , COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'brand' THEN o.order_id ELSE NULL END) AS brand_search_orders
     , COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN o.order_id ELSE NULL END)
                    AS Organic_search_orders
     , COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND http_referer IS NULL THEN o.order_id ELSE NULL END) AS Direct_type_in_orders
FROM website_sessions ws
LEFT JOIN orders o
    ON ws.website_session_id = o.website_session_id
WHERE ws.created_at >= '2012-04-01'
AND ws.created_at < '2015-01-01'
GROUP BY 1,2
;

#---Query #4: Show the overall session-to-order conversion rate trends for those same channels, by quarter.

SELECT YEAR(ws.created_at) AS Year
     , QUARTER(ws.created_at) AS Quarter
     , COUNT(DISTINCT CASE WHEN ws.utm_source = 'Gsearch' AND ws.utm_campaign = 'nonbrand' THEN o.order_id ELSE NULL END) /
       COUNT(DISTINCT CASE WHEN ws.utm_source = 'Gsearch' AND ws.utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END)
                    AS Gsearch_nonbrand_conv_rate
     , COUNT(DISTINCT CASE WHEN ws.utm_source = 'Bsearch' AND ws.utm_campaign = 'nonbrand' THEN o.order_id ELSE NULL END) /
       COUNT(DISTINCT CASE WHEN ws.utm_source = 'Bsearch' AND ws.utm_campaign = 'nonbrand' THEN ws.website_session_id ELSE NULL END)
                    AS Bsearch_nonbrand_conv_rate
     , COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'brand' THEN o.order_id ELSE NULL END) /
       COUNT(DISTINCT CASE WHEN ws.utm_campaign = 'brand' THEN ws.website_session_id ELSE NULL END)
                    AS Brand_search_conv_rate
     , COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN o.order_id ELSE NULL END) /
       COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND http_referer IN ('https://www.gsearch.com', 'https://www.bsearch.com') THEN ws.website_session_id ELSE NULL END)
                    AS Organic_search_conv_rate
     , COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND http_referer IS NULL THEN o.order_id ELSE NULL END) /
       COUNT(DISTINCT CASE WHEN ws.utm_source IS NULL AND http_referer IS NULL THEN ws.website_session_id ELSE NULL END)
                    AS Direct_type_in_conv_rate
FROM website_sessions ws
LEFT JOIN orders o
    ON ws.website_session_id = o.website_session_id
WHERE ws.created_at >= '2012-04-01'
AND ws.created_at < '2015-01-01'
GROUP BY 1,2
;

#---Query #5: Pull monthly trending for revenue and margin by product, along with total sales and revenue.

SELECT DISTINCT primary_product_id FROM orders;  #---Find how many products we have.

SELECT YEAR(created_at) AS Year
     , MONTH(created_at) AS Month
     , COUNT(DISTINCT order_id) AS Total_sales
     , SUM(price_usd) AS Total_revenue
     , SUM(CASE WHEN primary_product_id = 1 THEN price_usd - orders.cogs_usd ELSE NULL END) AS P1_revenue_margin
     , SUM(CASE WHEN primary_product_id = 2 THEN price_usd - orders.cogs_usd ELSE NULL END) AS P2_revenue_margin
     , SUM(CASE WHEN primary_product_id = 3 THEN price_usd - orders.cogs_usd ELSE NULL END) AS P3_revenue_margin
     , SUM(CASE WHEN primary_product_id = 4 THEN price_usd - orders.cogs_usd ELSE NULL END) AS P4_revenue_margin
FROM orders
GROUP BY 1,2
;

/*
---Query #6: Pull monthly sessions to the /product page, and show how the % of those sessions clicking thru another
page has change over time, along with a view of how conversion from /products to placing an order has improved.
 */

SELECT YEAR(time_click_products) AS Year
     , MONTH(time_click_products) AS Month
     , COUNT(DISTINCT products_sessions.website_session_id) AS sessions_to_products
     , COUNT(DISTINCT wp.website_session_id) AS next_page_clickthru
     , COUNT(DISTINCT wp.website_session_id)  /
       COUNT(DISTINCT products_sessions.website_session_id) AS products_clickthru_rate
     , COUNT(DISTINCT o.order_id) AS orders
     , COUNT(DISTINCT o.order_id) / COUNT(DISTINCT products_sessions.website_session_id)
            AS sessions_to_orders_products
FROM
    (SELECT created_at AS time_click_products
     , website_session_id
     , website_pageview_id
     , pageview_url
FROM website_pageviews
WHERE pageview_url = '/products') AS products_sessions
LEFT JOIN website_pageviews wp
    ON products_sessions.website_pageview_id < wp.website_pageview_id
    AND products_sessions.website_session_id = wp.website_session_id
LEFT JOIN orders o
    ON products_sessions.website_session_id = o.website_session_id
GROUP BY 1,2
;


/*
---Query #7: The 4th product has been available as primary from Dec 05, 2014, which was only a cross-item previously.
Pull sales data since then, and show how well each product cross-sells from one another?
 */

DROP TEMPORARY TABLE IF EXISTS cross_sale_products;
CREATE TEMPORARY TABLE cross_sale_products
SELECT
	primary_products.*,
    order_items.product_id AS cross_sell_products_id
FROM (
    SELECT
	order_id,
    primary_product_id,
    created_at AS order_date
FROM orders
WHERE created_at > '2014-12-05') AS primary_products
	LEFT JOIN order_items
		ON order_items.order_id = primary_products.order_id
        AND order_items.is_primary_item = 0;

SELECT
	primary_product_id,
    COUNT(DISTINCT order_id) AS total_orders,
    COUNT(DISTINCT CASE WHEN cross_sell_products_id = 1 THEN order_id ELSE NULL END) AS _xsold_p1,
    COUNT(DISTINCT CASE WHEN cross_sell_products_id = 2 THEN order_id ELSE NULL END) AS _xsold_p2,
    COUNT(DISTINCT CASE WHEN cross_sell_products_id = 3 THEN order_id ELSE NULL END) AS _xsold_p3,
    COUNT(DISTINCT CASE WHEN cross_sell_products_id = 4 THEN order_id ELSE NULL END) AS _xsold_p4,
    COUNT(DISTINCT CASE WHEN cross_sell_products_id = 1 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p1_xsell_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_products_id = 2 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p2_xsell_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_products_id = 3 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p3_xsell_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_products_id = 4 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p4_xsell_rt
FROM cross_sale_products
GROUP BY 1;

