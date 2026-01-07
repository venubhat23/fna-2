class CustomerDocument < ApplicationRecord
  belongs_to :customer
  has_one_attached :file

  validates :document_type, presence: true
  validates :file, presence: true

  # Document types
  DOCUMENT_TYPES = [
    'Aadhaar Card',
    'Pancard',
    'Driving License',
    'Mediclaim',
    'RC Book',
    'Other File'
  ].freeze

  validates :document_type, inclusion: { in: DOCUMENT_TYPES }

  def filename
    file.attached? ? file.filename.to_s : nil
  end

  def file_size
    file.attached? ? file.byte_size : nil
  end

  def file_type
    file.attached? ? file.content_type : nil
  end
end