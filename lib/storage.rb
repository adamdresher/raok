require_relative 'metadata-processor'
require_relative 'database-connection'

# Account management and public data interface
class Storage < DatabaseConnection
  include MetadataProcessor

  # Reading storage

  # could be more expressive to use User::exists?(username: nil, user_id: nil)
  def user_exists?(username: nil, user_id: nil)
    if username
      sql = 'SELECT username FROM users;'
      result = query(sql)
      users = result.values.flatten

      users.include?(username)
    else
      sql = 'SELECT id FROM users;'
      result = query(sql)
      users = result.values.flatten

      users.include?(user_id)
    end
  end

  alias includes_username? user_exists?

  # could be more expressive to use User::email_exists? or User::email_used?
  def includes_email?(email)
    sql = 'SELECT email FROM users;'

    result = query(sql)
    users = result.values.flatten

    users.include?(email)
  end

  def find_user_id(username)
  # def user_id_for(username)
    sql = <<~QUERY
      SELECT id FROM users
       WHERE username = $1;
    QUERY

    result = query(username, sql)

    result.first['id']
  end

  def similar_user_ids_for(username)
    sql = <<~QUERY
      SELECT id FROM users
       WHERE $1       SIMILAR TO concat('%', username, '%')
          OR username SIMILAR TO concat('%', $1, '%');
    QUERY

    result = query(username, sql)
    result.values.flatten
  end

  def find_posts_for(hashtag)
  # def all_posts_for(hashtag)
    sql = <<~QUERY
      SELECT p.id AS post_id,
             u.username AS posted_by,
             u.id AS user_id,
             p.description AS description,
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
        JOIN hashtags AS h
          ON p.id = h.post_id
        JOIN hashtag_list AS hl
          ON h.hashtag_id = hl.id
       WHERE $1 = hl.title
    ORDER BY p.id;
    QUERY

    result = query(hashtag, sql)
    merge_metadata(result)
  end

  def encrypted_password_for(username)
    sql = <<~QUERY
      SELECT password FROM users
       WHERE username = $1;
    QUERY

    result = query(username, sql)

    result.values.flatten.first
  end

  def all_posts
    sql = <<~QUERY
      SELECT p.id AS post_id,
             u.username AS posted_by,
             u.id AS user_id,
             p.description AS description,
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
    ORDER BY p.id;
    QUERY

    result = query(sql)
    merge_metadata(result)
  end

  def post(id)
    sql = <<~QUERY
      SELECT p.id AS post_id,
             u.username AS posted_by,
             u.id AS user_id,
             p.description AS description,
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
       WHERE p.id = $1;
    QUERY

    result = query(id, sql)
    merge_metadata(result)[id]
  end

  # Writing to storage

  def add_user!(user_data)
    sql = <<~QUERY
      INSERT INTO users
             (name, email, username, password)
      VALUES ($1, $2, $3, $4)
    QUERY

    query(*user_data, sql)
  end

  def delete_user!(user)
    sql = <<~QUERY
      DELETE FROM users
            WHERE id = $1;
    QUERY

    query(user.id, sql)
  end
end
