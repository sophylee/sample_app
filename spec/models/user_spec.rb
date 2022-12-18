require 'spec_helper'

describe User do 
  let(:user) { build(:user, email: email, password: password) }

  describe 'validations' do
    let(:valid_email) { 'user@test.com' }
    let(:valid_password) { 'WatermelonRoofTapMile1!' }
    let(:invalid_email_error_message) { ["Email is invalid"] }
    let(:invalid_password_error_message) { ["Password not strong enough. Please use 1 uppercase, 1 lowercase, 1 digit, and 1 special character."] }
    let(:short_password_error_message) { ["Password is too short (minimum is 10 characters)"] }

    describe 'valid user' do 
      let(:email) { valid_email }
      let(:password) { valid_password }

      it 'marks the user as valid' do 
        expect(user.valid?).to eq(true)
        expect(user.errors.full_messages).to eq([])
      end
    end

    describe 'invalid email' do 
      let(:email) { 'a@a' }
      let(:password) { valid_password }

      it 'marks the user as invalid' do 
        expect(user.valid?).to eq(false)
        expect(user.errors.full_messages).to eq(invalid_email_error_message)
      end
    end

    describe 'short password' do 
      let(:email) { valid_email }
      let(:password) { 'Water1!' }

      it 'marks the user as invalid' do 
        expect(user.valid?).to eq(false)
        expect(user.errors.full_messages).to eq(short_password_error_message)
      end
    end

    describe 'weak password - no uppercase' do 
      let(:email) { valid_email }
      let(:password) { 'watermelonrooftapmile1!' }

      it 'marks the user as invalid' do 
        expect(user.valid?).to eq(false)
        expect(user.errors.full_messages).to eq(invalid_password_error_message)
      end
    end

    describe 'weak password - no lowercase' do 
      let(:email) { valid_email }
      let(:password) { 'WATERMELONROOTTAPMILE1!' }

      it 'marks the user as invalid' do 
        expect(user.valid?).to eq(false)
        expect(user.errors.full_messages).to eq(invalid_password_error_message)
      end
    end

    describe 'weak password - no number' do 
      let(:email) { valid_email }
      let(:password) { 'Watermelonrooftapmile!!' }

      it 'marks the user as invalid' do 
        expect(user.valid?).to eq(false)
        expect(user.errors.full_messages).to eq(invalid_password_error_message)
      end
    end

    describe 'weak password - no special character' do 
      let(:email) { valid_email }
      let(:password) { 'Watermelonrooftapmile12' }

      it 'marks the user as invalid' do 
        expect(user.valid?).to eq(false)
        expect(user.errors.full_messages).to eq(invalid_password_error_message)
      end
    end
  end
end