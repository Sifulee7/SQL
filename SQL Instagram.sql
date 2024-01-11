-- 1. How many times does the average user post?
WITH CTE AS(SELECT * FROM users JOIN photos ON users.id=photos.user_id),
Photos_Count AS(SELECT COUNT(*) FROM photos),
Users_Count AS(SELECT COUNT(*) FROM users),
Average AS (SELECT
	(SELECT COUNT(*) FROM photos) AS Photos_Count,
    (SELECT COUNT(*) FROM users) AS Users_Count,
    ((SELECT COUNT(*) FROM photos)/(SELECT COUNT(*) FROM users)) AS Avg)
SELECT * FROM Average;

SELECT COUNT(DISTINCT user_id) as Number_Of_Users, COUNT(photos.id) as Total_Photos,(SELECT COUNT(photos.id)/COUNT(DISTINCT user_id)) as Average_User_Post FROM photos;


-- 2. Find the top 5 most used hashtags.

SELECT 
	tag_name, 
    count(tag_id) AS tag_count 
FROM tags INNER JOIN (SELECT tag_id FROM photo_tags) ptg ON tags.id = ptg.tag_id
GROUP BY tag_name
ORDER BY tag_count DESC
LIMIT 5;

-- 3. Find users who have liked every single photo on the site.
SELECT users.username as Users_Who_liked_every_photo
FROM users
WHERE id IN (
    SELECT user_id
    FROM likes
    GROUP BY user_id
    HAVING COUNT(photo_id) = (SELECT COUNT(*) FROM photos)
); 

-- 4. Retrieve a list of users along with their usernames and the rank of their account creation, ordered by the creation date in ascending order

SELECT id, username, created_at, RANK() OVER( ORDER BY created_at ASC) AS ranking FROM users;


-- 5. List the comments made on photos with their comment texts, photo URLs, and usernames of users who posted the comments. Include the comment count for each photo
WITH Comments_made AS (
SELECT
  photos.id,
  image_url,
  comment_text,
  comments.user_id
FROM comments
INNER JOIN photos ON comments.photo_id = photos.id)
SELECT Comments_made.id AS Photo_id, comment_text, image_url, comments_made.user_id AS ID_Of_User_Who_Commented, username, count(Comments_made.id) Over (PARTITION BY Comments_made.id) AS Count_Of_Comments_for_each_Post  FROM Comments_made
INNER JOIN users ON Comments_made.user_id = users.id;


-- 6. For each tag, show the tag name and the number of photos associated with that tag. Rank the tags by the number of photos in descending order.
SELECT
  tag_name,
  COUNT(*) AS photo_count,
  RANK() OVER(ORDER BY COUNT(*) DESC) as ranking
FROM tags
INNER JOIN photo_tags ON tags.id = photo_tags.tag_id
GROUP BY tag_name;


-- 7. List the usernames of users who have posted photos along with the count of photos they have posted. Rank them by the number of photos in descending order.
SELECT 
	username, 
	COUNT(*) AS post_count,
	RANK() OVER(ORDER BY COUNT(*) DESC) AS ranking
FROM users u
INNER JOIN photos p ON  u.id=p.user_id
GROUP BY username;


-- 8. Display the username of each user along with the creation date of their first posted photo and the creation date of their next posted photo.
With answer AS
	 (SELECT users.id, username, image_url AS first_photo,
	 ROW_NUMBER() OVER(PARTITION BY users.id ORDER BY p.created_at) AS Row_Num,
	 p.created_at  creation_date_first_photo,
	 LEAD(image_url) OVER( PARTITION BY users.id ORDER BY p.created_at) AS next_photo,
	 LEAD(p.created_at) OVER( PARTITION BY users.id ORDER BY p.created_at ASC) AS Creation_date_next_photo
	 FROM photos p INNER JOIN users ON p.user_id=users.id )
 SELECT answer.id,username,first_photo,creation_date_first_photo,next_photo,Creation_date_next_photo FROM answer WHERE Row_Num=1;
 
 
-- 9.  For each comment, show the comment text, the username of the commenter, and the comment text of the previous comment made on the same photo.
CREATE VIEW Comment_user as
SELECT photos.id,
	image_url,
	comment_text,
	username,
    LAG(comment_text) OVER(PARTITION BY photos.id ORDER BY comments.created_at) AS previous_comment_on_same_photo 
    FROM photos INNER JOIN comments ON comments.photo_id=photos.id INNER JOIN users ON comments.user_id=users.id;

SELECT * FROM Comment_user;


-- 10. Show the username of each user along with the number of photos they have posted and the number of photos posted by the user before them and after them, based on the creation date.
SELECT
  user_id,
  username,
  COUNT(*) ,
  LEAD(count(*)) OVER ( ORDER BY photos.created_at) AS photo_count_after,
  LAG(count(*)) OVER ( ORDER BY photos.created_at) AS photo_count_before
FROM photos INNER JOIN users ON photos.user_id=users.id GROUP BY user_id;

