class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, 
         :lockable

  validates_format_of :password,
                      with: /(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-])/,
                      if: -> {
                        password.present? &&
                          encrypted_password.present? &&
                          encrypted_password_changed?
                      },
                      message: :complexity
end
