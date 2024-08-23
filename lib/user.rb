require_relative 'database_connection'
require_relative 'metadata_processor'

# Interface for individual users
class User < DatabaseConnection
  include MetadataProcessor

  def initialize(user_id: nil, logger: nil)
    super(logger: logger)

    @profile = find_profile(user_id)
    @id = @profile['id']
    @username = @profile['username']
    @name = @profile['name']
    @email = @profile['email']
  end

  attr_reader :profile, :id, :username, :name, :email

  def add_comment!(post_id, comment)
    sql = <<~QUERY
      INSERT INTO comments
                  (post_id, user_id, description)
           VALUES ($1, $2, $3);
    QUERY

    query(post_id, @id, comment, sql)
  end

  def add_post!(description)
    sql = <<~QUERY
      INSERT INTO posts
                  (user_id, description)
           VALUES ($1, $2);
    QUERY

    query(id, description, sql)

    Hashtags.new.record_from(last_post)
  end

  def delete_post!(post_id)
    sql = <<~QUERY
      DELETE FROM posts
            WHERE id = $1;
    QUERY

    query(post_id, sql)
  end

  def public_profile
    @profile.reject { |k, _| ['id', 'username'].include? k }
    # username should be part of the public profile but not editable
  end

  def toggle_like!(post)
    like_state = post.liked_by.include?(@username)
    like_sql = <<~QUERY
      INSERT INTO likes
                  (post_id, user_id)
           VALUES ($1, $2);
    QUERY
    unlike_sql = <<~QUERY
      DELETE FROM likes
            WHERE post_id = $1 AND user_id = $2;
    QUERY

    sql = (like_state ? unlike_sql : like_sql)

    query(post.id, @id, sql)
  end

  def update_profile!(new_name, new_email)
    sql = <<~QUERY
      UPDATE users
         SET name = $1,
             email = $2
       WHERE name = $3 AND email = $4;
    QUERY

    query(new_name, new_email, @name, @email, sql)
    @profile = find_profile(@id)
  end

  private

  def find_profile(user_id)
    sql = <<~QUERY
      SELECT id, name, email, username FROM users
       WHERE id = $1;
    QUERY

    result = query(user_id, sql)

    result.first
  end

  def post_liked?(id)
    public_posts = all_posts
    likes = public_posts[id]['liked_by']

    likes&.include?(username)
  end
end
