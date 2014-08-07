require 'contentful/management'
require 'csv'

access_token = 'd508948e2545cde4caa461fa4ba9a26b43ce560bbda265a605b0ce0a5c9a5839'
organization_id = '1EQPR5IHrPx94UY4AViTYO'

Contentful::Management::Client.new(access_token)

# create a Space
space = Contentful::Management::Space.create(name: 'Breweries and Beers', organization_id: organization_id)

# create Brewery ContentType
brewery_type = space.content_types.create(name: 'Brewery', description: 'Brewery description')
brewery_type.fields.create(id: 'brewery_name', name: 'Brewery Name', type: 'Text', localized: true, required: true)
brewery_type.fields.create(id: 'brewery_description', name: 'Brewery Description', type: 'Text', localized: true)
brewery_type.fields.create(id: 'brewery_phone', name: 'Brewery Phone', type: 'Text', localized: true)
brewery_type.fields.create(id: 'brewery_city', name: 'Brewery City', type: 'Text', localized: false)
brewery_type.fields.create(id: 'brewery_code', name: 'Brewery Code', type: 'Symbol', localized: false)
brewery_type.fields.create(id: 'brewery_website', name: 'Brewery Website', type: 'Text', localized: false)

brewery_beers = Contentful::Management::Field.new
brewery_beers.type = 'Link'
brewery_beers.link_type = 'Entry'
brewery_type.fields.create(id: 'brewery_beers', name: 'Brewery Beer', type: 'Array', localized: true, items: brewery_beers)

# create Beer ContentType
beer_type = space.content_types.create(name: 'Beer')
beer_type.fields.create(id: 'beer_name', name: 'Beer Name', type: 'Text', localized: true)
beer_type.fields.create(id: 'beer_description', name: 'Beer Description', type: 'Text', localized: true)
beer_type.fields.create(id: 'beer_abv', name: 'Alcohol by Volume', type: 'Text', localized: true)
beer_type.fields.create(id: 'beer_brewery_id', name: 'Beer Brewery', type: 'Link', link_type: 'Entry', localized: false, required: true)
beer_type.fields.create(id: 'beer_cat_id', name: 'Beer Category', type: 'Link', link_type: 'Entry', localized: true)
beer_type.fields.create(id: 'beer_style_id', name: 'Beer Style', type: 'Link', link_type: 'Entry', localized: true)

# create Category ContentType
category_type = space.content_types.create(name: 'Category')
category_type.fields.create(id: 'category_name', name: 'Category Name', type: 'Text', localized: true)

# create Style ContentType
style_type = space.content_types.create(name: 'Style')
style_type.fields.create(id: 'style_name', name: 'Style Name', type: 'Text', localized: true)
style_type.fields.create(id: 'style_category_id', name: 'Style category ', type: 'Link', link_type: 'Entry', localized: true)

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
  category_entries[row[0]] = category_type.entries.create({id: "category_#{row[0]}", category_name: row[1]})
end

#publish all Category entries
category_entries.map { |_k, v| v.publish }

sleep 2

style_entries = {}
category_ids = category_entries.map(&:id)
CSV.foreach('data/styles.csv', headers: true) do |row|
  style_entries[row[0]] = style_type.entries.create(id: "style_#{row[0]}", style_category_id: category_entry, style_name: row[2]) if category_ids.include? "category_#{row[0]}" #limit styles to 11.
end

#publish all Style entries
style_entries.map { |_k, v| v.publish }

breweries_ids = %w(1 10 62 103 500 901 1302 1009 1101 1260)
breweries_by_id = {}

CSV.foreach('data/breweries.csv', headers: true) do |row|
  brewery = brewery_type.entries.create(id: "brewery_#{row[0]}", brewery_name: row[1], brewery_description: row[11], brewery_phone: row[8], brewery_city: row[4], brewery_code: row[6], brewery_website: row[9]) if breweries_ids.include? row[0]
  breweries_by_id[row[0]] = brewery unless brewery.nil?
end
sleep 2
breweries_by_id.map { |_k, v| v.publish }

#TODO add geolocation from csv to breweries

beers_entries = {}
brewery_ids = breweries_by_id.keys
CSV.foreach('data/beers.csv', headers: true) do |row|
  beers_entries[row[0]] = beer_type.entries.create(beer_name: row[2], beer_description: row[10], beer_abv: row[5], beer_brewery_id: brewery, beer_cat_id: category_entries[row[3]], beer_style_id: style_entries[row[4]]) if brewery_ids.include? row[1]
end
beers_entries.map { |_k, v| v.publish }
