require 'pg'

class DatabaseConnection
  def initialize(logger: nil)
    if Sinatra::Base.production?
      @db = PG.connect(ENV["DATABASE_URL"])
    elsif Sinatra::Base.test?
      @db = PG.connect(dbname: 'raok_db_test')
    else
      @db = PG.connect(dbname: 'raok_db')
    end
    @logger = logger
  end

  def disconnect
    @db.close
  end

  def query(*params, sql)
    @logger.info "#{sql}: #{params}"
    @db.exec_params(sql, params)
  end

  def delete_all_data
    sql = "DELETE FROM users;"

    @db.query(sql)
  end
end

