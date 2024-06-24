class DatabasePersistence
  def initialize(logger)
  @db = PG.connect(dbname: 'raok')
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def query(sql, *params)
    @logger.info "#{sql}: #{params}"
    @db.exec_params(sql, params)
  end
end

class Storage
  def initialize(db:)
    @db = db
  end

  def add_user!(user_data)
    sql = "INSERT INTO users (name, email, username, password) VALUES ($1, $2, $3, $4)"

    @db.query(sql, *user_data)
  end

  def user_exists?(username)
    sql = "SELECT username FROM users;"
    result = @db.query(sql)
    users = result.values.flatten

    users.include?(username)
  end

  def encrypted_password_for(username)
    sql = "SELECT password FROM users WHERE username = $1;"
    result = @db.query(sql, username)

    result.values.flatten.first
  end

  def user_profile(username) # doesnt display password
    sql = "SELECT name, email, username FROM users WHERE username = $1;"
    result = @db.query(sql, username)

    result.first
  end

  def add_post!(username, description)
    sql = "SELECT id FROM users WHERE username = $1"
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

  def all_posts
    sql = "SELECT description FROM posts;"

    @db.query(sql)
  end
end

class User
  def initialize(db:)
    @db = db
  end

  def profile(username) # doesnt display password
    sql = "SELECT name, email, username FROM users WHERE username = $1;"
    result = @db.query(sql, username)

    result.first
  end

  def add_post!(username, description)
    sql = "SELECT id FROM users WHERE username = $1"
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
