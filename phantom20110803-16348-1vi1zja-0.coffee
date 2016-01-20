waitFor = (testFx, onReady, timeOutMillis=3000) ->
    start = new Date().getTime()
    condition = false
    f = ->
        if (new Date().getTime() - start < timeOutMillis) and not condition
            # If not time-out yet and condition not yet fulfilled
            condition = (if typeof testFx is 'string' then eval testFx else testFx()) #< defensive code
        else
            if not condition
                # If condition still not fulfilled (timeout but condition is 'false')
                phantom.exit(1)
            else
                # Condition fulfilled (timeout and/or condition is 'true')
                if typeof onReady is 'string' then eval onReady else onReady() #< Do what it's supposed to do once the condition is fulfilled
                clearInterval interval #< Stop this interval
    interval = setInterval f, 250 #< repeat check every 250ms


page = new WebPage()
page.viewportSize = { width: 600, height : 600 }

page.resources = []
page.onResourceRequested = (req) ->
  page.resources[req.id] =
    request: req
    startReply: null
    endReply: null
page.onResourceReceived = (res) ->
  if res.stage is 'start'
    console.log res
    page.resources[res.id].startReply = res
  if res.stage is 'end'
    console.log res
    page.resources[res.id].endReply = res

page.onConsoleMessage = (msg) -> console.log msg

page.onAlert = (msg) ->
  console.log 'ALERT: "'+msg+'"'
  time = new Date().getTime()
  page.render userid+'-'+time+'-error.png'
  phantom.exit(1)

userid = phantom.args[0]

page.open 'http://orin.meinlschmidt.org/~znouza/swamp/sp/abc.php', (status) ->
  
  waitFor ->
    page.evaluate ->
      waitFor = (testFx, onReady, timeOutMillis=3000) ->
         start = new Date().getTime()
         condition = false
         f = ->
             if (new Date().getTime() - start < timeOutMillis) and not condition
                 condition = (if typeof testFx is 'string' then eval testFx else testFx()) #< defensive code
             else
                 if not condition
                     console.log "'waitFor()' timeout"
                     phantom.exit(1)
                 else
                     console.log "'waitFor()' finished in #{new Date().getTime() - start}ms."
                     if typeof onReady is 'string' then eval onReady else onReady() #< Do what it's supposed to do once the condition is fulfilled
                     clearInterval interval #< Stop this interval
         interval = setInterval f, 250 #< repeat check every 250ms

     
      clickelement = (element, evttype = 'click') ->
        evt = document.createevent("mouseevents")
        evt.initmouseevent(evttype, true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
        if element
          element.dispatchevent(evt)
      
      blurelement = (element, evttype = 'blur') ->
        evt = document.createevent('htmlevents')
        evt.initevent('blur', true, true)
        if element
          element.dispatchevent evt
   
      filltext = (element, value) ->
        el = body.queryselector element
        return unless el
        el.value = value
      
      clickbutton = (element) ->
        el = body.queryselector element
        return unless el
        el.click()

      selectvalue = (element, value) ->
        filltext element, value

      body = document.body
      console.log 'title1 = '+document.title
      filltext 'input[name=jmeno]', 'jmeno'
      filltext 'input[name=prijmeni]', ''
      filltext 'input[name=age]', ''
      filltext 'select[name=gender]', ''
      clickbutton 'input[name=submit]'
      console.log 'submitted'
      console.log 'title2 = '+document.title
      return true

  , ->
    result = page.evaluate ->
      console.log 'title3 = '+document.title
      result = document.body.querySelector('#result').innerHTML
    
    res = 1 #error
    res = 0 if result.length > 0
    console.log result
    phantom.exit(res)
