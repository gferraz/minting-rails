class CreateSimpleOffers < ActiveRecord::Migration[7.1]
  def change
    create_table :simple_offers do |t|
      t.string :product
      t.date :date
      t.decimal :price
      t.decimal :discount

      t.timestamps
    end
  end
end
