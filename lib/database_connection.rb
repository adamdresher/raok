require 'pg'

# Connects to the database
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
    @logger&.info "#{sql}: #{params}"
    @db.exec_params(sql, params)
  end

  def delete_all_data
    relations = ['users', 'hashtag_list']
    sequences = ['users_id_seq', 'posts_id_seq', 'likes_id_seq',
                 'comments_id_seq', 'favorites_id_seq',
                 'hashtags_id_seq', 'hashtag_list_id_seq']

    relations.each do |relation|
      sql = "DELETE FROM #{relation};"
      @db.query(sql)
    end

    sequences.each do |sequence|
      sql = "ALTER SEQUENCE #{sequence} RESTART;"
      @db.exec(sql)
    end
  end
end
