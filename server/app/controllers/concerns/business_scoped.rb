# Shared by every controller nested under /api/businesses/:business_id/...
# Loads the business and enforces that the current user is a member of it
# before any action runs - mirroring the same "membership + role" check on
# every request, not just in one place.
module BusinessScoped
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
    before_action :set_business
    before_action :set_membership!
  end

  private

  def set_business
    @business = Business.find(params[:business_id])
  end

  def set_membership!
    @membership = @business.business_members.find_by(user_id: current_user.id)
    raise ApplicationController::AuthorizationError if @membership.nil?
  end

  def require_owner!
    raise ApplicationController::AuthorizationError unless @membership.owner?
  end
end
