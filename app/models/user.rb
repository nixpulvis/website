# User
# A user is the main model for accounts on the site. It stores the
# email and handles password authentication. Users are allowed to have
# characters, which is where we pull in information to display about
# them.
#
class User < ActiveRecord::Base
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Allowed to have many characters, but one **must** be the main.
  has_many :characters, dependent: :destroy

  # Users make posts.
  has_many :posts, dependent: :destroy

  # If a user has a rank they MUST be in the guild. Users without
  # a rank are assumed to be not invited yet.
  belongs_to :rank

  # A user **must** have an email address, and a character.
  validates :email, presence: true
  validates :characters, presence: true

  # Allow users forms to create characters.
  accepts_nested_attributes_for :characters

  # -> String
  # The name of this user is defined to be the name of their main.
  #
  def to_s
    self.main.to_s
  end

  # -> Character
  # The users main character.
  #
  def main
    self.characters.where(main: true).first
  end
end
