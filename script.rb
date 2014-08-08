# This Open Beer Database data is made available under the Open Database License.
# Any rights in individual contents of the database are licensed under the Database Contents License.
# http://openbeerdb.com/

require 'contentful/management'
require 'csv'

ACCESS_TOKEN = 'access_token'
ORGANIZATION_ID = 'organization_id'
STYLE_IDS = %w(1 2 3 4 5 6 11 22 24 25 27 49 90 110 112)
BREWERIES_IDS = %w(1 10 62 103 500 901 1302 1009 1101 1260)

Contentful::Management::Client.new(ACCESS_TOKEN)

# create a Space
space = Contentful::Management::Space.create(name: 'Breweries and Beers', organization_id: ORGANIZATION_ID)

# create Brewery ContentType
brewery_type = space.content_types.create(name: 'Brewery')
brewery_type.fields.create(id: 'name', name: 'Name', type: 'Text', required: true)
brewery_type.fields.create(id: 'description', name: 'Description', type: 'Text')
brewery_type.fields.create(id: 'phone', name: 'Phone', type: 'Text')
brewery_type.fields.create(id: 'city', name: 'City', type: 'Text')
brewery_type.fields.create(id: 'code', name: 'Code', type: 'Symbol')
brewery_type.fields.create(id: 'website', name: 'Website', type: 'Text')
brewery_type.fields.create(id: 'location', name: 'Location', type: 'Location')

brewery_beers = Contentful::Management::Field.new
brewery_beers.type = 'Link'
brewery_beers.link_type = 'Entry'
brewery_type.fields.create(id: 'beers', name: 'Beers', type: 'Array', items: brewery_beers)

# create Beer ContentType
beer_type = space.content_types.create(name: 'Beer')
beer_type.fields.create(id: 'name', name: 'Name', type: 'Text')
beer_type.fields.create(id: 'description', name: 'Description', type: 'Text')
beer_type.fields.create(id: 'abv', name: 'Alcohol by Volume', type: 'Number')
beer_type.fields.create(id: 'brewery_id', name: 'Brewery', type: 'Link', link_type: 'Entry', required: true)
beer_type.fields.create(id: 'category_id', name: 'Category', type: 'Link', link_type: 'Entry')
beer_type.fields.create(id: 'style_id', name: 'Style', type: 'Link', link_type: 'Entry')

# create Category ContentType
category_type = space.content_types.create(name: 'Category')
category_type.fields.create(id: 'name', name: 'Category Name', type: 'Text')

# create Style ContentType
style_type = space.content_types.create(name: 'Style')
style_type.fields.create(id: 'name', name: 'Name', type: 'Text')
style_type.fields.create(id: 'category_id', name: 'Category', type: 'Link', link_type: 'Entry')

sleep 2

#activate all content types
brewery_type.activate
beer_type.activate
category_type.activate
style_type.activate

sleep 2

#create an entries for Category ContentType
category_entries = {}
CSV.foreach('data/categories.csv', headers: true) do |row|
  category_entries[row['id']] = category_type.entries.create({id: "category_#{row['id']}", name: row['cat_name']})
end

#publish all Category entries
category_entries.map { |_id, category| category.publish }

sleep 2

style_entries = {}
CSV.foreach('data/styles.csv', headers: true) do |row|
  style_entries[row['id']] = style_type.entries.create(id: "style_#{row['id']}", category_id: category_entries[row['cat_id']], name: row['style_name']) if STYLE_IDS.include? row['id']
end

#publish all Style entries
style_entries.map { |_id, style| style.publish }

breweries_entries = {}
CSV.foreach('data/breweries.csv', headers: true) do |row|
  brewery = brewery_type.entries.create(id: "brewery_#{row['id']}", name: row['name'], description: row['descript'], phone: row['phone'], city: row['city'], code: row['code'], website: row['website']) if BREWERIES_IDS.include? row['id']
  breweries_entries[row['id']] = brewery unless brewery.nil?
end

sleep 2
breweries_entries.map { |_id, brewery| brewery.publish }

beers_entries = {}
brewery_ids = breweries_entries.keys
CSV.foreach('data/beers.csv', headers: true) do |row|
  beers_entries[row['id']] = beer_type.entries.create(name: row['name'], description: row['descript'], abv: row['abv'].to_i, brewery_id: breweries_entries[row['brewery_id']], category_id: category_entries[row['cat_id']], style_id: style_entries[row['style_id']]) if brewery_ids.include? row['brewery_id']
end

sleep 2
beers_entries.map { |_id, beer| beer.publish }

# update Breweries ContentTypes (add geolocation attribute)
CSV.foreach('data/breweries_geocode.csv', headers: true) do |row|
  brewery = breweries_entries[row['brewery_id']]
  unless brewery.nil?
    location = Contentful::Management::Location.new
    location.lat = row['latitude'].to_f
    location.lon = row['longitude'].to_f
    brewery.update(location: location)
  end
end

#update Breweries ContentTypes (add beers_entries)
breweries_entries.each do |key, brewery_entry|
  brewery_beers = beers_entries.each_with_object([]) do |(_id, beer), brewery_beers|
    brewery_beers << beer if beer.fields[:brewery_id]['sys']['id'] == "brewery_#{key}"
  end
  brewery_entry.update(beers: brewery_beers)
end
