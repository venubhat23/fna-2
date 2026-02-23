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
    begin
      cloudinary_config = Rails.application.config_for(:cloudinary)

      if cloudinary_config.present? && cloudinary_config['cloud_name'].present?
        Cloudinary.config do |config|
          config.cloud_name = cloudinary_config['cloud_name']
          config.api_key = cloudinary_config['api_key']
          config.api_secret = cloudinary_config['api_secret']
          config.secure = cloudinary_config['secure'] || true
        end
        Rails.logger.info "Cloudinary configured from config/cloudinary.yml with cloud_name: #{cloudinary_config['cloud_name']}"
      else
        # Set default configuration to prevent errors
        Cloudinary.config do |config|
          config.cloud_name = "dfbg5qy10"
          config.api_key = "514942996649779"
          config.api_secret = "spvCKAjnscmgGXwOZar_JwNt29Y"
          config.secure = true
        end
        Rails.logger.warn "Using hardcoded Cloudinary configuration as fallback"
      end
    rescue => config_error
      # If config_for fails, use hardcoded values
      Cloudinary.config do |config|
        config.cloud_name = "dfbg5qy10"
        config.api_key = "514942996649779"
        config.api_secret = "spvCKAjnscmgGXwOZar_JwNt29Y"
        config.secure = true
      end
      Rails.logger.warn "Failed to load cloudinary.yml, using hardcoded configuration: #{config_error.message}"
    end
  end

  # Verify configuration is properly set
  if Cloudinary.config.cloud_name.blank?
    Rails.logger.error "Cloudinary cloud_name is still not set after configuration attempt"
  else
    Rails.logger.info "Cloudinary configuration verified with cloud_name: #{Cloudinary.config.cloud_name}"
  end
rescue => e
  Rails.logger.error "Failed to configure Cloudinary: #{e.message}"
  # Set minimal fallback configuration
  Cloudinary.config do |config|
    config.cloud_name = "dfbg5qy10"
    config.api_key = "514942996649779"
    config.api_secret = "spvCKAjnscmgGXwOZar_JwNt29Y"
    config.secure = true
  end
end