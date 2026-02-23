class CreateReferrals < ActiveRecord::Migration[8.0]
  def change
    create_table :referrals do |t|
      t.references :affiliate, null: false, foreign_key: true
      t.string :referred_name
      t.string :referred_mobile
      t.string :referred_email
      t.date :referral_date
      t.string :status
      t.text :notes
      t.datetime :converted_at
      t.references :customer, null: false, foreign_key: true

      t.timestamps
    end
  end
end
