module MetadataProcessor
  private

  def merge_metadata(posts) # posts is a PG::Result object which has access to Enumerable methods
    merged_posts = {}
    lists = ['liked_by', 'comment']
    strings = ['post_id', 'posted_by', 'description']

    posts.each do |post|
      id = post['post_id'].to_i
      comment = { 'comment' => post['comment'],
                  'commented_by' => post['commented_by'] }

      # creates post
      # adds post wo comments/likes
      unless merged_posts[id]
        merged_posts[id] = {}

        strings.each do |string|
          merged_posts[id][string] = post[string]
        end
      end

      lists.each do |list|
        if post[list]

          # updates post
          # adds extra comments/likes
          if (merged_posts[id][list].class == Array) && !merged_posts[id][list].include?(post[list])

            if list == 'commented_id'
              merged_posts[id]['comment_id'] << comment
            elsif list == 'liked_by'
              merged_posts[id]['liked_by'] << post[list]
            end
          end

          # updates post
          # adds first comment/like
          unless merged_posts[id][list]
            if list == 'comment'
              merged_posts[id][list] = { post['comment_id'] => comment }
            elsif list == 'liked_by'
              merged_posts[id][list] = [post[list]]
            end
          end
        end
      end
    end

    merged_posts
  end
end

