require_relative 'database-connection'
require_relative 'metadata-processor'

class Users < DatabaseConnection
  include MetadataProcessor

  def add!(user_data)
    sql = <<~QUERY
      INSERT INTO users
             (name, email, username, password)
      VALUES ($1, $2, $3, $4)
    QUERY

    query(*user_data, sql)
  end

  def delete!(user)
    sql = <<~QUERY
      DELETE FROM users
            WHERE id = $1;
    QUERY

    query(user.id, sql)
  end

  def encrypted_password_for(username)
    sql = <<~QUERY
      SELECT password FROM users
       WHERE username = $1;
    QUERY

    result = query(username, sql)

    result.values.flatten.first
  end

  def exists?(username: nil, user_id: nil, email: nil)
    if username
      sql = 'SELECT username FROM users;'

      result = query(sql)
      users = result.values.flatten

      users.include?(username)
    elsif user_id
      sql = 'SELECT id FROM users;'

      result = query(sql)
      users = result.values.flatten

      users.include?(user_id)
    elsif email
      sql = 'SELECT email FROM users;'

      result = query(sql)
      users = result.values.flatten

      users.include?(email)
    end
  end

  alias include? exists?

  def id_for(username)
    sql = <<~QUERY
      SELECT id FROM users
       WHERE username = $1;
    QUERY

    result = query(username, sql)

    result.first['id']
  end

  def ids_for_similar(username)
    sql = <<~QUERY
      SELECT id FROM users
       WHERE $1       SIMILAR TO concat('%', username, '%')
          OR username SIMILAR TO concat('%', $1, '%');
    QUERY

    result = query(username, sql)

    result.values.flatten
  end
end
