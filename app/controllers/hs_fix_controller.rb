class HsFixController < ApplicationController

  before_filter :set_feed_url

  def index
    @max_items = 50
    start_time = Time.now
    update_feed
    @feed_items = FeedItem.latest.limit(@max_items).where(feed: @feed_url)
    @cached_items_count = @feed_items.where('created_at < ?', start_time).count

    respond_to do |format|
      format.html
      format.rss  { render text: render_rss_feed(@feed_items) }
    end
  end

  private

  def update_feed
    start_time = Time.now
    content = ""
    begin
      open(@feed_url) do |s| content = s.read end
    rescue Exception => e
      Rails.logger.debug "e: #{e.message}"
      return [500, "feed URL not found " + e.message]
    end

    rss = RSS::Parser.parse(content, false)
    feed_items = []

    new_items = 0
    items_no_content = 0
    items_with_content = 0
    count = 0

    rss.entries.each do |entry|
      count += 1
      feed_item = FeedItem.find_by_url(entry.link.href)
      if feed_item.nil?
        feed_item = FeedItem.new(
                      feed:         @feed_url,
                      title:        entry.title.content,
                      url:          entry.link.href,
                      published_at: entry.published.content.to_s,
                      created_at:   Time.now.to_s,
                      content:      heise_content(entry.link.href))
        feed_item.save
        new_items += 1
      end
      feed_items << feed_item
    end

    Rails.logger.debug "#{count} items processed."
    Rails.logger.debug "#{new_items} new items."
    Rails.logger.debug "#{items_no_content} items without content"
    Rails.logger.debug "#{items_with_content} items with content"
  end

  def heise_content(link)
    doc = Nokogiri::HTML(open(link))
    doc.css('.meldung_wrapper').collect do |content|
      content.to_xhtml
    end.join.gsub('href="/', 'href="http://www.heise.de/').gsub('<img src="/', '<img src="http://www.heise.de/')
  end

  def render_rss_feed(items)
    start_time = Time.now
    version = "2.0"
    content = RSS::Maker.make(version) do |m|
      m.channel.link = "http://rss-tools.heroku.com/heise_newsfeed.rss"
      m.channel.description = "heise.de+content"
      items.each do |item|
        i = m.items.new_item
        i.title   = item.title
        i.link    = item.url
        i.date    = item.published_at
        i.summary = item.content
      end
      m.channel.title = "heise.de+content"
    end
    Rails.logger.debug "  in #{Time.now - start_time} seconds"
    content.to_s
  end

  def set_feed_url
    @feed_url ||= 'http://www.heise.de/newsticker/heise-atom.xml'
  end

end
