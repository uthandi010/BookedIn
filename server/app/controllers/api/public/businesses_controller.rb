module Api
  module Public
    class BusinessesController < ApplicationController
      def show
        business = Business.find_by!(slug: params[:slug])

        render json: {
          name: business.name,
          slug: business.slug,
          services: business.services.active.map { |s|
            {
              id: s.id,
              name: s.name,
              durationMinutes: s.duration_minutes,
              priceCents: s.price_cents,
              description: s.description,
            }
          },
        }
      end
    end
  end
end
