module Api
  class ServicesController < ApplicationController
    include BusinessScoped

    def index
      render json: @business.services.map { |s| service_summary(s) }
    end

    def create
      require_owner!
      service = @business.services.new(service_attributes)

      if service.save
        render json: service_summary(service), status: :created
      else
        render json: { message: service.errors.full_messages.to_sentence }, status: :unprocessable_content
      end
    end

    def update
      require_owner!
      service = @business.services.find(params[:id])

      if service.update(service_attributes)
        render json: service_summary(service)
      else
        render json: { message: service.errors.full_messages.to_sentence }, status: :unprocessable_content
      end
    end

    def destroy
      require_owner!
      service = @business.services.find(params[:id])
      service.destroy
      head :no_content
    rescue ActiveRecord::RecordNotDestroyed
      render json: { message: "Can't delete a service that already has appointments booked." },
             status: :unprocessable_content
    end

    private

    # Built from individually-read param values (never mass-assigned from
    # the raw params object), so this needs no strong-parameters allowlist
    # while still keeping the wire format (camelCase) separate from the
    # model's own attribute names (snake_case).
    def service_attributes
      {
        name: params[:name],
        duration_minutes: params[:durationMinutes],
        price_cents: params[:priceCents],
        description: params[:description],
        active: params[:active],
      }.compact
    end

    def service_summary(service)
      {
        id: service.id,
        name: service.name,
        durationMinutes: service.duration_minutes,
        priceCents: service.price_cents,
        description: service.description,
        active: service.active,
      }
    end
  end
end
