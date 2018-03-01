class EnhancersController < ApplicationController
  before_action :find_enhancer, :only => :show

  def show
    @feed_url = @enhancer.feed_url
    @max_items = 50
    start_time = Time.now
    update_feed
    @feed_items = FeedItem.latest.limit(@max_items).where(feed: @feed_url)
    @cached_items_count = @feed_items.where('created_at < ?', start_time).count
    
    respond_to do |format|
      format.html
      format.rss   { render plain: render_rss_feed(@feed_items) }
    end

    cleanup_feed_items
  end

  private

  def find_enhancer
    @enhancer = Enhancer.find(params[:id])
  end

  def update_feed
    start_time = Time.now
    feed = Feedzirra::Feed.fetch_and_parse(@feed_url)
    if feed.nil?
      Rails.logger.debug "e: #{e.message}"
      return [500, "feed URL not found " + e.message]
    end

    feed_items = []
    new_items = 0
    count = 0

    feed.entries.each do |entry|
      count += 1
      feed_item = FeedItem.find_by_url(entry.url)
      Rails.logger.debug "=> processing #{entry.url}"  
      if feed_item.nil?
        feed_item = FeedItem.new(
                      feed:         @feed_url,
                      title:        entry.title,
                      url:          entry.url,
                      published_at: entry.published.to_s,
                      created_at:   Time.now.to_s,
                      content:      extract_content(entry.url))
        feed_item.save
        new_items += 1
      end
      feed_items << feed_item
    end

    Rails.logger.debug "#{count} items processed."
    Rails.logger.debug "#{new_items} new items."
  end

  def extract_content(link)
    doc = Nokogiri::HTML(open(link))
    doc.css(@enhancer.css_selector).collect do |content|
      content.to_xhtml
    end.join.gsub('href="/', 'href="http://www.heise.de/').gsub('<img src="/', '<img src="http://www.heise.de/')
  end

  def render_rss_feed(items)
    start_time = Time.now
    version = "2.0"
    content = RSS::Maker.make(version) do |m|
      m.channel.title =         @enhancer.title
      m.channel.description =   @enhancer.description
      m.channel.link =          "http://rss-tools.heroku.com/enhancers/#{params[:id]}.rss"
      items.each do |item|
        i = m.items.new_item
        i.title   = item.title
        i.link    = item.url
        i.date    = item.published_at
        i.summary = item.content
      end
    end
    Rails.logger.debug "  in #{Time.now - start_time} seconds"
    content.to_s
  end

  def cleanup_feed_items
    quoted_feed_url = ActiveRecord::Base.connection.quote(@feed_url)
    sql = "SELECT id FROM feed_items
    WHERE feed = #{quoted_feed_url}
    ORDER BY created_at DESC
    LIMIT #{@max_items}"

    top_ids = ActiveRecord::Base.connection.select_rows(sql).flatten
    FeedItem.where(feed: @feed_url).where('id NOT IN (?)', top_ids).delete_all
  end

end
