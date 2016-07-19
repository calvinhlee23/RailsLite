require 'active_support'
require 'active_support/core_ext'
require 'erb'
require_relative './session'

class ControllerBase
  attr_reader :req, :res, :params

  # Setup the controller
  def initialize(req, res)
    @req = req
    @res = res
  end

  # Helper method to alias @already_built_response
  def already_built_response?
    return true if @already_built_response
    false
  end

  # Set the response status code and header
  def redirect_to(url)
    unless already_built_response?
      @res.header["location"] = url
      @res.status = 302
      @already_built_response = "redirect_to #{url}"
      self.session.store_session(@res)
    else
      raise "you cannot redirect more than once"
    end
  end

  # Populate the response with content.
  # Set the response's content type to the given type.
  # Raise an error if the developer tries to double render.
  def render_content(content, content_type)
    if @already_built_response
      raise "you cannot render more than once"
    else
      @already_built_response = content
    end
    @res['Content-Type'] = content_type
    @res.body = [content]
    self.session.store_session(@res)
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
      controller_name = self.class.to_s[/(.*)[^Controller]/]

      content = "<h1> ALL THE #{controller_name.upcase} </h1>"

      content += File.read("../views/#{controller_name.downcase}_controller/#{template_name}.html.erb")
      template = ERB.new(content).result(binding)
      render_content(template, "text/html")
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(self.req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
  end
end
