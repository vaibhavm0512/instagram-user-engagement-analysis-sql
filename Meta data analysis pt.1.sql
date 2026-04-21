-- OBJECTIVE QUESTIONS


USE ig_clone;

-- SOLUTION Q1.
 
-- Checking for null values

SELECT 'users' AS table_name, COUNT(*) AS null_count
FROM users
WHERE username IS NULL
UNION ALL
SELECT 'photos', COUNT(*)
FROM photos
WHERE user_id IS NULL
UNION ALL
SELECT 'likes', COUNT(*)
FROM likes
WHERE user_id IS NULL
UNION ALL
SELECT 'comments', COUNT(*)
FROM comments
WHERE user_id IS NULL
UNION ALL
SELECT 'follows', COUNT(*)
FROM follows
WHERE follower_id IS NULL OR followee_id IS NULL
UNION ALL
SELECT 'tags', COUNT(*)
FROM tags
WHERE tag_name IS NULL
UNION ALL
SELECT 'photo_tags', COUNT(*)
FROM photo_tags
WHERE photo_id IS NULL OR tag_id IS NULL;


-- Checking for duplicate values
-- 1. Duplicate users
SELECT 
    username,
    COUNT(*) AS duplicate_count
FROM users
GROUP BY username
HAVING COUNT(*) > 1;

-- 2. Duplicate likes 
SELECT 
    user_id,
    photo_id,
    COUNT(*) AS duplicate_count
FROM likes
GROUP BY user_id, photo_id
HAVING COUNT(*) > 1;

-- 3. Duplicate comments
SELECT 
    user_id,
    photo_id,
    comment_text,
    COUNT(*) AS duplicate_count
FROM comments
GROUP BY user_id, photo_id, comment_text
HAVING COUNT(*) > 1;



-- SOLUTION Q2.

WITH user_activity AS (
    SELECT
        u.id AS user_id,
        u.username,
        COUNT(DISTINCT p.id) AS total_photos,
        COUNT(DISTINCT l.photo_id) AS total_likes,
        COUNT(DISTINCT c.id) AS total_comments
    FROM users u
    LEFT JOIN photos p
        ON u.id = p.user_id
    LEFT JOIN likes l
        ON u.id = l.user_id
    LEFT JOIN comments c
        ON u.id = c.user_id
    GROUP BY u.id, u.username
),
activity_bucket AS (
    SELECT
        user_id,
        username,
        total_photos,
        total_likes,
        total_comments,
        (total_photos + total_likes + total_comments) AS total_activity,
        CASE
            WHEN (total_photos + total_likes + total_comments) = 0 THEN 'Inactive'
            WHEN (total_photos + total_likes + total_comments) BETWEEN 1 AND 5 THEN 'Low Activity'
            WHEN (total_photos + total_likes + total_comments) BETWEEN 6 AND 20 THEN 'Medium Activity'
            ELSE 'High Activity'
        END AS activity_level
    FROM user_activity
)
SELECT
    activity_level,
    COUNT(*) AS user_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM users), 2) AS user_percentage
FROM activity_bucket
GROUP BY activity_level
ORDER BY user_count DESC;



-- SOLUTION Q3.


-- a)Excluding posts with zero tags
SELECT ROUND(AVG(tag_count), 2) AS avg_tags_per_post
FROM(
      SELECT photo_id, 
      COUNT(tag_id) AS tag_count
      FROM photo_tags
      GROUP BY photo_id
) AS tag_summary;

-- b)Including posts with zero tags
-- Step 1: Count tags per photo
WITH tag_count AS (
    SELECT 
        p.id AS photo_id,
        COUNT(pt.tag_id) AS total_tags
    FROM photos p
    LEFT JOIN photo_tags pt ON p.id = pt.photo_id
    GROUP BY p.id
)
-- Step 2: Average tags per post
SELECT 
    ROUND(AVG(total_tags), 2) AS avg_tags_per_post
FROM tag_count;



-- SOLUTION Q4.


WITH posts AS (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id),
likes AS (
    SELECT p.user_id, COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l ON p.id = l.photo_id
    GROUP BY p.user_id),
comments AS (
    SELECT p.user_id, COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id)
SELECT 
    u.id AS user_id,
    u.username,
    COALESCE(p.total_posts, 0) AS total_posts,
    COALESCE(l.total_likes, 0) AS total_likes,
    COALESCE(c.total_comments, 0) AS total_comments,
    ROUND(
        CASE 
            WHEN COALESCE(p.total_posts, 0) = 0 THEN 0
            ELSE (COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)) * 1.0 
                 / COALESCE(p.total_posts, 0)
        END, 2
    ) AS engagement_rate
FROM users u
LEFT JOIN posts p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
ORDER BY engagement_rate DESC
LIMIT 20;



-- SOLUTION Q5.

-- Top users by followers
SELECT 
    u.id AS user_id,
    u.username,
    COUNT(f.followee_id) AS total_followers
FROM users u
LEFT JOIN follows f ON u.id = f.followee_id
GROUP BY u.id, u.username
ORDER BY total_followers DESC
LIMIT 10;

-- Top users by following
SELECT 
    u.id AS user_id,
    u.username,
    COUNT(f.follower_id) AS total_following
FROM users u
LEFT JOIN follows f ON u.id = f.follower_id
GROUP BY u.id, u.username
ORDER BY total_following DESC
LIMIT 10;



-- SOLUTION Q6.

-- Posts per user
WITH posts AS (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
),
-- Likes per user
likes AS (
    SELECT p.user_id, COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l ON p.id = l.photo_id
    GROUP BY p.user_id),
-- Comments per user
comments AS (
    SELECT p.user_id, COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id)
SELECT 
    u.id AS user_id,
    u.username,
    COALESCE(p.total_posts, 0) AS total_posts,
    COALESCE(l.total_likes, 0) AS total_likes,
    COALESCE(c.total_comments, 0) AS total_comments,
    ROUND(
        CASE 
            WHEN COALESCE(p.total_posts, 0) = 0 THEN 0
            ELSE (COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)) * 1.0 
                 / COALESCE(p.total_posts, 0)
        END, 2
    ) AS avg_engagement_per_post
FROM users u
LEFT JOIN posts p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
ORDER BY avg_engagement_per_post DESC;



-- SOLUTION Q7.


SELECT 
    u.id AS user_id,
    u.username
FROM users u
LEFT JOIN likes l ON u.id = l.user_id
WHERE l.user_id IS NULL;


