require_relative 'hashtags'
require_relative 'post'

# Structures Post data
module MetadataProcessor
  private

  def add_comments!(post, data)
    return unless data['comment']

    id = data['comment_id'].to_i
    new_comment = { 'comment' => data['comment'],
                    'commented_by' => data['commented_by'],
                    'user_id' => data['comment_user_id'] }

    if post['comments']
      # adds a comment if comments already exists
      unless post['comments'].include? data['comment_id']
        post['comments'].merge!(id => new_comment)
      end
    else
      # starts a list of comments if it doesn't exist
      post['comments'] = { id => new_comment }
    end

    post
  end

  def add_hashtags!(post, data)
    post['hashtags'] = Hashtags.new.select_hashtags(data['description'])
    post
  end

  def add_likes!(post, data)
    return unless data['liked_by']

    liked_by = 'liked_by'

    if post[liked_by]
      # adds a like if the user isn't included
      unless post[liked_by].include? data[liked_by]
        post[liked_by] << data[liked_by]
      end
    else
      # starts a list of likes if if doesn't exist
      post[liked_by] = [data[liked_by]]
    end

    post
  end

  def add_metadata!(post, data)
    add_likes!(post, data)
    add_comments!(post, data)
    add_hashtags!(post, data)

    post
  end

  def create_new_post(data, id)
    strings = ['id', 'created_on', 'posted_by', 'user_id', 'description']
    post = {}

    strings.each do |string|
      post[string] = data[string]
    end

    { id => post }
  end

  # rubocop:disable Metrics/MethodLength
  def last_post
    sql = <<~QUERY
        SELECT p.id,
               p.created_on,
               u.username AS posted_by,
               u.id AS user_id,
               p.description,
               hl.title AS hashtag,
               l_user.username AS liked_by,
               c.id AS comment_id,
               c_user.id AS comment_user_id,
               c_user.username AS commented_by,
               c.description AS comment
          FROM posts AS p
          JOIN users AS u
            ON u.id = p.user_id
     LEFT JOIN likes AS l
            ON p.id = l.post_id
     LEFT JOIN users AS l_user
            ON l.user_id = l_user.id
     LEFT JOIN comments AS c
            ON p.id = c.post_id
     LEFT JOIN users AS c_user
            ON c.user_id = c_user.id
     LEFT JOIN hashtags AS h
            ON p.id = h.post_id
     LEFT JOIN hashtag_list AS hl
            ON h.hashtag_id = hl.id
      ORDER BY p.id DESC
         LIMIT 1;
    QUERY

    result = query(sql)
    post_data = merge_metadata(result).values.first

    Post.new(post_data)
  end
  # rubocop:enable Metrics/MethodLength

  # posts is a PG::Result object which has access to Enumerable methods
  def merge_metadata(posts)
    merged_posts = {}

    posts.each do |post|
      id = post['id'].to_i

      unless merged_posts[id]
        merged_posts.merge! create_new_post(post, id)
      end

      merged_posts[id] = add_metadata!(merged_posts[id], post)
    end

    merged_posts
  end
end
