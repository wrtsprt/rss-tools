class HsFixController < ApplicationController

  before_action :set_feed_url

  def index
    @max_items = 50
    start_time = Time.now
    update_feed
    @feed_items = FeedItem.latest.limit(@max_items).where(feed: @feed_url)
    @cached_items_count = @feed_items.where('created_at < ?', start_time).count

    respond_to do |format|
      format.html
      format.rss  { render plain: render_rss_feed(@feed_items) }
    end

    cleanup_feed_items
  end

  private

  def update_feed
    start_time = Time.now
    feed_xml = Typhoeus.get(@feed_url, followlocation: true).response_body
    feed = Feedjira::Feed.parse feed_xml
    if feed.nil?
      Rails.logger.debug "e: #{e.message}"
      return [500, "feed URL not found " + e.message]
    end

    feed_items = []
    new_items = 0
    count = 0

    hydra = Typhoeus::Hydra.new
    feed.entries.each do |entry|
      count += 1
      feed_item = FeedItem.find_by_url(entry.url)
      Rails.logger.debug "=> processing #{entry.url}"  
      if feed_item.nil?
        request = Typhoeus::Request.new(entry.url, followlocation: true)
        request.on_complete do |response|
          feed_item = FeedItem.new(
              feed:         @feed_url,
              title:        entry.title,
              url:          entry.url,
              published_at: entry.published.to_s,
              created_at:   Time.now.to_s,
              content:      heise_content_html(response.response_body))
          feed_item.save
          new_items += 1
        end
        hydra.queue(request)
      end
      feed_items << feed_item
    end

    hydra.run

    Rails.logger.debug "#{count} items processed."
    Rails.logger.debug "#{new_items} new items."
  end

  def heise_content_html(html_string)
    doc = Nokogiri::HTML(html_string)
    doc.css('.article-content').collect do |content|
      content.to_xhtml
    end.join.gsub('href="/', 'href="http://www.heise.de/')
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

  def cleanup_feed_items
    quoted_feed_url = ActiveRecord::Base.connection.quote(@feed_url)
    sql = "SELECT id FROM feed_items
    WHERE feed = #{quoted_feed_url}
    ORDER BY created_at DESC
    LIMIT 50"

    top_ids = ActiveRecord::Base.connection.select_rows(sql).flatten
    FeedItem.where(feed: @feed_url).where('id NOT IN (?)', top_ids).delete_all
  end

end
