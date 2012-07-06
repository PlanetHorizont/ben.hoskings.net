require 'haml'
require 'kramdown'

project.assume_content_negotiation = true
project.assume_directory_index = true

Tilt.prefer Tilt::KramdownTemplate

# This is required because kramdown isn't one of haml's default processors.
module Haml::Filters::Md
  include Haml::Filters::Base

  def render_with_options text, options
    Kramdown::Document.new(text, options).to_html
  end
end

module Haml::Filters::Captioncode
  include Haml::Filters::Base

  def render_with_options text, options
    code, caption = text.split("\n\n", 2)
    formatted_caption = Kramdown::Document.new(caption, options).to_html.
      sub(%r{^<p>},  '').
      sub(%r{</p>$}, '')

    %Q{
      <figure class="code">
      <pre><code>#{code}</code></pre>
      <figcaption>
        #{formatted_caption}
      </figcaption>
      </figure>
    }
  end
end

project.helpers do
  def posts
    project.inputs.select {|input|
      input.path.dirname.to_s[%r{^\d{4}/\d{2}/\d{2}}]
    }
  end

  def date_of post
    Time.new *post.path.dirname.to_s.split('/')
  end

  def slug_for page
    page.title.gsub(/\W+/, '-')
  end

  def formatted_headline_for text
    # Make the final space non-breaking if the final two words fit within 20 characters.
    if text.length > 20 && text[-20..-1][/\s+\S+\s+\S+$/].nil?
      text
    else
      text.gsub /\s+(?=\S+$)/, "&nbsp;"
    end
  end
end
