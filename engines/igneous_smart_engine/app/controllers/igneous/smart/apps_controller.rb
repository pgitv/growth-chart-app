require 'igneous/smart'

module Igneous
  module Smart
    class AppsController < Igneous::Smart::ApplicationController

      skip_before_action :ensure_request_is_from_cerner_network, only: [:show]

      # rubocop:disable all
      @@app_param_keys = %w(ehr_source_id id pat_personid pat_pprcode vis_encntrid \
                            usr_personid usr_positioncd dev_location app_appname need_patient_banner \
                            username identity_token)
      # rubocop:enable all

      def index
        render locals: {
          ehr_source_id: params['ehr_source_id'],
          apps: App.all,
          query_string: request.query_string
        }
      end

      def show
        lowercase_params = lowercase_app_params(params)
        if params['ehr_source_id'].blank?
          render locals: {
            url_with_tenant_place_holder: "#{app_url(':tenant_id', params[:id])}?#{request.query_string}",
            user_person_id: lowercase_params['usr_personid']
          }
          return
        elsif lowercase_params['username'].blank?
          render locals: {
            url_with_tenant_place_holder: "#{app_url(params['ehr_source_id'], params[:id])}?#{request.query_string}",
            user_person_id: lowercase_params['usr_personid']
          }
          return
        end

        app = App.find_by app_id: params[:id]

        if app.nil?
          audit_smart_event(:smart_launch_app, :minor_failure, app_id: params[:id], error: 'Unknown Application')
          return head 404
        end

        launch_context = LaunchContext.new
        smart_launch_url = app.smart_launch_url(lowercase_params, launch_context.context_id)
        context = launch_context.context(lowercase_params, app.app_id, smart_launch_url)
        context_data = JSON.parse(context.data)

        audit_smart_launch_app_success(params, context_data)

        if app.authorized
          redirect_to controller: 'user', action: 'preauth', context_id: launch_context.context_id,
                      tenant: params['ehr_source_id'], identity_token: lowercase_params['identity_token']
        else
          redirect_to smart_launch_url
        end
      end

      def create
        app = App.create!(app_params)
        head 201, location: app.app_id
      end

      private

      def app_params
        params.require(:app).permit(:app_id, :name, :launch_url, :igneous_smart_fhir_server_id, :authorized)
      end

      def lowercase_app_params(params)
        # Convert PowerChart params to lowercase as they pass in keys with varying case (see OPENSVC-829)
        app_params = {}
        params.each do |k, v|
          app_params[k.downcase] = v if @@app_param_keys.include?(k.downcase)
        end
        app_params
      end

      def audit_smart_launch_app_success(params, context_data)

        audit_hash = {
          tenant: params['ehr_source_id'],
          user_id: context_data['user'],
          patient_id: context_data['patient'],
          encounter_id: context_data['encounter'],
          container_name: context_data['container_name'],
          app_id: params['id']
        }.reject { |_k, v| v.nil? }

        audit_smart_event(:smart_launch_app, :success, audit_hash)
      end
    end
  end
end
