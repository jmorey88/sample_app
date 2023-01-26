class User < ApplicationRecord
    has_many :microposts, dependent: :destroy
    attr_accessor :remember_token
    has_many :active_relationships, class_name: "Relationship",
                                   foreign_key: "follower_id",
                                   dependent:   :destroy
    has_many :passive_relationships, class_name: "Relationship",
                                     foreign_key: "followed_id",
                                     dependent:   :destroy
    has_many :following, through: :active_relationships, source: :followed
    has_many :followers, through: :passive_relationships, source: :follower
    before_save { email.downcase! }
    validates :name, presence: true, length: { maximum: 50 }
    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
    validates :email, presence: true, length: { maximum: 255 },
                      format: { with: VALID_EMAIL_REGEX },
                      uniqueness: true
    has_secure_password
    validates :password, presence: true, length: { minimum: 6 }, allow_nil: true

    # Remembers a user in the database for use in persistent sessions.
    def remember
      self.remember_token = User.new_token
      update_attribute(:remember_digest, User.digest(remember_token))
      remember_digest
    end
  
    # Returns a session token to prevent session hijacking.
    # We reuse the remember digest for convenience.
    def session_token
      remember_digest || remember
    end

    # Returns the hash digest of the given string
    def User.digest(string)
      cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                    BCrypt::Engine.cost
      BCrypt::Password.create(string, cost: cost)
    end

    # Returns a random token.
  def User.new_token
    SecureRandom.urlsafe_base64
  end

  # Defines a proto-feed.
  # See "Following users" for the full implementation
  def feed
    Micropost.where("user_id = ?", id)
  end

  # Returns a user's status feed.
  def feed
    following_ids = "SELECT followed_id FROM relationships
                     WHERE  follower_id = :user_id"
    Micropost.where("user_id IN (#{following_ids})
                     OR user_id = :user_id", user_id: id)
             .includes(:user, image_attachment: :blob)
  end

  # Follows a user.
  def follow(other_user)
    following << other_user unless self == other_user
  end

  # Unfollows a user.
  def unfollow(other_user)
    following.delete(other_user)
  end

  # Returns true if the current user is following the other user.
  def following?(other_user)
    following.include?(other_user)
  end
  
end
