require 'haml'
require 'kramdown'
require 'coderay'

project.assume_content_negotiation = true
project.assume_directory_index = true

Tilt.prefer Tilt::KramdownTemplate

# This is required because kramdown isn't one of haml's default processors.
module Haml::Filters::Md
  include Haml::Filters::Base

  def render text
    Kramdown::Document.new(text).to_html
  end
end

module Haml::Filters::Captioncode
  include Haml::Filters::Base

  def render text
    code, caption = text.split("\n\n", 2)

    highlighted_code = CodeRay.scan(code, :ruby).span(:css => :class)

    formatted_caption = Kramdown::Document.new(caption).to_html.
      sub(%r{^<p>},  '').
      sub(%r{</p>$}, '')

    %Q{
      <figure class="code">
      <pre><code>#{highlighted_code}</code></pre>
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
