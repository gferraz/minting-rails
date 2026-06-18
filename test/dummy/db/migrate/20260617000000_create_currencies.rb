class CreateCurrencies < ActiveRecord::Migration[8.1]
  def change
    create_table :currencies do |t|
      t.string :code, null: false
      t.integer :subunit, null: false, default: 2
      t.string :symbol, null: false, default: ''
      t.string :name

      t.timestamps
    end

    add_index :currencies, :code, unique: true
  end
end
