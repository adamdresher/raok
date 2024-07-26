module MetadataProcessor
  private

  def merge_metadata(posts) # posts is a PG::Result object which has access to Enumerable methods
    merged_posts = {}

    posts.each do |post|
      id = post['post_id'].to_i

      unless merged_posts[id]
        merged_posts.merge! create_new_post(post, id)
      end

      merged_posts[id] = add_metadata!(merged_posts[id], post)
    end

    merged_posts
  end

  def create_new_post(data, id)
    strings = ['post_id', 'posted_by', 'user_id', 'description']
    post = {}

    strings.each do |string|
      post[string] = data[string]
    end

    { id => post }
  end

  def add_metadata!(post, data)
    add_likes!(post, data)
    add_comments!(post, data)

    post
  end

  def add_likes!(post, data) # mutates posts
    return unless data['liked_by']

    id = data['post_id'].to_i
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

  def add_comments!(post, data) # mutates posts
    return unless data['comment']

    id = data['comment_id'].to_i
    comment, comments = 'comment', 'comments'
    new_comment = { comment => data[comment], 'commented_by' => data['commented_by'], 'user_id' => data['comment_user_id'] }

    if post[comments]
      # adds a comment if comments already exists
      unless post[comments].include? data['comment_id']
        post[comments].merge!(id => new_comment)
      end
    else
      # starts a list of comments if it doesn't exist
      post[comments] = { id => new_comment }
    end

    post
  end
end

