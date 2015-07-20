require './test/test_helper'

class ClientCanViewEventJsonDataTest < FeatureTest

  def test_view_one_event
    register_site
    Url.create(path: "http://jumpstartlab.com/blog", site_id: @site.id)
    browser1 = Browser.create(name: "Mozilla")
    platform1 = Platform.create(name: "Macintosh")
    event1 = Event.create(name: "socialLogin")
    referrer1 = Referrer.create(path: "espn.com")
    request_type1 = RequestType.create(verb: "GET")

    Payload.create(url_id: 1, resolution_width: "900", resolution_height: "1100",requested_at: "2013-02-16 12:38:28 -0700", responded_in: 37, event_id: event1.id, referrer_id: referrer1.id, browser_id: browser1.id,
                   platform_id: platform1.id, request_type_id: request_type1.id, sha: "alskdjfdflkj")
    Payload.create(url_id: 1, resolution_width: "900", resolution_height: "1100",requested_at: "2013-02-16 12:38:28 -0700", responded_in: 37, event_id: event1.id, referrer_id: referrer1.id, browser_id: browser1.id,
                   platform_id: platform1.id, request_type_id: request_type1.id, sha: "alskd2342lkj")


    visit '/sources/jumpstartlab/events.json'

    assert has_content?('"event":"socialLogin","total_requests":2')
  end

  def test_view_multiple_events
    register_site
    Url.create(path: "http://jumpstartlab.com/blog", site_id: @site.id)
    browser1 = Browser.create(name: "Mozilla")
    browser2 = Browser.create(name: "Chrome")
    platform1 = Platform.create(name: "Macintosh")
    platform2 = Platform.create(name: "Macintosh")
    event1 = Event.create(name: "socialLogin")
    event2 = Event.create(name: "register")
    referrer1 = Referrer.create(path: "espn.com")
    referrer2 = Referrer.create(path: "cnn.com")
    request_type1 = RequestType.create(verb: "GET")
    request_type2 = RequestType.create(verb: "POST")

    Payload.create(url_id: 1, resolution_width: "900", resolution_height: "1100",requested_at: "2013-02-16 12:38:28 -0700", responded_in: 37, event_id: event1.id, referrer_id: referrer1.id, browser_id: browser1.id,
                   platform_id: platform1.id, request_type_id: request_type1.id, sha: "alskdjfdflkj")
    Payload.create(url_id: 1, resolution_width: "600", resolution_height: "800",requested_at: "2013-02-17 08:38:28 -0700", responded_in: 157, event_id: event1.id, referrer_id: referrer2.id, browser_id: browser2.id,
                   platform_id: platform2.id, request_type_id: request_type1.id, sha: "alskdjf234slkj")
    Payload.create(url_id: 1, resolution_width: "900", resolution_height: "1100",requested_at: "2013-02-18 02:38:28 -0700", responded_in: 205, event_id: event2.id, referrer_id: referrer2.id, browser_id: browser2.id,
                   platform_id: platform2.id, request_type_id: request_type2.id, sha: "234djflkj")

    visit '/sources/jumpstartlab/events.json'

    assert has_content?('"event":"socialLogin","total_requests":2')
    assert has_content?('"event":"register","total_requests":1')
  end
end