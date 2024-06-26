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
         SELECT p_user.username AS posted_by, p.description, p.id, u.username AS liked_by
           FROM posts AS p
      FULL JOIN likes AS l
             ON p.id = l.post_id
           JOIN users AS u
             ON u.id = l.user_id
           JOIN users AS p_user
             ON p_user.id = p.user_id
           WHERE p_user.username = $1;
    QUERY

    @db.query(sql, username)
  end
end

