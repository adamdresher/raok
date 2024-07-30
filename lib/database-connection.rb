require 'pg'

# Connection to PostgreSQL database
class DatabaseConnection
  def initialize(logger: nil)
    @logger = logger
    @db = if Sinatra::Base.production?
            PG.connect(ENV['DATABASE_URL'])
          elsif Sinatra::Base.test?
            PG.connect(dbname: 'raok_db_test')
          else
            PG.connect(dbname: 'raok_db')
          end
  end

  def disconnect
    @db.close
  end

  def query(*params, sql)
    @logger.info "#{sql}: #{params}"
    @db.exec_params(sql, params)
  end

  def delete_all_data
    sql = 'DELETE FROM users;'

    @db.query(sql)
  end
end
