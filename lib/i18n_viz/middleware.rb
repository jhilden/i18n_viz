module I18nViz
  class Middleware
    JS  = File.read(File.join(File.dirname(__FILE__), '..', '..', 'assets', 'javascripts', 'i18n_viz.js' ))
    CSS = File.read(File.join(File.dirname(__FILE__), '..', '..', 'assets', 'stylesheets', 'i18n_viz.css' ))

    attr_accessor :external_tool_url
    attr_accessor :css_override
    def initialize(app, &block)
      @app = app

      yield(self) if block_given?
    end

    def call(env)
      @status, @headers, @body = @app.call(env)
      return [@status, @headers, @body] if !html? || !(env["QUERY_STRING"] =~ /i18n_viz/ || env["HTTP_COOKIE"] =~ /i18n_viz/)

      response = Rack::Response.new([], @status, @headers)

      @body.each { |fragment| response.write inject(env, fragment) }
      @body.close if @body.respond_to?(:close)

      response.finish
    end

    private

    def html?; @headers['Content-Type'] =~ /html/; end

    def inject(env, response)
      tool_url = external_tool_url.respond_to?(:call) ? external_tool_url.call(env) : external_tool_url

      response.sub! %r{</body>} do |m|
        style_and_script = %Q{
<script type='application/javascript'>
window.I18nViz = {
  regex:             new RegExp(/--([a-z0-9_\.]+)--/i),
  global_regex:      new RegExp(/--([a-z0-9_\.]+)--/gi),
  external_tool_url: '#{tool_url}'
}
#{JS}
</script>

<style>
#{CSS}
#{css_override}
</style>
}
        style_and_script << m.to_s
      end
      response
    end
  end

end

