class User < ActiveRecord::Base
  authenticates_with_sorcery!

  validates :password, confirmation: true
  validates :password_confirmation, length: { minimum: 3 }, if: :new_record?
  validates :password_confirmation, presence: true, if: :new_record?
  validates :name, presence: true, uniqueness: true
  validates :email, uniqueness: true

  has_and_belongs_to_many :user_groups
  has_many :items, through: :user_groups
  has_one :default_group, class_name: 'UserGroup', foreign_key: :user_group_default_id

  acts_as_user roles: :admin

  scope :with_name, ->(q) { where('users.name LIKE ?', "%#{q}%").distinct }
end