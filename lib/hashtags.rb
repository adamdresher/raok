require_relative 'database_connection'

# Handles the interface for hashtags
class Hashtags < DatabaseConnection
  def all
    sql = <<~QUERY
      SELECT title FROM hashtag_list;
    QUERY

    result = query(sql)
    result.values.flatten
  end

  def record_from(post)
    return if post.hashtags.empty?

    post.hashtags.each do |hashtag|
      create!(hashtag) unless exists?(hashtag)
      hashtag_id = id(hashtag)
      connect_to_post!(post.id, hashtag_id)
    end
  end

  def select_hashtags(post_description)
    post_description.split.select { |string| string[0] == '#' }.map { |string| string[1..] }
  end

  private

  def exists?(title)
    sql = <<~QUERY
      SELECT title
        FROM hashtag_list;
    QUERY

    result = query(sql)

    result.values.flatten.include? title
  end

  def id(title)
    sql = <<~QUERY
      SELECT id
        FROM hashtag_list
       WHERE title = $1;
    QUERY

    result = query(title, sql)
    result.values.flatten.first
  end

  def connect_to_post!(post_id, hashtag_id)
    sql = <<~QUERY
      INSERT INTO hashtags (post_id, hashtag_id)
      VALUES ($1, $2);
    QUERY

    query(post_id, hashtag_id, sql)
  end

  def create!(title)
    sql = <<~QUERY
      INSERT INTO hashtag_list (title)
      VALUES ($1);
    QUERY

    query(title, sql)
  end
end
