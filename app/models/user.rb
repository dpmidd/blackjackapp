class User < ActiveRecord::Base

  has_many :games

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email_address, presence: true, uniqueness: true

  has_secure_password
end
