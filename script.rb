require 'contentful/management'
require 'csv'

access_token = 'e69863392e6fa49cbe9e23b62d32de8c4f9001103246a681f411fd6055f27141'
organization_id = '1EQPR5IHrPx94UY4AViTYO'

Contentful::Management::Client.new(access_token)

breweries_ids = []
breweries_by_id = {}

#schema in contentful

CSV.foreach('data/breweries.csv') do |row|
  puts row
  # create if proper id
  # breweries_by_id[id] = brewery (entry)
end

#add geolocation from csv to breweries
#create categories from csv
#create styles from csv

CSV.foreach('data/beers.csv') do |row|
  # create beer  only if valid brewery
  # beer assign breweries_by_id[row.brewery_id]
  # beer assign category
  # beer assign style
end
