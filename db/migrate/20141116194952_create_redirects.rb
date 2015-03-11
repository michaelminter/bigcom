class CreateRedirects < ActiveRecord::Migration
  def change
    create_table :redirects do |t|
      t.string :url
      t.string :slug
      t.timestamps
    end
    add_index :redirects, :slug
  end
end
