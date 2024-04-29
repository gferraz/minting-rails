class CreateOffers < ActiveRecord::Migration[7.1]
  def change
    create_table :offers do |t|
      t.string :product
      t.date :date
      t.decimal :price_amount
      t.string :price_currency

      t.timestamps
    end
  end
end
