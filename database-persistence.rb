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

