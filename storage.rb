class Storage
  def initialize(db)
    @db = db
  end

  def user_exists?(username)
    sql = "SELECT username FROM users;"

    result = @db.query(sql)
    users = result.values.flatten

    users.include?(username)
  end

  def add_user!(user_data)
    sql = <<~QUERY
      INSERT INTO users
             (name, email, username, password)
      VALUES ($1, $2, $3, $4)
    QUERY

    @db.query(*user_data, sql)
  end

  def delete_user!(db, username)
    sql = <<~QUERY
      DELETE FROM users
       WHERE username = $1
    QUERY

  @db.query(*user_data, sql)
  end

  def encrypted_password_for(username)
    sql = <<~QUERY
      SELECT password FROM users
       WHERE username = $1;
    QUERY

    result = @db.query(username, sql)

    result.values.flatten.first
  end

  def all_posts
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
      ORDER BY p.id;
    QUERY

    @db.query(sql)
  end

  def post(id)
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
         WHERE p.id = $1;
    QUERY

    result = @db.query(id, sql)
  end
end

