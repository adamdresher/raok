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
    @logger.info "#{sql}: #{params}" if @logger
    @db.exec_params(sql, params)
  end

  def delete_all_data
    sql = 'DELETE FROM users;'

    @db.query(sql)

    sequences = ['users_id_seq', 'posts_id_seq', 'likes_id_seq', 'comments_id_seq',
                 'favorites_id_seq', 'hashtags_id_seq', 'hashtag_list_id_seq']

    sequences.each do |sequence|
      sql = "ALTER SEQUENCE #{sequence} RESTART;"
      @db.exec(sql)
    end
  end
end
