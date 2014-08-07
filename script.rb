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
CSV.foreach('data/categories.csv', :headers => true) do |row|
  category_entries[row[0]] = category_type.entries.create({id: "category_#{row[0]}", category_name: row[1]})
end

#publish all Category entries
category_entries.map { |_k, v| v.publish }

sleep 2

style_entries = {}
CSV.foreach('data/styles.csv', :headers => true) do |row|
  category_entries.each do |_k, category_entry|
    style_entries[row[0]]  = style_type.entries.create(id: "style_#{row[0]}", style_category_id: category_entry, style_name: row[2]) if category_entry.id == "category_#{row[0]}"  #limit styles to 11.
  end
end

#publish all Style entries
style_entries.map { |_k, v| v.publish }

breweries_ids = %w(1 10 62 103 500 901 1302 1009 1101 1260)
breweries_by_id = {}

CSV.foreach('data/breweries.csv', :headers => true) do |row|
  brewery = brewery_type.entries.create(id: "brewery_#{row[0]}", brewery_name: row[1], brewery_description: row[11], brewery_phone: row[8], brewery_city: row[4], brewery_code: row[6], brewery_website: row[9]) if breweries_ids.include? row[0]
  breweries_by_id[row[0]] = brewery unless brewery.nil?
end
sleep 2
breweries_by_id.map { |_k, v| v.publish }

#TODO add geolocation from csv to breweries

beers_entries = {}
CSV.foreach('data/beers.csv', :headers => true) do |row|
  breweries_by_id.each do |brewery_id, brewery|
    beers_entries[row[0]] = beer_type.entries.create(beer_name: row[2], beer_description: row[10], beer_abv: row[5], beer_brewery_id: brewery, beer_cat_id: category_entries[row[3]], beer_style_id: style_entries[row[4]]) if brewery_id == row[1]
  end
end
beers_entries.map { |_k, v| v.publish }

#
# # create an asset for Brewery with multiple locales
# brewing_512_asset = space.assets.new
# brewing_512_asset.title_with_locales = {'en-US' => 'Company logo of 512-Brewing', 'de-DE' => 'Firmenlogo 512-Brewing', 'pl-PL' => 'Firmowe logo 512-Brewing'}
# brewing_512_asset.description_with_locales = {'en-US' => 'Logo', 'de-DE' => 'Logo', 'pl-PL' => 'Logo'}
#
# logo1_512 = Contentful::Management::File.new
# logo1_512.properties[:contentType] = 'image/jpeg'
# logo1_512.properties[:fileName] = '512logo.jpg'
# logo1_512.properties[:upload] = 'http://www.examiner.com/images/blog/wysiwyg/image/512_Brew_Logo_rev.jpg'
#
# logo2_512 = Contentful::Management::File.new
# logo2_512.properties[:contentType] = 'image/jpeg'
# logo2_512.properties[:fileName] = '512logo.jpg'
# logo2_512.properties[:upload] = 'http://media.tumblr.com/tumblr_lx8p42g9k11r1ceif.jpg'
#
# brewing_512_asset.file_with_locales = {'en-US' => logo2_512, 'de-DE' => logo2_512, 'pl-PL' => logo1_512}
# brewing_512_asset.save
#
# sleep 3 # prevent race conditions
#
# brewing_512_asset.publish
#
# #create an assets for Beer
# beer1_photo_512 = Contentful::Management::File.new
# beer1_photo_512.properties[:contentType] = 'image/jpeg'
# beer1_photo_512.properties[:fileName] = '512logo.jpg'
# beer1_photo_512.properties[:upload] = 'http://res.cloudinary.com/ratebeer/image/upload/w_250,c_limit,q_85,d_beer_def.gif/beer_4016.jpg'
#
# beer1_photo2_512 = Contentful::Management::File.new
# beer1_photo2_512.properties[:contentType] = 'image/jpeg'
# beer1_photo2_512.properties[:fileName] = '512logo.jpg'
# beer1_photo2_512.properties[:upload] = 'http://img2.findthebest.com/sites/default/files/675/media/images/Southampton_Altbier__190724.jpg'
#
# beer1_512 = Bartender::Beer.find(1)
#
# beer1_512_asset = space.assets.create(title: beer1_512['name'], description: 'First photo of ALT beer', file: beer1_photo_512)
# beer1_512_asset2 = space.assets.create(title: beer1_512['name'], description: 'Second photo of ALT beer', file: beer1_photo2_512)
#
#
# #create an entry for Brewery for multiple locales
# brewing_512 = Bartender::Brewery.find(1)
# brewing_512_entry = brewery_type.entries.new
# brewing_512_entry.brewery_name_with_locales = {'en-US' => brewing_512['name'], 'de-DE' => 'Firm (512) Brewing', 'pl-PL' => 'Firma (512) Brewing'}
# brewing_512_entry.brewery_description_with_locales = {'en-US' => brewing_512['description'], 'de-DE' => '(512) - Beschreibung', 'pl-PL' => '(512) - Opis'}
# brewing_512_entry.save
#
# #update an entry
# brewing_512_entry.update(brewery_url: brewing_512['url'], brewery_logo: brewing_512_asset)
# brewing_512_entry.locale = 'pl-PL'
# brewing_512_entry.update(brewery_logo: brewing_512_asset)
#
#
# #create an entry for Beer for multiple locales
# brewing_512_beer_entries = []
# brewing_512_beer_entries << beer_type.entries.create(beer_name: beer1_512['name'], beer_description: 'Beer 1 description', beer_abv: beer1_512['abv'], beer_brewery: brewing_512_entry)
#
# beer2_512 = Bartender::Beer.find(2)
# brewing_512_beer_entries << beer_type.entries.create(beer_name: beer2_512['name'], beer_description: 'Beer 2 description', beer_abv: beer2_512['abv'], beer_brewery: brewing_512_entry)
#
#
# #update Brewery entry - add 2 beer entries
# # brewing_512_entry.update(brewery_beer: brewing_512_beer_entries)
#
#
# # space.destroy
