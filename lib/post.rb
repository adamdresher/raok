class Post
  def initialize(post_data)
    @id = post_data['id'].to_i
    @created_on = post_data['created_on']
    @posted_by = post_data['posted_by']
    @user_id = post_data['user_id'].to_i
    @description = post_data['description']
    @hashtags = post_data['hashtags'] ? post_data['hashtags'] : []
    @liked_by = post_data['liked_by'] ? post_data['liked_by'] : []
    @comments = post_data['comments'] ? post_data['comments'] : {}
  end

  attr_accessor :id, :created_on, :posted_by, :user_id, :description, :hashtags, :liked_by, :comments
end
