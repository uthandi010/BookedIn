module Api
  class BusinessesController < ApplicationController
    before_action :authenticate_user!

    def index
      memberships = current_user.business_memberships.includes(business: [:business_members, :services])
      render json: memberships.map { |m| business_summary(m.business, m.role) }
    end

    def show
      business = Business.find(params[:id])
      membership = business.business_members.find_by(user_id: current_user.id)
      raise ApplicationController::AuthorizationError if membership.nil?

      render json: business_summary(business, membership.role)
    end

    def create
      business = Business.new(name: params[:name], slug: params[:slug], owner: current_user)

      ActiveRecord::Base.transaction do
        business.save!
        business.business_members.create!(user: current_user, role: :owner)
      end

      render json: business_summary(business, "owner"), status: :created
    rescue ActiveRecord::RecordInvalid => e
      render json: { message: e.record.errors.full_messages.to_sentence }, status: :unprocessable_content
    end

    private

    def business_summary(business, role)
      {
        id: business.id,
        name: business.name,
        slug: business.slug,
        myRole: role.to_s.capitalize,
        memberCount: business.business_members.size,
        serviceCount: business.services.size,
      }
    end
  end
end
