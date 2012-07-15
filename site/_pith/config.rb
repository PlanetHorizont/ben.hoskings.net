require 'haml'
require 'kramdown'
require 'coderay'

project.assume_content_negotiation = true
project.assume_directory_index = true

class Tilt::CustomKramdownTemplate < Tilt::Template
  def prepare
    @engine = Kramdown::Document.new(data, options)
    @output = nil
  end

  def evaluate(scope, locals, &block)
    @output ||= @engine.to_html
  end
end

Tilt.register Tilt::CustomKramdownTemplate, 'markdown', 'mkd', 'md'
Tilt.prefer Tilt::CustomKramdownTemplate

module HamlHelpers
  module_function

  def markdown text
    Kramdown::Document.new(text.strip).to_html
  end

  def highlight text, lang
    "<pre><code class='#{lang}'>#{CodeRay.scan(text.strip, lang).span(:css => :class)}</code></pre>"
  end

  def captioned text, lang
    code, _, caption = text.strip.rpartition("\n\n")

    formatted_caption = markdown(caption).sub(%r{^<p>},  '').sub(%r{</p>$}, '')

    %Q{
      <figure class="code">
        #{highlight(code, lang)}
        <figcaption>
          #{formatted_caption}
        </figcaption>
      </figure>
    }
  end
end

# This is required because kramdown isn't one of haml's default processors.
module Haml::Filters::Md
  include Haml::Filters::Base
  def render text
    HamlHelpers.markdown(text)
  end
end

module Haml::Filters::Preruby
  include Haml::Filters::Base
  def render text
    HamlHelpers.highlight(text, :ruby)
  end
end

module Haml::Filters::Presql
  include Haml::Filters::Base
  def render text
    HamlHelpers.highlight(text, :sql)
  end
end

module Haml::Filters::Prediff
  include Haml::Filters::Base
  def render text
    HamlHelpers.highlight(text, :diff)
  end
end

module Haml::Filters::Captionedruby
  include Haml::Filters::Base
  def render text
    HamlHelpers.captioned(text, :ruby)
  end
end

module Haml::Filters::Captionedsql
  include Haml::Filters::Base
  def render text
    HamlHelpers.captioned(text, :sql)
  end
end

module Haml::Filters::Captionedc
  include Haml::Filters::Base
  def render text
    HamlHelpers.captioned(text, :c)
  end
end

project.helpers do
  def posts
    project.inputs.select {|input|
      input.path.dirname.to_s[%r{^\d{4}/\d{2}/\d{2}}]
    }
  end

  def date_of post
    date_str = (page.meta['custom_date'] || post.path.dirname).to_s.split('/')
    Time.new(*date_str)
  end

  def slug_for page
    page.title.gsub(/\W+/, '-').downcase
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
