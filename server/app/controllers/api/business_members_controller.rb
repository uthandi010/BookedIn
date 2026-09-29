module Api
  class BusinessMembersController < ApplicationController
    include BusinessScoped

    def index
      render json: @business.business_members.includes(:user).map { |m| member_summary(m) }
    end

    def create
      require_owner!

      if params[:role].to_s.downcase == "owner"
        return render json: { message: "A business can only have one owner." }, status: :bad_request
      end

      invited = User.find_by(email: params[:email].to_s.strip.downcase)
      if invited.nil?
        return render json: { message: "No account found with that email. They need to register first." },
                      status: :not_found
      end

      member = @business.business_members.new(user: invited, role: params[:role].presence || "staff")

      if member.save
        render json: member_summary(member), status: :created
      else
        render json: { message: member.errors.full_messages.to_sentence }, status: :unprocessable_content
      end
    end

    private

    def member_summary(member)
      { userId: member.user_id, name: member.user.name, email: member.user.email, role: member.role.capitalize }
    end
  end
end
