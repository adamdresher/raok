class Storage
  def initialize(db:)
    @db = db
  end

  def add_user!(user_data)
    sql = <<~QUERY
      INSERT INTO users
             (name, email, username, password)
      VALUES ($1, $2, $3, $4)
    QUERY

    @db.query(sql, *user_data)
  end

  def user_exists?(username)
    sql = "SELECT username FROM users;"

    result = @db.query(sql)
    users = result.values.flatten

    users.include?(username)
  end

  def encrypted_password_for(username)
    sql = <<~QUERY
      SELECT password FROM users
       WHERE username = $1;
    QUERY

    result = @db.query(sql, username)

    result.values.flatten.first
  end

  def all_posts
    sql = "SELECT description FROM posts;"

    @db.query(sql)
  end
end

