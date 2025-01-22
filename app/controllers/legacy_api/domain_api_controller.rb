# app/controllers/legacy_api/domain_api_controller.rb

module LegacyAPI
  class DomainAPIController < BaseController
    # Create a domain
    #
    #   URL:            /api/v1/domains/create
    #
    #   Parameters:     name            => REQ: The name of the domain (max 50 characters)
    #
    #   Response:       A hash containing the domain information
    #                   OR an error if the domain could not be created.
    #
    def create
      if api_params["name"].blank?
        render_parameter_error "`name` parameter is required but is missing"
        return
      end

      domain = @current_credential.server.domains.find_by_name(api_params["name"])
      if domain.nil?
        domain = Domain.new(
          server: @current_credential.server,
          name: api_params["name"],
          verification_method: "DNS",
          owner_type: Server,
          owner_id: @current_credential.server.id,
          verified_at: Time.now
        )

        if domain.save
          render_success domain: domain_to_hash(domain)
        else
          error_message = domain.errors.full_messages.first
          if error_message == "Name is invalid"
            render_error "InvalidDomainName", message: "The provided domain name is invalid"
          else
            render_error "UnknownError", message: error_message
          end
        end
      else
        render_error "DomainNameExists", message: "The domain name already exists"
      end
    end

    # Query a domain
    #
    #   URL:            /api/v1/domains/query
    #
    #   Parameters:     name            => REQ: The name of the domain to query
    #
    #   Response:       A hash containing the domain information
    #                   OR an error if the domain does not exist.
    #
    def query
      if api_params["name"].blank?
        render_parameter_error "`name` parameter is required but is missing"
        return
      end

      domain = @current_credential.server.domains.find_by_name(api_params["name"])
      if domain.nil?
        render_error "DomainNotFound", message: "No domain found matching the provided name"
      else
        render_success domain: domain_to_hash(domain)
      end
    end

    # Check domain status
    #
    #   URL:            /api/v1/domains/check
    #
    #   Parameters:     name            => REQ: The name of the domain to check
    #
    #   Response:       A hash containing the domain status information
    #                   OR an error if the domain does not exist.
    #
    def check
      if api_params["name"].blank?
        render_parameter_error "`name` parameter is required but is missing"
        return
      end

      domain = @current_credential.server.domains.find_by_name(api_params["name"])
      if domain.nil?
        render_error "DomainNotFound", message: "No domain found matching the provided name"
      else
        domain.check_dns(:manual)
        render_success domain: domain_to_hash(domain)
      end
    end

    # Delete a domain
    #
    #   URL:            /api/v1/domains/delete
    #
    #   Parameters:     name            => REQ: The name of the domain to delete
    #
    #   Response:       A success message if deleted successfully
    #                   OR an error if the domain could not be deleted.
    #
    def delete
      if api_params["name"].blank?
        render_parameter_error "`name` parameter is required but is missing"
        return
      end

      domain = @current_credential.server.domains.find_by_name(api_params["name"])
      if domain.nil?
        render_error "DomainNotFound", message: "No domain found matching the provided name"
      elsif domain.delete
        render_success message: "Domain deleted successfully"
      else
        render_error "DomainNotDeleted", message: "Domain could not be deleted"
      end
    end

    private

    # Helper method to convert a domain object into a hash
    def domain_to_hash(domain)
      {
        id: domain.id,
        name: domain.name,
        verification_method: domain.verification_method,
        owner_type: domain.owner_type,
        owner_id: domain.owner_id,
        verified_at: domain.verified_at&.to_f
        spf_status: domain.spf_status,
        spf_error: domain.spf_error,
        dkim_status: domain.dkim_status,
        dkim_error: domain.dkim_error
        return_path_status: domain.return_path_status,
        return_path_error: domain.return_path_error,
        dkim_record: domain.dkim_record,
        dkim_identifier: domain.dkim_identifier,
        spf_record: domain.spf_record
        spf_identifier: domain.spf_identifier,
        return_path_domain: domain.return_path_domain
      }
    end
  end
end
