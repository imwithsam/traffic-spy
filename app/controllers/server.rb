module TrafficSpy
  class Server < Sinatra::Base
    register Sinatra::Partial
    set :partial_template_engine, :erb
    get '/' do
      erb :index
    end

    post '/sources' do
      parsed_params = HashParser.parse(params)
      site = Site.new(parsed_params)

      if site.save
        status 200
        body "{'#{params.keys.first}':'#{site.identifier}'}"
      elsif site.errors.full_messages.join.include?("blank")
        status 400
        body site.errors.full_messages.join(", ")
      else
        status 403
        body site.errors.full_messages.join(", ")
      end
    end

    get '/sources/:identifier.json' do |identifier|
      @identifier = identifier
      @site = Site.find_by(:identifier => @identifier)
      urls = @site.payloads.group(:url).count.sort_by {  |_, v| v }.reverse
      browsers = @site.payloads.group(:browser).count.sort_by { |_, v| v }.reverse
      platforms = @site.payloads.group(:platform).count.sort_by { |_, v| v }.reverse
      screens = @site.payloads.group(:resolution_width, :resolution_height).count.sort_by { |_, v| v }.reverse
      response_times = @site.payloads.group(:url).average(:responded_in).sort_by {  |_, v| v }

      @browsers       = {}
      @sorted_urls    = {}
      @platforms      = {}
      @screens        = {}
      @response_times = {}

       urls.each do |url|
        @sorted_urls[url.first.path] = url.last
       end

      browsers.each do |browser|
        @browsers[browser.first.name] = browser.last
      end

      platforms.map do |platform|
        @platforms[platform.first.name] = platform.last
      end

      screens.map do |screen|
        @screens[screen.first.join('x')] = screen.last
      end

      response_times.map do |time|
        @response_times[time.first.path] = time.last.to_i
      end

      content_type :json
      { :sorted_urls => @sorted_urls, :browsers => @browsers,
        :platforms => @platforms, :screens => @screens,
        :response_times => @response_times }.to_json

    end

    get '/sources/:identifier' do |identifier|
      @identifier = identifier
      site = Site.find_by(:identifier => identifier)

      if site.blank?
        @message = "The identifier, #{identifier}, does not exist."

        erb :message
      else
        @dashboard_renderer = DashboardRenderer.new(identifier, site)

        erb :dashboard
      end
    end

    get '/sources/:identifier/urls.json' do |identifier|
      @identifier = identifier
      @site = Site.find_by(:identifier => @identifier)

      content_type :json
      @site.urls.map do |url|
        @fastest_response_time = url.payloads.minimum(:responded_in)
        @slowest_response_time = url.payloads.maximum(:responded_in)
        @average_response_time = url.payloads.average(:responded_in).round(2)
        http_verbs = url.payloads.group(:request_type).count.sort_by { |_, v| v }.reverse
        top_referrers = url.payloads.group(:referrer).count.sort_by { |_, v| v }.reverse
        top_browsers = url.payloads.group(:browser).count.sort_by { |_, v| v }.reverse
        top_platforms = url.payloads.group(:platform).count.sort_by { |_, v| v }.reverse

        @http_verbs       = {}
        @top_referrers    = {}
        @top_browsers     = {}
        @top_platforms    = {}

        http_verbs.map do |verb|
          @http_verbs[verb.first.verb] = verb.last
        end

        top_referrers.map do |referrer|
          @top_referrers[referrer.first.path] = referrer.last
        end

        top_browsers.map do |browser|
          @top_browsers[browser.first.name] = browser.last
        end

        top_platforms.map do |platform|
          @top_platforms[platform.first.name] = platform.last
        end

        { :url => url.path,:data => {:fastest_response_time => @fastest_response_time,
                                     :slowest_response_time => @slowest_response_time,
                                     :average_reponse_time => @average_response_time,
                                     :http_verbs => @http_verbs,
                                     :top_referrers => @top_referrers,
                                     :top_browsers => @top_browsers,
                                     :top_platforms => @top_platforms} }
      end.to_json

    end

    get '/sources/:identifier/urls/:relative_path' do |identifier, relative_path|
      @identifier = identifier
      site = Site.find_by(:identifier => identifier)
      url = site.urls.find_by(:path => "#{site.root_url}/#{relative_path}")

      if url.blank?
        @message = "The URL path, /#{relative_path}, has not been requested."

        erb :message
      else
        @url_data_renderer = UrlDataRenderer.new(relative_path, url)

        erb :url_data
      end
    end

    get '/sources/:identifier/events.json' do |identifier|
      @identifier = identifier
      @site = Site.find_by(:identifier => @identifier)
      @events = @site.payloads.group(:event).count.sort_by { |_, v| v }.reverse

      content_type :json
      @events.map do |event|
        { :event => event.first.name, :total_requests  => event.last }
      end.to_json

    end

    get '/sources/:identifier/events' do |identifier|
      @identifier = identifier
      site = Site.find_by(:identifier => @identifier)

      if site.blank?
        @message = "The identifier, #{identifier}, does not exist."

        erb :message
      else
        @events = site.payloads.group(:event).count.sort_by { |_, v| v }.reverse

        erb :event_index
      end
    end

    get '/sources/:identifier/events/:event_name' do |identifier, event_name|
      @identifier = identifier
      site = Site.find_by(:identifier => identifier)
      event = site.events.find_by(:name => event_name)

      if event.blank?
        @message = "The event, '#{event_name}', has not been requested."

        erb :message
      else
        @event_data_renderer = EventDataRenderer.new(identifier, event_name, site, event)

        erb :event_data
      end
    end

    post "/sources/:identifier/data" do |identifier|
      @identifier = identifier
      site = Site.find_by(:identifier => identifier)
      sha = Payload.create_sha(params[:payload])
      sha_exists = Payload.exists?(:sha => sha)

      if !params[:payload]
        status 400
        body "Payload is missing"
      elsif site.blank?
        status 403
        body "Application not registered"
      elsif sha_exists
        status 403
        body "Payload already received"
      else
        if Payload.process(site, sha, params[:payload]).save
          status 200
        end
      end
    end

    not_found do
      @message = "AHHHHH! 404 not found!"

      erb :message
    end
  end
end

