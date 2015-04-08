require 'csv'

class Deck < ActiveRecord::Base
  belongs_to :user
  has_many :cards
  has_many :card_suggestions
  has_many :cards

  validates :title, length: { minimum: 5, maximum: 65 }
  validates :user_id, presence: :true

  # There has gotta be an AR scope for this. No?
  scope :saved, lambda { where('id > 0') }   

  def _instructions
    if instructions.present?
      instructions
    else
      "This deck doesn't have instructions yet."
    end
  end

  def owner
    self.user
  end

  def any_card_suggestions_pending?
    card_suggestions.pending.any?
  end

  def card_count
    cards.count
  end

  def file_name
    "#{self.title.delete(' ')}.csv"
  end

  def card_suggestions_count
    card_suggestions.count
  end

  def to_csv
    csv_string = CSV.generate do |csv|
      self.cards.each {|c| csv << [ c.question, c.answer ] }
    end
  end
end
