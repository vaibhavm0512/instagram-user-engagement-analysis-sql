-- SUBJECTIVE QUESTIONS



USE ig_clone;

-- SOLUTION Q1. 


WITH user_metrics AS (
    SELECT 
        u.id AS user_id,
        u.username,
        COALESCE(p.total_posts, 0) AS total_posts,
        COALESCE(lg.likes_given, 0) AS likes_given,
        COALESCE(cm.comments_made, 0) AS comments_made,
        COALESCE(lr.likes_received, 0) AS likes_received,
        COALESCE(cr.comments_received, 0) AS comments_received
    FROM users u
    LEFT JOIN (
        SELECT user_id, COUNT(*) AS total_posts
        FROM photos
        GROUP BY user_id
    ) p ON u.id = p.user_id
    LEFT JOIN (
        SELECT p.user_id, COUNT(*) AS likes_received
        FROM photos p
        JOIN likes l ON p.id = l.photo_id
        GROUP BY p.user_id
    ) lr ON u.id = lr.user_id
    LEFT JOIN (
        SELECT p.user_id, COUNT(*) AS comments_received
        FROM photos p
        JOIN comments c ON p.id = c.photo_id
        GROUP BY p.user_id
    ) cr ON u.id = cr.user_id
    LEFT JOIN (
        SELECT user_id, COUNT(*) AS likes_given
        FROM likes
        GROUP BY user_id
    ) lg ON u.id = lg.user_id
    LEFT JOIN (
        SELECT user_id, COUNT(*) AS comments_made
        FROM comments
        GROUP BY user_id
    ) cm ON u.id = cm.user_id
)
SELECT 
    user_id,
    username,
    total_posts,
    likes_given,
    comments_made,
    likes_received,
    comments_received,
    (
        (total_posts * 10) +
        likes_given +
        comments_made +
        likes_received +
        comments_received
    ) AS weighted_engagement_score
FROM user_metrics
ORDER BY weighted_engagement_score DESC
LIMIT 15;




-- SOLUTION Q2. 


SELECT u.id AS user_id, u.username
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
WHERE p.id IS NULL 
  AND l.user_id IS NULL 
  AND c.user_id IS NULL;




-- SOLUTION Q3. 


WITH tag_photos AS (
    SELECT 
        t.tag_name,
        pt.photo_id
    FROM photo_tags pt
    JOIN tags t ON pt.tag_id = t.id
),
photo_engagement AS (
    SELECT 
        p.id AS photo_id,
        COALESCE(l.likes_count, 0) + COALESCE(c.comments_count, 0) AS total_engagement
    FROM photos p
    LEFT JOIN (
        SELECT photo_id, COUNT(*) AS likes_count
        FROM likes
        GROUP BY photo_id
    ) l ON p.id = l.photo_id
    LEFT JOIN (
        SELECT photo_id, COUNT(*) AS comments_count
        FROM comments
        GROUP BY photo_id
    ) c ON p.id = c.photo_id
),
tag_engagement AS (
    SELECT 
        tp.tag_name,
        pe.total_engagement
    FROM tag_photos tp
    JOIN photo_engagement pe 
        ON tp.photo_id = pe.photo_id
)
SELECT 
    tag_name,
    COUNT(*) AS total_posts,
    SUM(total_engagement) AS total_engagement,
    ROUND(AVG(total_engagement), 2) AS avg_engagement,
    RANK() OVER (
        ORDER BY AVG(total_engagement) ASC
    ) AS rnk
FROM tag_engagement
GROUP BY tag_name
ORDER BY avg_engagement DESC
LIMIT 15;



-- SOLUTION Q4. 


-- Number of posts per day of the week
SELECT
  DAYNAME(created_at) AS day_of_week,
  COUNT(id) AS total_posts
FROM photos
GROUP BY day_of_week
ORDER BY FIELD(day_of_week,
  'Monday','Tuesday','Wednesday',
  'Thursday','Friday','Saturday','Sunday');

-- Number of likes per day of the week
SELECT
  DAYNAME(created_at) AS day_of_week,
  COUNT(*) AS total_likes
FROM likes
GROUP BY day_of_week
ORDER BY FIELD(day_of_week,
  'Monday','Tuesday','Wednesday',
  'Thursday','Friday','Saturday','Sunday');

-- Number of comments per day of the week
SELECT
  DAYNAME(created_at) AS day_of_week,
  COUNT(id) AS total_comments
FROM comments
GROUP BY day_of_week
ORDER BY FIELD(day_of_week,
  'Monday','Tuesday','Wednesday',
  'Thursday','Friday','Saturday','Sunday');



-- SOLUTION Q5. 


WITH follower_count AS (
    SELECT 
        followee_id AS user_id,
        COUNT(follower_id) AS total_followers
    FROM follows
    GROUP BY followee_id
),

photo_engagement AS (
    SELECT 
        p.id AS photo_id,
        p.user_id,
        COALESCE(l.likes_count, 0) + COALESCE(c.comments_count, 0) AS total_engagement
    FROM photos p
    LEFT JOIN (
        SELECT photo_id, COUNT(*) AS likes_count
        FROM likes
        GROUP BY photo_id
    ) l ON p.id = l.photo_id
    LEFT JOIN (
        SELECT photo_id, COUNT(*) AS comments_count
        FROM comments
        GROUP BY photo_id
    ) c ON p.id = c.photo_id
),

user_engagement AS (
    SELECT 
        user_id,
        COUNT(photo_id) AS total_posts,
        AVG(total_engagement) AS avg_engagement
    FROM photo_engagement
    GROUP BY user_id
)

SELECT 
    u.id AS user_id,
    u.username,
    fc.total_followers,
    ue.total_posts,
    ROUND(ue.avg_engagement, 2) AS avg_engagement,
    ROUND(ue.avg_engagement / NULLIF(fc.total_followers, 0), 4) AS engagement_rate,
    RANK() OVER (
        ORDER BY (ue.avg_engagement / NULLIF(fc.total_followers, 0)) DESC
    ) AS influencer_rank
    
FROM users u
JOIN follower_count fc ON u.id = fc.user_id
JOIN user_engagement ue ON u.id = ue.user_id

WHERE total_posts>2
ORDER BY influencer_rank
LIMIT 10;



-- SOLUTION Q6. 


WITH user_activity AS (
    SELECT 
        u.id AS user_id,
        u.username,

        COUNT(DISTINCT p.id) AS total_posts,
        COUNT(DISTINCT l.photo_id) AS total_likes_given,
        COUNT(DISTINCT c.id) AS total_comments_given,

        -- Activity Score:
        -- 1 post = 10 points
        -- 1 like/comment = 1 point
        (COUNT(DISTINCT p.id) * 10) +
        COUNT(DISTINCT l.photo_id) +
        COUNT(DISTINCT c.id) AS activity_score

    FROM users u
    LEFT JOIN photos p ON u.id = p.user_id
    LEFT JOIN likes l ON u.id = l.user_id
    LEFT JOIN comments c ON u.id = c.user_id

    GROUP BY u.id, u.username
)

SELECT 
    user_id,
    username,
    total_posts,
    total_likes_given,
    total_comments_given,
    activity_score,

    CASE 
        WHEN activity_score >=500 THEN 'Star Users'
        WHEN activity_score >= 150 THEN 'Active Users'
        WHEN activity_score BETWEEN 10 AND 149 THEN 'Moderate Users'
        ELSE 'Inactive'
    END AS user_segment

FROM user_activity
ORDER BY activity_score DESC;




-- SOLUTION Q7. 

-- This query will not run, as its an assumption
-- Assuming there is a table named ad_campaigns, calculating the overall funnel performance per campaign

SELECT
  campaign_id,
  campaign_name,
  SUM(impressions) AS total_impressions,
  SUM(clicks) AS total_clicks,
  SUM(conversions) AS total_conversions,
  ROUND(SUM(clicks) / SUM(impressions) * 100, 2) AS ctr_percent,
  ROUND(SUM(conversions) / SUM(clicks) * 100, 2) AS cvr_percent,
  ROUND(SUM(spend) / SUM(clicks), 2) AS cost_per_click,
  ROUND(SUM(spend) / SUM(conversions), 2) AS cost_per_acquisition
FROM ad_campaigns
GROUP BY campaign_id, campaign_name
ORDER BY cost_per_acquisition ASC;



-- SOLUTION Q10.


-- This query will not run, as its an assumption
-- Assuming there is a table named User_Interactions with a column named Engagement_type, Update engagement type from 'Like' to 'Heart':

UPDATE User_Interactions
SET Engagement_Type = 'Heart'
WHERE Engagement_Type = 'Like';


