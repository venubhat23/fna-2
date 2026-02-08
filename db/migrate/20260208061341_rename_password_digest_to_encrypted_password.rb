class RenamePasswordDigestToEncryptedPassword < ActiveRecord::Migration[8.0]
  def change
    rename_column :users, :password_digest, :encrypted_password
  end
end
