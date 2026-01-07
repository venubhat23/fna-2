class FamilyMember < ApplicationRecord
  belongs_to :customer
  has_many :documents, as: :documentable, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :relationship, presence: true, inclusion: { in: ['father', 'mother', 'spouse', 'child', 'sibling', 'other'] }

  enum :relationship, { father: 'father', mother: 'mother', spouse: 'spouse', child: 'child', sibling: 'sibling', other_relationship: 'other' }
  enum :gender, { male: 'male', female: 'female', other_gender: 'other' }

  accepts_nested_attributes_for :documents, allow_destroy: true, reject_if: :all_blank

  before_save :calculate_age

  def full_name
    "#{first_name} #{middle_name} #{last_name}".strip.squeeze(' ')
  end

  def name
    full_name
  end

  private

  def calculate_age
    if birth_date.present?
      self.age = Date.current.year - birth_date.year
      self.age -= 1 if Date.current < birth_date + age.years
    end
  end
end
