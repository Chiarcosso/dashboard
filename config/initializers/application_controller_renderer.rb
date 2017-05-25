# Be sure to restart your server when you modify this file.

# ApplicationController.renderer.defaults.merge!(
#   http_host: 'example.org',
#   https: false
# )
ActiveSupport::Dependencies.explicitly_unloadable_constants << 'Handsoap::Service'
