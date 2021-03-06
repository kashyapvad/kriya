class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_action :configure_permitted_parameters,:set_raven_context, if: :devise_controller?

  acts_as_token_authentication_handler_for User, fallback: :none
  acts_as_token_authentication_handler_for Freelancer, fallback: :none

  before_action do
    if current_user && current_user.email == "cqpanxu@gmail.com"
      Rack::MiniProfiler.authorize_request
    end

    if freelancer_signed_in? && (session[:last_seen_at] == nil || session[:last_seen_at] < 15.minutes.ago)
      session[:last_seen_at] = Time.now
      current_freelancer.update_attribute(:last_seen_at, Time.now)
    end

    if user_signed_in? && (session[:last_seen_at] == nil || session[:last_seen_at] < 15.minutes.ago)
      session[:last_seen_at] = Time.now
      current_user.update_attribute(:last_seen_at, Time.now)
    end
  end

  def slack_integration_html
    link = view_context.link_to slack_integration_url, class: 'slack-button' do
      view_context.image_tag 'https://platform.slack-edge.com/img/add_to_slack.png', alt: 'Add this task to Slack'
    end

    @slack_integration_html = "</br>#{link}".html_safe
  end

  def slack_integration_url
    "https://slack.com/oauth/authorize?&scope=chat:write:bot%20chat:write:user%20files:write:user%20groups:history%20groups:read%20groups:write%20pins:write%20identify%20incoming-webhook%20channels:read%20channels:write&client_id=#{Rails.application.secrets.slack_app_id}"
  end

  def css_class_name
    "#{controller_name}-#{action_name}"
  end

  helper_method :css_class_name
  helper_method :slack_integration_html
  helper_method :slack_integration_url

  private

  def set_raven_context
    Raven.user_context(id: session[:current_user_id]) # or anything else in session
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end

  def authenticate_manager!
    return user_signed_in? && current_user.manager?
  end

  def authenticate!
    return user_signed_in? || freelancer_signed_in?
  end

  def set_meta(options={})
    site_name   = "Goomp"
    title       = "Goomp"
    description = "Goomp is an exclusive member only group where creators share network, mentorship and premium content for free or a membership fee"
    image       = ActionController::Base.helpers.asset_path("logo-v.png")
    current_url = request.url
    keywords = %w[迅雷 bt 下载 网盘 高清 电影 动漫 日剧 美剧 天天 720p 1080p]

    # Let's prepare a nice set of defaults
    defaults = {
      site:        site_name,
      title:       title,
      reverse: true,
      separator: '-',
      image:       image,
      description: description,
      keywords:    keywords,
      twitter: {
        site_name: site_name,
        site: '@thecookieshq',
        card: 'summary',
        description: description,
        image: image
      },
      og: {
        url: current_url,
        site_name: site_name,
        title: title,
        image: image,
        description: description,
        type: 'website'
      }
    }

    options.reverse_merge!(defaults)

    @meta_tags = options
  end

  protected

  def configure_permitted_parameters
    keys = %i(
      username
      bio
      first_name
      last_name picture
      headline
      work_experience
      gender
      profile_attributes
    )
    devise_parameter_sanitizer.permit(:sign_up) do |user|
      user.permit(:email, :password, :password_confirmation, :unsername, :bio, :first_name, :last_name, :picture, :headline, :work_experience, :gender)
    end
    devise_parameter_sanitizer.permit(:sign_up) do |freelancer|
      freelancer.permit(:email, :password, :password_confirmation, :unsername, :bio, :first_name, :last_name, :picture, :headline, :work_experience, :gender, :category, :availability, :primary_skill, :years_of_experiences, :project_description, :project_url, :professional_profile_link1, :professional_profile_link2, skill_ids: [])
    end
  end

  def respond_modal_with(*args, &blk)
    options = args.extract_options!
    options[:responder] = ModalResponder
    respond_with *args, options, &blk
  end

  # The path used after sign in.
  def after_sign_in_path_for(resource)
    root_path
  end

  def set_raven_context
    Raven.user_context(id: session[:current_user_id]) # or anything else in session
    Raven.extra_context(params: params.to_unsafe_h, url: request.url)
  end

  def manager
    @manager ||= User.manager
  end
end
