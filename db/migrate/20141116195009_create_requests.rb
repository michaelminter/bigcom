class CreateRequests < ActiveRecord::Migration
  def change
    create_table :requests do |t|
      t.string :redirect_id
      t.string :ip
      t.string :browser
      t.string :version
      t.string :platform
      t.string :is_mobile
      t.timestamps
    end
    add_index :requests, :redirect_id
  end
end
