class CreateEnhancers < ActiveRecord::Migration[4.2]
  def change
    create_table :enhancers do |t|
      t.string  :title
      t.text    :description
      t.string  :feed_url
      t.string  :css_selector
      t.text    :replacement_map

      t.timestamps
    end
  end
end
