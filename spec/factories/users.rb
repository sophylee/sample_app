FactoryBot.define do 
  factory :user do 
    sequence(:email) { |n| "testuser_#{n}@gifted.software" }
    password { 'P4$sw0rD12' }
  end
end