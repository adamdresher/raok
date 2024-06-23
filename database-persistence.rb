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

  def add_user!(user_data)
    sql = "INSERT INTO users (name, email, username, password) VALUES ($1, $2, $3, $4)"

    query(sql, *user_data)
  end

  def user_exists?(username)
    sql = "SELECT username FROM users;"
    result = query(sql)
    users = result.values.flatten

    users.include?(username)
  end

  def encrypted_password_for(username)
    sql = "SELECT password FROM users WHERE username = $1;"
    result = query(sql, username)

    result.values.flatten.first
  end

  def user_profile(username) # doesnt display password
    sql = "SELECT name, email, username FROM users WHERE username = $1;"
    result = query(sql, username)

    result.first
  end
end

