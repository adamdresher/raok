require_relative 'database_connection'
require_relative 'metadata_processor'
require_relative 'post'

# Interface for all posts
class Posts < DatabaseConnection
  include MetadataProcessor

  # rubocop:disable Metrics/MethodLength
  def all
    sql = <<~QUERY
        SELECT p.id,
               p.created_on,
               u.username AS posted_by,
               u.id AS user_id,
               p.description,
               hl.title AS hashtag,
               l_user.username AS liked_by,
               c.id AS comment_id,
               c_user.id AS comment_user_id,
               c_user.username AS commented_by,
               c.description AS comment
          FROM posts AS p
          JOIN users AS u
            ON u.id = p.user_id
     LEFT JOIN likes AS l
            ON p.id = l.post_id
     LEFT JOIN users AS l_user
            ON l.user_id = l_user.id
     LEFT JOIN comments AS c
            ON p.id = c.post_id
     LEFT JOIN users AS c_user
            ON c.user_id = c_user.id
     LEFT JOIN hashtags AS h
            ON p.id = h.post_id
     LEFT JOIN hashtag_list AS hl
            ON h.hashtag_id = hl.id
      ORDER BY p.id;
    QUERY

    result = query(sql)
    posts_data = merge_metadata(result)

    posts_data.map { |_id, post_data| Post.new(post_data) }
  end

  def from_user(id)
    sql = <<~QUERY
        SELECT p.id,
               p.created_on,
               u.username AS posted_by,
               u.id AS user_id,
               p.description,
               hl.title AS hashtag,
               l_user.username AS liked_by,
               c.id AS comment_id,
               c_user.id AS comment_user_id,
               c_user.username AS commented_by,
               c.description AS comment
          FROM posts AS p
          JOIN users AS u
            ON u.id = p.user_id
     LEFT JOIN likes AS l
            ON p.id = l.post_id
     LEFT JOIN users AS l_user
            ON l.user_id = l_user.id
     LEFT JOIN comments AS c
            ON p.id = c.post_id
     LEFT JOIN users AS c_user
            ON c.user_id = c_user.id
     LEFT JOIN hashtags AS h
            ON p.id = h.post_id
     LEFT JOIN hashtag_list AS hl
            ON h.hashtag_id = hl.id
         WHERE u.id = $1
      ORDER BY p.id;
    QUERY

    result = query(id, sql)
    posts_data = merge_metadata(result)

    posts_data.map { |_id, post_data| Post.new(post_data) }
  end

  def last_post
    sql = <<~QUERY
        SELECT p.id,
               p.created_on,
               u.username AS posted_by,
               u.id AS user_id,
               p.description,
               hl.title AS hashtag,
               l_user.username AS liked_by,
               c.id AS comment_id,
               c_user.id AS comment_user_id,
               c_user.username AS commented_by,
               c.description AS comment
          FROM posts AS p
          JOIN users AS u
            ON u.id = p.user_id
     LEFT JOIN likes AS l
            ON p.id = l.post_id
     LEFT JOIN users AS l_user
            ON l.user_id = l_user.id
     LEFT JOIN comments AS c
            ON p.id = c.post_id
     LEFT JOIN users AS c_user
            ON c.user_id = c_user.id
     LEFT JOIN hashtags AS h
            ON p.id = h.post_id
     LEFT JOIN hashtag_list AS hl
            ON h.hashtag_id = hl.id
      ORDER BY p.id
         LIMIT 1;
    QUERY

    result = query(sql)
    post_data = merge_metadata(result).first

    Post.new(post_data)
  end

  def with_hashtag(title)
    sql = <<~QUERY
        SELECT p.id,
               p.created_on,
               u.username AS posted_by,
               u.id AS user_id,
               p.description,
               hl.title AS hashtag,
               l_user.username AS liked_by,
               c.id AS comment_id,
               c_user.id AS comment_user_id,
               c_user.username AS commented_by,
               c.description AS comment
          FROM posts AS p
          JOIN users AS u
            ON u.id = p.user_id
     LEFT JOIN likes AS l
            ON p.id = l.post_id
     LEFT JOIN users AS l_user
            ON l.user_id = l_user.id
     LEFT JOIN comments AS c
            ON p.id = c.post_id
     LEFT JOIN users AS c_user
            ON c.user_id = c_user.id
     LEFT JOIN hashtags AS h
            ON p.id = h.post_id
     LEFT JOIN hashtag_list AS hl
            ON h.hashtag_id = hl.id
         WHERE hl.title = $1
      ORDER BY p.id;
    QUERY

    result = query(title, sql)
    posts_data = merge_metadata(result)

    posts_data.map { |_id, post_data| Post.new(post_data) }
  end

  def with_id(id)
    sql = <<~QUERY
      SELECT p.id,
             p.created_on,
             u.username AS posted_by,
             u.id AS user_id,
             p.description,
             hl.title AS hashtag,
             l_user.username AS liked_by,
             c.id AS comment_id,
             c_user.id AS comment_user_id,
             c_user.username AS commented_by,
             c.description AS comment
        FROM posts AS p
        JOIN users AS u
          ON u.id = p.user_id
   LEFT JOIN likes AS l
          ON p.id = l.post_id
   LEFT JOIN users AS l_user
          ON l.user_id = l_user.id
   LEFT JOIN comments AS c
          ON p.id = c.post_id
   LEFT JOIN users AS c_user
          ON c.user_id = c_user.id
   LEFT JOIN hashtags AS h
          ON p.id = h.post_id
   LEFT JOIN hashtag_list AS hl
          ON h.hashtag_id = hl.id
       WHERE p.id = $1;
    QUERY

    result = query(id, sql)
    post_data = merge_metadata(result)[id]

    Post.new(post_data)
  end
  # rubocop:enable Metrics/MethodLength
end
