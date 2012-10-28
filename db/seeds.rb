# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Enhancer.create(
    title:        'Heise Newsticker Feed', 
    description:  'The famous heise newsfeed.',
    feed_url:     'http://www.heise.de/newsticker/heise-atom.xml',
    css_selector: '.meldung_wrapper',
    replacement_map: 'href="/\nhref="http://www.heise.de/\n
                    <img src="/\n<img src="http://www.heise.de/'
    )
