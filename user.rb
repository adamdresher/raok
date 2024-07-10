require_relative 'metadata_processor'

class User
  include MetadataProcessor

  def initialize(user_id, db)
    @db = db
    @profile = self.class.profile(user_id, db)

    @id = @profile['id']
    @username = @profile['username']
    @name = @profile['name']
    @email = @profile['email']
  end

  attr_reader :profile, :id, :username, :name, :email

  def self.id(username, db)
    sql = <<~QUERY
      SELECT id, name, email, username FROM users
       WHERE username = $1;
    QUERY

    result = db.query(username, sql)

    result.first['id']
  end

  def self.profile(user_id, db)
    sql = <<~QUERY
      SELECT id, name, email, username FROM users
       WHERE id = $1;
    QUERY

    result = db.query(user_id, sql)

    result.first
  end

  def update_profile!(old_name, old_email, new_name, new_email)
    sql = <<~QUERY
      UPDATE users
         SET name = $1,
             email = $2
       WHERE name = $3 AND email = $4;
    QUERY

    @db.query(new_name, new_email, old_name, old_email, sql)
    @profile = self.class.profile(@id, @db)
  end

  def delete!
    sql = <<~QUERY
      DELETE FROM users
       WHERE id = $1;
    QUERY

    @db.query(@id, sql)
  end

  def add_post!(username, description)
    sql = <<~QUERY
      INSERT INTO posts
             (user_id, description)
      VALUES ($1, $2);
    QUERY

    @db.query(@id, description, sql)
  end

  def delete_post!(post_id)
    sql = <<~QUERY
      DELETE FROM posts
       WHERE id = $1;
    QUERY

    @db.query(post_id, sql)
  end

  def posts
    sql = <<~QUERY
        SELECT p.id AS post_id,
               u.username AS posted_by,
               p.description AS description,
               l_user.username AS liked_by,
               c.id AS comment_id,
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

    result = @db.query(self.username, sql)
    merge_metadata(result)
  end
end

