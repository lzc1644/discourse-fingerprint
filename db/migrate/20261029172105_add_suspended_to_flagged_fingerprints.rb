# frozen_string_literal: true

class AddSuspendedToFlaggedFingerprints < ActiveRecord::Migration[8.1]
  def change
    add_column :flagged_fingerprints, :suspended, :boolean, default: false, null: false
  end
end
