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
      SELECT description FROM posts
        JOIN users
          ON users.id = posts.user_id
       WHERE username = $1;
    QUERY

    @db.query(sql, username)
  end
end

