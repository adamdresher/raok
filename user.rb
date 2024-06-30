class User
  def initialize(db:)
    @db = db
  end

  def profile(username) # doesnt display password
    sql = <<~QUERY
      SELECT name, email, username FROM users
       WHERE username = $1;
    QUERY

    result = @db.query(sql, username)

    result.first
  end

  def add_post!(username, description)
    sql = <<~QUERY
      SELECT id FROM users
       WHERE username = $1
    QUERY

    user_id = @db.query(sql, username).values.flatten.first

    sql = "INSERT INTO posts (user_id, description) VALUES ($1, $2);"

    @db.query(sql, user_id, description)
  end

  def posts(username)
    sql = <<~QUERY
        SELECT p.id AS post_id,
               u.username AS posted_by,
               substring(p.description FOR 24) AS description,
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

    @db.query(sql, username)
  end
end

