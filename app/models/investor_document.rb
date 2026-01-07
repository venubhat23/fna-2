class InvestorDocument < ApplicationRecord
  # Associations
  belongs_to :investor
  has_one_attached :document_file

  # Validations
  validates :document_type, presence: true
  validates :document_file, presence: true
  validates :document_type, inclusion: {
    in: ['Aadhaar Card', 'Pancard', 'Driving License', 'Mediclaim', 'RC Book', 'Other File']
  }

  # Instance methods
  def document_name
    document_file.attached? ? document_file.filename.to_s : "No file attached"
  end

  def document_size
    document_file.attached? ? number_to_human_size(document_file.byte_size) : "0 KB"
  end

  def document_url
    document_file.attached? ? Rails.application.routes.url_helpers.rails_blob_path(document_file, only_path: true) : nil
  end

  private

  def number_to_human_size(number)
    ActionController::Base.helpers.number_to_human_size(number)
  end
end
