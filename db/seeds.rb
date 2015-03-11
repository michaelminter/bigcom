require 'faker'

# ActiveRecord::Base.connection.execute("TRUNCATE TABLE redirects")
# Request.delete_all
# puts 'Remove all current data'
#
# (0..1000).to_a.each do |i|
#   Redirect.create(url: Faker::Internet.url)
# end
# puts 'Create fake redirects'

(1..1000).to_a.each do |i|
  Request.create({
                     redirect_id: (1..1000).to_a.sample,
                     ip: Faker::Internet.ip_v4_address,
                     browser: ['Chrome', 'Firefox', 'Safari', 'IE'].sample,
                     version: (1..50).to_a.sample,
                     platform: ['Macintosh', 'Windows', 'Linux'].sample,
                     is_mobile: ['f', 't'].sample,
                     created_at: Faker::Time.backward(60, :evening)
                 })
end
puts 'Create fake requests'