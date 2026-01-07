class Document < ApplicationRecord
  belongs_to :documentable, polymorphic: true
  has_one_attached :file

  validates :title, presence: true
  validates :document_type, presence: true
  validates :file, presence: true
  validates :uploaded_by, presence: true

  # File validation
  validate :acceptable_file_type
  validate :acceptable_file_size

  DOCUMENT_TYPES = [
    'aadhar', 'pan_card', 'driving_license', 'passport', 'voter_id',
    'birth_certificate', 'marriage_certificate', 'income_certificate',
    'salary_slip', 'bank_statement', 'gst_certificate', 'other'
  ].freeze

  ALLOWED_FILE_TYPES = ['application/pdf', 'image/jpeg', 'image/jpg', 'image/png',
                        'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'].freeze

  validates :document_type, inclusion: { in: DOCUMENT_TYPES }

  scope :by_type, ->(type) { where(document_type: type) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def file_name
    file.attached? ? file.filename.to_s : 'No file attached'
  end

  def file_size
    file.attached? ? file.blob.byte_size : 0
  end

  def file_type
    file.attached? ? file.blob.content_type : 'Unknown'
  end

  def file_size_mb
    return 0 unless file.attached?
    (file_size.to_f / 1.megabyte).round(2)
  end

  def file_extension
    return '' unless file.attached?
    File.extname(file.filename.to_s).downcase
  end

  def downloadable?
    file.attached?
  end

  def human_file_type
    case file_type
    when 'application/pdf'
      'PDF Document'
    when 'image/jpeg', 'image/jpg'
      'JPEG Image'
    when 'image/png'
      'PNG Image'
    when 'application/msword'
      'Word Document'
    when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      'Word Document'
    else
      'Unknown'
    end
  end

  def human_document_type
    case document_type
    when 'aadhar'
      'Aadhaar Card'
    when 'pan_card'
      'PAN Card'
    when 'driving_license'
      'Driving License'
    when 'passport'
      'Passport'
    when 'voter_id'
      'Voter ID'
    when 'birth_certificate'
      'Birth Certificate'
    when 'marriage_certificate'
      'Marriage Certificate'
    when 'income_certificate'
      'Income Certificate'
    when 'salary_slip'
      'Salary Slip'
    when 'bank_statement'
      'Bank Statement'
    when 'gst_certificate'
      'GST Certificate'
    when 'other'
      'Other Document'
    else
      document_type.humanize
    end
  end

  def file_icon
    case file_type
    when 'application/pdf'
      'file-earmark-pdf'
    when 'image/jpeg', 'image/jpg', 'image/png'
      'file-earmark-image'
    when 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
      'file-earmark-word'
    when 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
      'file-earmark-excel'
    when 'text/plain'
      'file-earmark-text'
    when 'application/zip', 'application/x-zip-compressed'
      'file-earmark-zip'
    else
      case document_type
      when 'aadhar'
        'person-badge'
      when 'pan_card'
        'credit-card'
      when 'driving_license'
        'car-front'
      when 'passport'
        'airplane'
      when 'voter_id'
        'person-check'
      when 'birth_certificate', 'marriage_certificate'
        'award'
      when 'income_certificate', 'salary_slip'
        'receipt'
      when 'bank_statement'
        'bank'
      when 'gst_certificate'
        'building'
      else
        'file-earmark'
      end
    end
  end

  private

  def acceptable_file_type
    return unless file.attached?

    unless ALLOWED_FILE_TYPES.include?(file.blob.content_type)
      errors.add(:file, 'must be PDF, JPG, PNG, or DOC format')
    end
  end

  def acceptable_file_size
    return unless file.attached?

    if file.blob.byte_size > 10.megabytes
      errors.add(:file, 'must be less than 10MB')
    end
  end
end