project.assume_content_negotiation = true
project.assume_directory_index = true

project.helpers do
  def posts
    project.inputs.select {|input|
      input.path.basename.to_s[/^\d{4}\-\d{2}\-\d{2}/]
    }
  end

  def date_of post
    Time.new *post.path.basename.to_s.scan(/^\d{4}\-\d{2}\-\d{2}/).first.split('-')
  end
end
