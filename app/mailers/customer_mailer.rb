class CustomerMailer < ApplicationMailer
  default from: 'atmanirbharfarm@gmail.com'
  layout 'mailer'

  def password_reset_instructions(customer)
    @customer = customer
    @reset_token = customer.password_reset_token
    @app_name = 'AtmaNirbhar Farm'
    @reset_url = customer_reset_password_url(token: @reset_token)

    mail(
      to: @customer.email,
      subject: 'Password Reset Instructions - AtmaNirbhar Farm'
    )
  end

  def password_changed_notification(customer)
    @customer = customer
    @app_name = 'AtmaNirbhar Farm'

    mail(
      to: @customer.email,
      subject: 'Your Password Has Been Changed - AtmaNirbhar Farm'
    )
  end
end
