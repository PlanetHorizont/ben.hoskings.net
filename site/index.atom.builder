host = "http://benhoskin.gs"
feed_posts = published_posts[0...30]

xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.feed xmlns: 'http://www.w3.org/2005/Atom' do
  xml.id host
  xml.title "benhoskin.gs"
  xml.link href: "#{host}/index.atom", rel: "self", type: "application/atom+xml"
  xml.link href: host, rel: "alternate", type: "application/atom+xml"
  xml.updated date_of(published_posts.first).xmlschema
  xml.author do
    xml.name "Ben Hoskings"
    xml.email "ben@hoskings.net"
    xml.uri host
  end
  feed_posts.each do |post|
    post_uri = "#{host}/#{href(post)}"
    xml.entry do
      xml.id post_uri
      xml.title post.title
      xml.link rel: "alternate", type: "text/html", href: post_uri
      xml.updated date_of(post).xmlschema
    end
  end
end
