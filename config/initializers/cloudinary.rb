require 'cloudinary'

# Load Cloudinary configuration from environment variables or cloudinary.yml
begin
  # Try environment variables first (recommended for production)
  if ENV['CLOUDINARY_CLOUD_NAME'].present?
    Cloudinary.config do |config|
      config.cloud_name = ENV['CLOUDINARY_CLOUD_NAME']
      config.api_key = ENV['CLOUDINARY_API_KEY']
      config.api_secret = ENV['CLOUDINARY_API_SECRET']
      config.secure = true
    end
    Rails.logger.info "Cloudinary configured from environment variables"
  else
    # Fallback to cloudinary.yml
    cloudinary_config = Rails.application.config_for(:cloudinary)

    if cloudinary_config.present?
      Cloudinary.config do |config|
        config.cloud_name = cloudinary_config['cloud_name']
        config.api_key = cloudinary_config['api_key']
        config.api_secret = cloudinary_config['api_secret']
        config.secure = cloudinary_config['secure'] || true
      end
      Rails.logger.info "Cloudinary configured from config/cloudinary.yml"
    else
      Rails.logger.warn "Cloudinary configuration not found. Please set environment variables or check config/cloudinary.yml"
    end
  end
rescue => e
  Rails.logger.error "Failed to configure Cloudinary: #{e.message}"
end