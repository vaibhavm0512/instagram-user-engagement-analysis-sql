-- OBJECTIVE QUESTIONS



USE ig_clone;


-- SOLUTION Q8.


-- 1. Overall most popular tags
SELECT 
    t.tag_name,
    COUNT(pt.photo_id) AS total_usage
FROM photo_tags pt
JOIN tags t ON pt.tag_id = t.id
GROUP BY t.tag_name
ORDER BY total_usage DESC
LIMIT 10;

-- 2. Tags from high-engagement photos
WITH likes_count AS (
    SELECT photo_id, COUNT(*) AS total_likes
    FROM likes
    GROUP BY photo_id
),
comments_count AS (
    SELECT photo_id, COUNT(*) AS total_comments
    FROM comments
    GROUP BY photo_id
),
photo_engagement AS (
    SELECT 
        p.id AS photo_id,
        COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0) AS total_engagement
    FROM photos p
    LEFT JOIN likes_count l ON p.id = l.photo_id
    LEFT JOIN comments_count c ON p.id = c.photo_id
),
top_photos AS (
    SELECT photo_id
    FROM photo_engagement
    ORDER BY total_engagement DESC
    LIMIT 50
)
SELECT 
    t.tag_name,
    COUNT(*) AS usage_in_top_photos
FROM top_photos tp
JOIN photo_tags pt ON tp.photo_id = pt.photo_id
JOIN tags t ON pt.tag_id = t.id
GROUP BY t.tag_name
ORDER BY usage_in_top_photos DESC
LIMIT 10 ;



-- SOLUTION Q10.


-- Likes received
WITH likes_received AS (
    SELECT p.user_id, COUNT(*) AS likes_received
    FROM photos p
    JOIN likes l ON p.id = l.photo_id
    GROUP BY p.user_id
),

-- Likes given
likes_given AS (
    SELECT user_id, COUNT(*) AS likes_given
    FROM likes
    GROUP BY user_id
),

-- Comments received
comments_received AS (
    SELECT p.user_id, COUNT(*) AS comments_received
    FROM photos p
    JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
),

-- Comments made
comments_made AS (
    SELECT user_id, COUNT(*) AS comments_made
    FROM comments
    GROUP BY user_id
),

-- Tags used
tags_used AS (
    SELECT p.user_id, COUNT(*) AS total_tags
    FROM photos p
    JOIN photo_tags pt ON p.id = pt.photo_id
    GROUP BY p.user_id
)

-- Final result
SELECT 
    u.id AS user_id,
    u.username,

    COALESCE(lr.likes_received, 0) AS likes_received,
    COALESCE(lg.likes_given, 0) AS likes_given,

    COALESCE(cr.comments_received, 0) AS comments_received,
    COALESCE(cm.comments_made, 0) AS comments_made,

    COALESCE(t.total_tags, 0) AS total_tags

FROM users u
LEFT JOIN likes_received lr ON u.id = lr.user_id
LEFT JOIN likes_given lg ON u.id = lg.user_id
LEFT JOIN comments_received cr ON u.id = cr.user_id
LEFT JOIN comments_made cm ON u.id = cm.user_id
LEFT JOIN tags_used t ON u.id = t.user_id;



-- SOLUTION Q11. 


WITH latest_date AS (
    SELECT MAX(created_at) AS max_date
    FROM (
        SELECT created_at FROM likes
        UNION ALL
        SELECT created_at FROM comments
    ) t
),

likes AS (
    SELECT 
        p.user_id,
        COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l ON p.id = l.photo_id
    WHERE l.created_at >= DATE_SUB((SELECT max_date FROM latest_date), INTERVAL 1 MONTH)
    GROUP BY p.user_id
),

comments AS (
    SELECT 
        p.user_id,
        COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c ON p.id = c.photo_id
    WHERE c.created_at >= DATE_SUB((SELECT max_date FROM latest_date), INTERVAL 1 MONTH)
    GROUP BY p.user_id
)

SELECT 
    u.id AS user_id,
    u.username,

    COALESCE(l.total_likes, 0) AS total_likes,
    COALESCE(c.total_comments, 0) AS total_comments,

    (COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)) AS total_engagement,

    RANK() OVER (
        ORDER BY 
        (COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)) DESC
    ) AS rnk

FROM users u
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id;




-- SOLUTION Q12. 


WITH top_photos AS (
    SELECT 
        p.id AS photo_id,
        COUNT(l.user_id) AS total_likes
    FROM photos p
    LEFT JOIN likes l 
        ON p.id = l.photo_id
    GROUP BY p.id
    ORDER BY total_likes DESC
    LIMIT 50
),
tag_likes AS (
    SELECT 
        t.tag_name,
        tp.total_likes
    FROM top_photos tp
    JOIN photo_tags pt 
        ON tp.photo_id = pt.photo_id
    JOIN tags t 
        ON pt.tag_id = t.id
)
SELECT 
    tag_name,
    ROUND(AVG(total_likes), 2) AS avg_likes
FROM tag_likes
GROUP BY tag_name
ORDER BY avg_likes DESC
LIMIT 10;


-- SOLUTION Q13. 

-- For the users who have started following someone after being followed by that person:

SELECT 
    f1.follower_id AS user_a,
    f1.followee_id AS user_b,
    f1.created_at AS a_followed_b_time,
    f2.created_at AS b_followed_a_time
FROM follows f1
JOIN follows f2 
    ON f1.follower_id = f2.followee_id
   AND f1.followee_id = f2.follower_id
WHERE f2.created_at > f1.created_at;


-- For the users who mutually follows each other:

SELECT 
    u1.id AS user1_id,
    u1.username AS user1,
    u2.id AS user2_id,
    u2.username AS user2
FROM follows f1
JOIN follows f2 
    ON f1.follower_id = f2.followee_id
   AND f1.followee_id = f2.follower_id
JOIN users u1 ON f1.follower_id = u1.id
JOIN users u2 ON f1.followee_id = u2.id
WHERE u1.id < u2.id;