require_relative 'metadata-processor'
require_relative 'database-connection'

# User interface
class User < DatabaseConnection
  include MetadataProcessor

  def initialize(user_id: nil, logger: nil)
    super(logger: logger)

    @profile = find_profile(user_id)
    @id = @profile['id']
    @username = @profile['username']
    @name = @profile['name']
    @email = @profile['email']
  end

  attr_reader :profile, :id, :username, :name, :email

  def public_profile
    @profile.reject { |k, _| ['id', 'username'].include? k }
  end

  def update_profile!(old_name, old_email, new_name, new_email)
    sql = <<~QUERY
      UPDATE users
         SET name = $1,
             email = $2
       WHERE name = $3 AND email = $4;
    QUERY

    query(new_name, new_email, old_name, old_email, sql)
    @profile = find_profile(@id)
  end

  def posts
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
       WHERE u.username = $1
    ORDER BY p.id;
    QUERY

    result = query(username, sql)
    merge_metadata(result)
  end

  def add_post!(description)
    sql = <<~QUERY
      INSERT INTO posts
                  (user_id, description)
           VALUES ($1, $2);
    QUERY

    query(id, description, sql)
  end

  def delete_post!(post_id)
    sql = <<~QUERY
      DELETE FROM posts
            WHERE id = $1;
    QUERY

    query(post_id, sql)
  end

  def toggle_like!(post_id)
    like_state = post_liked?(post_id)
    like_sql = <<~QUERY
      INSERT INTO likes
                  (post_id, user_id)
           VALUES ($1, $2);
    QUERY
    unlike_sql = <<~QUERY
      DELETE FROM likes
            WHERE post_id = $1 AND user_id = $2;
    QUERY

    sql = (like_state ? unlike_sql : like_sql)
    user_id = id

    query(post_id, user_id, sql)
  end

  def add_comment!(post_id, comment)
    sql = <<~QUERY
      INSERT INTO comments
                  (post_id, user_id, description)
           VALUES ($1, $2, $3);
    QUERY

    query(post_id, @id, comment, sql)
  end

  private

  def find_profile(user_id)
    sql = <<~QUERY
      SELECT id, name, email, username FROM users
       WHERE id = $1;
    QUERY

    result = query(user_id, sql)

    result.first
  end

  def post_liked?(id)
    public_posts = all_posts
    likes = public_posts[id]['liked_by']

    likes.include?(username) if likes
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
end
